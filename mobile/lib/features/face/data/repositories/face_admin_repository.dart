import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/face_remote_datasource.dart';
import '../models/face_enrollment_model.dart';

final faceAdminRepositoryProvider = Provider<FaceAdminRepository>(
  (ref) => FaceAdminRepository(ref.watch(faceRemoteDatasourceProvider)),
);

class FaceAdminRepository {
  final FaceRemoteDatasource _ds;
  FaceAdminRepository(this._ds);

  Future<({List<FaceEnrollmentModel> items, int total, int lastPage})>
      getFaceEnrollments({int page = 1, String? search, String? enrolled}) =>
          _ds.getFaceEnrollments(page: page, search: search, enrolled: enrolled);

  Future<void> deleteFaceData(int faceDataId) => _ds.deleteFaceData(faceDataId);
}
