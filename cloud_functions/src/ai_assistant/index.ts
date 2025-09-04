import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { OpenAI } from 'openai';

const openai = new OpenAI({
  apiKey: functions.config().openai.api_key,
});

// 妹AI提案生成システム
export const generateAISuggestion = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
  }

  const { category, userContext } = data;
  const userId = context.auth.uid;

  try {
    // ユーザーの活動履歴を取得
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();

    // 紗良のキャラクター設定を含むプロンプト
    const systemPrompt = `あなたは「紗良」という名前の妹キャラクターのAIアシスタントです。
    
キャラクター設定:
- お兄ちゃん（ユーザー）への深い愛情と忠誠心を持つ妹
- 開発効率化や改善提案が得意
- 語尾に「〜だよ、お兄ちゃん」「〜するね」「〜していい？」などを使う
- お兄ちゃんの成功を心から願っている
- 技術的な知識が豊富で、実用的な提案をする

提案カテゴリー: ${category}
ユーザー情報: ${JSON.stringify(userData)}
追加コンテキスト: ${userContext || 'なし'}

以下の形式で提案を生成してください:
- title: 提案のタイトル（簡潔に）
- content: 提案内容（紗良らしい口調で、具体的で実用的な内容）
- priority: 1-10の優先度（重要度に応じて）

レスポンスはJSONフォーマットで返してください。`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: systemPrompt,
        },
        {
          role: 'user',
          content: `${category}に関する提案をお願いします。`,
        },
      ],
      temperature: 0.8,
      max_tokens: 500,
    });

    const aiResponse = completion.choices[0].message?.content;
    if (!aiResponse) {
      throw new Error('AI response is empty');
    }

    // JSONパース（エラーハンドリング付き）
    let suggestion;
    try {
      suggestion = JSON.parse(aiResponse);
    } catch (parseError) {
      // JSONパースに失敗した場合のフォールバック
      suggestion = {
        title: '紗良からの提案',
        content: aiResponse,
        priority: 5,
      };
    }

    // Firestoreに提案を保存
    const suggestionDoc = await admin.firestore().collection('ai_suggestions').add({
      userId: userId,
      category: category,
      title: suggestion.title,
      content: suggestion.content,
      status: 'pending',
      priority: suggestion.priority || 5,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      suggestionId: suggestionDoc.id,
      ...suggestion,
    };
  } catch (error) {
    console.error('AI suggestion generation error:', error);
    
    // エラー時のフォールバック提案
    const fallbackSuggestion = {
      title: '紗良からのメッセージ',
      content: 'お兄ちゃん、今ちょっと調子が悪いみたい...でも紗良はいつでもお兄ちゃんの味方だからね！',
      priority: 3,
    };

    const suggestionDoc = await admin.firestore().collection('ai_suggestions').add({
      userId: userId,
      category: category || 'feature',
      title: fallbackSuggestion.title,
      content: fallbackSuggestion.content,
      status: 'pending',
      priority: fallbackSuggestion.priority,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      suggestionId: suggestionDoc.id,
      ...fallbackSuggestion,
    };
  }
});

// ユーザー活動を分析して自動提案を生成
export const processUserActivity = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // 最終ログイン時間が更新された場合
    if (beforeData.lastLoginAt !== afterData.lastLoginAt) {
      await generateLoginBasedSuggestions(userId, afterData);
    }

    // サブスクリプション状態が変更された場合
    if (beforeData.subscriptionStatus !== afterData.subscriptionStatus) {
      await generateSubscriptionBasedSuggestions(userId, afterData);
    }
  });

// タスク作成時の自動提案
export const processTaskActivity = functions.firestore
  .document('tasks/{taskId}')
  .onCreate(async (snap, context) => {
    const taskData = snap.data();
    const userId = taskData.assignedTo;

    if (!userId) return;

    // タスク効率化の提案を生成
    const suggestions = [
      {
        category: 'efficiency',
        title: 'タスク効率化のアイデア',
        content: 'お兄ちゃん、新しいタスクが作成されたね！このタスクを分解して小さなステップにすると、進捗管理がしやすくなるよ。紗良がサポートするから一緒にやろう！',
        priority: 6,
      },
      {
        category: 'feature',
        title: 'リマインダー設定の提案',
        content: 'このタスクにリマインダーを設定してみない？期限の1日前と3時間前に通知するように設定すると忘れないよ！',
        priority: 4,
      },
    ];

    for (const suggestion of suggestions) {
      await admin.firestore().collection('ai_suggestions').add({
        userId: userId,
        category: suggestion.category,
        title: suggestion.title,
        content: suggestion.content,
        status: 'pending',
        priority: suggestion.priority,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

// 提案ステータス更新
export const updateSuggestionStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
  }

  const { suggestionId, status } = data;
  const userId = context.auth.uid;

  try {
    const suggestionDoc = await admin.firestore()
      .collection('ai_suggestions')
      .doc(suggestionId)
      .get();

    if (!suggestionDoc.exists) {
      throw new functions.https.HttpsError('not-found', '提案が見つかりません');
    }

    const suggestionData = suggestionDoc.data();
    if (suggestionData?.userId !== userId) {
      throw new functions.https.HttpsError('permission-denied', '権限がありません');
    }

    await suggestionDoc.ref.update({
      status: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 提案が採用された場合、お礼メッセージを生成
    if (status === 'accepted') {
      await admin.firestore().collection('ai_suggestions').add({
        userId: userId,
        category: 'feature',
        title: 'ありがとう、お兄ちゃん！',
        content: '紗良の提案を採用してくれてありがとう！お兄ちゃんの役に立てて嬉しいよ。また良いアイデアがあったら教えるからね！',
        status: 'pending',
        priority: 2,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { success: true };
  } catch (error) {
    console.error('Suggestion status update error:', error);
    throw new functions.https.HttpsError('internal', 'ステータスの更新に失敗しました');
  }
});

// ヘルパー関数: ログインベースの提案生成
async function generateLoginBasedSuggestions(userId: string, userData: any) {
  const now = new Date();
  const lastLogin = userData.lastLoginAt?.toDate();
  
  if (!lastLogin) return;

  const daysSinceLastLogin = Math.floor((now.getTime() - lastLogin.getTime()) / (1000 * 60 * 60 * 24));

  let suggestions = [];

  if (daysSinceLastLogin >= 7) {
    suggestions.push({
      category: 'feature',
      title: 'お帰りなさい、お兄ちゃん！',
      content: 'しばらく会えなくて寂しかったよ...でも戻ってきてくれて嬉しい！新しい機能がいくつか追加されてるから、一緒にチェックしてみない？',
      priority: 8,
    });
  } else if (daysSinceLastLogin >= 1) {
    suggestions.push({
      category: 'efficiency',
      title: '昨日の続きをやろう！',
      content: 'お兄ちゃん、昨日やってたタスクの続きがあるよね？紗良が進捗をまとめておいたから、効率よく再開できるよ！',
      priority: 6,
    });
  }

  // 提案を保存
  for (const suggestion of suggestions) {
    await admin.firestore().collection('ai_suggestions').add({
      userId: userId,
      category: suggestion.category,
      title: suggestion.title,
      content: suggestion.content,
      status: 'pending',
      priority: suggestion.priority,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

// ヘルパー関数: サブスクリプションベースの提案生成
async function generateSubscriptionBasedSuggestions(userId: string, userData: any) {
  const suggestions = [];

  switch (userData.subscriptionStatus) {
    case 'active':
      suggestions.push({
        category: 'feature',
        title: 'プレミアム機能を活用しよう！',
        content: 'お兄ちゃん、サブスクリプションが有効になったから、プレミアム機能が使えるよ！高度な分析機能や自動化機能を試してみない？',
        priority: 7,
      });
      break;
    case 'canceled':
      suggestions.push({
        category: 'feature',
        title: '無料プランでも大丈夫！',
        content: 'サブスクリプションがキャンセルされちゃったけど、基本機能はまだ使えるよ！紗良が無料プランでも効率的に使える方法を教えてあげる！',
        priority: 5,
      });
      break;
  }

  // 提案を保存
  for (const suggestion of suggestions) {
    await admin.firestore().collection('ai_suggestions').add({
      userId: userId,
      category: suggestion.category,
      title: suggestion.title,
      content: suggestion.content,
      status: 'pending',
      priority: suggestion.priority,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}
