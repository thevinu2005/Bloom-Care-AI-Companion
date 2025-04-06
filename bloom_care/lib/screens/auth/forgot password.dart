import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloom_care/screens/auth/login_screen.dart';
import 'package:bloom_care/screens/auth/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Define the possible states for the password reset flow
  int _currentStep = 0; // 0: email, 1: verification code, 2: new password, 3: success
  
  // Form keys for validation
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final _emailController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Focus nodes for verification code
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  // Loading state
  bool _isLoading = false;
  
  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Firebase auth
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Send verification code to email
  Future<void> _sendVerificationCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        final email = _emailController.text.trim();
        
        // This would actually send an email in a real app
        // For testing, it returns the code
        final code = await authService.sendPasswordResetCode(email);
        
        // For testing purposes only - in a real app, you wouldn't show this
        print('Verification code: $code'); // Remove in production
        
        setState(() {
          _isLoading = false;
          _currentStep = 1; // Move to verification code step
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Resend verification code
  Future<void> _resendCode() async {
    // Clear existing code fields
    for (var controller in _codeControllers) {
      controller.clear();
    }
    
    // Focus on first field
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
    
    // Resend code
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real implementation, you would call your service to resend a verification code
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent to your email'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend verification code: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Verify the code entered by user
  Future<void> _verifyCode() async {
    // Check if all code fields are filled
    bool isValid = true;
    for (var controller in _codeControllers) {
      if (controller.text.isEmpty) {
        isValid = false;
        break;
      }
    }
    
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all digits of the verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine the code from all text fields
      final code = _codeControllers.map((controller) => controller.text).join();
      final email = _emailController.text.trim();
      
      final authService = AuthService();
      final isValid = await authService.verifyPasswordResetCode(email, code);
      
      if (isValid) {
        setState(() {
          _isLoading = false;
          _currentStep = 2; // Move to new password step
        });
      } else {
        throw Exception('Invalid verification code');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Reset password with new password
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        final email = _emailController.text.trim();
        final newPassword = _passwordController.text;
        
        await authService.resetPassword(email, newPassword);
        
        setState(() {
          _isLoading = false;
          _currentStep = 3; // Move to success step
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get screen title based on current step
  String _getScreenTitle() {
    switch (_currentStep) {
      case 0:
        return 'Forgot Password';
      case 1:
        return 'Verification Code';
      case 2:
        return 'New Password';
      case 3:
        return 'Success';
      default:
        return 'Forgot Password';
    }
  }

  // Get screen subtitle based on current step
  String _getScreenSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter your email and we\'ll send you a verification code';
      case 1:
        return 'Enter the verification code sent to ${_emailController.text}';
      case 2:
        return 'Create a new password for your account';
      case 3:
        return 'Your password has been reset successfully';
      default:
        return 'Enter your email and we\'ll send you a verification code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assest/images/background_for_welcome.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay
          Container(
            color: const Color(0xFF6B84DC).withOpacity(0.7),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                            onPressed: () {
                              if (_currentStep == 0) {
                                Navigator.of(context).pop();
                              } else {
                                setState(() {
                                  _currentStep--;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getScreenTitle(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getScreenSubtitle(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // White Container with Form
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          Image.asset(
                            'assest/images/signup.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: _buildCurrentStepWidget(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build widget based on current step
  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildEmailInputForm();
      case 1:
        return _buildVerificationCodeForm();
      case 2:
        return _buildNewPasswordForm();
      case 3:
        return _buildSuccessMessage();
      default:
        return _buildEmailInputForm();
    }
  }

  // Email input form
  Widget _buildEmailInputForm() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: const TextStyle(color: Colors.black87),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B84DC)),
            hintText: 'Enter your email',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6B84DC)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B84DC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Send Verification Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: const Text(
            'Back to Login',
            style: TextStyle(
              color: Color(0xFF6B84DC),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Verification code form
  Widget _buildVerificationCodeForm() {
    return Column(
      children: [
        const Text(
          'Enter 6-digit code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: 40,
              child: TextField(
                controller: _codeControllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6B84DC)),
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B84DC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Verify Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive the code? ",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resendCode,
              child: const Text(
                'Resend',
                style: TextStyle(
                  color: Color(0xFF6B84DC),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // New password form
  Widget _buildNewPasswordForm() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'New Password',
            labelStyle: const TextStyle(color: Colors.black87),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B84DC)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            hintText: 'Enter your new password',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6B84DC)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            labelStyle: const TextStyle(color: Colors.black87),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B84DC)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            hintText: 'Confirm your new password',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6B84DC)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B84DC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  // Success message
  Widget _buildSuccessMessage() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF6B84DC),
          size: 80,
        ),
        const SizedBox(height: 20),
        const Text(
          'Password Reset Successful!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your password has been reset successfully. You can now log in with your new password.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B84DC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Go to Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

