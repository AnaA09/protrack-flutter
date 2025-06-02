import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/services.dart';
import 'routes/app_routes.dart';
import 'services/cognito_service.dart';
import 'services/user_metadata_service.dart';
import 'services/api_service.dart';

Future<void> _configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);

    // Load the configuration file
    final configFile =
        await rootBundle.loadString('assets/amplifyconfiguration.json');
    await Amplify.configure(configFile);

    print('Amplify configured successfully');
  } catch (e) {
    print('Error configuring Amplify: $e');
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProTrackApp());
}

class ProTrackApp extends StatefulWidget {
  const ProTrackApp({super.key});

  @override
  State<ProTrackApp> createState() => _ProTrackAppState();
}

class _ProTrackAppState extends State<ProTrackApp> {
  bool _isAmplifyConfigured = false;
  late CognitoService _cognitoService;
  late UserMetadataService _userMetadataService;
  late ApiService _apiService;
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _configureAmplify();
    _cognitoService = CognitoService();
    _userMetadataService = UserMetadataService(
      'https://acnpe7a49i.execute-api.us-east-1.amazonaws.com/prod',
      _cognitoService,
    );

    // Get the ID token if user is signed in
    String? idToken;
    if (await _cognitoService.isSignedIn()) {
      idToken = await _cognitoService.getIdToken();
    }

    _apiService = ApiService(
      baseUrl: 'https://acnpe7a49i.execute-api.us-east-1.amazonaws.com/prod',
      authToken: idToken,
    );

    _cognitoService.setUserMetadataService(_userMetadataService);
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final isAuthenticated = await _cognitoService.isSignedIn();
    setState(() {
      _initialRoute = !hasSeenOnboarding
          ? AppRoutes.onboarding
          : isAuthenticated
              ? AppRoutes.home
              : AppRoutes.login;
      _isAmplifyConfigured = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAmplifyConfigured || _initialRoute == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _cognitoService),
        Provider.value(value: _userMetadataService),
        Provider.value(value: _apiService),
      ],
      child: MaterialApp(
        title: 'ProTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            primary: const Color(0xFF1E88E5),
            secondary: const Color(0xFF03A9F4),
            tertiary: const Color(0xFF00BCD4),
            background: Colors.white,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        initialRoute: _initialRoute,
        routes: AppRoutes.getRoutes(),
      ),
    );
  }
}
