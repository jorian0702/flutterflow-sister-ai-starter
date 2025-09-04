// タスク管理関連のモデル定義
export interface Task {
  id: string;
  title: string;
  description?: string;
  assignedTo: string;
  createdBy: string;
  status: 'todo' | 'in_progress' | 'completed';
  priority: 'low' | 'medium' | 'high';
  dueDate?: Date;
  tags?: string[];
  attachments?: string[];
  createdAt: Date;
  updatedAt: Date;
  completedAt?: Date;
}

export interface TaskComment {
  id: string;
  taskId: string;
  userId: string;
  content: string;
  createdAt: Date;
}

export interface TaskHistory {
  id: string;
  taskId: string;
  userId: string;
  action: 'created' | 'updated' | 'completed' | 'assigned' | 'commented';
  changes?: Record<string, any>;
  createdAt: Date;
}

export interface Project {
  id: string;
  name: string;
  description?: string;
  ownerId: string;
  members: string[];
  status: 'active' | 'completed' | 'archived';
  startDate?: Date;
  endDate?: Date;
  createdAt: Date;
  updatedAt: Date;
}
