import '../models/memo.dart';
import 'collaboration_metadata_store.dart';

/// オフライン版では共同編集機能を提供しないため、
/// 既存コードとの互換性を保つダミー実装を用意する。
class CollaborationSyncCoordinator {
  CollaborationSyncCoordinator._();

  static final CollaborationSyncCoordinator instance =
      CollaborationSyncCoordinator._();

  final CollaborationMetadataStore _store = CollaborationMetadataStore.instance;

  Future<CollaborationMetadata?> getMetadata(int mapId) {
    return _store.getForMap(mapId);
  }

  Future<bool> isCollaborative(int mapId) async => false;

  Future<void> registerCollaborativeMap({
    required int mapId,
    required String ownerUid,
    required bool isOwner,
    String? ownerEmail,
  }) async {
    await _store.deleteForMap(mapId);
  }

  Future<void> unregisterCollaborativeMap(int mapId) async {
    await _store.deleteForMap(mapId);
  }

  Future<void> onLocalMemoCreated(Memo memo) async {}

  Future<void> onLocalMemoUpdated(Memo memo) async {}

  Future<void> onLocalMemoDeleted(Memo memo) async {}
}
