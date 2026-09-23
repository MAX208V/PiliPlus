import 'package:PiliPlus/http/follow.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/pages/rcmd/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class RcmdFollowSettingController extends GetxController {
  final account = Accounts.main;
  List<int> selectedMids = [];
  List<FollowItemModel> followList = [];
  bool isLoading = false;
  bool hasMore = true;
  int page = 1;
  String? error;

  void init() {
    selectedMids = List<int>.from(Pref.rcmdFollowMids);
    loadFollowList();
  }

  Future<void> loadFollowList() async {
    if (!account.isLogin) {
      error = '请先登录';
      update();
      return;
    }

    isLoading = true;
    error = null;
    update();

    final res = await FollowHttp.followings(
      vmid: account.mid,
      pn: page,
      ps: 50,
    );

    if (res case Success(:final response)) {
      if (response.list != null && response.list!.isNotEmpty) {
        if (page == 1) {
          followList = response.list!;
        } else {
          followList = [...followList, ...response.list!];
        }
        hasMore = response.list!.length >= 50;
      } else {
        hasMore = false;
        if (followList.isEmpty) {
          error = '暂无关注用户';
        }
      }
    } else {
      error = '加载失败';
    }

    isLoading = false;
    update();
  }

  void toggleMid(int mid) {
    if (selectedMids.contains(mid)) {
      selectedMids.remove(mid);
    } else {
      selectedMids.add(mid);
    }
    update();
  }

  Future<void> saveSettings() async {
    await GStorage.setting.put(SettingBoxKey.rcmdFollowMids, selectedMids);
    SmartDialog.showToast('保存成功');

    try {
      final rcmdController = Get.find<RcmdController>();
      rcmdController.updateFollowMids(selectedMids);
    } catch (_) {}

    Get.back();
  }
}
