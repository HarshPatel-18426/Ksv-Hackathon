import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/erp_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<ErpProvider>(
          create: (_) => ErpProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.router(context);

          return MaterialApp.router(
            title: 'VendorBridge ERP',
            debugShowCheckedModeBanner: false,
            // Router Configuration
            routerConfig: router,
            // Styling System (Material Design 3)
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A5F),
                primary: const Color(0xFF1E3A5F),
                secondary: const Color(0xFF2E86AB),
                surface: Colors.white,
                error: const Color(0xFFE74C3C),
              ),
              // Typography & Text Style Defaults
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFF1A202C)),
                bodyMedium: TextStyle(color: Color(0xFF718096)),
              ),
              // Card Styling (12px Border Radius & Subtle Shadow)
              cardTheme: CardThemeData(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
              ),
              // Form Input Styling
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 1.5),
                ),
              ),
              // App Bar Style
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1A202C),
                elevation: 0,
                centerTitle: false,
              ),
            ),
          );
        },
      ),
    );
  }
}
