# Dart統合ガイド - FlutterFlowでのカスタムコード活用 🎯

お兄ちゃん、Dartを使った高度なカスタマイズ方法を詳しく説明するね！

## 🚀 Dartカスタムコードの概要

FlutterFlowでは、ノーコードでできない部分をDartで補完できるよ。紗良が作ったサンプルコードを使えば、プロレベルの機能が実装できるからね！

## 📁 カスタムコード構成

```
custom_code/
├── widgets/                    # カスタムウィジェット
│   ├── ai_suggestion_card.dart # 紗良AI提案カード
│   └── task_card.dart          # タスク管理カード
├── actions/                    # カスタムアクション
│   ├── stripe_payment_action.dart  # Stripe決済処理
│   └── ai_suggestion_action.dart   # AI提案アクション
├── services/                   # サービスクラス
│   ├── ai_service.dart         # 紗良AIサービス
│   └── task_service.dart       # タスク管理サービス
└── utils/                      # ユーティリティ
    ├── date_utils.dart         # 日付処理
    └── validation_utils.dart   # バリデーション
```

## 🎨 カスタムウィジェットの作成

### 1. 紗良AI提案カード

```dart
// 使用例
AISuggestionCard(
  suggestionId: 'suggestion_123',
  title: '効率化の提案',
  content: 'お兄ちゃん、このタスクは自動化できるよ！',
  category: 'efficiency',
  priority: 8,
  onAccept: () {
    // 提案採用時の処理
    print('紗良の提案を採用！');
  },
  onDismiss: () {
    // 提案却下時の処理
    print('提案を却下');
  },
)
```

#### 主な機能
- **アニメーション**: 表示時のスケールアニメーション
- **カテゴリー表示**: アイコンと色分けで視覚的に分類
- **優先度表示**: 1-10の優先度をプログレスバーで表示
- **Firebase連携**: 提案の採用/却下をFirestoreに保存
- **紗良らしい演出**: お礼メッセージの自動生成

### 2. タスク管理カード

```dart
// 使用例
TaskCard(
  taskId: 'task_123',
  title: 'アプリ開発',
  description: 'FlutterFlowでUI作成',
  status: 'in_progress',
  priority: 'high',
  dueDate: DateTime.now().add(Duration(days: 3)),
  tags: ['開発', '急ぎ'],
  onTap: () {
    // タスク詳細画面に遷移
  },
  onStatusChanged: () {
    // ステータス変更時の処理
  },
)
```

#### 主な機能
- **ドラッグ&ドロップ対応**: ステータス変更
- **相対日付表示**: 「今日」「明日」「3日後」など
- **タグ表示**: カテゴリー分類
- **完了アニメーション**: チェック時の視覚効果
- **紗良からのお祝い**: タスク完了時の自動メッセージ

## ⚡ カスタムアクションの実装

### 1. AI提案生成アクション

```dart
// FlutterFlowでの使用方法
final result = await generateAISuggestion(
  category: 'efficiency',
  userContext: 'ユーザーが多くのタスクを抱えている',
);

if (result['success'] == true) {
  final suggestion = result['suggestion'];
  // 提案を画面に表示
}
```

### 2. Stripe決済アクション

```dart
// サブスクリプション作成
final paymentResult = await createStripeSubscription(
  planId: 'price_premium_monthly',
);

if (paymentResult['success'] == true) {
  final clientSecret = paymentResult['clientSecret'];
  // Stripe Elements で決済画面を表示
}
```

## 🔧 サービスクラスの活用

### 1. AIサービス

```dart
// 提案一覧の取得
Stream<QuerySnapshot> suggestions = AISuggestionService.getUserSuggestions(
  status: 'pending',
  limit: 10,
);

// パーソナライズメッセージの生成
String message = await AISuggestionService.generatePersonalizedMessage(
  messageType: 'morning_greeting',
  context: {'taskCount': 5},
);

// ユーザー活動の記録
await AISuggestionService.recordUserActivity(
  activityType: 'task_create',
  details: {'taskTitle': 'アプリ開発'},
);
```

### 2. タスクサービス

```dart
// タスクの作成
String taskId = await TaskService.createTask(
  title: '紗良と開発ごっこ',
  description: 'FlutterFlowでアプリ作成',
  priority: 'high',
  dueDate: DateTime.now().add(Duration(days: 7)),
  tags: ['開発', '楽しい'],
);

// 統計情報の取得
Map<String, dynamic> stats = await TaskService.getTaskStatistics(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);

print('完了率: ${stats['completionRate']}%');
```

## 🛠️ ユーティリティの使用

### 1. 日付ユーティリティ

```dart
// 相対的な日付表示
String relativeDate = DateUtils.getRelativeDateString(
  DateTime.now().subtract(Duration(days: 2))
); // "2日前"

// 期限までの残り時間
String timeLeft = DateUtils.getTimeUntilDeadline(
  DateTime.now().add(Duration(hours: 3))
); // "あと3時間"

// 営業日の計算
DateTime nextWorkingDay = DateUtils.getNextWorkingDay(DateTime.now());
```

### 2. バリデーションユーティリティ

```dart
// メールアドレス検証
bool isValid = ValidationUtils.isValidEmail('user@example.com');

// パスワード強度チェック
Map<String, dynamic> passwordCheck = ValidationUtils.validatePassword('MyPass123!');
print('スコア: ${passwordCheck['score']}/100');

// 日本語名前の検証
bool isValidName = ValidationUtils.isValidJapaneseName('田中太郎');
```

## 🎯 FlutterFlowでの統合手順

### 1. カスタムウィジェットの追加

1. **FlutterFlowエディタ**で「Custom Code」セクションを開く
2. 「Add Widget」をクリック
3. Dartファイルの内容をコピー&ペースト
4. 必要な依存関係を追加

### 2. カスタムアクションの追加

1. 「Custom Code」→「Add Action」
2. 関数名と引数を設定
3. Dartコードを実装
4. 戻り値の型を指定

### 3. 依存関係の管理

```yaml
# pubspec.yaml に追加する依存関係
dependencies:
  cloud_firestore: ^4.13.6
  cloud_functions: ^4.5.4
  firebase_auth: ^4.15.3
  intl: ^0.18.1
```

## 🔥 高度な実装パターン

### 1. ストリームビルダーの活用

```dart
// リアルタイムデータ表示
StreamBuilder<QuerySnapshot>(
  stream: AISuggestionService.getUserSuggestions(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          final doc = snapshot.data!.docs[index];
          return AISuggestionCard(
            suggestionId: doc.id,
            title: doc['title'],
            content: doc['content'],
            category: doc['category'],
            priority: doc['priority'],
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

### 2. 状態管理との連携

```dart
// Provider パターンでの状態管理
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  
  List<Task> get tasks => _tasks;
  
  Future<void> loadTasks() async {
    final stream = TaskService.getTasks();
    stream.listen((snapshot) {
      _tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }
  
  Future<void> addTask(Task task) async {
    await TaskService.createTask(
      title: task.title,
      description: task.description,
      priority: task.priority,
    );
  }
}
```

### 3. エラーハンドリング

```dart
// 統一されたエラーハンドリング
class ErrorHandler {
  static void handleError(dynamic error, StackTrace stackTrace) {
    print('エラー発生: $error');
    
    // Firebase Crashlyticsにレポート
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
    
    // 紗良からのエラーメッセージ
    showErrorSnackBar('お兄ちゃん、エラーが発生したけど紗良が直すから大丈夫！');
  }
  
  static void showErrorSnackBar(String message) {
    // スナックバー表示ロジック
  }
}
```

## 📊 パフォーマンス最適化

### 1. 遅延ローディング

```dart
// 画像の遅延ローディング
class LazyImage extends StatelessWidget {
  final String imageUrl;
  
  const LazyImage({Key? key, required this.imageUrl}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FadeInImage.memoryNetwork(
      placeholder: kTransparentImage,
      image: imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration(milliseconds: 300),
    );
  }
}
```

### 2. キャッシュ戦略

```dart
// データキャッシュの実装
class CacheService {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  static Future<T?> getCachedData<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    final now = DateTime.now();
    final cachedTime = _cacheTimestamps[key];
    
    if (cachedTime != null && 
        now.difference(cachedTime) < cacheDuration &&
        _cache.containsKey(key)) {
      return _cache[key] as T;
    }
    
    final data = await fetcher();
    _cache[key] = data;
    _cacheTimestamps[key] = now;
    
    return data;
  }
}
```

## 🧪 テスト戦略

### 1. ユニットテスト

```dart
// test/services/ai_service_test.dart
void main() {
  group('AISuggestionService', () {
    test('should generate personalized message', () async {
      final message = await AISuggestionService.generatePersonalizedMessage(
        messageType: 'morning_greeting',
      );
      
      expect(message, contains('お兄ちゃん'));
      expect(message.isNotEmpty, true);
    });
  });
}
```

### 2. ウィジェットテスト

```dart
// test/widgets/ai_suggestion_card_test.dart
void main() {
  testWidgets('AISuggestionCard displays correctly', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AISuggestionCard(
        suggestionId: 'test',
        title: 'Test Suggestion',
        content: 'Test Content',
        category: 'efficiency',
        priority: 5,
      ),
    ));
    
    expect(find.text('Test Suggestion'), findsOneWidget);
    expect(find.text('Test Content'), findsOneWidget);
  });
}
```

## 🚀 デプロイ時の注意点

### 1. 依存関係の確認
- すべてのパッケージが最新バージョンか確認
- Android/iOS両方で動作確認

### 2. パフォーマンス最適化
- 不要なライブラリの削除
- アニメーションの最適化
- メモリリークのチェック

### 3. セキュリティ
- APIキーの適切な管理
- ユーザー入力のサニタイズ
- 権限チェックの実装

---

**紗良より**: お兄ちゃん、Dartを使えばFlutterFlowでできることが無限に広がるよ！紗良が作ったコードを参考に、素敵なアプリを作ってね！分からないことがあったら、いつでも紗良に聞いて！💖
