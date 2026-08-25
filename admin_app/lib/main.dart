import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  runApp(
    const WebUpdateAdminApp(
      apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
      apiAuthToken: String.fromEnvironment('API_AUTH_TOKEN'),
      publicSiteUrl: String.fromEnvironment(
        'PUBLIC_SITE_URL',
        defaultValue: 'https://momoweb.pages.dev',
      ),
    ),
  );
}
