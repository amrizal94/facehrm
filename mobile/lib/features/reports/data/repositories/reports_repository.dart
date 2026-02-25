import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/reports_remote_datasource.dart';
import '../models/reports_overview_model.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(reportsRemoteDataSourceProvider)),
);

class ReportsRepository {
  final ReportsRemoteDataSource _ds;
  ReportsRepository(this._ds);

  Future<ReportsOverviewModel> getOverview() => _ds.getOverview();
}
