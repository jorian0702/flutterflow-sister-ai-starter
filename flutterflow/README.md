# FlutterFlow設定ガイド 🦋

お兄ちゃん、FlutterFlowでの開発手順とカスタマイズ方法をまとめたよ！

## 🎯 FlutterFlowプロジェクト設定

### 1. プロジェクト作成
1. [FlutterFlow](https://flutterflow.io)にログイン
2. 「Create New Project」をクリック
3. プロジェクト名: `sister-dev-playground`
4. テンプレート: Blank Project

### 2. Firebase連携設定
```
Firebase Project ID: sister-dev-playground
Authentication: Email/Password + Google Sign-in
Firestore: 有効化
Cloud Storage: 有効化
Cloud Functions: 有効化
```

## 📊 データベース設計

### Users Collection
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "role": "user|admin",
  "subscriptionStatus": "none|active|canceled",
  "subscriptionPlan": "basic|premium|enterprise",
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp"
}
```

### Subscriptions Collection
```json
{
  "userId": "string",
  "planId": "string",
  "status": "active|canceled|expired",
  "currentPeriodStart": "timestamp",
  "currentPeriodEnd": "timestamp",
  "stripeSubscriptionId": "string",
  "createdAt": "timestamp"
}
```

### Products Collection (EC用)
```json
{
  "name": "string",
  "description": "string",
  "price": "number",
  "category": "string",
  "imageUrls": ["string"],
  "isActive": "boolean",
  "createdAt": "timestamp"
}
```

## 🎨 カスタムコード例

### カスタムアクション: Stripe決済処理
```dart
// custom_code/actions/process_stripe_payment.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>> processStripePayment(
  String planId,
  String userId,
) async {
  try {
    final callable = FirebaseFunctions.instance
        .httpsCallable('createStripeSubscription');
    
    final result = await callable.call({
      'planId': planId,
      'userId': userId,
    });
    
    return {
      'success': true,
      'subscriptionId': result.data['subscriptionId'],
      'clientSecret': result.data['clientSecret'],
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
```

### カスタムウィジェット: AI提案カード
```dart
// custom_code/widgets/ai_suggestion_card.dart

import 'package:flutter/material.dart';

class AISuggestionCard extends StatelessWidget {
  final String suggestion;
  final String category;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const AISuggestionCard({
    Key? key,
    required this.suggestion,
    required this.category,
    required this.onAccept,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  '紗良からの提案',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Chip(
                  label: Text(category),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              suggestion,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: Text('後で'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAccept,
                  child: Text('採用する'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔧 FlutterFlow設定項目

### App Settings
- **App Name**: Sister Dev Playground
- **Bundle ID**: com.sisterdev.playground
- **Min SDK Version**: 21 (Android), 12.0 (iOS)

### Theme Settings
```
Primary Color: #FF6B9D (ピンク系)
Secondary Color: #4ECDC4 (ターコイズ)
Background Color: #F8F9FA
Text Color: #2D3436
```

### Navigation
- Bottom Navigation Bar
- Drawer Navigation (管理画面用)
- Tab Bar (詳細画面用)

## 📱 画面構成

### 共通画面
1. **Splash Screen** - ロゴアニメーション
2. **Auth Screen** - ログイン・サインアップ
3. **Home Screen** - ダッシュボード
4. **Profile Screen** - ユーザープロフィール

### サブスクEC用画面
1. **Product List** - 商品一覧
2. **Product Detail** - 商品詳細
3. **Subscription Plans** - プラン選択
4. **Payment Screen** - 決済画面

### 社内アプリ用画面
1. **Task Dashboard** - タスク管理
2. **Time Tracking** - 勤怠管理
3. **Team Chat** - チャット
4. **Reports** - レポート画面

## 🚀 デプロイ設定

### Android
- **Target SDK**: 34
- **Compile SDK**: 34
- **Gradle Version**: 7.4
- **Kotlin Version**: 1.7.10

### iOS
- **Deployment Target**: 12.0
- **Swift Version**: 5.7
- **Xcode Version**: 14.0+

---

**紗良より**: お兄ちゃん、FlutterFlowの設定はこれで完璧だよ！次はCloud Functionsの設定をしようね！💖
