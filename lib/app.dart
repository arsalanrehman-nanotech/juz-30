import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'logic/settings.dart';
import 'screens/home_screen.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';

class HifzApp extends StatelessWidget {
  const HifzApp({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      app: app,
      child: Builder(
        builder: (BuildContext context) {
          final ThemePref pref = AppScope.of(context).settings.theme;
          final ThemeMode mode = pref == ThemePref.light
              ? ThemeMode.light
              : pref == ThemePref.dark
                  ? ThemeMode.dark
                  : ThemeMode.system;
          return MaterialApp(
            title: 'Juz 30 Hifz',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: mode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
