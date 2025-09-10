import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();

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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Title
                const Text(
                  "Forgot Password 🔑",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter your registered email to receive a reset link.",
                  style: TextStyle(color: Color.fromARGB(255, 25, 24, 24)),
                ),
                const SizedBox(height: 40),

                // Email input
                _buildInputField(
                  "Email",
                  Icons.email_outlined,
                  _emailController,
                ),

                const SizedBox(height: 24),

                // Send Reset Link button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 226, 214, 214),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    String email = _emailController.text.trim();
                    if (email.isEmpty) {
                      _showMessage("Please enter your email.");
                    } else {
                      // TODO: Integrate Firebase Auth here
                      _showMessage("Password reset link sent to $email");
                    }
                  },
                  child: const Text(
                    "Send Reset Link",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Back to Login
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "← Back to Login",
                      style: TextStyle(fontWeight: FontWeight.bold
                      ,
                        
                        color: Color.fromARGB(255, 34, 7, 75),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Input Field
  Widget _buildInputField(
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 59, 59, 59).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color.fromARGB(255, 251, 247, 247)),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color.fromARGB(255, 230, 222, 222)),
        ),
      ),
    );
  }

  // Snackbar for messages
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.deepPurple),
    );
  }
}
