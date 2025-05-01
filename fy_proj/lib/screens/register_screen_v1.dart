import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fy_proj/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please accept the terms and conditions',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Stack(
            children: [
              // Background with gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              
              // Background pattern
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(size.width, size.height * 0.7),
                  painter: BackgroundPatternPainter(),
                ),
              ),
              
              // App name with large font in background
              Positioned(
                top: size.height * 0.15,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'EDURECOM',
                    style: GoogleFonts.montserrat(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.07),
                      letterSpacing: 5,
                    ),
                  ),
                ),
              ),
              
              // Back button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              
              // Main content
              SafeArea(
                child: authProvider.isLoading
                    ? const SimpleLoadingWidget()
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, size.height * 0.08, 24, 24),
                          child: AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: child,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Logo & App name
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 72,
                                        width: 72,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            'E',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'EDURECOM',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Personalized Learning Experience',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: size.height * 0.05),
                                
                                // Welcome text
                                Text(
                                  'Create Account',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start your personalized learning experience',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Registration form
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Username field
                                      Text(
                                        'Username',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _usernameController,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Choose a username',
                                            hintStyle: GoogleFonts.montserrat(
                                              color: Colors.white.withOpacity(0.5),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.person_outline,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter a username';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Email field
                                      Text(
                                        'Email',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter your email',
                                            hintStyle: GoogleFonts.montserrat(
                                              color: Colors.white.withOpacity(0.5),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.email_outlined,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter an email';
                                            }
                                            // if (!value.contains('@') || !value.contains('.')) {
                                            //   return 'Please enter a valid email';
                                            // }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Password field
                                      Text(
                                        'Password',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Create a password',
                                            hintStyle: GoogleFonts.montserrat(
                                              color: Colors.white.withOpacity(0.5),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock_outline,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter a password';
                                            }
                                            if (value.length < 8) {
                                              return 'Password must be at least 8 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Confirm password field
                                      Text(
                                        'Confirm Password',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Confirm your password',
                                            hintStyle: GoogleFonts.montserrat(
                                              color: Colors.white.withOpacity(0.5),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock_outline,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                                });
                                              },
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
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
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Password hint
                                      Text(
                                        'Password must be at least 8 characters',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.6),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Terms and conditions checkbox
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: _acceptTerms 
                                                  ? Colors.white 
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.7),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _acceptTerms = !_acceptTerms;
                                                  });
                                                },
                                                child: _acceptTerms
                                                    ? const Icon(
                                                        Icons.check,
                                                        size: 18,
                                                        color: Colors.black,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'I agree to the Terms of Service and Privacy Policy',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      // Error message if any
                                      if (authProvider.error != null)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(top: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  authProvider.error!,
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 12,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Register button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: authProvider.isLoading ? null : _handleRegister,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 3,
                                          ),
                                          child: Text(
                                            'CREATE ACCOUNT',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Social login options
                                      Center(
                                        child: Text(
                                          'OR SIGN UP WITH',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(0.5),
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Social login buttons
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildSocialButton(Icons.g_mobiledata, 'Google'),
                                          const SizedBox(width: 16),
                                          _buildSocialButton(Icons.facebook, 'Facebook'),
                                          const SizedBox(width: 16),
                                          _buildSocialButton(Icons.apple, 'Apple'),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Login option
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Already have an account? ',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: Text(
                                              'Sign In',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSocialButton(IconData icon, String platform) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
        onPressed: () {
          // Handle social registration
        },
      ),
    );
  }
}

// Background pattern painter for decorative elements
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    
    // Draw decorative circles
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.4), 120, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 60, paint);
    
    // Draw decorative lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 15
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.3, size.height * 0.3),
      linePaint,
    );
    
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.4),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}