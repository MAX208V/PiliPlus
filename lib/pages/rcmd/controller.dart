import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/follow_video_item.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';

class RcmdController extends CommonListController {
  late bool enableSaveLastData = Pref.enableSaveLastData;
  final bool appRcmd = Pref.appRcmd;

  int? lastRefreshAt;
  late bool savedRcmdTip = Pref.savedRcmdTip;

  // 关注更新
  RxList<FollowVideoItemModel> followVideos = <FollowVideoItemModel>[].obs;
  RxBool followLoading = false.obs;
  late final RxList<int> followMids = RxList<int>(Pref.rcmdFollowMids);

  @override
  bool get isEnd => false;

  @override
  void onInit() {
    super.onInit();
    page = 0;
    queryData();
    loadFollowVideos();
  }

  @override
  Future<LoadingState> customGetData() {
    return appRcmd
        ? VideoHttp.rcmdVideoListApp(freshIdx: page)
        : VideoHttp.rcmdVideoList(freshIdx: page, ps: 20);
  }

  @override
  bool handleError(String? errMsg) {
    return enableSaveLastData;
  }

  @override
  void handleListResponse(List dataList) {
    if (enableSaveLastData && page == 0) {
      if (loadingState.value case Success(:final response)) {
        if (response != null && response.isNotEmpty) {
          if (savedRcmdTip) {
            lastRefreshAt = dataList.length;
          }
          if (response.length > 200) {
            dataList.addAll(response.take(50));
          } else {
            dataList.addAll(response);
          }
        }
      }
    }
  }

  @override
  Future<void> onRefresh() async {
    page = 0;
    isEnd = false;
    loadFollowVideos();
    return queryData();
  }

  /// 加载关注UP主的最新视频
  Future<void> loadFollowVideos() async {
    final mids = followMids.toList();
    if (mids.isEmpty) {
      followVideos.clear();
      return;
    }

    followLoading.value = true;
    final List<FollowVideoItemModel> results = [];

    // 并行请求所有UP主的最新视频
    final futures = mids.map((mid) async {
      try {
        final res = await DynamicsHttp.followDynamic(
          hostMid: mid,
          type: DynamicsTabType.up,
        );
        if (res case Success(:final response)) {
          if (response.items != null && response.items!.isNotEmpty) {
            // 只取第一个视频类型的动态
            for (final item in response.items!) {
              if (item.modules.moduleDynamic?.major?.archive != null) {
                results.add(FollowVideoItemModel.fromDynamic(item));
                break;
              }
            }
          }
        }
      } catch (_) {}
    });

    await Future.wait(futures);
    followVideos.assignAll(results);
    followLoading.value = false;
  }

  /// 更新关注列表并刷新
  Future<void> updateFollowMids(List<int> mids) async {
    await GStorage.setting.put(SettingBoxKey.rcmdFollowMids, mids);
    followMids.assignAll(mids);
    loadFollowVideos();
  }
}
