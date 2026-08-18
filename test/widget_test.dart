import 'package:baucua2027_ios_game/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens the Bau Cua table from the lobby', (tester) async {
    await tester.pumpWidget(const BauCuaApp(firebaseReady: false));

    expect(find.text('Bầu Cua Tết 2026'), findsOneWidget);
    expect(find.text('CHƠI'), findsOneWidget);

    await tester.tap(find.text('CHƠI'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('MỞ'), findsOneWidget);

    await tester.tap(find.text('MỞ'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('XÓC'), findsOneWidget);
  });
}
