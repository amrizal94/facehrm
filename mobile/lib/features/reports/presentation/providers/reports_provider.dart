import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/reports_overview_model.dart';
import '../../data/repositories/reports_repository.dart';

final reportsOverviewProvider = FutureProvider<ReportsOverviewModel>(
  (ref) => ref.watch(reportsRepositoryProvider).getOverview(),
);
