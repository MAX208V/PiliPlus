import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/http/follow.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/pages/rcmd/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showFollowSelectDialog(BuildContext context) async {
  final account = Accounts.main;
  if (!account.isLogin) {
    SmartDialog.showToast('请先登录');
    return;
  }

  final result = await showDialog<List<int>>(
    context: context,
    builder: (context) => _FollowSelectDialog(accountMid: account.mid),
  );

  if (result != null) {
    await GStorage.setting.put(SettingBoxKey.rcmdFollowMids, result);
    SmartDialog.showToast('保存成功');
    try {
      final rcmdController = Get.find<RcmdController>();
      rcmdController.updateFollowMids(result);
    } catch (_) {}
  }
}

class _FollowSelectDialog extends StatefulWidget {
  final int accountMid;
  const _FollowSelectDialog({required this.accountMid});

  @override
  State<_FollowSelectDialog> createState() => _FollowSelectDialogState();
}

class _FollowSelectDialogState extends State<_FollowSelectDialog> {
  List<FollowItemModel> followList = [];
  late Set<int> selectedMids;
  bool isLoading = true;
  bool hasMore = true;
  int page = 1;
  String? error;

  @override
  void initState() {
    super.initState();
    selectedMids = Set<int>.from(Pref.rcmdFollowMids);
    _loadFollowList();
  }

  Future<void> _loadFollowList() async {
    setState(() => isLoading = true);

    final res = await FollowHttp.followings(
      vmid: widget.accountMid,
      pn: page,
      ps: 50,
    );

    if (res case Success(:final response)) {
      if (response.list != null && response.list!.isNotEmpty) {
        setState(() {
          followList = [...followList, ...response.list!];
          hasMore = response.list!.length >= 50;
          isLoading = false;
        });
      } else {
        setState(() {
          hasMore = false;
          isLoading = false;
          if (followList.isEmpty) error = '暂无关注用户';
        });
      }
    } else {
      setState(() {
        isLoading = false;
        error = '加载失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleMedium = TextTheme.of(context).titleMedium!;

    return AlertDialog(
      clipBehavior: Clip.hardEdge,
      title: const Text('选择关注UP主'),
      constraints: const BoxConstraints.tightFor(width: 320, height: 480),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: Material(
        type: .transparency,
        child: _buildContent(titleMedium),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(selectedMids.toList()),
          child: Text('保存(${selectedMids.length})'),
        ),
      ],
    );
  }

  Widget _buildContent(TextStyle titleMedium) {
    if (error != null && followList.isEmpty) {
      return Center(
        heightFactor: 3,
        child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      );
    }

    if (followList.isEmpty && isLoading) {
      return m3eLoading;
    }

    final itemCount = followList.length + (hasMore ? 1 : 0);

    return SizedBox(
      height: 400,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == followList.length) {
            _loadFollowList();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = followList[index];
          final isSelected = selectedMids.contains(item.mid);

          return CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (isSelected) {
                  selectedMids.remove(item.mid);
                } else {
                  selectedMids.add(item.mid);
                }
              });
            },
            secondary: NetworkImgLayer(
              type: .avatar,
              src: item.face,
              width: 36,
              height: 36,
            ),
            title: Text(item.uname ?? '', style: titleMedium),
            dense: true,
          );
        },
      ),
    );
  }
}
