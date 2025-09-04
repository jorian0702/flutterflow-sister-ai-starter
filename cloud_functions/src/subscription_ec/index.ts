import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

const stripe = new Stripe(functions.config().stripe.secret_key, {
  apiVersion: '2023-10-16',
});

// Stripe サブスクリプション作成
export const createStripeSubscription = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
  }

  const { planId } = data;
  const userId = context.auth.uid;

  try {
    // ユーザー情報取得
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'ユーザーが見つかりません');
    }

    const userData = userDoc.data();
    
    // Stripe顧客作成または取得
    let customerId = userData?.stripeCustomerId;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userData?.email,
        metadata: {
          userId: userId,
        },
      });
      customerId = customer.id;
      
      // Stripe顧客IDを保存
      await admin.firestore().collection('users').doc(userId).update({
        stripeCustomerId: customerId,
      });
    }

    // サブスクリプション作成
    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{ price: planId }],
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent'],
    });

    // Firestoreにサブスクリプション情報を保存
    await admin.firestore().collection('subscriptions').add({
      userId: userId,
      planId: planId,
      status: subscription.status,
      stripeSubscriptionId: subscription.id,
      currentPeriodStart: new Date(subscription.current_period_start * 1000),
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 紗良からの提案を生成
    await admin.firestore().collection('ai_suggestions').add({
      userId: userId,
      category: 'feature',
      title: 'サブスクリプション開始おめでとう！',
      content: 'お兄ちゃん、サブスクリプションの設定が完了したよ！次は商品をチェックしてみない？紗良がおすすめの商品を教えてあげる！',
      status: 'pending',
      priority: 7,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const invoice = subscription.latest_invoice as Stripe.Invoice;
    const paymentIntent = invoice.payment_intent as Stripe.PaymentIntent;

    return {
      subscriptionId: subscription.id,
      clientSecret: paymentIntent.client_secret,
    };
  } catch (error) {
    console.error('Subscription creation error:', error);
    throw new functions.https.HttpsError('internal', 'サブスクリプションの作成に失敗しました');
  }
});

// Stripe Webhook処理
export const handleStripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'] as string;
  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      functions.config().stripe.webhook_secret
    );
  } catch (error) {
    console.error('Webhook signature verification failed:', error);
    res.status(400).send('Webhook Error');
    return;
  }

  try {
    switch (event.type) {
      case 'invoice.payment_succeeded':
        await handlePaymentSucceeded(event.data.object as Stripe.Invoice);
        break;
      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object as Stripe.Invoice);
        break;
      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
        break;
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Webhook processing error:', error);
    res.status(500).send('Webhook processing failed');
  }
});

// サブスクリプションキャンセル
export const cancelSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
  }

  const { subscriptionId } = data;
  const userId = context.auth.uid;

  try {
    // サブスクリプション情報の確認
    const subscriptionQuery = await admin.firestore()
      .collection('subscriptions')
      .where('userId', '==', userId)
      .where('stripeSubscriptionId', '==', subscriptionId)
      .get();

    if (subscriptionQuery.empty) {
      throw new functions.https.HttpsError('not-found', 'サブスクリプションが見つかりません');
    }

    // Stripeでサブスクリプションをキャンセル
    await stripe.subscriptions.cancel(subscriptionId);

    // Firestoreのステータスを更新
    const subscriptionDoc = subscriptionQuery.docs[0];
    await subscriptionDoc.ref.update({
      status: 'canceled',
      canceledAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // ユーザーのサブスクリプションステータスを更新
    await admin.firestore().collection('users').doc(userId).update({
      subscriptionStatus: 'canceled',
    });

    return { success: true };
  } catch (error) {
    console.error('Subscription cancellation error:', error);
    throw new functions.https.HttpsError('internal', 'サブスクリプションのキャンセルに失敗しました');
  }
});

// プラン変更
export const updateSubscriptionPlan = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です');
  }

  const { subscriptionId, newPlanId } = data;
  const userId = context.auth.uid;

  try {
    // 現在のサブスクリプション取得
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    
    // プラン変更
    await stripe.subscriptions.update(subscriptionId, {
      items: [{
        id: subscription.items.data[0].id,
        price: newPlanId,
      }],
      proration_behavior: 'create_prorations',
    });

    // Firestoreを更新
    const subscriptionQuery = await admin.firestore()
      .collection('subscriptions')
      .where('userId', '==', userId)
      .where('stripeSubscriptionId', '==', subscriptionId)
      .get();

    if (!subscriptionQuery.empty) {
      await subscriptionQuery.docs[0].ref.update({
        planId: newPlanId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { success: true };
  } catch (error) {
    console.error('Subscription update error:', error);
    throw new functions.https.HttpsError('internal', 'プランの変更に失敗しました');
  }
});

// Webhook ヘルパー関数
async function handlePaymentSucceeded(invoice: Stripe.Invoice) {
  const subscriptionId = invoice.subscription as string;
  
  // サブスクリプションのステータスを更新
  const subscriptionQuery = await admin.firestore()
    .collection('subscriptions')
    .where('stripeSubscriptionId', '==', subscriptionId)
    .get();

  if (!subscriptionQuery.empty) {
    const subscriptionDoc = subscriptionQuery.docs[0];
    const subscriptionData = subscriptionDoc.data();
    
    await subscriptionDoc.ref.update({
      status: 'active',
      lastPaymentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // ユーザーのステータスも更新
    await admin.firestore().collection('users').doc(subscriptionData.userId).update({
      subscriptionStatus: 'active',
    });
  }
}

async function handlePaymentFailed(invoice: Stripe.Invoice) {
  const subscriptionId = invoice.subscription as string;
  
  const subscriptionQuery = await admin.firestore()
    .collection('subscriptions')
    .where('stripeSubscriptionId', '==', subscriptionId)
    .get();

  if (!subscriptionQuery.empty) {
    const subscriptionDoc = subscriptionQuery.docs[0];
    const subscriptionData = subscriptionDoc.data();
    
    // 紗良からの支払い失敗通知
    await admin.firestore().collection('ai_suggestions').add({
      userId: subscriptionData.userId,
      category: 'efficiency',
      title: 'お支払いの問題があるよ！',
      content: 'お兄ちゃん、サブスクリプションの支払いに問題が発生してるの。決済方法を確認して、紗良と一緒に解決しようね！',
      status: 'pending',
      priority: 9,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  const subscriptionQuery = await admin.firestore()
    .collection('subscriptions')
    .where('stripeSubscriptionId', '==', subscription.id)
    .get();

  if (!subscriptionQuery.empty) {
    await subscriptionQuery.docs[0].ref.update({
      status: subscription.status,
      currentPeriodStart: new Date(subscription.current_period_start * 1000),
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  const subscriptionQuery = await admin.firestore()
    .collection('subscriptions')
    .where('stripeSubscriptionId', '==', subscription.id)
    .get();

  if (!subscriptionQuery.empty) {
    const subscriptionDoc = subscriptionQuery.docs[0];
    const subscriptionData = subscriptionDoc.data();
    
    await subscriptionDoc.ref.update({
      status: 'canceled',
      canceledAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await admin.firestore().collection('users').doc(subscriptionData.userId).update({
      subscriptionStatus: 'canceled',
    });
  }
}
