import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'user_metadata_service.dart';

class CognitoService extends ChangeNotifier {
  static const String _userPoolId = 'us-east-1_oEvEdG7hY';
  static const String _clientId = '112eapunjrouch2koprr5kf5hd';
  static const String _identityPoolId =
      'us-east-1:b534c259-e111-454a-9ebd-d759e2ea4394';
  static const String _region = 'us-east-1';

  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn();
  bool _isSignedIn = false;
  String? _name;
  String? _email;
  String? _userId;
  UserMetadataService? _userMetadataService;

  void setUserMetadataService(UserMetadataService service) {
    _userMetadataService = service;
  }

  // Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userAttributes = {
        CognitoUserAttributeKey.email: email,
        CognitoUserAttributeKey.name: name,
      };

      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );

      _name = name;
      _email = email;
      notifyListeners();
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        // Try to sign in with the email as username
        final result = await Amplify.Auth.signIn(
          username: email,
          password: password,
        );

        if (result.isSignedIn) {
          final session = await Amplify.Auth.fetchAuthSession();
          _userId = email; // Using email as userId since it's unique
          await _saveSession(session);
          return true;
        }
        return false;
      } catch (e) {
        // Retry if credential store is still loading
        if (e.toString().contains('CredentialStoreLoadingStoredCredentials')) {
          retryCount++;
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        print('Error signing in: $e');

        // Check if the error is a UserNotConfirmedException
        if (e.toString().contains('UserNotConfirmedException')) {
          throw Exception(
              'UserNotConfirmedException: Please verify your email before signing in.');
        }

        // Check if the error is a UserNotFoundException
        if (e.toString().contains('UserNotFoundException')) {
          throw Exception(
              'UserNotFoundException: User does not exist. Please register first.');
        }

        // Check if the error is an incorrect password
        if (e.toString().contains('Incorrect username or password')) {
          throw Exception('Incorrect username or password. Please try again.');
        }

        // Rethrow other errors to be handled by the UI
        rethrow;
      }
    }
    throw Exception(
        'Credential store not ready. Please try again in a moment.');
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return false;

      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.google,
      );

      if (result.isSignedIn) {
        final session = await Amplify.Auth.fetchAuthSession();
        await _saveSession(session);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in with Google: $e');
      return false;
    }
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.apple,
      );

      if (result.isSignedIn) {
        final session = await Amplify.Auth.fetchAuthSession();
        await _saveSession(session);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in with Apple: $e');
      return false;
    }
  }

  // Forgot password
  Future<bool> forgotPassword(String email) async {
    try {
      await Amplify.Auth.resetPassword(username: email);
      return true;
    } catch (e) {
      print('Error initiating forgot password: $e');
      return false;
    }
  }

  // Confirm forgot password
  Future<bool> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: code,
      );
      return true;
    } catch (e) {
      print('Error confirming forgot password: $e');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await Amplify.Auth.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      await _googleSignIn.signOut();
      await _storage.delete(key: 'cognito_session');
      _isSignedIn = false;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      return false;
    }
  }

  // Save session
  Future<void> _saveSession(AuthSession session) async {
    try {
      if (session is CognitoAuthSession) {
        final sessionData = {
          'isSignedIn': session.isSignedIn.toString(),
        };
        await _storage.write(
          key: 'cognito_session',
          value: json.encode(sessionData),
        );
        _isSignedIn = session.isSignedIn;

        // Get and store the Cognito user sub (UUID) as userId
        final attributes = await Amplify.Auth.fetchUserAttributes();
        _userId = attributes
            .firstWhere(
              (attr) => attr.userAttributeKey == CognitoUserAttributeKey.sub,
              orElse: () => throw Exception('No Cognito user sub found'),
            )
            .value;

        notifyListeners();
      }
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  Future<bool> confirmSignUp({
    required String email,
    required String confirmationCode,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );

      if (result.isSignUpComplete) {
        // Check if user is already signed in
        final isAlreadySignedIn = await isSignedIn();

        if (!isAlreadySignedIn) {
          // Only sign in if not already signed in
          final signInResult = await Amplify.Auth.signIn(
            username: email,
            password: password,
          );

          if (signInResult.isSignedIn) {
            final session = await Amplify.Auth.fetchAuthSession();
            await _saveSession(session);
          }
        }

        // Create user metadata in DynamoDB regardless of sign in state
        if (_userMetadataService != null) {
          try {
            await _userMetadataService!.createUserMetadata({
              'email': email,
              'name': _name,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              'role': '',
              'education': '',
              'location': '',
              'phone': '',
            });
          } catch (e) {
            print('Error creating user metadata: $e');
            // Don't throw here as the user is already registered in Cognito
          }
        }
        notifyListeners();
      }
      return result.isSignUpComplete;
    } catch (e) {
      print('Error in confirmSignUp: $e');
      rethrow;
    }
  }

  Future<void> resendSignUpCode({required String email}) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<CognitoAuthSession?> getCurrentSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is CognitoAuthSession) {
        return session;
      }
      return null;
    } catch (e) {
      print('Error getting current session: $e');
      return null;
    }
  }

  Future<String?> getIdToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is CognitoAuthSession) {
        final tokens = session.userPoolTokensResult.valueOrNull;
        if (tokens != null) {
          final idToken = tokens.idToken.raw;
          print('Got ID token: ${idToken.substring(0, 10)}...');
          return idToken;
        }
      }
      return null;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  String? get userId => _userId;
}
