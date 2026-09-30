import 'package:flutter/material.dart';

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      brightness: brightness,
    ),
  );
}
