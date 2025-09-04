// タスク管理カード - カスタムウィジェット
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatefulWidget {
  final String taskId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final List<String>? tags;
  final VoidCallback? onTap;
  final VoidCallback? onStatusChanged;
  
  const TaskCard({
    Key? key,
    required this.taskId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.tags,
    this.onTap,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ステータスに応じたスタイルを取得
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status) {
      case 'todo':
        return {
          'icon': Icons.radio_button_unchecked,
          'color': Colors.grey,
          'label': '未着手',
          'backgroundColor': Colors.grey[100],
        };
      case 'in_progress':
        return {
          'icon': Icons.access_time,
          'color': Colors.blue,
          'label': '進行中',
          'backgroundColor': Colors.blue[50],
        };
      case 'completed':
        return {
          'icon': Icons.check_circle,
          'color': Colors.green,
          'label': '完了',
          'backgroundColor': Colors.green[50],
        };
      default:
        return {
          'icon': Icons.help,
          'color': Colors.grey,
          'label': '不明',
          'backgroundColor': Colors.grey[100],
        };
    }
  }

  // 優先度に応じたスタイルを取得
  Map<String, dynamic> _getPriorityStyle(String priority) {
    switch (priority) {
      case 'high':
        return {
          'icon': Icons.keyboard_arrow_up,
          'color': Colors.red,
          'label': '高',
        };
      case 'medium':
        return {
          'icon': Icons.remove,
          'color': Colors.orange,
          'label': '中',
        };
      case 'low':
        return {
          'icon': Icons.keyboard_arrow_down,
          'color': Colors.green,
          'label': '低',
        };
      default:
        return {
          'icon': Icons.remove,
          'color': Colors.grey,
          'label': '未設定',
        };
    }
  }

  // 期限の表示スタイルを取得
  Map<String, dynamic> _getDueDateStyle(DateTime? dueDate) {
    if (dueDate == null) return {'color': Colors.grey, 'text': '期限なし'};
    
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) {
      return {'color': Colors.red, 'text': '期限切れ'};
    } else if (difference == 0) {
      return {'color': Colors.orange, 'text': '今日まで'};
    } else if (difference == 1) {
      return {'color': Colors.amber, 'text': '明日まで'};
    } else if (difference <= 7) {
      return {'color': Colors.blue, 'text': '${difference}日後'};
    } else {
      return {'color': Colors.grey, 'text': DateFormat('MM/dd').format(dueDate)};
    }
  }

  // タスクステータスを更新
  Future<void> _updateTaskStatus(String newStatus) async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });

    try {
      final updates = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'completed') {
        updates['completedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update(updates);

      if (widget.onStatusChanged != null) {
        widget.onStatusChanged!();
      }

      // 完了時に紗良からのお祝いメッセージ
      if (newStatus == 'completed') {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('ai_suggestions')
              .add({
            'userId': user.uid,
            'category': 'feature',
            'title': 'お疲れ様、お兄ちゃん！',
            'content': 'タスク「${widget.title}」の完了おめでとう！お兄ちゃんの頑張りを見てて嬉しいよ。次のタスクも紗良が一緒にサポートするからね！',
            'status': 'pending',
            'priority': 3,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      _showSnackBar('タスクを更新しました', Colors.green);
    } catch (e) {
      _showSnackBar('更新に失敗しました: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ステータス変更ダイアログを表示
  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('ステータスを変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('todo'),
            _buildStatusOption('in_progress'),
            _buildStatusOption('completed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String status) {
    final statusStyle = _getStatusStyle(status);
    final isSelected = widget.status == status;
    
    return ListTile(
      leading: Icon(
        statusStyle['icon'],
        color: statusStyle['color'],
      ),
      title: Text(statusStyle['label']),
      selected: isSelected,
      onTap: () {
        Navigator.of(context).pop();
        if (!isSelected) {
          _updateTaskStatus(status);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _getStatusStyle(widget.status);
    final priorityStyle = _getPriorityStyle(widget.priority);
    final dueDateStyle = _getDueDateStyle(widget.dueDate);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusStyle['color'].withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー行
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _showStatusDialog,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: statusStyle['backgroundColor'],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              statusStyle['icon'],
                              color: statusStyle['color'],
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3436),
                              decoration: widget.status == 'completed'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        // 優先度表示
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityStyle['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                priorityStyle['icon'],
                                size: 12,
                                color: priorityStyle['color'],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                priorityStyle['label'],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: priorityStyle['color'],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // 説明文
                    if (widget.description != null && widget.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // フッター行
                    Row(
                      children: [
                        // 期限表示
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: dueDateStyle['color'],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dueDateStyle['text'],
                          style: TextStyle(
                            fontSize: 12,
                            color: dueDateStyle['color'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        
                        // タグ表示
                        if (widget.tags != null && widget.tags!.isNotEmpty)
                          ...widget.tags!.take(2).map((tag) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[700],
                              ),
                            ),
                          )).toList(),
                        
                        if (widget.tags != null && widget.tags!.length > 2)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${widget.tags!.length - 2}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
