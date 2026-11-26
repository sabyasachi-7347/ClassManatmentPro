import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'shell/app_shell.dart';

void main() => runApp(const ClassesOsApp());

class ClassesOsApp extends StatefulWidget {
  const ClassesOsApp({super.key});

  @override
  State<ClassesOsApp> createState() => _ClassesOsAppState();
}

class _ClassesOsAppState extends State<ClassesOsApp> {
  ThemeMode _mode = ThemeMode.light;

  bool get _isDark => _mode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'classes.os',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: _mode,
      home: AppShell(
        isDark: _isDark,
        onToggleTheme: () => setState(
          () => _mode = _isDark ? ThemeMode.light : ThemeMode.dark,
        ),
      ),
    );
  }
}
