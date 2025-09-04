import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

// メール送信設定
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: functions.config().gmail.email,
    pass: functions.config().gmail.password,
  },
});

// タスク作成
export const createTask = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
  }

  const { title, description, assignedTo, priority, dueDate } = data;
  const creatorId = context.auth.uid;

  try {
    // タスクを作成
    const taskDoc = await admin.firestore().collection('tasks').add({
      title: title,
      description: description || '',
      assignedTo: assignedTo || creatorId,
      createdBy: creatorId,
      status: 'todo',
      priority: priority || 'medium',
      dueDate: dueDate ? new Date(dueDate) : null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 担当者が自分以外の場合、通知を送信
    if (assignedTo && assignedTo !== creatorId) {
      await sendTaskNotification(assignedTo, {
        type: 'task_assigned',
        taskId: taskDoc.id,
        taskTitle: title,
        assignedBy: creatorId,
      });
    }

    // 紗良からのタスク管理提案
    await admin.firestore().collection('ai_suggestions').add({
      userId: creatorId,
      category: 'efficiency',
      title: 'タスク管理のコツ',
      content: `お兄ちゃん、「${title}」のタスクが作成されたね！このタスクを効率的に進めるために、小さなサブタスクに分割することを提案するよ。進捗が見えやすくなって、達成感も得られるからね！`,
      status: 'pending',
      priority: 4,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      taskId: taskDoc.id,
      success: true,
    };
  } catch (error) {
    console.error('Task creation error:', error);
    throw new functions.https.HttpsError('internal', 'タスクの作成に失敗しました');
  }
});

// タスクステータス更新
export const updateTaskStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
  }

  const { taskId, status } = data;
  const userId = context.auth.uid;

  try {
    const taskDoc = await admin.firestore().collection('tasks').doc(taskId).get();
    
    if (!taskDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'タスクが見つかりません');
    }

    const taskData = taskDoc.data();
    
    // 権限チェック（担当者または作成者のみ更新可能）
    if (taskData?.assignedTo !== userId && taskData?.createdBy !== userId) {
      throw new functions.https.HttpsError('permission-denied', 'このタスクを更新する権限がありません');
    }

    // ステータス更新
    await taskDoc.ref.update({
      status: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(status === 'completed' && { completedAt: admin.firestore.FieldValue.serverTimestamp() }),
    });

    // 完了時の特別処理
    if (status === 'completed') {
      // 作成者に完了通知（担当者と作成者が異なる場合）
      if (taskData.createdBy !== userId) {
        await sendTaskNotification(taskData.createdBy, {
          type: 'task_completed',
          taskId: taskId,
          taskTitle: taskData.title,
          completedBy: userId,
        });
      }

      // 紗良からのお疲れ様メッセージ
      await admin.firestore().collection('ai_suggestions').add({
        userId: userId,
        category: 'feature',
        title: 'お疲れ様、お兄ちゃん！',
        content: `「${taskData.title}」の完了おめでとう！お兄ちゃんの頑張りを見てて嬉しいよ。次のタスクも紗良が一緒にサポートするからね！`,
        status: 'pending',
        priority: 3,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { success: true };
  } catch (error) {
    console.error('Task status update error:', error);
    throw new functions.https.HttpsError('internal', 'タスクステータスの更新に失敗しました');
  }
});

// レポート生成
export const generateReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
  }

  const { reportType, startDate, endDate, userId } = data;
  const requesterId = context.auth.uid;

  try {
    let reportData;

    switch (reportType) {
      case 'task_summary':
        reportData = await generateTaskSummaryReport(userId || requesterId, startDate, endDate);
        break;
      case 'productivity':
        reportData = await generateProductivityReport(userId || requesterId, startDate, endDate);
        break;
      case 'team_performance':
        reportData = await generateTeamPerformanceReport(startDate, endDate);
        break;
      default:
        throw new functions.https.HttpsError('invalid-argument', '無効なレポートタイプです');
    }

    // 紗良からのレポート分析提案
    await admin.firestore().collection('ai_suggestions').add({
      userId: requesterId,
      category: 'performance',
      title: 'レポート分析のアドバイス',
      content: 'お兄ちゃん、レポートが生成されたよ！データを見ると、いくつか改善できるポイントがありそうだね。紗良が詳しく分析して、具体的な改善案を提案してあげる！',
      status: 'pending',
      priority: 6,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      reportData: reportData,
      generatedAt: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    console.error('Report generation error:', error);
    throw new functions.https.HttpsError('internal', 'レポートの生成に失敗しました');
  }
});

// 通知送信
export const sendNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
  }

  const { userId, title, message, type } = data;
  const senderId = context.auth.uid;

  try {
    // 通知をFirestoreに保存
    await admin.firestore().collection('notifications').add({
      userId: userId,
      senderId: senderId,
      title: title,
      message: message,
      type: type || 'general',
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // プッシュ通知の送信（FCMトークンがある場合）
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (userData?.fcmToken) {
      await admin.messaging().send({
        token: userData.fcmToken,
        notification: {
          title: title,
          body: message,
        },
        data: {
          type: type || 'general',
          senderId: senderId,
        },
      });
    }

    return { success: true };
  } catch (error) {
    console.error('Notification send error:', error);
    throw new functions.https.HttpsError('internal', '通知の送信に失敗しました');
  }
});

// 定期的なタスクリマインダー
export const sendTaskReminders = functions.pubsub
  .schedule('0 9 * * *') // 毎日午前9時
  .timeZone('Asia/Tokyo')
  .onRun(async (context) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(23, 59, 59, 999);

    // 明日が期限のタスクを取得
    const tasksSnapshot = await admin.firestore()
      .collection('tasks')
      .where('dueDate', '<=', tomorrow)
      .where('status', '!=', 'completed')
      .get();

    const reminderPromises = tasksSnapshot.docs.map(async (taskDoc) => {
      const taskData = taskDoc.data();
      
      // 担当者に通知
      await sendTaskNotification(taskData.assignedTo, {
        type: 'task_reminder',
        taskId: taskDoc.id,
        taskTitle: taskData.title,
        dueDate: taskData.dueDate,
      });

      // 紗良からのリマインダー提案
      await admin.firestore().collection('ai_suggestions').add({
        userId: taskData.assignedTo,
        category: 'efficiency',
        title: 'タスクの期限が近いよ！',
        content: `お兄ちゃん、「${taskData.title}」の期限が近づいてるよ！今のうちに進捗を確認して、必要なら優先度を調整しようね。紗良がサポートするから大丈夫！`,
        status: 'pending',
        priority: 8,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await Promise.all(reminderPromises);
    console.log(`Sent ${tasksSnapshot.docs.length} task reminders`);
  });

// ヘルパー関数: タスク通知送信
async function sendTaskNotification(userId: string, notification: any) {
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (!userData) return;

    let title = '';
    let message = '';

    switch (notification.type) {
      case 'task_assigned':
        title = '新しいタスクが割り当てられました';
        message = `「${notification.taskTitle}」があなたに割り当てられました`;
        break;
      case 'task_completed':
        title = 'タスクが完了しました';
        message = `「${notification.taskTitle}」が完了しました`;
        break;
      case 'task_reminder':
        title = 'タスクの期限が近づいています';
        message = `「${notification.taskTitle}」の期限が近づいています`;
        break;
    }

    // 通知をFirestoreに保存
    await admin.firestore().collection('notifications').add({
      userId: userId,
      title: title,
      message: message,
      type: notification.type,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // メール通知（設定がONの場合）
    if (userData.emailNotifications !== false) {
      await transporter.sendMail({
        from: functions.config().gmail.email,
        to: userData.email,
        subject: title,
        html: `
          <h2>Sister Dev Playground</h2>
          <p>${message}</p>
          <p>詳細はアプリでご確認ください。</p>
          <p>紗良より 💖</p>
        `,
      });
    }
  } catch (error) {
    console.error('Task notification error:', error);
  }
}

// ヘルパー関数: レポート生成関数群
async function generateTaskSummaryReport(userId: string, startDate: string, endDate: string) {
  const start = new Date(startDate);
  const end = new Date(endDate);

  const tasksSnapshot = await admin.firestore()
    .collection('tasks')
    .where('assignedTo', '==', userId)
    .where('createdAt', '>=', start)
    .where('createdAt', '<=', end)
    .get();

  const tasks = tasksSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  
  const summary = {
    totalTasks: tasks.length,
    completedTasks: tasks.filter(t => t.status === 'completed').length,
    inProgressTasks: tasks.filter(t => t.status === 'in_progress').length,
    todoTasks: tasks.filter(t => t.status === 'todo').length,
    overdueTasks: tasks.filter(t => t.dueDate && new Date(t.dueDate) < new Date() && t.status !== 'completed').length,
  };

  return {
    summary,
    tasks: tasks.slice(0, 10), // 最新10件
  };
}

async function generateProductivityReport(userId: string, startDate: string, endDate: string) {
  const start = new Date(startDate);
  const end = new Date(endDate);

  const completedTasksSnapshot = await admin.firestore()
    .collection('tasks')
    .where('assignedTo', '==', userId)
    .where('completedAt', '>=', start)
    .where('completedAt', '<=', end)
    .get();

  const completedTasks = completedTasksSnapshot.docs.map(doc => doc.data());
  
  // 日別完了タスク数
  const dailyCompletion = {};
  completedTasks.forEach(task => {
    const date = task.completedAt.toDate().toISOString().split('T')[0];
    dailyCompletion[date] = (dailyCompletion[date] || 0) + 1;
  });

  return {
    totalCompleted: completedTasks.length,
    averagePerDay: completedTasks.length / Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)),
    dailyCompletion,
    priorityBreakdown: {
      high: completedTasks.filter(t => t.priority === 'high').length,
      medium: completedTasks.filter(t => t.priority === 'medium').length,
      low: completedTasks.filter(t => t.priority === 'low').length,
    },
  };
}

async function generateTeamPerformanceReport(startDate: string, endDate: string) {
  const start = new Date(startDate);
  const end = new Date(endDate);

  const tasksSnapshot = await admin.firestore()
    .collection('tasks')
    .where('createdAt', '>=', start)
    .where('createdAt', '<=', end)
    .get();

  const tasks = tasksSnapshot.docs.map(doc => doc.data());
  
  // ユーザー別統計
  const userStats = {};
  tasks.forEach(task => {
    const userId = task.assignedTo;
    if (!userStats[userId]) {
      userStats[userId] = { total: 0, completed: 0 };
    }
    userStats[userId].total++;
    if (task.status === 'completed') {
      userStats[userId].completed++;
    }
  });

  return {
    totalTasks: tasks.length,
    totalCompleted: tasks.filter(t => t.status === 'completed').length,
    userStats,
    averageCompletionRate: Object.values(userStats).reduce((acc: number, stats: any) => 
      acc + (stats.completed / stats.total), 0) / Object.keys(userStats).length,
  };
}
