// -------------------- REGISTER PAGE -------------------- //
import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:lifeprint/authservice.dart';
import 'package:lifeprint/cloudinary_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  String? _profileImageUrl;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: const ParticleOptions(
            baseColor: Color.fromARGB(255, 255, 255, 255),
            spawnMinSpeed: 20,
            spawnMaxSpeed: 70,
            particleCount: 30,
          ),
        ),
        vsync: this,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.withOpacity(0.1),
                          Colors.purple.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Join us and start your journey",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Registration Card
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Picture Section
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.deepPurple,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[100],
                                  backgroundImage: _profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : (_profileImage != null
                                            ? kIsWeb
                                                  ? NetworkImage(
                                                      _profileImage!.path,
                                                    )
                                                  : FileImage(
                                                      File(_profileImage!.path),
                                                    )
                                            : null),
                                  child:
                                      _profileImageUrl == null &&
                                          _profileImage == null
                                      ? (_isUploadingImage
                                            ? const CircularProgressIndicator(
                                                color: Colors.deepPurple,
                                                strokeWidth: 2,
                                              )
                                            : const Icon(
                                                Icons.camera_alt,
                                                size: 40,
                                                color: Colors.deepPurple,
                                              ))
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: kIsWeb
                                    ? _buildWebImagePickerButton()
                                    : GestureDetector(
                                        onTap: _showImagePicker,
                                        onLongPress: _profileImageUrl != null
                                            ? _clearProfilePicture
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _profileImageUrl != null
                                                ? Colors.red
                                                : Colors.deepPurple,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            _profileImageUrl != null
                                                ? Icons.close
                                                : Icons.add,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isUploadingImage
                              ? "Uploading..."
                              : (_profileImageUrl != null
                                    ? "Profile Picture Added"
                                    : kIsWeb
                                    ? "Click to upload image file"
                                    : "Add Profile Picture"),
                          style: TextStyle(
                            color: _isUploadingImage
                                ? Colors.orange[600]
                                : (_profileImageUrl != null
                                      ? Colors.green[600]
                                      : Colors.grey[600]),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Full Name Field
                        _buildInputField(
                          "Full Name",
                          Icons.person_outline,
                          _fullNameController,
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        _buildInputField(
                          "Email Address",
                          Icons.email_outlined,
                          _emailController,
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        _buildInputField(
                          "Password",
                          Icons.lock_outline,
                          _passwordController,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        _buildInputField(
                          "Confirm Password",
                          Icons.lock_outline,
                          _confirmPasswordController,
                          isPassword: true,
                          isConfirmPassword: true,
                        ),
                        const SizedBox(height: 20),

                        // Terms and Conditions
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                });
                              },
                              activeColor: Colors.deepPurple,
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  children: [
                                    const TextSpan(text: "I agree to the "),
                                    TextSpan(
                                      text: "Terms & Conditions",
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: " and "),
                                    TextSpan(
                                      text: "Privacy Policy",
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Social Register Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                "Google",
                                Icons.g_mobiledata,
                                Colors.red,
                                () {},
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildSocialButton(
                                "Apple",
                                Icons.apple,
                                Colors.black,
                                () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
    );
  }

  Widget _buildInputField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText:
            isPassword &&
            (isConfirmPassword
                ? !_isConfirmPasswordVisible
                : !_isPasswordVisible),
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isConfirmPassword
                        ? (_isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off)
                        : (_isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirmPassword) {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      } else {
                        _isPasswordVisible = !_isPasswordVisible;
                      }
                    });
                  },
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    // For web, directly open file picker without dialog
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }

    // For mobile, show bottom sheet with camera and gallery options
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Profile Picture",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    "Camera",
                    Icons.camera_alt,
                    () => _pickImage(ImageSource.camera),
                  ),
                  _buildImagePickerOption(
                    "Gallery",
                    Icons.photo_library,
                    () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.deepPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        // No size or quality restrictions - upload original image
      );

      if (image != null && mounted) {
        setState(() {
          _profileImage = image;
          _isUploadingImage = true;
        });

        // Close bottom sheet only on mobile
        if (!kIsWeb) {
          Navigator.pop(context);
        }

        // Upload to Cloudinary with platform-specific optimization
        String? imageUrl;

        // First, try the optimized method
        if (kIsWeb) {
          imageUrl = await CloudinaryService.uploadImageWebOptimized(
            _profileImage!,
          );
        } else {
          imageUrl = await CloudinaryService.uploadImageWithTransformations(
            _profileImage!,
            width: 200,
            height: 200,
            crop: 'fill',
            gravity: 'face',
          );
        }

        // If optimized method fails, try fallback method
        if (imageUrl == null) {
          print('Optimized upload failed, trying fallback method...');
          imageUrl = await CloudinaryService.uploadImageSimple(_profileImage!);
        }

        if (imageUrl != null && mounted) {
          setState(() {
            _profileImageUrl = imageUrl;
            _isUploadingImage = false;
          });
          _showSnackBar("Profile picture uploaded successfully!");
        } else {
          setState(() {
            _isUploadingImage = false;
          });
          _showSnackBar("Failed to upload image. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        String errorMessage = "Error picking image: $e";

        // Provide more specific error messages for web
        if (kIsWeb) {
          if (e.toString().contains('permission')) {
            errorMessage =
                "Permission denied. Please allow file access and try again.";
          }
        }

        _showSnackBar(errorMessage);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleRegister() async {
    String fullName = _fullNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (fullName.isEmpty) {
      _showSnackBar("Please enter your full name");
      return;
    }

    if (email.isEmpty) {
      _showSnackBar("Please enter your email address");
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar("Please enter a valid email address");
      return;
    }

    if (password.isEmpty) {
      _showSnackBar("Please enter a password");
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters long");
      return;
    }

    if (confirmPassword.isEmpty) {
      _showSnackBar("Please confirm your password");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match");
      return;
    }

    if (!_agreeToTerms) {
      _showSnackBar("Please agree to the Terms & Conditions");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Registerss(
        ConfirmPassword: confirmPassword,
        Password: password,
        EmailAddress: email,
        FullName: fullName,
        ProfileImageUrl: _profileImageUrl,
        context: context,
      );
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _clearProfilePicture() {
    setState(() {
      _profileImage = null;
      _profileImageUrl = null;
      _isUploadingImage = false;
    });
    _showSnackBar("Profile picture removed");
  }

  Widget _buildWebImagePickerButton() {
    return GestureDetector(
      onTap: _showImagePicker,
      onLongPress: _profileImageUrl != null ? _clearProfilePicture : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _profileImageUrl != null ? Colors.red : Colors.deepPurple,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          _profileImageUrl != null ? Icons.close : Icons.upload_file,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
