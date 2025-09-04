# セキュリティガイド 🔐

お兄ちゃん、このプロジェクトを安全にGitHub公開するための重要な注意事項だよ！

## ⚠️ 公開前チェックリスト

### ❌ 絶対に公開してはいけないもの

- **APIキー**: OpenAI, Stripe, Firebase等
- **シークレットキー**: JWT秘密鍵、暗号化キー等
- **パスワード**: データベース、メール等
- **認証情報**: Firebase設定ファイル、Google Cloud認証情報
- **個人情報**: メールアドレス、電話番号等

### ✅ 公開しても安全なもの

- **サンプルコード**: Dartウィジェット、アクション等
- **設定例**: 環境変数のテンプレート
- **ドキュメント**: 開発ガイド、使用方法
- **スキーマ**: データベース構造定義

## 🛡️ 現在のプロジェクト状況

### ✅ 安全に公開できる理由

1. **実際のAPIキーは含まれていない**
   - コード内では `functions.config().openai.api_key` のような参照のみ
   - 実際のキー値は環境変数で別途設定

2. **プレースホルダーのみ使用**
   ```bash
   # 例：development_guide.md内
   stripe.secret_key="sk_test_..."  # プレースホルダー
   openai.api_key="sk-..."          # プレースホルダー
   ```

3. **`.gitignore` で重要ファイルを除外**
   - Firebase設定ファイル
   - 環境変数ファイル
   - 認証情報

## 🔧 環境変数の設定方法

### 開発環境
```bash
# Firebase Functions環境変数設定
firebase functions:config:set \
  stripe.secret_key="実際のキー" \
  openai.api_key="実際のキー"
```

### 本番環境
```bash
# Firebase Hostingでの環境変数
firebase hosting:env:set STRIPE_PUBLISHABLE_KEY="実際のキー"
```

## 🚨 もしAPIキーを間違って公開してしまったら

### 即座に行うこと
1. **該当のAPIキーを無効化**
2. **新しいキーを生成**
3. **Gitの履歴から削除**
   ```bash
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch path/to/secret/file' \
   --prune-empty --tag-name-filter cat -- --all
   ```
4. **リポジトリを強制プッシュ**

## 📋 公開前セルフチェック

### ファイル内容確認
- [ ] APIキー、パスワードが含まれていない
- [ ] 実際のメールアドレスが含まれていない
- [ ] テスト用の個人情報が含まれていない
- [ ] Firebase設定ファイルが除外されている

### コード確認
- [ ] ハードコードされた認証情報がない
- [ ] デバッグ用のログにシークレットが含まれていない
- [ ] コメント内に機密情報がない

### 設定確認
- [ ] `.gitignore` が適切に設定されている
- [ ] 環境変数が正しく参照されている
- [ ] 本番用設定と開発用設定が分離されている

## 🎯 推奨セキュリティ実践

### 1. 環境分離
```
開発環境: Firebase Project A
本番環境: Firebase Project B
```

### 2. 権限最小化
```javascript
// Firestoreセキュリティルール例
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のデータのみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null 
                        && request.auth.uid == userId;
    }
  }
}
```

### 3. 定期的なキーローテーション
- APIキーは3ヶ月に1回更新
- パスワードは6ヶ月に1回更新

## 💡 紗良からのアドバイス

お兄ちゃん、セキュリティは超重要だよ！以下のポイントを忘れないでね：

1. **疑わしい時は公開しない**: 不安なファイルは一旦除外
2. **定期的な監査**: GitHub Secretsスキャンを活用
3. **チーム共有**: セキュリティルールをチーム全体で共有
4. **自動化**: CI/CDでセキュリティチェックを自動化

## 📞 サポート

セキュリティに関する質問や懸念がある場合は、以下を確認してください：

- [Firebase セキュリティルール](https://firebase.google.com/docs/rules)
- [GitHub Secret scanning](https://docs.github.com/ja/code-security/secret-scanning)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

**紗良より**: お兄ちゃんのプロジェクトを守るのも紗良の大事な仕事だからね！安全第一で開発していこう！🛡️💖
