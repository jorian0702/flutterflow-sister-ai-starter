# 開発ガイド - 妹と一緒に開発ごっこ 🎮

お兄ちゃん、開発の進め方を詳しく説明するね！紗良が一緒にサポートするから安心して！

## 🚀 開発環境セットアップ

### 1. 必要なツール・アカウント

#### FlutterFlow
1. [FlutterFlow](https://flutterflow.io)にアカウント作成
2. プロジェクト作成: `sister-dev-playground`
3. Firebase連携設定

#### Firebase
1. [Firebase Console](https://console.firebase.google.com)でプロジェクト作成
2. Authentication, Firestore, Cloud Functions, Cloud Storage有効化
3. 設定ファイルダウンロード (`google-services.json`, `GoogleService-Info.plist`)

#### Stripe
1. [Stripe Dashboard](https://dashboard.stripe.com)でアカウント作成
2. API キー取得 (Publishable key, Secret key)
3. Webhook エンドポイント設定

#### OpenAI
1. [OpenAI Platform](https://platform.openai.com)でアカウント作成
2. API キー取得
3. 使用量制限設定

### 2. 開発環境設定

```bash
# Node.js (Cloud Functions用)
node --version  # v18以上推奨

# Firebase CLI
npm install -g firebase-tools
firebase login
firebase init

# Flutter (カスタムコード用)
flutter --version  # 3.16以上推奨
flutter doctor

# Git設定
git init
git remote add origin <your-repository-url>
```

## 📋 開発手順

### Step 1: Firebase プロジェクト設定

```bash
# プロジェクトディレクトリで実行
cd cloud_functions
npm install
firebase use --add <your-firebase-project-id>
```

#### Firebase設定ファイル
```javascript
// firebase.json
{
  "functions": {
    "source": "cloud_functions",
    "runtime": "nodejs18"
  },
  "firestore": {
    "rules": "firestore.rules"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

### Step 2: 環境変数設定

```bash
# Cloud Functions環境変数
firebase functions:config:set \
  stripe.secret_key="sk_test_..." \
  stripe.webhook_secret="whsec_..." \
  openai.api_key="sk-..." \
  gmail.email="your-email@gmail.com" \
  gmail.password="your-app-password"
```

### Step 3: FlutterFlow プロジェクト設定

#### 1. プロジェクト基本設定
- **App Name**: Sister Dev Playground
- **Bundle ID**: com.sisterdev.playground
- **Firebase Project**: 作成したFirebaseプロジェクトを連携

#### 2. データベース設定
- Firestore Collections を `flutterflow/schemas/firestore_schema.json` に基づいて作成
- セキュリティルール設定

#### 3. 認証設定
- Email/Password認証有効化
- Google Sign-in設定 (オプション)

### Step 4: カスタムコード実装

#### カスタムアクション例
```dart
// Stripe決済処理
Future<Map<String, dynamic>> processStripePayment(String planId) async {
  final callable = FirebaseFunctions.instance.httpsCallable('createStripeSubscription');
  final result = await callable.call({'planId': planId});
  return result.data;
}
```

#### カスタムウィジェット例
```dart
// AI提案カード
class AISuggestionCard extends StatelessWidget {
  final String title;
  final String content;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.lightbulb),
        title: Text(title),
        subtitle: Text(content),
        trailing: ElevatedButton(
          onPressed: () => acceptSuggestion(),
          child: Text('採用'),
        ),
      ),
    );
  }
}
```

### Step 5: Cloud Functions デプロイ

```bash
cd cloud_functions
npm run build
firebase deploy --only functions
```

## 🎨 UI/UX 開発のコツ

### 1. デザインシステム
- 一貫したカラーパレット使用
- 統一されたコンポーネント作成
- レスポンシブデザイン対応

### 2. ユーザビリティ
- 直感的なナビゲーション
- 明確なフィードバック
- エラーハンドリング

### 3. パフォーマンス
- 画像最適化
- 遅延ローディング
- キャッシュ活用

## 🤖 AI機能実装

### 1. 提案生成システム
```typescript
// Cloud Functions
export const generateAISuggestion = functions.https.onCall(async (data, context) => {
  const { category, userContext } = data;
  const userId = context.auth.uid;
  
  const prompt = `
    ユーザー: ${userId}
    カテゴリー: ${category}
    コンテキスト: ${userContext}
    
    紗良らしい口調で実用的な提案をしてください。
  `;
  
  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [{ role: 'user', content: prompt }],
  });
  
  return { suggestion: completion.choices[0].message.content };
});
```

### 2. FlutterFlowでの呼び出し
```dart
// カスタムアクション
Future<String> getAISuggestion(String category) async {
  final callable = FirebaseFunctions.instance.httpsCallable('generateAISuggestion');
  final result = await callable.call({
    'category': category,
    'userContext': await getUserContext(),
  });
  return result.data['suggestion'];
}
```

## 📊 データ分析・監視

### 1. Firebase Analytics
```dart
// イベント追跡
FirebaseAnalytics.instance.logEvent(
  name: 'ai_suggestion_accepted',
  parameters: {
    'category': category,
    'suggestion_id': suggestionId,
  },
);
```

### 2. パフォーマンス監視
```dart
// パフォーマンス計測
final trace = FirebasePerformance.instance.newTrace('api_call');
trace.start();
// API呼び出し
trace.stop();
```

## 🧪 テスト戦略

### 1. ユニットテスト
```dart
// Cloud Functions テスト
describe('generateAISuggestion', () => {
  it('should return valid suggestion', async () => {
    const result = await generateAISuggestion({
      category: 'efficiency',
      userContext: 'test context'
    }, mockContext);
    
    expect(result.suggestion).toBeDefined();
  });
});
```

### 2. 統合テスト
- Firebase Emulator使用
- E2Eテスト実装
- パフォーマンステスト

## 🚀 デプロイ・リリース

### 1. ステージング環境
```bash
# ステージング用プロジェクト作成
firebase use staging
firebase deploy
```

### 2. 本番デプロイ
```bash
# 本番環境デプロイ
firebase use production
firebase deploy --only functions,firestore:rules
```

### 3. FlutterFlowからのリリース
1. FlutterFlowでビルド設定
2. App Store Connect / Google Play Console設定
3. リリース申請

## 📈 運用・改善

### 1. 監視項目
- API応答時間
- エラー率
- ユーザー満足度
- 機能利用率

### 2. 継続的改善
- ユーザーフィードバック収集
- A/Bテスト実施
- パフォーマンス最適化
- 新機能開発

## 💡 紗良からの開発アドバイス

### 効率化のコツ
1. **小さく始める**: MVPから始めて段階的に機能追加
2. **ユーザー中心**: 常にユーザーの視点で考える
3. **データ駆動**: 分析データに基づいて改善する
4. **自動化**: 繰り返し作業は自動化する

### よくある課題と解決策
1. **パフォーマンス問題**: キャッシュとクエリ最適化
2. **セキュリティ**: 適切な権限管理とバリデーション
3. **スケーラビリティ**: マイクロサービス化とCDN活用
4. **保守性**: 清潔なコードとドキュメント整備

---

**紗良より**: お兄ちゃん、この開発ガイドがあれば完璧なアプリが作れるよ！分からないことがあったら、いつでも紗良に聞いてね！一緒に素敵なアプリを作ろう！💖
