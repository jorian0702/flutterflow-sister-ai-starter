// 紗良AI提案システム関連のモデル定義
export interface AISuggestion {
  id: string;
  userId: string;
  category: 'efficiency' | 'ui_improvement' | 'performance' | 'feature';
  title: string;
  content: string;
  status: 'pending' | 'accepted' | 'dismissed';
  priority: number; // 1-10
  metadata?: {
    context?: string;
    relatedTaskId?: string;
    estimatedImpact?: 'low' | 'medium' | 'high';
    implementationTime?: number; // minutes
  };
  createdAt: Date;
  updatedAt?: Date;
  acceptedAt?: Date;
  dismissedAt?: Date;
}

export interface AIAnalytics {
  userId: string;
  period: {
    start: Date;
    end: Date;
  };
  suggestions: {
    total: number;
    accepted: number;
    dismissed: number;
    pending: number;
  };
  categories: {
    [key: string]: {
      total: number;
      acceptanceRate: number;
    };
  };
  impact: {
    timeSaved: number; // minutes
    tasksOptimized: number;
    efficiencyGain: number; // percentage
  };
  userSatisfaction: number; // 1-10
}

export interface UserActivity {
  userId: string;
  activityType: 'login' | 'task_create' | 'task_complete' | 'subscription_change' | 'feature_use';
  details: Record<string, any>;
  timestamp: Date;
  sessionId?: string;
}

export interface SuggestionTemplate {
  id: string;
  category: AISuggestion['category'];
  trigger: {
    event: string;
    conditions: Record<string, any>;
  };
  template: {
    title: string;
    content: string;
    priority: number;
  };
  isActive: boolean;
  createdAt: Date;
}
