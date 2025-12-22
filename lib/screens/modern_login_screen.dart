import 'package:flutter/material.dart';
import 'package:lifeprint/authservice.dart';
import 'package:lifeprint/screens/modern_forgot_screen.dart';
import 'package:lifeprint/screens/modern_register_screen.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await loginPage(
        EmailAddress: _emailController.text.trim(),
        Password: _passwordController.text,
        context: context,
      );
    } catch (e) {
      // Error handling is done in authservice.dart
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;
    final isLargeScreen = screenWidth >= 1200;
    
    // Responsive padding
    final horizontalPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 32.0 : 48.0);
    final formPadding = isSmallScreen ? 20.0 : (isMediumScreen ? 28.0 : 32.0);
    final topSpacing = isSmallScreen ? 20.0 : (isMediumScreen ? 30.0 : 40.0);
    final formSpacing = isSmallScreen ? 30.0 : (isMediumScreen ? 40.0 : 50.0);
    
    // Responsive container width
    final maxFormWidth = isLargeScreen ? 500.0 : (isMediumScreen ? 450.0 : double.infinity);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                child: Column(
                  children: [
                    SizedBox(height: topSpacing),
                    // Logo and Welcome
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Welcome Back',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    fontSize: isSmallScreen ? 28 : (isMediumScreen ? 32 : 36),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Text(
                              'Sign in to continue your journey',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: formSpacing),
                    // Login Form
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: maxFormWidth),
                          padding: EdgeInsets.all(formPadding),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  hintText: 'Enter your email',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.white.withOpacity(0.7),
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 16,
                                    vertical: isSmallScreen ? 12 : 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  hintText: 'Enter your password',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.white.withOpacity(0.7),
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white.withOpacity(0.7),
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 16,
                                    vertical: isSmallScreen ? 12 : 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => const ModernForgotScreen(),
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              return SlideTransition(
                                                position:
                                                    Tween<Offset>(
                                                      begin: const Offset(1, 0),
                                                      end: Offset.zero,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: animation,
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                child: child,
                                              );
                                            },
                                        transitionDuration: const Duration(
                                          milliseconds: 300,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: isSmallScreen ? 13 : 14,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 20 : 30),
                              // Login Button
                              Container(
                                height: isSmallScreen ? 48 : 56,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    onTap: _isLoading ? null : _handleLogin,
                                    child: Center(
                                      child: _isLoading
                                          ? SizedBox(
                                              width: isSmallScreen ? 20 : 24,
                                              height: isSmallScreen ? 20 : 24,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                      Colors.white,
                                                    ),
                                              ),
                                            )
                                          : Text(
                                              'Sign In',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: isSmallScreen ? 16 : 18,
                                                  ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 20 : 30),
                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 20 : 30),
                              // Register Button
                              Container(
                                height: isSmallScreen ? 48 : 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => const ModernRegisterScreen(),
                                          transitionsBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                return SlideTransition(
                                                  position:
                                                      Tween<Offset>(
                                                        begin: const Offset(1, 0),
                                                        end: Offset.zero,
                                                      ).animate(
                                                        CurvedAnimation(
                                                          parent: animation,
                                                          curve: Curves.easeInOut,
                                                        ),
                                                      ),
                                                  child: child,
                                                );
                                              },
                                          transitionDuration: const Duration(
                                            milliseconds: 300,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Center(
                                      child: Text(
                                        'Create New Account',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: isSmallScreen ? 16 : 18,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
