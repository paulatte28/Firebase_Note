import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder()
              ),
            ),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder()
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: loading
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Register'),
              onPressed: () async {
                if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;
                setState(() => loading = true);  
                
                final user = await _authService.registerWithEmail(
                  emailCtrl.text, passwordCtrl.text);

                  setState(() => loading = false);

                if (user != null) {
                  //send verification email
                  if(!user.emailVerified){
                    await user.sendEmailVerification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Verification email sent. Please check your inbox.")),
                    );
                  }
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                    );
                }else{
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Registration failed")),
                  );
                }
              },
            ),
            SizedBox(height: 12),
            TextButton(
              child: Text("Already have an account? Login"),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}