import 'package:admin_app/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the initial admin screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const WebUpdateAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('サイト更新'), findsOneWidget);
    expect(find.text('純喫茶 ロマン'), findsOneWidget);
    expect(find.text('お知らせ'), findsOneWidget);
    expect(find.text('画像'), findsOneWidget);
    expect(find.text('内容を確認して更新'), findsOneWidget);
  });
}
