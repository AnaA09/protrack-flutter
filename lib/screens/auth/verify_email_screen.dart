import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cognito_service.dart';
import '../../routes/app_routes.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String password;

  const VerifyEmailScreen({
    Key? key,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cognitoService =
          Provider.of<CognitoService>(context, listen: false);
      final isVerified = await cognitoService.confirmSignUp(
        email: widget.email,
        confirmationCode: _codeController.text,
        password: widget.password,
      );

      if (isVerified) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    try {
      final cognitoService =
          Provider.of<CognitoService>(context, listen: false);
      await cognitoService.resendSignUpCode(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Please enter the verification code sent to ${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyEmail,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Verify Email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _resendCode,
                child: const Text('Resend Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
