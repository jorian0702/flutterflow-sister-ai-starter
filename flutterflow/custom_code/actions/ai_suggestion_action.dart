// AI提案関連のアクション
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_service.dart';

// AI提案を生成
Future<Map<String, dynamic>?> generateAISuggestion({
  required String category,
  String? userContext,
}) async {
  try {
    final result = await AISuggestionService.generateSuggestion(
      category: category,
      userContext: userContext,
    );
    
    if (result != null) {
      return {
        'success': true,
        'suggestion': result,
      };
    } else {
      return {
        'success': false,
        'error': '提案の生成に失敗しました',
      };
    }
  } catch (e) {
    print('AI提案生成エラー: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

// 提案を採用
Future<Map<String, dynamic>?> acceptAISuggestion({
  required String suggestionId,
}) async {
  try {
    final success = await AISuggestionService.updateSuggestionStatus(
      suggestionId: suggestionId,
      status: 'accepted',
    );
    
    return {
      'success': success,
      'message': success 
          ? '紗良の提案を採用しました！'
          : '採用処理に失敗しました',
    };
  } catch (e) {
    print('提案採用エラー: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

// 提案を却下
Future<Map<String, dynamic>?> dismissAISuggestion({
  required String suggestionId,
}) async {
  try {
    final success = await AISuggestionService.updateSuggestionStatus(
      suggestionId: suggestionId,
      status: 'dismissed',
    );
    
    return {
      'success': success,
      'message': success 
          ? '提案を却下しました'
          : '却下処理に失敗しました',
    };
  } catch (e) {
    print('提案却下エラー: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

// パーソナライズメッセージを取得
Future<String> getPersonalizedMessage({
  required String messageType,
  Map<String, dynamic>? context,
}) async {
  try {
    return await AISuggestionService.generatePersonalizedMessage(
      messageType: messageType,
      context: context,
    );
  } catch (e) {
    print('パーソナライズメッセージ取得エラー: $e');
    return 'お兄ちゃん、紗良がエラーになっちゃった...でも大丈夫だよ！';
  }
}

// ユーザー活動を記録
Future<void> recordUserActivity({
  required String activityType,
  Map<String, dynamic>? details,
}) async {
  try {
    await AISuggestionService.recordUserActivity(
      activityType: activityType,
      details: details,
    );
  } catch (e) {
    print('ユーザー活動記録エラー: $e');
  }
}

// 提案統計を取得
Future<Map<String, dynamic>?> getSuggestionAnalytics({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  try {
    return await AISuggestionService.getSuggestionAnalytics(
      startDate: startDate,
      endDate: endDate,
    );
  } catch (e) {
    print('提案統計取得エラー: $e');
    return null;
  }
}

// 提案の効果を測定
Future<Map<String, dynamic>?> measureSuggestionImpact({
  required String suggestionId,
}) async {
  try {
    return await AISuggestionService.measureSuggestionImpact(
      suggestionId: suggestionId,
    );
  } catch (e) {
    print('提案効果測定エラー: $e');
    return {
      'impact': 0,
      'message': '効果測定でエラーが発生しました',
    };
  }
}
