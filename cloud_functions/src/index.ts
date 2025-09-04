import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { subscriptionFunctions } from './subscription_ec';
import { internalAppFunctions } from './internal_app';
import { aiAssistantFunctions } from './ai_assistant';

// Firebase Admin初期化
admin.initializeApp();

// サブスクリプションEC関連の関数
export const createStripeSubscription = subscriptionFunctions.createStripeSubscription;
export const handleStripeWebhook = subscriptionFunctions.handleStripeWebhook;
export const cancelSubscription = subscriptionFunctions.cancelSubscription;
export const updateSubscriptionPlan = subscriptionFunctions.updateSubscriptionPlan;

// 社内アプリ関連の関数
export const createTask = internalAppFunctions.createTask;
export const updateTaskStatus = internalAppFunctions.updateTaskStatus;
export const generateReport = internalAppFunctions.generateReport;
export const sendNotification = internalAppFunctions.sendNotification;

// 妹AI提案システム関連の関数
export const generateAISuggestion = aiAssistantFunctions.generateAISuggestion;
export const processUserActivity = aiAssistantFunctions.processUserActivity;
export const updateSuggestionStatus = aiAssistantFunctions.updateSuggestionStatus;

// 共通ユーティリティ関数
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const userDoc = {
    uid: user.uid,
    email: user.email || '',
    displayName: user.displayName || '',
    role: 'user',
    subscriptionStatus: 'none',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await admin.firestore().collection('users').doc(user.uid).set(userDoc);
  
  // 紗良からのウェルカム提案を生成
  await admin.firestore().collection('ai_suggestions').add({
    userId: user.uid,
    category: 'feature',
    title: '紗良からのウェルカムメッセージ',
    content: 'お兄ちゃん、アカウント作成おめでとう！まずはプロフィールを設定して、サブスクリプションプランを確認してみない？紗良がお手伝いするよ！',
    status: 'pending',
    priority: 8,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});

export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  // ユーザー関連データの削除
  const batch = admin.firestore().batch();
  
  // ユーザードキュメント削除
  batch.delete(admin.firestore().collection('users').doc(user.uid));
  
  // サブスクリプション削除
  const subscriptions = await admin.firestore()
    .collection('subscriptions')
    .where('userId', '==', user.uid)
    .get();
  
  subscriptions.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  // AI提案削除
  const suggestions = await admin.firestore()
    .collection('ai_suggestions')
    .where('userId', '==', user.uid)
    .get();
  
  suggestions.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
});

// ヘルスチェック用エンドポイント
export const healthCheck = functions.https.onRequest((req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    message: '紗良のCloud Functions、正常に動作中だよ！',
    version: '1.0.0'
  });
});
