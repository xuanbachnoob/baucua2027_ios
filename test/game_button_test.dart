import 'package:baucua2027_ios_game/widgets/game_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps touch position when the UI rebuilds during a tap', (
    tester,
  ) async {
    final rebuild = ValueNotifier<int>(0);
    Offset? pressedAt;

    Widget buildButton() {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder<int>(
              valueListenable: rebuild,
              builder: (context, value, child) {
                return GameButton(
                  key: const ValueKey('open-button'),
                  label: 'MO',
                  icon: null,
                  onPressed: () {},
                  onPressedAt: (position) => pressedAt = position,
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildButton());
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('MO')),
    );

    rebuild.value += 1;
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(pressedAt, isNotNull);
    expect(pressedAt!.dx, closeTo(110, 1));
    expect(pressedAt!.dy, closeTo(42, 1));
  });
}
