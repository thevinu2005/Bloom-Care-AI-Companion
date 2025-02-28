import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloom_care/screens/auth/auth_service.dart';
import 'package:bloom_care/screens/auth/login_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dateController = TextEditingController();

  // Add this to your _SignUpPageState class
  String? _selectedUserType;
  final _familyMemberController = TextEditingController();
  final Set<String> _selectedHobbies = {};
  final Set<String> _selectedFavorites = {};

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dateController.dispose();
    _familyMemberController.dispose();
    // ... rest of your dispose code
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B84DC),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
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
                image: AssetImage('assets/images/background_for_welsome.jpg'),
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
                          // Sign Up Text
                          const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Already registered text
                          Row(
                            children: [
                              const Text(
                                'Already registered? ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontFamily: 'PlayfairDisplay',
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                                  );
                                },
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                    fontFamily: 'PlayfairDisplay',
                                  ),
                                ),
                              ),
                            ],
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
                          // Illustration
                          Image.asset(
                            'assets/images/signup_illustration.png', // Add your illustration here
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Name Field
                                  TextFormField(
                                    controller: _nameController,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(color: Colors.black87),
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                      labelStyle: const TextStyle(color: Colors.black87),
                                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6B84DC)),
                                      hintText: 'Enter your name',
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
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
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
                                  const SizedBox(height: 20),
                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    keyboardType: TextInputType.visiblePassword,
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(color: Colors.black87),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: const TextStyle(color: Colors.black87),
                                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B84DC)),
                                      hintText: 'Enter your password',
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
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // Date of Birth Field
                                  TextFormField(
                                    controller: _dateController,
                                    readOnly: true,
                                    style: const TextStyle(color: Colors.black87),
                                    decoration: InputDecoration(
                                      labelText: 'Date of Birth',
                                      labelStyle: const TextStyle(color: Colors.black87),
                                      prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF6B84DC)),
                                      hintText: 'Select your date of birth',
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
                                    onTap: () => _selectDate(context),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select your date of birth';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // User Type Dropdown
                                  DropdownButtonFormField<String>(
                                    value: _selectedUserType,
                                    decoration: InputDecoration(
                                      labelText: 'User Type',
                                      labelStyle: const TextStyle(color: Colors.black87),
                                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6B84DC)),
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
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'caregiver',
                                        child: Text('Caregiver'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'elder',
                                        child: Text('Elder'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'family_member',
                                        child: Text('Family Member'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUserType = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select a user type';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Conditional Family Member Field
                                  if (_selectedUserType == 'family_member')
                                    TextFormField(
                                      controller: _familyMemberController,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.done,
                                      style: const TextStyle(color: Colors.black87),
                                      decoration: InputDecoration(
                                        labelText: 'Specify Family Member Type',
                                        labelStyle: const TextStyle(color: Colors.black87),
                                        prefixIcon: const Icon(Icons.family_restroom, color: Color(0xFF6B84DC)),
                                        hintText: 'e.g., Son, Daughter, Spouse',
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
                                        if (_selectedUserType == 'family_member' && (value == null || value.isEmpty)) {
                                          return 'Please specify your relationship';
                                        }
                                        return null;
                                      },
                                    ),
                                  const SizedBox(height: 40),
                                  // Sign Up Button
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          // Handle sign up logic
                                          final userData = {
                                            'name': _nameController.text,
                                            'email': _emailController.text,
                                            'password': _passwordController.text,
                                            'dateOfBirth': _dateController.text,
                                            'userType': _selectedUserType,
                                            'familyMemberType': _selectedUserType == 'family_member' 
                                                ? _familyMemberController.text 
                                                : null,
                                            'hobbies': _selectedUserType == 'elder' 
                                                ? _selectedHobbies.toList() 
                                                : null,
                                            'favorites': _selectedUserType == 'elder' 
                                                ? _selectedFavorites.toList() 
                                                : null,
                                          };
                                          // Process the userData
                                          
                                          // Show success message
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Sign up successful!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          
                                          // Navigate to login page
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(builder: (context) => const SignUpPage()),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6B84DC),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          try {
                                            final UserCredential? result = await _authService.signInWithGoogle();
                                            if (result != null && result.user != null) {
                                              setState(() {
                                                _nameController.text = result.user!.displayName ?? '';
                                                _emailController.text = result.user!.email ?? '';
                                              });
                                              
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Successfully signed in with Google'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error signing in with Google: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        icon: Image.asset(
                                          'assets/images/google_logo.png',
                                          height: 24,
                                        ),
                                        label: const Text('Google'),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          try {
                                            final UserCredential? result = await _authService.signInWithFacebook();
                                            if (result != null && result.user != null) {
                                              setState(() {
                                                _nameController.text = result.user!.displayName ?? '';
                                                _emailController.text = result.user!.email ?? '';
                                              });
                                              
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Successfully signed in with Facebook'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                          }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error signing in with Facebook: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF1877F2),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        icon: Image.asset(
                                          'assets/images/facebook_logo.png',
                                          height: 24,
                                        ),
                                        label: const Text('Facebook'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
}

