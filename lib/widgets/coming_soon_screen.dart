import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Schermata placeholder per funzionalità non ancora implementate.
///
/// Prima house_settings_screen.dart e recipes_screen.dart duplicavano lo
/// stesso identico layout (icona + titolo + descrizione, con l'AppBar
/// Material di default) usando uno stile visivamente diverso dal resto
/// dell'app. Ora è un solo widget, riallineato al design system
/// bianco/nero/minimale usato altrove.
class ComingSoonScreen extends StatelessWidget {
  final String appBarTitle;
  final IconData icon;
  final String title;
  final String message;

  const ComingSoonScreen({
    super.key,
    required this.appBarTitle,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: Text(appBarTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                ),
                child: Icon(icon, size: 40, color: AppColors.grey400),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.fieldLabel.copyWith(fontSize: 18, letterSpacing: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
