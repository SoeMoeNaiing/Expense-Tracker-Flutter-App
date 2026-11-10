import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/expenses/presentation/screens/expenses_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const ExpensesScreen(),
    );
  }
}
