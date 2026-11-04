import 'package:intl/intl.dart';

/// Extension and utilities to guarantee all dates and times in the application
/// are converted to and displayed in Indian Standard Time (IST, UTC+5:30).
extension IstDateTime on DateTime {
  /// Converts this [DateTime] into Indian Standard Time (IST, UTC+5:30).
  ///
  /// The returned [DateTime] has its [year], [month], [day], [hour], [minute], [second]
  /// fields matching IST.
  DateTime toIst() {
    final utc = toUtc();
    final ist = utc.add(const Duration(hours: 5, minutes: 30));
    return DateTime(
      ist.year,
      ist.month,
      ist.day,
      ist.hour,
      ist.minute,
      ist.second,
      ist.millisecond,
      ist.microsecond,
    );
  }

  /// Formats this [DateTime] in IST using the provided [pattern].
  /// Default: 'dd MMM yyyy, HH:mm' (e.g. 21 Sep 2026, 11:45)
  String formatIst([String pattern = 'dd MMM yyyy, HH:mm']) {
    return DateFormat(pattern).format(toIst());
  }

  /// Formats date only in IST (e.g. 21 Sep 2026)
  String formatIstDate([String pattern = 'dd MMM yyyy']) {
    return DateFormat(pattern).format(toIst());
  }

  /// Formats time only in IST (e.g. 11:45)
  String formatIstTime([String pattern = 'HH:mm']) {
    return DateFormat(pattern).format(toIst());
  }
}

extension NullableIstDateTime on DateTime? {
  /// Converts to IST if not null.
  DateTime? toIst() => this?.toIst();

  /// Formats to IST string if not null, otherwise returns [fallback].
  String formatIst({String pattern = 'dd MMM yyyy, HH:mm', String fallback = '--'}) {
    if (this == null) return fallback;
    return this!.formatIst(pattern);
  }
}

/// Helper to parse ISO / DB timestamps and ensure they are parsed as UTC
/// if no timezone offset was specified.
DateTime parseUtc(dynamic input) {
  if (input is DateTime) {
    return input.toUtc();
  }
  final dateStr = input.toString();
  final dt = DateTime.parse(dateStr);
  if (!dateStr.endsWith('Z') &&
      !dateStr.contains('+') &&
      !RegExp(r'-\d\d:\d\d').hasMatch(dateStr)) {
    return DateTime.utc(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      dt.microsecond,
    );
  }
  return dt.toUtc();
}
