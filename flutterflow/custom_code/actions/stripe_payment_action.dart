// Stripe決済処理 - カスタムアクション
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Stripeサブスクリプション作成
Future<Map<String, dynamic>?> createStripeSubscription({
  required String planId,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final callable = FirebaseFunctions.instance
        .httpsCallable('createStripeSubscription');
    
    final result = await callable.call({
      'planId': planId,
    });
    
    if (result.data != null) {
      return {
        'success': true,
        'subscriptionId': result.data['subscriptionId'],
        'clientSecret': result.data['clientSecret'],
      };
    } else {
      return {
        'success': false,
        'error': 'サブスクリプションの作成に失敗しました',
      };
    }
  } catch (e) {
    print('Stripe決済エラー: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

// サブスクリプションキャンセル
Future<Map<String, dynamic>?> cancelStripeSubscription({
  required String subscriptionId,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final callable = FirebaseFunctions.instance
        .httpsCallable('cancelSubscription');
    
    final result = await callable.call({
      'subscriptionId': subscriptionId,
    });
    
    return {
      'success': result.data['success'] == true,
      'message': result.data['success'] == true 
          ? 'サブスクリプションをキャンセルしました'
          : 'キャンセルに失敗しました',
    };
  } catch (e) {
    print('サブスクリプションキャンセルエラー: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

// プラン変更
Future<Map<String, dynamic>?> updateSubscriptionPlan({
  required String subscriptionId,
  required String newPlanId,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final callable = FirebaseFunctions.instance
        .httpsCallable('updateSubscriptionPlan');
    
    final result = await callable.call({
      'subscriptionId': subscriptionId,
      'newPlanId': newPlanId,
    });
    
    return {
      'success': result.data['success'] == true,
      'message': result.data['success'] == true 
          ? 'プランを変更しました'
          : 'プラン変更に失敗しました',
    };
  } catch (e) {
    print('プラン変更エラー: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
