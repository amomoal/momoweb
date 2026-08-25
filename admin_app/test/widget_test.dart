import 'package:admin_app/app.dart';
import 'package:admin_app/pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the initial admin screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const WebUpdateAdminApp(
        apiBaseUrl: '',
        apiAuthToken: '',
        publicSiteUrl: 'https://momoweb.pages.dev',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('サイト更新'), findsOneWidget);
    expect(find.text('純喫茶 ロマン'), findsOneWidget);
    expect(find.text('お知らせ'), findsOneWidget);
    expect(find.text('画像'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('admin-content-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(find.text('内容を確認して更新'), findsOneWidget);
  });

  testWidgets('shows remember input checkbox on access key screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: AccessKeyPage(onSubmit: (_) {})));
    await tester.pumpAndSettle();

    expect(find.text('更新キー'), findsOneWidget);
    expect(find.text('更新キーを入力'), findsOneWidget);
    expect(find.text('入力内容を次回も表示'), findsOneWidget);
  });
}
