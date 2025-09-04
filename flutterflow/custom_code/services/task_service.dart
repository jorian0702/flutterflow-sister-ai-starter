// タスク管理サービス - Dartサービスクラス
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // タスクを作成
  static Future<String?> createTask({
    required String title,
    String? description,
    String? assignedTo,
    String priority = 'medium',
    DateTime? dueDate,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      final callable = _functions.httpsCallable('createTask');
      final result = await callable.call({
        'title': title,
        'description': description ?? '',
        'assignedTo': assignedTo ?? user.uid,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
        'tags': tags ?? [],
      });

      return result.data['taskId'] as String?;
    } catch (e) {
      print('タスク作成エラー: $e');
      return null;
    }
  }

  // タスク一覧を取得
  static Stream<QuerySnapshot> getTasks({
    String? assignedTo,
    String? status,
    String? priority,
    int limit = 20,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    Query query = _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true);

    // フィルター条件を適用
    if (assignedTo != null) {
      query = query.where('assignedTo', isEqualTo: assignedTo);
    } else {
      // デフォルトで自分のタスクのみ表示
      query = query.where('assignedTo', isEqualTo: user.uid);
    }

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    if (priority != null && priority != 'all') {
      query = query.where('priority', isEqualTo: priority);
    }

    return query.limit(limit).snapshots();
  }

  // 今日期限のタスクを取得
  static Stream<QuerySnapshot> getTodayTasks() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: user.uid)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isNotEqualTo: 'completed')
        .orderBy('status')
        .orderBy('priority')
        .snapshots();
  }

  // 期限切れのタスクを取得
  static Stream<QuerySnapshot> getOverdueTasks() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final now = DateTime.now();

    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: user.uid)
        .where('dueDate', isLessThan: Timestamp.fromDate(now))
        .where('status', isNotEqualTo: 'completed')
        .orderBy('dueDate')
        .snapshots();
  }

  // タスクのステータスを更新
  static Future<bool> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateTaskStatus');
      final result = await callable.call({
        'taskId': taskId,
        'status': status,
      });

      return result.data['success'] == true;
    } catch (e) {
      print('タスクステータス更新エラー: $e');
      return false;
    }
  }

  // タスクを更新
  static Future<bool> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    DateTime? dueDate,
    List<String>? tags,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (priority != null) updates['priority'] = priority;
      if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);
      if (tags != null) updates['tags'] = tags;
      
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update(updates);

      return true;
    } catch (e) {
      print('タスク更新エラー: $e');
      return false;
    }
  }

  // タスクを削除
  static Future<bool> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      return true;
    } catch (e) {
      print('タスク削除エラー: $e');
      return false;
    }
  }

  // タスクにコメントを追加
  static Future<bool> addTaskComment({
    required String taskId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      await _firestore.collection('task_comments').add({
        'taskId': taskId,
        'userId': user.uid,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // タスクの最終更新時間も更新
      await _firestore.collection('tasks').doc(taskId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('コメント追加エラー: $e');
      return false;
    }
  }

  // タスクのコメント一覧を取得
  static Stream<QuerySnapshot> getTaskComments(String taskId) {
    return _firestore
        .collection('task_comments')
        .where('taskId', isEqualTo: taskId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // タスクの統計情報を取得
  static Future<Map<String, dynamic>> getTaskStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final tasks = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      int totalTasks = tasks.docs.length;
      int completedTasks = 0;
      int inProgressTasks = 0;
      int todoTasks = 0;
      int overdueTasks = 0;
      Map<String, int> priorityBreakdown = {'high': 0, 'medium': 0, 'low': 0};
      Map<String, int> dailyCompletion = {};

      final now = DateTime.now();

      for (var doc in tasks.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final priority = data['priority'] as String;
        final dueDate = data['dueDate'] as Timestamp?;
        final completedAt = data['completedAt'] as Timestamp?;

        // ステータス別カウント
        switch (status) {
          case 'completed':
            completedTasks++;
            // 日別完了タスク数
            if (completedAt != null) {
              final dateKey = _formatDate(completedAt.toDate());
              dailyCompletion[dateKey] = (dailyCompletion[dateKey] ?? 0) + 1;
            }
            break;
          case 'in_progress':
            inProgressTasks++;
            break;
          case 'todo':
            todoTasks++;
            break;
        }

        // 期限切れチェック
        if (dueDate != null && 
            dueDate.toDate().isBefore(now) && 
            status != 'completed') {
          overdueTasks++;
        }

        // 優先度別カウント
        priorityBreakdown[priority] = (priorityBreakdown[priority] ?? 0) + 1;
      }

      // 完了率計算
      double completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

      // 平均完了時間計算（日数）
      double averageCompletionDays = 0;
      if (completedTasks > 0) {
        int totalDays = 0;
        int validTasks = 0;
        
        for (var doc in tasks.docs) {
          final data = doc.data();
          if (data['status'] == 'completed') {
            final createdAt = data['createdAt'] as Timestamp?;
            final completedAt = data['completedAt'] as Timestamp?;
            
            if (createdAt != null && completedAt != null) {
              final days = completedAt.toDate().difference(createdAt.toDate()).inDays;
              totalDays += days;
              validTasks++;
            }
          }
        }
        
        if (validTasks > 0) {
          averageCompletionDays = totalDays / validTasks;
        }
      }

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'inProgressTasks': inProgressTasks,
        'todoTasks': todoTasks,
        'overdueTasks': overdueTasks,
        'completionRate': completionRate.round(),
        'priorityBreakdown': priorityBreakdown,
        'dailyCompletion': dailyCompletion,
        'averageCompletionDays': averageCompletionDays.round(),
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      print('タスク統計取得エラー: $e');
      return {};
    }
  }

  // タスクの検索
  static Future<List<DocumentSnapshot>> searchTasks({
    required String searchTerm,
    String? status,
    String? priority,
    int limit = 20,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      // Firestoreでは全文検索が制限されているため、
      // タイトルの部分一致で検索
      Query query = _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: user.uid)
          .orderBy('title')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff']);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      if (priority != null && priority != 'all') {
        query = query.where('priority', isEqualTo: priority);
      }

      final result = await query.limit(limit).get();
      return result.docs;
    } catch (e) {
      print('タスク検索エラー: $e');
      return [];
    }
  }

  // タスクを複製
  static Future<String?> duplicateTask({
    required String taskId,
    String? newTitle,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      final originalTask = await _firestore
          .collection('tasks')
          .doc(taskId)
          .get();

      if (!originalTask.exists) {
        throw Exception('元のタスクが見つかりません');
      }

      final originalData = originalTask.data()!;
      
      final newTaskData = {
        'title': newTitle ?? '${originalData['title']} (コピー)',
        'description': originalData['description'] ?? '',
        'assignedTo': user.uid,
        'createdBy': user.uid,
        'status': 'todo',
        'priority': originalData['priority'] ?? 'medium',
        'dueDate': originalData['dueDate'],
        'tags': originalData['tags'] ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final newTaskDoc = await _firestore
          .collection('tasks')
          .add(newTaskData);

      return newTaskDoc.id;
    } catch (e) {
      print('タスク複製エラー: $e');
      return null;
    }
  }

  // 期限切れタスクの通知
  static Future<List<Map<String, dynamic>>> getOverdueTasksForNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final overdueTasks = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: user.uid)
          .where('dueDate', isLessThan: Timestamp.fromDate(yesterday))
          .where('status', isNotEqualTo: 'completed')
          .get();

      return overdueTasks.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'],
          'dueDate': data['dueDate'],
          'priority': data['priority'],
        };
      }).toList();
    } catch (e) {
      print('期限切れタスク取得エラー: $e');
      return [];
    }
  }

  // ユーティリティ: 日付フォーマット
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // タスクの自動分類（AI提案用）
  static Future<String> categorizeTask(String title, String? description) async {
    final content = '$title ${description ?? ''}'.toLowerCase();
    
    // 簡単なキーワードベース分類
    if (content.contains('会議') || content.contains('ミーティング')) {
      return 'meeting';
    } else if (content.contains('開発') || content.contains('コード') || content.contains('プログラム')) {
      return 'development';
    } else if (content.contains('資料') || content.contains('ドキュメント')) {
      return 'documentation';
    } else if (content.contains('レビュー') || content.contains('確認')) {
      return 'review';
    } else if (content.contains('テスト') || content.contains('検証')) {
      return 'testing';
    } else {
      return 'general';
    }
  }

  // 作業時間の推定
  static int estimateWorkingHours(String title, String? description, String priority) {
    final content = '$title ${description ?? ''}'.toLowerCase();
    int baseHours = 2; // デフォルト2時間
    
    // 優先度による調整
    switch (priority) {
      case 'high':
        baseHours = 4;
        break;
      case 'medium':
        baseHours = 2;
        break;
      case 'low':
        baseHours = 1;
        break;
    }
    
    // キーワードによる調整
    if (content.contains('簡単') || content.contains('軽微')) {
      baseHours = (baseHours * 0.5).round();
    } else if (content.contains('複雑') || content.contains('大規模')) {
      baseHours = (baseHours * 2).round();
    }
    
    return baseHours.clamp(1, 8); // 1-8時間の範囲
  }
}
