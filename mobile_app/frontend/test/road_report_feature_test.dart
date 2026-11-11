import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Pages/reports/create_report_page.dart';
import 'package:vehnway/Pages/reports/widgets/report_card.dart';
import 'package:vehnway/Pages/reports/widgets/report_filter_sheet.dart';
import 'package:vehnway/Providers/road_report_provider.dart';
import 'package:vehnway/models/road_report_model.dart';

void main() {
  group('RoadReportModel & Enum Tests', () {
    test('RoadReportCategory enum values and fromValue parsing', () {
      expect(RoadReportCategory.fromValue('pothole'), RoadReportCategory.pothole);
      expect(RoadReportCategory.fromValue('marked_speedbreaker'), RoadReportCategory.markedSpeedbreaker);
      expect(RoadReportCategory.fromValue('unmarked_speedbreaker'), RoadReportCategory.unmarkedSpeedbreaker);
      expect(RoadReportCategory.fromValue('unpaved_road'), RoadReportCategory.unpavedRoad);
      expect(RoadReportCategory.fromValue('longitudinal_crack'), RoadReportCategory.longitudinalCrack);
      expect(RoadReportCategory.fromValue('other'), RoadReportCategory.other);
      expect(RoadReportCategory.fromValue('unknown'), RoadReportCategory.other);
    });

    test('RoadReportSeverity enum values and colors', () {
      expect(RoadReportSeverity.fromValue('low'), RoadReportSeverity.low);
      expect(RoadReportSeverity.fromValue('moderate'), RoadReportSeverity.moderate);
      expect(RoadReportSeverity.fromValue('high'), RoadReportSeverity.high);
      expect(RoadReportSeverity.fromValue(null), isNull);
      expect(RoadReportSeverity.fromValue('invalid'), isNull);
    });

    test('RoadReportStatus enum parsing and labels', () {
      expect(RoadReportStatus.fromValue('pending'), RoadReportStatus.pending);
      expect(RoadReportStatus.fromValue('confirmed'), RoadReportStatus.confirmed);
      expect(RoadReportStatus.fromValue('disputed'), RoadReportStatus.disputed);
      expect(RoadReportStatus.fromValue('resolved'), RoadReportStatus.resolved);
      expect(RoadReportStatus.fromValue('archived'), RoadReportStatus.archived);
      expect(RoadReportStatus.fromValue('invalid'), RoadReportStatus.pending);
    });

    test('VerificationVerdict enum parsing', () {
      expect(VerificationVerdict.fromValue('present'), VerificationVerdict.present);
      expect(VerificationVerdict.fromValue('repaired'), VerificationVerdict.repaired);
      expect(VerificationVerdict.fromValue('incorrect'), VerificationVerdict.incorrect);
    });

    test('RoadReport.fromRpcMap parses PostGIS RPC output correctly', () {
      final now = DateTime.now().toUtc();
      final rpcData = {
        'id': 'b1c3e390-e4b2-4d51-93c8-e362fa90a112',
        'user_id': 'firebase_uid_123',
        'issue_type': 'pothole',
        'latitude': 13.024097,
        'longitude': 77.636558,
        'location_accuracy': 5.5,
        'severity': 'high',
        'description': 'Deep pothole across whole lane',
        'status': 'confirmed',
        'source_trip_id': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'distance_meters': 345.2,
        'media_storage_paths': ['firebase_uid_123/report_1/photo1.jpg'],
        'verification_counts': {
          'present': 3,
          'repaired': 0,
          'incorrect': 1,
        },
        'user_verdict': 'present',
        'is_own_report': false,
      };

      final report = RoadReport.fromRpcMap(rpcData, currentUserId: 'other_user_456');

      expect(report.id, 'b1c3e390-e4b2-4d51-93c8-e362fa90a112');
      expect(report.userId, 'firebase_uid_123');
      expect(report.category, RoadReportCategory.pothole);
      expect(report.latitude, 13.024097);
      expect(report.longitude, 77.636558);
      expect(report.severity, RoadReportSeverity.high);
      expect(report.status, RoadReportStatus.confirmed);
      expect(report.formattedDistance, '345 m');
      expect(report.totalVerifications, 4);
      expect(report.mediaStoragePaths.length, 1);
      expect(report.userVerdict, VerificationVerdict.present);
      expect(report.isOwnReport, isFalse);
      expect(report.canBeVerifiedBy('other_user_456'), isTrue);
      expect(report.canBeVerifiedBy('firebase_uid_123'), isFalse); // Authors cannot verify own report
    });

    test('Distance formatting switches to km for >=1000m', () {
      final reportShort = RoadReport(
        id: '1',
        userId: 'u1',
        category: RoadReportCategory.pothole,
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        distanceMeters: 450,
      );
      expect(reportShort.formattedDistance, '450 m');

      final reportLong = reportShort.copyWith(distanceMeters: 2350);
      expect(reportLong.formattedDistance, '2.4 km');
    });

    test('Archived reports cannot be verified', () {
      final archivedReport = RoadReport(
        id: '2',
        userId: 'author_uid',
        category: RoadReportCategory.markedSpeedbreaker,
        latitude: 0,
        longitude: 0,
        status: RoadReportStatus.archived,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(archivedReport.canBeVerifiedBy('other_uid'), isFalse);
    });
  });

  group('Road Reports UI Widget Tests', () {
    testWidgets('ReportCard renders category label, formatted distance and status', (tester) async {
      final report = RoadReport(
        id: 'rep_1',
        userId: 'u1',
        category: RoadReportCategory.pothole,
        latitude: 13.0,
        longitude: 77.0,
        status: RoadReportStatus.confirmed,
        distanceMeters: 120,
        severity: RoadReportSeverity.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
        verificationCounts: const {'present': 2, 'repaired': 0, 'incorrect': 0},
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(
              report: report,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Pothole'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('120 m'), findsOneWidget);
      expect(find.text('High Severity'), findsOneWidget);
      expect(find.text('2 verified'), findsOneWidget);

      await tester.tap(find.byType(ReportCard));
      expect(tapped, isTrue);
    });

    testWidgets('ReportFilterSheet renders category and status chips', (tester) async {
      RoadReportCategory? selectedCat;
      RoadReportStatus? selectedSt;
      double selectedRad = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  ReportFilterSheet.show(
                    context: ctx,
                    initialCategory: null,
                    initialStatus: null,
                    initialRadiusMeters: 2000,
                    onApply: (cat, st, rad) {
                      selectedCat = cat;
                      selectedSt = st;
                      selectedRad = rad;
                    },
                  );
                },
                child: const Text('Open Filters'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Reports'), findsOneWidget);
      expect(find.text('Search Radius'), findsOneWidget);
      expect(find.text('Issue Category'), findsOneWidget);
      expect(find.text('Report Status'), findsOneWidget);

      // Tap Pothole chip
      await tester.tap(find.text('Pothole'));
      await tester.pumpAndSettle();

      // Tap Confirmed status chip
      await tester.tap(find.text('Confirmed'));
      await tester.pumpAndSettle();

      // Tap Apply Filters
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(selectedCat, RoadReportCategory.pothole);
      expect(selectedSt, RoadReportStatus.confirmed);
      expect(selectedRad, 2000.0);
    });

    testWidgets('CreateReportPage renders safety banner, 6 categories, and side-by-side cards', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RoadReportProvider()),
          ],
          child: const MaterialApp(
            home: CreateReportPage(),
          ),
        ),
      );

      // Verify Safety reminder
      expect(find.textContaining('Drive Safely: Only report or take photographs when your vehicle is safely stopped.'), findsOneWidget);

      // Verify 6 Categories
      expect(find.text('Pothole'), findsOneWidget);
      expect(find.text('Marked speedbreaker'), findsOneWidget);
      expect(find.text('Unmarked speedbreaker'), findsOneWidget);
      expect(find.text('Unpaved road'), findsOneWidget);
      expect(find.text('Longitudinal crack'), findsOneWidget);
      expect(find.text('...'), findsOneWidget);

      // Verify Side-by-Side Cards
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);

      // Verify Severity options
      expect(find.text('Severity (Optional)'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);

      // Verify Submit Button (disabled initially because category and photo are missing)
      final submitFinder = find.widgetWithText(ElevatedButton, 'Submit Road Report');
      expect(submitFinder, findsOneWidget);
      final submitButton = tester.widget<ElevatedButton>(submitFinder);
      expect(submitButton.onPressed, isNull);
    });
  });
}

