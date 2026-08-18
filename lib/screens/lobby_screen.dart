import 'package:flutter/material.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({
    super.key,
    required this.assetsReady,
    required this.onPlay,
    required this.onQuit,
  });

  final bool assetsReady;
  final VoidCallback? onPlay;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxWidth / 430).clamp(0.78, 1.12);
              return Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 72 * scale),
                      child: SizedBox(
                        width: 380 * scale,
                        height: 315 * scale,
                        child: Image.asset(
                          'assets/hinh_cho.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 500 * scale,
                    left: 0,
                    right: 0,
                    child: _LobbyImageButton(
                      asset: 'assets/btn_choi.png',
                      enabled: assetsReady && onPlay != null,
                      onPressed: onPlay,
                    ),
                  ),
                  Positioned(
                    top: 650 * scale,
                    left: 0,
                    right: 0,
                    child: _LobbyImageButton(
                      asset: 'assets/btn_thoat.png',
                      onPressed: onQuit,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LobbyImageButton extends StatelessWidget {
  const _LobbyImageButton({
    required this.asset,
    required this.onPressed,
    this.enabled = true,
  });

  final String asset;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.68,
          child: Image.asset(
            asset,
            width: 245,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
