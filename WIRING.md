# Wiring the Admissions section into the app (3 small edits, nothing else changes)

1. Copy these 5 files into your project (keep the same folders):
   lib/data/admissions_models.dart
   lib/data/admissions_repository.dart
   lib/pages/admissions/admissions_page.dart
   lib/pages/admissions/university_page.dart
   lib/pages/admissions/way_page.dart

2. Register 3 routes (where your other GetPage routes are):
   GetPage(name: '/admissions', page: () => const AdmissionsPage()),
   GetPage(name: '/admissions/university/:id', page: () => const UniversityPage()),
   GetPage(name: '/admissions/university/:id/way/:way', page: () => const WayPage()),
   plus the three imports for those pages.

3. Make the Admissions card on the home page open '/admissions'.
   The home page uses OpportunitySection.all / section.route (in lib/data/opportunity.dart).
   Change only the admissions section's route to '/admissions'.

Run it as is: AdmissionsRepository.useSampleData = true shows placeholder data.
Real data: import tf_public_api.json into n8n, activate it, then in admissions_repository.dart
set apiBase to your production webhook URL and useSampleData = false.
