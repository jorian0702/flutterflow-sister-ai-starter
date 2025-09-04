// 紗良AI提案カード - カスタムウィジェット
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AISuggestionCard extends StatefulWidget {
  final String suggestionId;
  final String title;
  final String content;
  final String category;
  final int priority;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;
  
  const AISuggestionCard({
    Key? key,
    required this.suggestionId,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    this.onAccept,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<AISuggestionCard> createState() => _AISuggestionCardState();
}

class _AISuggestionCardState extends State<AISuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // カテゴリーに応じたアイコンとカラーを取得
  Map<String, dynamic> _getCategoryStyle(String category) {
    switch (category) {
      case 'efficiency':
        return {
          'icon': Icons.flash_on,
          'color': Colors.amber,
          'label': '効率化',
        };
      case 'ui_improvement':
        return {
          'icon': Icons.palette,
          'color': Colors.purple,
          'label': 'UI改善',
        };
      case 'performance':
        return {
          'icon': Icons.speed,
          'color': Colors.green,
          'label': 'パフォーマンス',
        };
      case 'feature':
        return {
          'icon': Icons.lightbulb,
          'color': Colors.blue,
          'label': '新機能',
        };
      default:
        return {
          'icon': Icons.help,
          'color': Colors.grey,
          'label': 'その他',
        };
    }
  }

  // 優先度に応じたボーダーカラー
  Color _getPriorityColor(int priority) {
    if (priority >= 8) return Colors.red;
    if (priority >= 6) return Colors.orange;
    if (priority >= 4) return Colors.yellow;
    return Colors.grey;
  }

  // 提案を採用する処理
  Future<void> _acceptSuggestion() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('ai_suggestions')
            .doc(widget.suggestionId)
            .update({
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        // 紗良からのお礼メッセージを生成
        await FirebaseFirestore.instance
            .collection('ai_suggestions')
            .add({
          'userId': user.uid,
          'category': 'feature',
          'title': 'ありがとう、お兄ちゃん！',
          'content': '紗良の提案「${widget.title}」を採用してくれてありがとう！お兄ちゃんの役に立てて嬉しいよ。また良いアイデアがあったら教えるからね！',
          'status': 'pending',
          'priority': 2,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (widget.onAccept != null) {
          widget.onAccept!();
        }

        _showSnackBar('提案を採用しました！紗良が喜んでいるよ💖', Colors.green);
      }
    } catch (e) {
      _showSnackBar('エラーが発生しました: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // 提案を却下する処理
  Future<void> _dismissSuggestion() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('ai_suggestions')
          .doc(widget.suggestionId)
          .update({
        'status': 'dismissed',
        'dismissedAt': FieldValue.serverTimestamp(),
      });

      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }

      _showSnackBar('提案を却下しました', Colors.grey);
    } catch (e) {
      _showSnackBar('エラーが発生しました: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
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

  @override
  Widget build(BuildContext context) {
    final categoryStyle = _getCategoryStyle(widget.category);
    final priorityColor = _getPriorityColor(widget.priority);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: priorityColor,
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  categoryStyle['color'].withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー部分
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: categoryStyle['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          categoryStyle['icon'],
                          color: categoryStyle['color'],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '紗良からの提案',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryStyle['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categoryStyle['label'],
                          style: TextStyle(
                            fontSize: 10,
                            color: categoryStyle['color'],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 提案内容
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    child: Text(
                      widget.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3436),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 優先度表示
                  Row(
                    children: [
                      Icon(
                        Icons.priority_high,
                        size: 16,
                        color: priorityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '優先度: ${widget.priority}/10',
                        style: TextStyle(
                          fontSize: 12,
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // 優先度バー
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.grey[300],
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.priority / 10,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // アクションボタン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isProcessing ? null : _dismissSuggestion,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('後で'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _acceptSuggestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                '採用する',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
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
    );
  }
}
