import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth/verify_email_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String onboarding = '/onboarding';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      home: (context) => const HomeScreen(),
      onboarding: (context) => const OnboardingScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      verifyEmail: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return VerifyEmailScreen(
          email: args['email'],
          password: args['password'],
        );
      },
    };
  }
}
