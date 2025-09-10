// -------------------- REGISTER PAGE -------------------- //
import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
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
                const Text(
                  "Create Account ✨",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Register to start preserving your memories",
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
                const SizedBox(height: 40),

                // Circle Avatar
                Center(
                  child: CircleAvatar(
                    child: Icon(Icons.camera_alt_outlined,color: Colors.black,),
                    radius: 70,
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                _buildInputField("Full Name", Icons.person_outline),
                const SizedBox(height: 16),

                _buildInputField("Email", Icons.email_outlined),
                const SizedBox(height: 16),

                _buildInputField(
                  "Password",
                  Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  "Confirm Password",
                  Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 216, 204, 187),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Color.fromARGB(255, 26, 0, 99)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 59, 59, 59).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color.fromARGB(255, 212, 204, 204)),
        ),
      ),
    );
  }
}
