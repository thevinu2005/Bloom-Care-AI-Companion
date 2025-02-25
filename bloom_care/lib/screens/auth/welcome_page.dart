import 'package:flutter/material.dart';
import 'package:bloom_care/screens/auth/login_screen.dart';
import 'package:bloom_care/screens/auth/signup_page.dart';


class welcomepage extends StatelessWidget {
  const welcomepage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     body: Container(
       height: double.infinity,
       width: double.infinity,
       decoration: const BoxDecoration(
         gradient: LinearGradient(
           colors: [
             Color.fromARGB(255, 21, 1, 25),
             Color.fromARGB(255, 92, 157, 255),
           ]
         )
       ),
       child: Column(
         children: [
           const Padding(
             padding: EdgeInsets.only(top: 100, left: 310, right: 310),
             child: Image(image: AssetImage('assest/icons/logo.jpg')),
           ),
           const SizedBox(
             height: 50,
           ),
           const Text('Welcome !',style: TextStyle(
             fontSize: 30,
             color: Colors.white
           ),),
          const SizedBox(height: 30,),
          GestureDetector(
            onTap: (){
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: Container(
              height: 53,
              width: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white),
              ),
              child: const Center(child: Text('LOGIN',style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),),),
            ),
          ),
           const SizedBox(height: 30,),
           GestureDetector(
             onTap: (){
               Navigator.push(context,
                   MaterialPageRoute(builder: (context) => const SignupScreen()));
             },
             child: Container(
               height: 53,
               width: 320,
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(30),
                 border: Border.all(color: Colors.white),
               ),
               child: const Center(child: Text('SIGN UP',style: TextStyle(
                   fontSize: 20,
                   fontWeight: FontWeight.bold,
                   color: Colors.black
               ),),),
             ),
           ),
           const Spacer(),
           const Text('Login with Social Media',style: TextStyle(
               fontSize: 17,
               color: Colors.white
           ),),//
          const SizedBox(height: 45,),
          ]
       ),
     ),

    );
  }
}
