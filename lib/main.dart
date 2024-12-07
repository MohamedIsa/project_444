import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project_444/pages/adminhome/widgets/addExam.dart';
import 'package:project_444/pages/adminhome/widgets/addQuestionExam.dart';
import 'package:project_444/pages/forgotpassword/forgot_v.dart';
import 'package:project_444/pages/questions/Allexam.dart';
import 'package:project_444/pages/studenthome/studenthome.dart';
import 'package:project_444/utils/loading.dart';
import 'pages/adminhome/adminhomeV.dart';
import 'firebase_options.dart';
import 'pages/complete/complete_v.dart';
import 'pages/login/login_v.dart';
import 'pages/signup/signup_v.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    routes: {
      '/': (context) => const Loading(),
      '/login': (context) => LoginPage(),
      '/signup': (context) => SignUp(),
      '/forgotpassword': (context) => ForgotV(),
      '/completeProfile': (context) => Complete(),
      '/dashboard': (context) => Studenthome(
            name: 'name',
          ),
      '/admindashboard': (context) => const Adminhome(),
      '/createExam': (context) => AddExamWidget(),
      '/addQuestion': (context) => AddQuestionExam(examId: ""),
      '/TFQ': (context) => AllExam(
            examId: '',
            Semail: '',
            Sid: '',
            Sname: '',
            duration: 0,
          ),
    },
  ));
}
