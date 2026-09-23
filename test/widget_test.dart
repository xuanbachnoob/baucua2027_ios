import 'package:baucua2027_ios_game/main.dart';
import 'package:baucua2027_ios_game/screens/lobby_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the lobby image controls', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const BauCuaApp(firebaseReady: false));
    await tester.pumpAndSettle();

    expect(find.byType(LobbyScreen), findsOneWidget);
    expect(_assetImage('assets/btn_choi.png'), findsOneWidget);
    expect(_assetImage('assets/btn_thoat.png'), findsOneWidget);
  });
}

Finder _assetImage(String assetName) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName,
  );
}
