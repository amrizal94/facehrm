import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/employee_remote_datasource.dart';
import '../models/employee_model.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>(
  (ref) => EmployeeRepository(ref.watch(employeeRemoteDataSourceProvider)),
);

class EmployeeRepository {
  final EmployeeRemoteDataSource _ds;
  EmployeeRepository(this._ds);

  Future<({List<EmployeeModel> items, int total, int lastPage})> getEmployees({
    int page = 1,
    String? search,
    String? departmentId,
  }) => _ds.getEmployees(page: page, search: search, departmentId: departmentId);

  Future<EmployeeModel> toggleActive(int employeeId) =>
      _ds.toggleActive(employeeId);
}
