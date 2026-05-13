import 'package:flutter/material.dart';
import 'package:opsin/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}
