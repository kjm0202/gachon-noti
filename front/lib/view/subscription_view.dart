import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
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

  void _handleToggleBoard(String boardId) {
    _controller.toggleBoard(
      boardId,
      onUpdate: (newList) {
        if (mounted) {
          setState(() {
            // 컨트롤러가 상태를 업데이트하므로 setState만 호출
          });
        }
      },
      onError: (err) {
        if (mounted) {
          _showErrorSnackBar(
            '구독 설정 업데이트에 실패했습니다. 다시 시도해주세요.',
            () => _handleToggleBoard(boardId),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView(
      children:
          _controller.allBoards.map((boardId) {
            final subscribed = _controller.isBoardSubscribed(boardId);
            return CheckboxListTile(
              title: Text(_controller.getBoardName(boardId)),
              subtitle: Text(_controller.getBoardDescription(boardId)),
              value: subscribed,
              onChanged: (val) {
                if (val != null) {
                  _handleToggleBoard(boardId);
                }
              },
            );
          }).toList(),
    );
  }
}
