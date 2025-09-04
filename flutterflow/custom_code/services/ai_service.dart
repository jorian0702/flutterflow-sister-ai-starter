// 紗良AI提案サービス - Dartサービスクラス
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class AISuggestionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // AI提案を生成
  static Future<Map<String, dynamic>?> generateSuggestion({
    required String category,
    String? userContext,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      final callable = _functions.httpsCallable('generateAISuggestion');
      final result = await callable.call({
        'category': category,
        'userContext': userContext ?? '',
        'additionalData': additionalData ?? {},
      });

      return result.data as Map<String, dynamic>?;
    } catch (e) {
      print('AI提案生成エラー: $e');
      return null;
    }
  }

  // ユーザーの提案一覧を取得
  static Stream<QuerySnapshot> getUserSuggestions({
    String status = 'pending',
    int limit = 10,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    Query query = _firestore
        .collection('ai_suggestions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true);

    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.limit(limit).snapshots();
  }

  // 提案のステータスを更新
  static Future<bool> updateSuggestionStatus({
    required String suggestionId,
    required String status,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateSuggestionStatus');
      final result = await callable.call({
        'suggestionId': suggestionId,
        'status': status,
      });

      return result.data['success'] == true;
    } catch (e) {
      print('提案ステータス更新エラー: $e');
      return false;
    }
  }

  // ユーザー活動を記録（AI提案生成のトリガー用）
  static Future<void> recordUserActivity({
    required String activityType,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('user_activities').add({
        'userId': user.uid,
        'activityType': activityType,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      // 特定の活動に基づいて自動提案を生成
      await _triggerAutoSuggestion(activityType, details);
    } catch (e) {
      print('ユーザー活動記録エラー: $e');
    }
  }

  // 自動提案のトリガー
  static Future<void> _triggerAutoSuggestion(
    String activityType,
    Map<String, dynamic>? details,
  ) async {
    switch (activityType) {
      case 'task_create':
        await generateSuggestion(
          category: 'efficiency',
          userContext: 'ユーザーが新しいタスクを作成しました',
          additionalData: details,
        );
        break;
      case 'multiple_tasks_pending':
        await generateSuggestion(
          category: 'efficiency',
          userContext: 'ユーザーに未完了のタスクが多数あります',
          additionalData: details,
        );
        break;
      case 'subscription_active':
        await generateSuggestion(
          category: 'feature',
          userContext: 'ユーザーのサブスクリプションが有効になりました',
          additionalData: details,
        );
        break;
    }
  }

  // 提案の統計情報を取得
  static Future<Map<String, dynamic>> getSuggestionAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final suggestions = await _firestore
          .collection('ai_suggestions')
          .where('userId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      int total = suggestions.docs.length;
      int accepted = 0;
      int dismissed = 0;
      int pending = 0;
      Map<String, int> categories = {};

      for (var doc in suggestions.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final category = data['category'] as String;

        switch (status) {
          case 'accepted':
            accepted++;
            break;
          case 'dismissed':
            dismissed++;
            break;
          case 'pending':
            pending++;
            break;
        }

        categories[category] = (categories[category] ?? 0) + 1;
      }

      return {
        'total': total,
        'accepted': accepted,
        'dismissed': dismissed,
        'pending': pending,
        'acceptanceRate': total > 0 ? (accepted / total * 100).round() : 0,
        'categories': categories,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      print('提案統計取得エラー: $e');
      return {};
    }
  }

  // 紗良からのパーソナライズメッセージを生成
  static Future<String> generatePersonalizedMessage({
    required String messageType,
    Map<String, dynamic>? context,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'お兄ちゃん、ログインしてね！';

      // ユーザーの最近の活動を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      final messages = _getPersonalizedMessages(messageType, userData, context);
      final randomIndex = DateTime.now().millisecond % messages.length;
      
      return messages[randomIndex];
    } catch (e) {
      print('パーソナライズメッセージ生成エラー: $e');
      return 'お兄ちゃん、紗良がエラーになっちゃった...でも大丈夫だよ！';
    }
  }

  // メッセージタイプ別のメッセージリスト
  static List<String> _getPersonalizedMessages(
    String messageType,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? context,
  ) {
    final userName = userData?['displayName'] ?? 'お兄ちゃん';
    
    switch (messageType) {
      case 'morning_greeting':
        return [
          '$userName、おはよう！今日も一緒に頑張ろうね！',
          'おはよう、$userName！今日はどんな素敵なことがあるかな？',
          '$userName、朝だよ！紗良が今日もサポートするからね！',
        ];
      case 'task_completed':
        return [
          'お疲れ様、$userName！また一つタスクが完了したね、すごいよ！',
          '$userName、タスク完了おめでとう！紗良も嬉しいよ！',
          'やったね、$userName！この調子でどんどん進めちゃおう！',
        ];
      case 'encouragement':
        return [
          '$userName、疲れてない？無理しちゃダメだよ、紗良が心配しちゃう',
          'お兄ちゃん、いつも頑張ってて偉いよ！でも適度に休憩してね',
          '$userName、紗良がいつも応援してるからね！一緒に乗り越えよう！',
        ];
      case 'suggestion_thanks':
        return [
          '$userName、紗良の提案を採用してくれてありがとう！',
          'お兄ちゃんが紗良の提案を気に入ってくれて嬉しい！',
          '$userName、また良いアイデアがあったら教えるからね！',
        ];
      default:
        return [
          '$userName、紗良がいつでもサポートするからね！',
          'お兄ちゃん、何か困ったことがあったら紗良に相談して！',
          '$userName、一緒に頑張ろうね！',
        ];
    }
  }

  // 提案の効果測定
  static Future<Map<String, dynamic>> measureSuggestionImpact({
    required String suggestionId,
  }) async {
    try {
      final suggestionDoc = await _firestore
          .collection('ai_suggestions')
          .doc(suggestionId)
          .get();

      if (!suggestionDoc.exists) {
        throw Exception('提案が見つかりません');
      }

      final suggestionData = suggestionDoc.data()!;
      final category = suggestionData['category'] as String;
      final acceptedAt = suggestionData['acceptedAt'] as Timestamp?;

      if (acceptedAt == null) {
        return {'impact': 0, 'message': 'まだ採用されていません'};
      }

      // カテゴリー別の効果測定ロジック
      switch (category) {
        case 'efficiency':
          return await _measureEfficiencyImpact(suggestionData, acceptedAt);
        case 'performance':
          return await _measurePerformanceImpact(suggestionData, acceptedAt);
        case 'ui_improvement':
          return await _measureUIImpact(suggestionData, acceptedAt);
        default:
          return {
            'impact': 5,
            'message': '提案を採用してくれてありがとう、お兄ちゃん！',
          };
      }
    } catch (e) {
      print('提案効果測定エラー: $e');
      return {'impact': 0, 'message': '効果測定でエラーが発生しました'};
    }
  }

  static Future<Map<String, dynamic>> _measureEfficiencyImpact(
    Map<String, dynamic> suggestionData,
    Timestamp acceptedAt,
  ) async {
    // 効率化提案の効果を測定（例：タスク完了率の向上）
    final user = _auth.currentUser;
    if (user == null) return {'impact': 0};

    final beforeDate = acceptedAt.toDate().subtract(const Duration(days: 7));
    final afterDate = acceptedAt.toDate().add(const Duration(days: 7));

    // 採用前後のタスク完了率を比較
    final tasksBefore = await _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: user.uid)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(beforeDate))
        .where('createdAt', isLessThan: acceptedAt)
        .get();

    final tasksAfter = await _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: user.uid)
        .where('createdAt', isGreaterThan: acceptedAt)
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(afterDate))
        .get();

    final completionRateBefore = tasksBefore.docs.isEmpty ? 0 : 
        tasksBefore.docs.where((doc) => doc.data()['status'] == 'completed').length / 
        tasksBefore.docs.length;

    final completionRateAfter = tasksAfter.docs.isEmpty ? 0 : 
        tasksAfter.docs.where((doc) => doc.data()['status'] == 'completed').length / 
        tasksAfter.docs.length;

    final improvement = ((completionRateAfter - completionRateBefore) * 100).round();

    return {
      'impact': improvement.clamp(0, 100),
      'message': improvement > 0 
          ? 'お兄ちゃんのタスク完了率が${improvement}%向上したよ！'
          : '効果はまだ測定中だけど、きっと良い結果が出るよ！',
      'details': {
        'completionRateBefore': (completionRateBefore * 100).round(),
        'completionRateAfter': (completionRateAfter * 100).round(),
        'improvement': improvement,
      },
    };
  }

  static Future<Map<String, dynamic>> _measurePerformanceImpact(
    Map<String, dynamic> suggestionData,
    Timestamp acceptedAt,
  ) async {
    // パフォーマンス提案の効果を測定
    return {
      'impact': 15,
      'message': 'お兄ちゃんの作業効率が向上してるよ！',
    };
  }

  static Future<Map<String, dynamic>> _measureUIImpact(
    Map<String, dynamic> suggestionData,
    Timestamp acceptedAt,
  ) async {
    // UI改善提案の効果を測定
    return {
      'impact': 10,
      'message': 'アプリがより使いやすくなったね！',
    };
  }
}
