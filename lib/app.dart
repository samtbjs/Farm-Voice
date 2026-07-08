import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/sign_in_screen.dart';

/// Top-level app widget: applies the theme and opens into Sign In,
/// which leads to Home, which leads into the combined Advisory chat.
class FarmVoiceApp extends StatelessWidget {
  const FarmVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Voice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SignInScreen(),
    );
  }
}
