import 'dart:async';
import 'dart:io' as io;
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'models/bau_cua_face.dart';
import 'models/cup_state.dart';
import 'models/rule_config.dart';
import 'screens/lobby_screen.dart';
import 'screens/table_screen.dart';
import 'services/device_activity_service.dart';
import 'services/asset_preloader.dart';
import 'services/machine_identity_service.dart';
import 'services/offline_law_generator.dart';
import 'services/result_generator.dart';
import 'services/rule_listener_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
        webExperimentalAutoDetectLongPolling: true,
      );
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
    firebaseReady = true;
  } catch (error) {
    debugPrint('Firebase init failed: $error');
  }
  runApp(BauCuaApp(firebaseReady: firebaseReady));
}

class BauCuaApp extends StatelessWidget {
  const BauCuaApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bầu Cua Tết 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D7A45),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: BauCuaGame(firebaseReady: firebaseReady),
    );
  }
}

enum GameView { lobby, table }

class BauCuaGame extends StatefulWidget {
  const BauCuaGame({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<BauCuaGame> createState() => _BauCuaGameState();
}

class _BauCuaGameState extends State<BauCuaGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final Random _random = Random();
  late final ResultGenerator _resultGenerator;
  final DeviceActivityService _activityService = DeviceActivityService();
  final MachineIdentityService _machineIdentityService =
      MachineIdentityService();
  final List<BauCuaFace> _faces = const [
    BauCuaFace.nai,
    BauCuaFace.bau,
    BauCuaFace.ga,
    BauCuaFace.ca,
    BauCuaFace.cua,
    BauCuaFace.tom,
  ];
  static const List<BauCuaFace> _defaultResults = [
    BauCuaFace.bau,
    BauCuaFace.bau,
    BauCuaFace.bau,
  ];

  late final AnimationController _shakeController;
  late final AudioPlayer _musicPlayer;
  late final AudioPlayer _dicePlayer;
  bool _musicStartInProgress = false;
  bool _musicDisposeStarted = false;
  bool _onlineReportInProgress = false;
  late List<BauCuaFace> _results;
  List<BauCuaFace>? _shownResults;
  List<BauCuaFace>? _luatConBaseResults;
  StreamSubscription<RuleSnapshot>? _ruleSubscription;

  GameView _view = GameView.lobby;
  CupState _cupState = CupState.opened;
  bool _soundEnabled = true;
  bool _online = false;
  String _machineId = '---';
  String _checkHack = '---';
  RemoteRuleConfig _remoteConfig = RemoteRuleConfig.empty();
  final DateTime _onlineStartedAt = DateTime.now();
  int _shakeCount = 0;
  String _lastRemoteCommandId = '';
  List<BauCuaFace>? _pendingRemoteResults;
  Timer? _shakeTimer;
  Timer? _clockTimer;
  Timer? _activityTimer;
  Timer? _connectionGraceTimer;
  bool _exitingApp = false;
  bool _assetsReady = false;

  String get _machineStatusText {
    final connectionCode = _online ? 'AM1' : 'AM0';
    return '$connectionCode:$_machineId.$_checkHack';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resultGenerator = ResultGenerator(_random);
    _results = List<BauCuaFace>.from(_defaultResults);
    _shownResults = List<BauCuaFace>.from(_defaultResults);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _musicPlayer = AudioPlayer(playerId: 'background_music');
    _dicePlayer = AudioPlayer(playerId: 'dice_sound');
    unawaited(_configureMusicPlayer());
    unawaited(_configureDicePlayer());
    _refreshCheckHack();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _refreshCheckHack();
    });
    unawaited(_initMachine());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(
      AssetPreloader.start(context).whenComplete(() {
        if (mounted && !_assetsReady) {
          setState(() => _assetsReady = true);
        }
      }),
    );
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _clockTimer?.cancel();
    _activityTimer?.cancel();
    _connectionGraceTimer?.cancel();
    _ruleSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_reportOffline());
    _shakeController.dispose();
    unawaited(_disposeMusicPlayer());
    unawaited(_disposeDicePlayer());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_exitingApp) {
      unawaited(_reportOnline());
    }
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(_exitWhenBackgrounded());
    } else if (state == AppLifecycleState.detached) {
      unawaited(_reportOffline());
    }
  }

  Future<void> _exitWhenBackgrounded() async {
    if (_exitingApp) return;
    _exitingApp = true;
    _shakeTimer?.cancel();
    _clockTimer?.cancel();
    _activityTimer?.cancel();
    _connectionGraceTimer?.cancel();
    await _ruleSubscription?.cancel();
    _shakeController.stop();

    try {
      await Future.wait([
        _reportOffline()
            .timeout(const Duration(milliseconds: 800), onTimeout: () {})
            .catchError((_) {}),
        _stopBackgroundMusic()
            .timeout(const Duration(milliseconds: 500), onTimeout: () {})
            .catchError((_) {}),
      ]);
    } finally {
      await SystemNavigator.pop();
    }
  }

  Future<void> _quitApp() async {
    if (_exitingApp) return;
    _exitingApp = true;
    _shakeTimer?.cancel();
    _clockTimer?.cancel();
    _activityTimer?.cancel();
    _connectionGraceTimer?.cancel();
    await _ruleSubscription?.cancel();
    _shakeController.stop();

    await Future.wait([
      _reportOffline()
          .timeout(const Duration(milliseconds: 800), onTimeout: () {})
          .catchError((_) {}),
      _stopBackgroundMusic()
          .timeout(const Duration(milliseconds: 500), onTimeout: () {})
          .catchError((_) {}),
    ]);

    if (io.Platform.isIOS) {
      io.exit(0);
    }
    await SystemNavigator.pop();
  }

  Future<void> _initMachine() async {
    final machineId = await _machineIdentityService.getOrCreateMachineId();
    if (!mounted) return;
    setState(() => _machineId = machineId);
    if (widget.firebaseReady) {
      _startRuleListener(machineId);
      unawaited(_reportOnline());
      _activityTimer?.cancel();
      _activityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        unawaited(_reportOnline());
      });
    }
  }

  Future<void> _reportOnline() async {
    if (!widget.firebaseReady || _machineId == '---') return;
    if (_onlineReportInProgress) return;
    _onlineReportInProgress = true;
    try {
      await _activityService.reportOnline(
        machineId: _machineId,
        onlineStartedAt: _onlineStartedAt,
        shakeCount: _shakeCount,
      ).timeout(const Duration(seconds: 6));
      _connectionGraceTimer?.cancel();
      if (mounted && !_online) {
        setState(() => _online = true);
      }
    } on TimeoutException catch (error) {
      debugPrint('Activity online report timeout: $error');
      _scheduleOfflineAfterGrace();
    } catch (error) {
      debugPrint('Activity online report failed: $error');
      _scheduleOfflineAfterGrace();
    } finally {
      _onlineReportInProgress = false;
    }
  }

  Future<void> _reportOffline() async {
    if (!widget.firebaseReady || _machineId == '---') return;
    try {
      await _activityService.reportOffline(
        machineId: _machineId,
        onlineStartedAt: _onlineStartedAt,
        shakeCount: _shakeCount,
      );
    } catch (error) {
      debugPrint('Activity offline report failed: $error');
    }
  }

  void _startRuleListener(String machineId) {
    _ruleSubscription?.cancel();
    _ruleSubscription = RuleListenerService()
        .watchMachine(machineId)
        .listen(
          (snapshot) {
            if (!mounted) return;
            if (snapshot.online) {
              _connectionGraceTimer?.cancel();
              setState(() {
                _remoteConfig = snapshot.hasData
                    ? snapshot.config
                    : RemoteRuleConfig.empty();
                _online = true;
              });
              _handleRemoteCommand(snapshot.config.control);
            } else {
              _scheduleOfflineAfterGrace();
            }
            _refreshCheckHack();
          },
          onError: (Object error) {
            debugPrint('Rule listener error: $error');
            _scheduleOfflineAfterGrace();
          },
        );
  }

  void _scheduleOfflineAfterGrace() {
    if (_connectionGraceTimer?.isActive == true) return;
    _connectionGraceTimer?.cancel();
    _connectionGraceTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted || !_online) return;
      setState(() => _online = false);
    });
  }

  void _refreshCheckHack() {
    final nextCheckHack = OfflineLawGenerator.currentCheckHack();
    if (_checkHack == nextCheckHack) return;
    setState(() => _checkHack = nextCheckHack);
  }

  void _handleRemoteCommand(RemoteControlConfig control) {
    if (!control.enabled) {
      _pendingRemoteResults = null;
      return;
    }

    if (control.commandId.isEmpty || control.commandId == _lastRemoteCommandId) {
      return;
    }

    _lastRemoteCommandId = control.commandId;
    if (_cupState == CupState.opened) {
      return;
    }

    final results = _resultsFromRemoteCommand(control);
    if (results == null) {
      return;
    }

    setState(() => _pendingRemoteResults = results);
  }

  List<BauCuaFace>? _resultsFromRemoteCommand(RemoteControlConfig control) {
    if (control.commandFaces.length >= 3) {
      return control.commandFaces.take(3).toList();
    }
    return _resultsFromRemoteDigits(control.commandDigits);
  }

  List<BauCuaFace>? _resultsFromRemoteDigits(String digits) {
    final diceOrder = _remoteConfig.luatCon.diceOrder;
    final results = <BauCuaFace>[];
    for (final unit in digits.codeUnits) {
      final digit = unit - 48;
      if (digit < 0 || digit > 5) {
        continue;
      }
      results.add(diceOrder[digit]);
      if (results.length == 3) {
        return results;
      }
    }
    return null;
  }

  Future<void> _playBackgroundMusic() async {
    if (!_soundEnabled || _musicStartInProgress || _musicDisposeStarted) return;
    _musicStartInProgress = true;
    try {
      await _musicPlayer.play(AssetSource('nhac_nen.mp3'));
    } on TimeoutException catch (error) {
      debugPrint('Background music start timeout: $error');
    } catch (error) {
      debugPrint('Background music start failed: $error');
    } finally {
      _musicStartInProgress = false;
    }
  }

  Future<void> _stopBackgroundMusic() async {
    if (_musicDisposeStarted) return;
    try {
      await _musicPlayer.stop();
    } on TimeoutException catch (error) {
      debugPrint('Background music stop timeout: $error');
    } catch (error) {
      debugPrint('Background music stop failed: $error');
    }
  }

  Future<void> _pauseBackgroundMusic() async {
    if (_musicDisposeStarted) return;
    try {
      await _musicPlayer.pause();
    } on TimeoutException catch (error) {
      debugPrint('Background music pause timeout: $error');
    } catch (error) {
      debugPrint('Background music pause failed: $error');
    }
  }

  Future<void> _configureMusicPlayer() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
    } on TimeoutException catch (error) {
      debugPrint('Background music configuration timeout: $error');
    } catch (error) {
      debugPrint('Background music configuration failed: $error');
    }
  }

  Future<void> _disposeMusicPlayer() async {
    if (_musicDisposeStarted) return;
    _musicDisposeStarted = true;
    try {
      await _musicPlayer.dispose();
    } on TimeoutException catch (error) {
      debugPrint('Background music dispose timeout: $error');
    } catch (error) {
      debugPrint('Background music dispose failed: $error');
    }
  }

  void _playDiceSound() {
    unawaited(_startDiceSound());
  }

  Future<void> _startDiceSound() async {
    try {
      await _dicePlayer.stop().timeout(const Duration(milliseconds: 500));
      await _dicePlayer
          .play(AssetSource('sound_xucsac.m4a'))
          .timeout(const Duration(seconds: 3));
    } on TimeoutException catch (error) {
      debugPrint('Dice sound start timeout: $error');
    } catch (error) {
      debugPrint('Dice sound start failed: $error');
    }
  }

  Future<void> _configureDicePlayer() async {
    try {
      await _dicePlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _dicePlayer.setReleaseMode(ReleaseMode.stop);
      await _dicePlayer.setAudioContext(
        AudioContextConfig(
          route: AudioContextConfigRoute.system,
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: false,
        ).build(),
      );
    } on TimeoutException catch (error) {
      debugPrint('Dice sound configuration timeout: $error');
    } catch (error) {
      debugPrint('Dice sound configuration failed: $error');
    }
  }

  Future<void> _disposeDicePlayer() async {
    try {
      await _dicePlayer.dispose();
    } on TimeoutException catch (error) {
      debugPrint('Dice sound dispose timeout: $error');
    } catch (error) {
      debugPrint('Dice sound dispose failed: $error');
    }
  }

  void _startGame() {
    unawaited(_playBackgroundMusic());
    setState(() {
      _view = GameView.table;
      _cupState = CupState.opened;
      _results = List<BauCuaFace>.from(_defaultResults);
      _shownResults = List<BauCuaFace>.from(_defaultResults);
      _luatConBaseResults = null;
    });
  }

  void _backToLobby() {
    _shakeTimer?.cancel();
    _shakeController.stop();
    unawaited(_stopBackgroundMusic());
    setState(() {
      _view = GameView.lobby;
      _cupState = CupState.opened;
      _results = List<BauCuaFace>.from(_defaultResults);
      _shownResults = List<BauCuaFace>.from(_defaultResults);
      _luatConBaseResults = null;
    });
  }

  void _toggleSound() {
    final enabled = !_soundEnabled;
    setState(() => _soundEnabled = enabled);
    if (enabled && _view == GameView.table) {
      unawaited(_playBackgroundMusic());
    } else {
      unawaited(_pauseBackgroundMusic());
    }
  }

  void _shake() {
    _shakeTimer?.cancel();
    _shakeController.stop();
    _shakeController.value = 0;
    _playDiceSound();
    setState(() {
      _cupState = CupState.shaking;
      _shakeCount += 1;
      _pendingRemoteResults = null;
    });
    unawaited(_reportOnline());

    _shakeTimer = Timer(const Duration(milliseconds: 620), () {
      if (!mounted || _cupState != CupState.shaking) return;
      setState(() {
        _results = _resultGenerator.randomRoll(_faces);
      });
      _shakeController.forward(from: 0);
      _shakeTimer = Timer(const Duration(milliseconds: 360), () {
        if (!mounted) return;
        _shakeController.stop();
        _shakeController.value = 0;
        setState(() {
          _cupState = CupState.covered;
        });
      });
    });
  }

  void _openCup(CupOpenZone zone) {
    if (_cupState != CupState.covered) return;
    final remoteResults = _pendingRemoteResults;
    final previousResults = _luatConBaseResults == null
        ? null
        : List<BauCuaFace>.from(_luatConBaseResults!);
    final candidate =
        remoteResults ??
        _resultGenerator.roll(
          faces: _faces,
          remoteConfig: _remoteConfig,
          online: _online,
          machineId: _machineId == '---' ? '000' : _machineId,
          now: OfflineLawGenerator.vietnamNow(),
          openZone: zone,
          previousResults: previousResults,
        );
    final results = _enforceLuatCai(
      candidate,
      zone,
      previousResults: previousResults,
    );
    setState(() {
      _cupState = CupState.opened;
      _results = results;
      _shownResults = List<BauCuaFace>.from(_results);
      _luatConBaseResults = _canUseAsLuatConBase(_results)
          ? List<BauCuaFace>.from(_results)
          : null;
      _pendingRemoteResults = null;
    });
  }

  List<BauCuaFace> _enforceLuatCai(
    List<BauCuaFace> candidate,
    CupOpenZone zone, {
    required List<BauCuaFace>? previousResults,
  }) {
    final rule = _remoteConfig.luatCai;
    if (!_online || !rule.enabled) return candidate;

    final blocked = rule.blockedFor(zone);
    if (blocked.isEmpty || !candidate.any(blocked.contains)) return candidate;

    final regenerated = _resultGenerator.roll(
      faces: _faces,
      remoteConfig: _remoteConfig,
      online: true,
      machineId: _machineId == '---' ? '000' : _machineId,
      now: OfflineLawGenerator.vietnamNow(),
      openZone: zone,
      previousResults: previousResults,
    );
    if (!regenerated.any(blocked.contains)) return regenerated;

    final allowed = _faces.where((face) => !blocked.contains(face)).toList();
    return List<BauCuaFace>.generate(
      3,
      (_) => allowed[_random.nextInt(allowed.length)],
    );
  }

  bool _canUseAsLuatConBase(List<BauCuaFace> results) {
    if (_online) {
      final rule = _remoteConfig.luatCon;
      if (!rule.enabled) return false;
      for (var index = 0; index < results.length && index < 3; index++) {
        final avoid = index < rule.selectedCons.length
            ? rule.selectedCons[index]
            : null;
        if (avoid != null && results[index] == avoid) return false;
      }
      return true;
    }

    final now = OfflineLawGenerator.vietnamNow();
    final law = OfflineLawGenerator.generate(
      machineCode: _machineId == '---' ? '000' : _machineId,
      date: now,
      hour: now.hour,
    );
    return !results.contains(law.avoidFace);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _view == GameView.lobby
            ? LobbyScreen(
                key: const ValueKey('lobby'),
                assetsReady: _assetsReady,
                onPlay: _assetsReady ? _startGame : null,
                onQuit: () => unawaited(_quitApp()),
              )
            : TableScreen(
                key: const ValueKey('table'),
                results: _results,
                shownResults: _shownResults,
                faces: _faces,
                cupState: _cupState,
                soundEnabled: _soundEnabled,
                shakeAnimation: _shakeController,
                onBack: _backToLobby,
                onToggleSound: _toggleSound,
                onShake: _shake,
                onOpen: _openCup,
                machineStatusText: _machineStatusText,
                machineId: _machineId,
                remoteControlled: _remoteConfig.control.enabled,
              ),
      ),
    );
  }
}
