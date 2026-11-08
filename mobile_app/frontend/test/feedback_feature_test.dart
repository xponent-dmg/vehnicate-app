import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehnway/Pages/profile/feedback_page.dart';
import 'package:vehnway/models/feedback_model.dart';

void main() {
  group('FeedbackModel Tests', () {
    test('FeedbackCategory enum values and fromValue parsing', () {
      expect(FeedbackCategory.fromValue('bug_report'), FeedbackCategory.bugReport);
      expect(FeedbackCategory.fromValue('feature_request'), FeedbackCategory.featureRequest);
      expect(FeedbackCategory.fromValue('general'), FeedbackCategory.general);
      expect(FeedbackCategory.fromValue('unknown'), FeedbackCategory.general);
    });

    test('FeedbackModel serializes to insert map correctly', () {
      final feedback = FeedbackModel(
        userId: 'test-firebase-uid',
        category: FeedbackCategory.bugReport,
        description: 'App freezes when tapping the start drive button.',
        attachmentUrls: ['test-firebase-uid/sub-1/screen1.jpg'],
        appVersion: '1.1.0',
        buildNumber: '11',
        deviceModel: 'Pixel 8',
        osVersion: 'Android 14',
      );

      final map = feedback.toInsertMap();
      expect(map['user_id'], 'test-firebase-uid');
      expect(map['category'], 'bug_report');
      expect(map['description'], 'App freezes when tapping the start drive button.');
      expect(map['attachment_urls'], ['test-firebase-uid/sub-1/screen1.jpg']);
      expect(map['app_version'], '1.1.0');
      expect(map['build_number'], '11');
      expect(map['device_model'], 'Pixel 8');
      expect(map['os_version'], 'Android 14');
      expect(map['status'], 'new');
      expect(map['email_status'], 'pending');
    });

    test('FeedbackModel deserializes from map correctly', () {
      final now = DateTime.now().toUtc();
      final map = {
        'id': 'a4a9cbb3-7188-4db8-b570-c75cce87b2db',
        'user_id': 'user_123',
        'category': 'feature_request',
        'description': 'Add dark mode auto switch based on sunset time.',
        'attachment_urls': ['user_123/sub-2/shot.png'],
        'app_version': '1.1.0',
        'build_number': '11',
        'device_model': 'iPhone 15 Pro',
        'os_version': 'iOS 17.5',
        'status': 'new',
        'email_status': 'sent',
        'created_at': now.toIso8601String(),
      };

      final model = FeedbackModel.fromMap(map);
      expect(model.id, 'a4a9cbb3-7188-4db8-b570-c75cce87b2db');
      expect(model.category, FeedbackCategory.featureRequest);
      expect(model.description, 'Add dark mode auto switch based on sunset time.');
      expect(model.emailStatus, 'sent');
      expect(model.attachmentUrls.length, 1);
      expect(model.attachmentUrls.first, 'user_123/sub-2/shot.png');
    });
  });

  group('FeedbackPage Widget Tests', () {
    testWidgets('Renders all feedback categories and description placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FeedbackPage(),
        ),
      );

      // Verify title is rendered
      expect(find.text('Send Feedback'), findsOneWidget);

      // Verify categories are rendered
      expect(find.text('Bug Report'), findsOneWidget);
      expect(find.text('Feature'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);

      // Verify submit button
      expect(find.text('Submit Feedback'), findsOneWidget);

      // Verify initial placeholder for Bug Report
      expect(
        find.textContaining('Please describe the bug encountered'),
        findsOneWidget,
      );

      // Tap on Feature Request chip
      await tester.tap(find.text('Feature'));
      await tester.pumpAndSettle();

      // Verify dynamic placeholder changes for Feature Request
      expect(
        find.textContaining('Describe the feature or improvement'),
        findsOneWidget,
      );

      // Tap on General chip
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      // Verify dynamic placeholder changes for General Feedback
      expect(
        find.textContaining('Share your general comments'),
        findsOneWidget,
      );
    });

    testWidgets('Prevents submission when description is too short', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: FeedbackPage(),
        ),
      );

      // Enter short description (< 10 chars)
      await tester.enterText(find.byType(TextField), 'Short');
      await tester.pumpAndSettle();

      // Scroll and tap submit
      final submitButton = find.text('Submit Feedback');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify submit warning snackbar is triggered
      expect(find.textContaining('10 characters'), findsOneWidget);
    });
  });
}
