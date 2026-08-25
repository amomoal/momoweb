import 'package:flutter/material.dart';

import 'auth_token_store.dart';
import 'pages.dart';

class WebUpdateAdminApp extends StatelessWidget {
  const WebUpdateAdminApp({
    required this.apiBaseUrl,
    required this.apiAuthToken,
    required this.publicSiteUrl,
    super.key,
  });

  final String apiBaseUrl;
  final String apiAuthToken;
  final String publicSiteUrl;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'サイト更新',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff5d6f5f),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfffaf8f3),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: AppEntryPoint(
        apiBaseUrl: apiBaseUrl,
        initialAuthToken: apiAuthToken,
        authTokenStore: const AuthTokenStore(),
        publicSiteUrl: publicSiteUrl,
      ),
    );
  }
}
