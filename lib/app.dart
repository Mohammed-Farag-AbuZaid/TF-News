import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/authentication_repository.dart';
import 'package:tf_news/bindings/general_bindings.dart';
import 'package:tf_news/data/opportunity.dart';
import 'package:tf_news/pages/admissions/admissions_page.dart';
import 'package:tf_news/pages/admissions/universities_page.dart';
import 'package:tf_news/pages/admissions/programs_page.dart';
import 'package:tf_news/pages/admissions/program_page.dart';
import 'package:tf_news/pages/admissions/university_page.dart';
import 'package:tf_news/pages/admissions/way_page.dart';
import 'package:tf_news/pages/opportunities_page.dart';
import 'package:tf_news/pages/home_page.dart';
import 'package:tf_news/pages/opportunity_page.dart';
import 'package:tf_news/utils/constants/colors.dart';
import 'package:tf_news/utils/theme/theme.dart';
import 'package:tf_news/utils/ui/tf_ui.dart';

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
      // A refreshed or shared link (for example /study/universities) keeps its
      // page when the user is already signed in. Before, every refresh threw the
      // user back to the home page.
      final user = AuthenticationRepository.instance.authUser;
      final route = Get.currentRoute;
      final onDeepLink = route.isNotEmpty && route != '/';
      if (onDeepLink && user != null && user.emailVerified) return;
      AuthenticationRepository.instance.screenRedirect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TF News', // browser tab / task switcher title
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      initialBinding: GeneralBindings(),
      defaultTransition: Transition.fadeIn,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const TfScrollBehavior(), // mouse-drag for chip rows on web
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            alignment: Alignment.topCenter,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      // Any unknown address shows a friendly page instead of a blank screen.
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => Scaffold(
          body: SafeArea(
            child: EmptyState(
              title: 'Page not found',
              message: 'The link may be old or incomplete.',
              actionLabel: 'Go to home',
              onAction: tfGoHome,
            ),
          ),
        ),
      ),
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
          page: () => const HomeScreen(),
        ),
        GetPage(
          name: '/HomeScreen',
          page: () => const HomeScreen(),
        ),
        // Admissions & Scholarships: university -> ways -> one way
        GetPage(
          name: '/admissions/university/:id',
          page: () => const UniversityPage(),
        ),
        GetPage(
          name: '/admissions/university/:id/way/:way',
          page: () => const WayPage(),
        ),
        // Admissions: choose -> browse (universities | programs) -> detail
        GetPage(name: '/study/universities', page: () => const UniversitiesPage()),
        GetPage(name: '/study/programs', page: () => const ProgramsPage()),
        GetPage(name: '/admissions/program/:key', page: () => const ProgramPage()),
        // The 4 home cards. Only the "study" section (Scholarships & Admissions)
        // opens the new Admissions pages; the other three are unchanged.
        for (final s in OpportunitySection.all)
          GetPage(
            name: s.route,
            page: () => s.id == OpportunitySection.study.id
                ? const AdmissionsPage()
                : OpportunitiesPage(section: s),
          ),
      ],
      initialRoute: '/',
    );
  }
}