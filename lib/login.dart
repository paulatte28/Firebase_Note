import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'register.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService auth = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //--EMAIL LOGIN--
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder()
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder()
                ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: Text("Forgot Password?"),
                  onPressed: () => _forgotPasswordDialog(),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                child: loading
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Login With Email'),
                onPressed: () async {
                  setState(() => loading = true);
                  final user = await auth.signInWithEmail(
                    emailCtrl.text, passwordCtrl.text);
                  setState(() => loading = false);

                  if (user != null) {
                    if(!user.emailVerified){
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Please verify your email before logging in.")),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (_) => HomePage()),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Invalid email or password")),
                    );
                  }
                },
              ),
             SizedBox(height: 24),
             Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ],
             ),
             SizedBox(height: 24),
             ElevatedButton.icon(
              icon: Icon(Icons.login),
              label: Text('Login with Google'),
              onPressed: () async {
                if (!mounted) return;
                setState(() => loading = true);
                final user = await auth.signInWithGoogle();
                if (!mounted) return;
                setState(() => loading = false);
                if (user != null) {
                  if(mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomePage()),
                    );
                  }
                }
              },
            ),
            SizedBox(height: 12),
            TextButton(
              child: Text("Don't have an account? Register"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterPage()),
                );
              },
            ),
          ],
         ),
        ),
      ),
    );
  }

  // FORGOT PASSWORD - SAME AS HOMEPAGE (Change Password Dialog)
  void _forgotPasswordDialog() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: confirmPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Reset Password"),
            onPressed: () async {
              if (currentPasswordCtrl.text.isEmpty || 
                  newPasswordCtrl.text.isEmpty || 
                  confirmPasswordCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              if (newPasswordCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }

              if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              final success = await auth.changePassword(
                currentPasswordCtrl.text,
                newPasswordCtrl.text,
              );

              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to change password. Check current password.'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}