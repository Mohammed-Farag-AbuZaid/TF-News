import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/bindings/general_bindings.dart';
import 'package:tf_news/utils/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      initialBinding: GeneralBindings(),
      builder: (context, child) {
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          alignment: Alignment.topCenter,

          child: child!,
        );
      },
      home: const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
