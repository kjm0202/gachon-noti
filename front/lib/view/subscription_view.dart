import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:gachon_noti_front/utils/alternative_text_style.dart';
import '../controller/subscription_controller.dart';

class SubscriptionView extends StatefulWidget {
  final Client client;
  const SubscriptionView({super.key, required this.client});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late BoardSelectionController _controller;
  bool _loading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = BoardSelectionController(client: widget.client);
    _initData();
  }

  Future<void> _initData() async {
    await _controller.initUserAndLoadSubscription(
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('사용자 정보를 불러오는데 실패했습니다.'),
              action: SnackBarAction(
                label: '다시 시도',
                onPressed: () => _initData(),
              ),
            ),
          );
        }
      },
      onFinally: () {
        if (mounted) {
          setState(() {
            _loading = _controller.loading;
          });
        }
      },
    );
  }

  void _showErrorSnackBar(String message, Function retryAction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: '다시 시도', onPressed: () => retryAction()),
      ),
    );
  }

  // 체크박스 변경 - 임시 상태만 변경
  void _handleToggleBoardTemp(String boardId) {
    setState(() {
      _controller.toggleBoardTemp(boardId);
    });
  }

  // 모든 변경사항 저장
  Future<void> _saveChanges() async {
    if (!_controller.hasChanges) return;

    setState(() {
      _isSaving = true;
    });

    final success = await _controller.saveAllSubscriptions(
      onUpdate: (newList) {
        // 저장 성공했을 때 UI 업데이트는 이미 setState에서 처리됨
      },
      onError: (err) {
        if (mounted) {
          _showErrorSnackBar(
            '구독 설정 저장에 실패했습니다. 다시 시도해주세요.',
            () => _saveChanges(),
          );
        }
      },
    );

    if (mounted && success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구독 설정이 저장되었습니다.')));
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 변경사항 취소
  void _cancelChanges() {
    setState(() {
      _controller.cancelChanges();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('변경사항이 취소되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        ListView(
          children: _controller.allBoards.map((boardId) {
            final subscribed = _controller.isBoardSubscribed(boardId);
            return CheckboxListTile(
              title: Text(_controller.getBoardName(boardId)),
              subtitle: Text(_controller.getBoardDescription(boardId)),
              value: subscribed,
              onChanged: _isSaving
                  ? null // 저장 중에는 체크박스 비활성화
                  : (val) {
                      if (val != null) {
                        _handleToggleBoardTemp(boardId);
                      }
                    },
            );
          }).toList(),
        ),

        // 변경사항이 있을 때만 저장/취소 버튼 표시
        if (_controller.hasChanges)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                elevation: 8,
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.cancel, color: Colors.white),
                        label: Text(
                          '취소',
                          style: AltTextStyle.bodyLarge
                              .copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        onPressed: _isSaving ? null : _cancelChanges,
                      ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.save, color: Colors.white),
                        label: Text(
                          '저장',
                          style: AltTextStyle.bodyLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        onPressed: _isSaving ? null : _saveChanges,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
