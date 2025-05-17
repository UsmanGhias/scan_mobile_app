import 'dart:async';
import 'dart:developer';

import 'package:app/pages/home.dart';
import 'package:app/pages/login.dart';
import 'package:app/services/shared_pref.dart';
import 'package:flutter/material.dart';

class Decider extends StatelessWidget {
  static const routeName = '/decider-screen';
  const Decider({super.key});

  Future<String> getToken() async {
    String token = await SharedPrefsService.getTokenId();
    log('📦 Retrieved token: $token');
    return token;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data!;
        log('📡 Final token in FutureBuilder: $token');

        if (token.isEmpty) {
          return AuthScreen();
        } else {
          return HomeScreen();
        }
      },
    );
  }
}
