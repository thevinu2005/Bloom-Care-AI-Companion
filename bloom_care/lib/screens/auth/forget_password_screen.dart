import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  String _email = '';

  ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your email to receive password reset code',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _sendResetInstructions(context),
                child: const Text('Send Reset Instructions'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Remember your password?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendResetInstructions(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Implement actual password reset logic here
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset code sent to your email'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );

      // Optional: Navigate back to sign-in screen after a short delay
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pop(context);
      });
    }
  }
}

