import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/asset_model.dart';
import '../../data/repositories/asset_repository.dart';

// ── Staff: My Assigned Assets ─────────────────────────────────────────────────

class MyAssetsNotifier extends AsyncNotifier<List<AssetAssignmentModel>> {
  @override
  Future<List<AssetAssignmentModel>> build() =>
      ref.watch(assetRepositoryProvider).getMyAssets();
}

final myAssetsProvider =
    AsyncNotifierProvider<MyAssetsNotifier, List<AssetAssignmentModel>>(
        () => MyAssetsNotifier());
