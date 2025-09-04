// 共通ユーザーモデル定義
export interface User {
  uid: string;
  email: string;
  displayName?: string;
  role: 'user' | 'admin';
  subscriptionStatus: 'none' | 'active' | 'canceled' | 'expired';
  subscriptionPlan?: 'basic' | 'premium' | 'enterprise';
  stripeCustomerId?: string;
  fcmToken?: string;
  createdAt: Date;
  lastLoginAt?: Date;
}

export interface UserPreferences {
  userId: string;
  categories: string[];
  priceRange: {
    min: number;
    max: number;
  };
  deliveryPreferences: {
    frequency: 'weekly' | 'monthly';
    dayOfWeek?: number;
    timeSlot?: string;
  };
  notifications: {
    email: boolean;
    push: boolean;
    sms: boolean;
  };
}

export interface Subscription {
  id: string;
  userId: string;
  planId: string;
  status: 'active' | 'canceled' | 'expired';
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  stripeSubscriptionId: string;
  canceledAt?: Date;
  createdAt: Date;
}
