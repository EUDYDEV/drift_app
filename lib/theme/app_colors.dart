import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Gradient principal (Bleu → Violet)
  static const Color gradientBlue = Color(0xFF1E90FF);
  static const Color gradientPurple = Color(0xFF800080);

  // Prestige / CTA
  static const Color orange = Color(0xFFFF7F0E);

  // Fonds
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);

  // Texte
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color grayText = Color(0xFF757575);
  static const Color lightText = Color(0xFFBDBDBD);

  // Statut
  static const Color green = Color(0xFF4CAF50);

  // Gradients réutilisables
  static const LinearGradient blueViolet = LinearGradient(
    colors: [gradientBlue, gradientPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient blueVioletVertical = LinearGradient(
    colors: [gradientBlue, gradientPurple],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
