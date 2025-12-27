import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/card_provider.dart';
import 'screens/home_screen.dart';
import 'theme/liquid_glass_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardFlowApp());
}

class CardFlowApp extends StatelessWidget {
  const CardFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CardProvider()),
      ],
      child: MaterialApp(
        title: 'CardFlow 贺卡流',
        debugShowCheckedModeBanner: false,
        theme: LiquidGlassTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}
