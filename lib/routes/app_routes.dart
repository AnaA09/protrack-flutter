import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/settings_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String onboarding = '/onboarding';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String settings = '/settings';
  static const String profile = '/settings/profile';
  static const String security = '/settings/security';
  static const String help = '/settings/help';
  static const String about = '/settings/about';
  static const String privacyPolicy = '/settings/privacy';
  static const String termsOfService = '/settings/terms';

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
      settings: (context) => const SettingsPage(),
      profile: (context) => const SettingsPage(), // TODO: Create ProfilePage
      security: (context) => const SettingsPage(), // TODO: Create SecurityPage
      help: (context) => const SettingsPage(), // TODO: Create HelpPage
      about: (context) => const SettingsPage(), // TODO: Create AboutPage
      privacyPolicy: (context) =>
          const SettingsPage(), // TODO: Create PrivacyPolicyPage
      termsOfService: (context) =>
          const SettingsPage(), // TODO: Create TermsOfServicePage
    };
  }
}
