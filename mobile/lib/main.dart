import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/permission_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final setupDone = prefs.getBool('permission_setup_done') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        permissionSetupDoneProvider.overrideWith(
          () => PermissionSetupDoneNotifier(setupDone),
        ),
      ],
      child: const FaceHRMApp(),
    ),
  );
}

class FaceHRMApp extends ConsumerWidget {
  const FaceHRMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FaceHRM',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
