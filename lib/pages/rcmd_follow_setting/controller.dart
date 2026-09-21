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

class RcmdFollowSettingController extends GetxController {
  final account = Accounts.main;
  RxList<int> selectedMids = <int>[].obs;
  RxList<FollowItemModel> followList = <FollowItemModel>[].obs;
  RxBool isLoading = false.obs;
  int page = 1;
  bool hasMore = true;

  @override
  void onInit() {
    super.onInit();
    selectedMids.assignAll(Pref.rcmdFollowMids);
    loadFollowList();
  }

  Future<void> loadFollowList() async {
    if (!account.isLogin) {
      SmartDialog.showToast('请先登录');
      return;
    }

    isLoading.value = true;
    final res = await FollowHttp.followings(
      vmid: account.mid,
      pn: page,
      ps: 50,
    );

    if (res case Success(:final response)) {
      if (response.list != null && response.list!.isNotEmpty) {
        if (page == 1) {
          followList.assignAll(response.list!);
        } else {
          followList.addAll(response.list!);
        }
        hasMore = response.list!.length >= 50;
      } else {
        hasMore = false;
      }
    } else {
      SmartDialog.showToast('加载失败');
    }

    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore) return;
    page++;
    await loadFollowList();
  }

  void toggleMid(int mid) {
    if (selectedMids.contains(mid)) {
      selectedMids.remove(mid);
    } else {
      selectedMids.add(mid);
    }
  }

  Future<void> saveSettings() async {
    await GStorage.setting.put(
      SettingBoxKey.rcmdFollowMids,
      selectedMids.toList(),
    );
    SmartDialog.showToast('保存成功');

    try {
      final rcmdController = Get.find<RcmdController>();
      rcmdController.updateFollowMids(selectedMids.toList());
    } catch (_) {}

    Get.back();
  }
}
