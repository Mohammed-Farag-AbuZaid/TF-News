import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          SizedBox(height: 20),
          NavBar(),
          Divider()
          
        ],
      ),
    );
  }
}

