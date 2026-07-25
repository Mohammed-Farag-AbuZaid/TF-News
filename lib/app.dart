import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/repositories/authentication_repositrories.dart';
import 'package:tf_news/bindings/general_bindings.dart';
import 'package:tf_news/pages/home_page.dart';
import 'package:tf_news/pages/opportunity_page.dart';
import 'package:tf_news/utils/constants/colors.dart';
import 'package:tf_news/utils/theme/theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthenticationRepository.instance.screenRedirect();
    });
  }

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
          child: child ?? const SizedBox.shrink(),
        );
      },
      getPages: [
        GetPage(
          name: '/',
          page: () => const Scaffold(
            body: Center(child: CircularProgressIndicator(color: TColors.primary)),
          ),
        ),
        GetPage(
          name: '/opportunity/:id',
          page: () => const OpportunityPage(),
        ),
        GetPage(
          name: '/must-know',
          page: () => const HomeScreen(initialCategory: 'Must-know'),
        ),
        GetPage(
          name: '/HomeScreen',
          page: () => const HomeScreen(),
        ),
      ],
      initialRoute: '/',
    );
  }
}