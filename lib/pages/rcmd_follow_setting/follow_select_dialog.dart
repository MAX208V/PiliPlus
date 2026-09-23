import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/pendant_avatar.dart';
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

  final result = await showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) =>
          _FollowSelectSheet(accountMid: account.mid),
    ),
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

class _FollowSelectSheet extends StatefulWidget {
  final int accountMid;
  const _FollowSelectSheet({required this.accountMid});

  @override
  State<_FollowSelectSheet> createState() => _FollowSelectSheetState();
}

class _FollowSelectSheetState extends State<_FollowSelectSheet> {
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

  void _toggle(int mid) {
    setState(() {
      if (selectedMids.contains(mid)) {
        selectedMids.remove(mid);
      } else {
        selectedMids.add(mid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Column(
      children: [
        // 顶部栏
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '选择关注UP主',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(selectedMids.toList()),
                child: Text('保存(${selectedMids.length})'),
              ),
            ],
          ),
        ),
        Divider(height: 1),
        // 列表
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (error != null && followList.isEmpty) {
      return Center(
        child: Text(error!,
            style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      );
    }

    if (followList.isEmpty && isLoading) {
      return const Center(child: m3eLoading);
    }

    final itemCount = followList.length + (hasMore ? 1 : 0);

    return ListView.builder(
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

        return _FollowSelectItem(
          item: item,
          isSelected: isSelected,
          onTap: () => _toggle(item.mid),
        );
      },
    );
  }
}

/// 复用 FollowItem 布局，增加选中状态
class _FollowSelectItem extends StatelessWidget {
  final FollowItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _FollowSelectItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              PendantAvatar(
                size: 45,
                badgeSize: 14,
                item.face,
                officialType: item.officialVerify?.type,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  spacing: 3,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.uname!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (item.sign != null)
                      Text(
                        item.sign!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
