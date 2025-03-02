import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bloom_care/screens/auth/signup_page.dart';
import 'package:bloom_care/screens/auth/forgot password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Check these import paths are correct
import 'package:bloom_care/screens/home/caregviver_home.dart';  // Note: possible typo in 'caregviver'
import 'package:bloom_care/screens/home/elders_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle email/password sign in
  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (userCredential.user != null) {
          print('User authenticated successfully with UID: ${userCredential.user!.uid}');
          print('Email: ${userCredential.user!.email}');
          
          try {
            // First verify the user exists in Firestore
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();

            print('Attempting to fetch user document...');
            print('Document exists: ${userDoc.exists}');
            
            if (userDoc.exists) {
              final userData = userDoc.data();
              print('User data retrieved: $userData');
              
              // Verify all required fields
              if (userData != null && userData.containsKey('userType')) {
                final userType = userData['userType'] as String?;
                print('User type found: $userType');
                
                if (mounted) {
                  if (userType == 'caregiver' || userType == 'family_member') {
                    print('Navigating to CaregiverHomePage');
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const CaregiverHomePage()),
                    );
                  } else if (userType == 'elder') {
                    print('Navigating to BloomCareHomePage');
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const BloomCareHomePage()),
                    );
                  } else {
                    print('Invalid user type detected: $userType');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Invalid user type. Please contact support.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                print('User type field missing in document');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: User type not found. Please complete registration.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  // Optionally navigate to complete profile setup
                  // Navigator.of(context).pushReplacement(
                  //   MaterialPageRoute(builder: (context) => const CompleteProfilePage()),
                  // );
                }
              }
            } else {
              print('No user document found for UID: ${userCredential.user!.uid}');
              // Create a new user document if it doesn't exist
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userCredential.user!.uid)
                    .set({
                  'email': userCredential.user!.email,
                  'createdAt': FieldValue.serverTimestamp(),
                  // Add any other default fields needed
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please complete your profile setup'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  // Navigate to complete profile setup
                  // Navigator.of(context).pushReplacement(
                  //   MaterialPageRoute(builder: (context) => const CompleteProfilePage()),
                  // );
                }
              } catch (e) {
                print('Error creating new user document: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating user profile: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          } catch (e) {
            print('Error accessing Firestore: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error accessing user data: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An error occurred';
        
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found with this email';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email address';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'This account has been disabled';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Handle Google sign in
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Get user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userType = userDoc.data()?['userType'] as String?;
          
          if (mounted) {
            if (userType == 'caregiver' || userType == 'family_member') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const CaregiverHomePage()),
              );
            } else if (userType == 'elder') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const BloomCareHomePage()),
              );
            } else {
              // Handle unknown user type
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error: Invalid user type'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in with Google: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'New to the app? ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontFamily: 'PlayfairDisplay',
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                                  );
                                },
                                child: const Text(
                                  'Sign up',
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
                          const SizedBox(height: 60),
                          Image.asset(
                            'assest/images/signup.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    enabled: !_isLoading,
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
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    keyboardType: TextInputType.visiblePassword,
                                    textInputAction: TextInputAction.done,
                                    enabled: !_isLoading,
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
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _isLoading ? null : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                        );
                                      },
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Color(0xFF6B84DC),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 60),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleSignIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6B84DC),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Or login with',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        icon: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B84DC)),
                                                ),
                                              )
                                            : Image.asset(
                                                'assest/images/google icon.png',
                                                height: 24,
                                              ),
                                        label: const Text('Google'),
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

