import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cognito_service.dart';
import '../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final cognitoService =
                  Provider.of<CognitoService>(context, listen: false);
              await cognitoService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}
