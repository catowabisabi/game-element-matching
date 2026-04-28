import 'package:flutter/material.dart';

import '../../services/local_store.dart';
import 'game_screen.dart';

class ElementaryGameApp extends StatelessWidget {
  const ElementaryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elementary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffff8a2b),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: GameScreen(store: LocalStore()),
    );
  }
}
