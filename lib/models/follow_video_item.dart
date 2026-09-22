import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart';

/// 从动态数据转换而来的视频卡片模型，用于推荐页顶部「关注更新」区域
class FollowVideoItemModel extends BaseRcmdVideoItemModel {
  /// UP主头像（BaseOwner 无 face 字段，单独存储）
  String? ownerFace;

  FollowVideoItemModel.fromDynamic(DynamicItemModel item) {
    final archive = item.modules.moduleDynamic?.major?.archive;
    final author = item.modules.moduleAuthor;

    aid = archive?.aid;
    bvid = archive?.bvid;
    cid = null;
    cover = archive?.cover;
    title = archive?.title ?? '';
    duration = _parseDuration(archive?.durationText);
    goto = 'av';
    uri = archive?.jumpUrl;
    rcmdReason = null;
    isFollowed = true;

    ownerFace = author?.face;

    owner = _FollowOwner(
      mid: author?.mid,
      name: author?.name,
    );

    stat = _FollowStat(
      view: int.tryParse(archive?.stat?.play ?? ''),
      like: null,
      danmu: int.tryParse(archive?.stat?.danmu ?? ''),
    );
  }

  static int _parseDuration(String? text) {
    if (text == null || text.isEmpty) return 0;
    final parts = text.split(':').map(int.parse).toList();
    if (parts.length == 3) {
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.length == 2) {
      return parts[0] * 60 + parts[1];
    }
    return 0;
  }
}

class _FollowOwner implements BaseOwner {
  @override
  int? mid;
  @override
  String? name;

  _FollowOwner({this.mid, this.name});
}

class _FollowStat implements BaseStat {
  @override
  int? view;
  @override
  int? like;
  @override
  int? danmu;

  _FollowStat({this.view, this.like, this.danmu});
}
