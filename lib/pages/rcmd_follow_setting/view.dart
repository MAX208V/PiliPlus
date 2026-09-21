import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/pages/rcmd_follow_setting/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RcmdFollowSettingPage extends StatelessWidget {
  const RcmdFollowSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RcmdFollowSettingController());
    final colorScheme = ColorScheme.of(context);

    return SimpleScaffold(
      appBar: AppBar(
        title: const Text('关注更新设置'),
        actions: [
          Obx(() {
            final count = controller.selectedMids.length;
            return TextButton(
              onPressed: controller.saveSettings,
              child: Text('保存($count)'),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.followList.isEmpty && controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.followList.isEmpty) {
          return const Center(child: Text('暂无关注用户'));
        }

        return ListView.builder(
          itemCount: controller.followList.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.followList.length) {
              if (controller.hasMore) {
                controller.loadMore();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return const SizedBox.shrink();
            }

            final item = controller.followList[index];
            final isSelected = controller.selectedMids.contains(item.mid);

            return ListTile(
              leading: NetworkImgLayer(
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
                  color: colorScheme.outline,
                ),
              ),
              trailing: Checkbox(
                value: isSelected,
                onChanged: (_) => controller.toggleMid(item.mid),
              ),
              onTap: () => controller.toggleMid(item.mid),
            );
          },
        );
      }),
    );
  }
}
