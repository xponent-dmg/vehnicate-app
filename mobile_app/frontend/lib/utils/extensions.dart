import 'package:flutter/material.dart';
import 'package:vehnway/l10n/app_localizations.dart';

export 'package:vehnway/utils/ist_date_time.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}

