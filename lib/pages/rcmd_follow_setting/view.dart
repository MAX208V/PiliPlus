import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/pages/rcmd_follow_setting/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RcmdFollowSettingPage extends StatefulWidget {
  const RcmdFollowSettingPage({super.key});

  @override
  State<RcmdFollowSettingPage> createState() => _RcmdFollowSettingPageState();
}

class _RcmdFollowSettingPageState extends State<RcmdFollowSettingPage> {
  late final RcmdFollowSettingController controller;
  late EdgeInsets padding;

  @override
  void initState() {
    super.initState();
    controller = Get.put(RcmdFollowSettingController());
    controller.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    padding = MediaQuery.viewPaddingOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(
        title: const Text('推荐页关注更新'),
        actions: [
          TextButton(
            onPressed: controller.saveSettings,
            child: const Text('保存'),
          ),
          SizedBox(width: padding.right > 0 ? padding.right : 12),
        ],
      ),
      body: GetBuilder<RcmdFollowSettingController>(
        init: controller,
        builder: (controller) {
          if (controller.error != null && controller.followList.isEmpty) {
            return Center(child: Text(controller.error!));
          }

          if (controller.followList.isEmpty && controller.isLoading) {
            return m3eLoading;
          }

          return ListView.builder(
            padding: EdgeInsets.only(bottom: padding.bottom + 100),
            itemCount: controller.followList.length + (controller.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.followList.length) {
                controller.loadFollowList();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = controller.followList[index];
              final isSelected = controller.selectedMids.contains(item.mid);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => controller.toggleMid(item.mid),
                secondary: NetworkImgLayer(
                  type: .avatar,
                  src: item.face,
                  width: 40,
                  height: 40,
                ),
                title: Text(item.uname ?? ''),
                subtitle: Text(
                  'UID: ${item.mid}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
