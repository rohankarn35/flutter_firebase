import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
                onPressed: () async{
                  googlesignin();
                },
                icon: Icon(Icons.app_registration),
                label: Text("Sign in"))
          ],
        ),
      ),
    );
  }

  void googlesignin() async {
    GoogleSignInAccount? guser = await GoogleSignIn().signIn();
    GoogleSignInAuthentication? gauth = await guser?.authentication;
    AuthCredential credential = GoogleAuthProvider.credential(
      idToken: gauth?.idToken,
      accessToken: gauth?.accessToken,
    );

    UserCredential userCredential = await   FirebaseAuth.instance.signInWithCredential(credential);
    print(userCredential.user?.email);
   
  }
}
