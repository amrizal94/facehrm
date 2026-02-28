<?php

use App\Http\Controllers\Api\V1\Auth\AuthController;
use App\Http\Controllers\Api\V1\Auth\ProfileController;
use App\Http\Controllers\Api\V1\AnnouncementController;
use App\Http\Controllers\Api\V1\ExpenseController;
use App\Http\Controllers\Api\V1\AuditLogController;
use App\Http\Controllers\Api\V1\AttendanceController;
use App\Http\Controllers\Api\V1\DepartmentController;
use App\Http\Controllers\Api\V1\EmployeeController;
use App\Http\Controllers\Api\V1\LabelController;
use App\Http\Controllers\Api\V1\LeaveRequestController;
use App\Http\Controllers\Api\V1\LeaveTypeController;
use App\Http\Controllers\Api\V1\FaceDataController;
use App\Http\Controllers\Api\V1\HolidayController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\OvertimeController;
use App\Http\Controllers\Api\V1\PayrollController;
use App\Http\Controllers\Api\V1\ProjectController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\SettingController;
use App\Http\Controllers\Api\V1\ShiftController;
use App\Http\Controllers\Api\V1\TaskController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {

    // Public
    Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:login');

    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::prefix('auth')->group(function () {
            Route::post('/logout',    [AuthController::class, 'logout']);
            Route::get('/me',         [AuthController::class, 'me']);
            Route::put('/profile',    [ProfileController::class, 'update']);
            Route::put('/fcm-token',  [ProfileController::class, 'updateFcmToken']);
        });

        // Attendance — staff
        Route::prefix('attendance')->group(function () {
            Route::post('/check-in',  [AttendanceController::class, 'checkIn']);
            Route::post('/check-out', [AttendanceController::class, 'checkOut']);
            Route::get('/today',      [AttendanceController::class, 'today']);
            Route::get('/my',         [AttendanceController::class, 'myAttendance']);
            Route::get('/policy',     [AttendanceController::class, 'policy']);
        });

        // Leave — staff
        Route::get('leave-types',        [LeaveTypeController::class, 'index']);
        Route::get('leave/my',           [LeaveRequestController::class, 'myLeaves']);
        Route::get('leave/quota',        [LeaveRequestController::class, 'quota']);
        Route::post('leave',             [LeaveRequestController::class, 'store']);
        Route::delete('leave/{leaveRequest}', [LeaveRequestController::class, 'destroy']);

        // Notifications — all authenticated
        Route::get('notifications', [NotificationController::class, 'index']);
        Route::post('notifications/{id}/read', [NotificationController::class, 'markRead']);
        Route::post('notifications/read-all', [NotificationController::class, 'markAllRead']);

        // Holidays — all authenticated (read-only)
        Route::get('holidays', [HolidayController::class, 'index']);
        Route::get('holidays/dates', [HolidayController::class, 'dates']);

        // Overtime — staff
        Route::post('overtime', [OvertimeController::class, 'store']);
        Route::get('overtime/my', [OvertimeController::class, 'myOvertime']);
        Route::delete('overtime/{overtime}', [OvertimeController::class, 'destroy']);

        // Payroll — staff
        Route::get('payroll/my', [PayrollController::class, 'myPayslips']);

        // Expenses — staff
        Route::get('expenses/my', [ExpenseController::class, 'myExpenses']);
        Route::post('expenses', [ExpenseController::class, 'store']);
        Route::delete('expenses/{expense}', [ExpenseController::class, 'destroy']);

        // Tasks & Projects — all authenticated (read + staff update)
        Route::get('labels',              [LabelController::class, 'index']);
        Route::get('projects',            [ProjectController::class, 'index']);
        Route::get('projects/{project}',  [ProjectController::class, 'show']);
        Route::get('tasks',               [TaskController::class, 'index']);
        Route::get('tasks/{task}',        [TaskController::class, 'show']);
        Route::put('tasks/{task}',        [TaskController::class, 'update']);
        Route::patch('tasks/{task}/checklist/{item}/toggle', [TaskController::class, 'toggleChecklistItem']);

        // Face — all authenticated (check-in/out via face), rate-limited
        Route::middleware('throttle:face')->group(function () {
            Route::post('face/identify',         [FaceDataController::class, 'identify']);
            Route::post('face/attendance',       [FaceDataController::class, 'faceAttendance']);
            Route::post('face/attendance-image', [FaceDataController::class, 'faceAttendanceImage']);
            Route::post('face/self-enroll-image',[FaceDataController::class, 'selfEnrollImage']);
            Route::post('face/self-enroll',      [FaceDataController::class, 'selfEnroll']);
        });
        // Face — enrollment status for current user
        Route::get('face/me', [FaceDataController::class, 'myStatus']);

        // Announcements — all authenticated (read), admin|hr (write)
        Route::get('announcements', [AnnouncementController::class, 'index']);
        Route::get('announcements/{announcement}', [AnnouncementController::class, 'show']);

        // Shifts — any authenticated user can view their own shift
        Route::get('my-shift', [ShiftController::class, 'myShift']);

        // Admin & HR
        Route::middleware('role:admin|hr')->group(function () {
            // Labels
            Route::post('labels',           [LabelController::class, 'store']);
            Route::put('labels/{label}',    [LabelController::class, 'update']);
            Route::delete('labels/{label}', [LabelController::class, 'destroy']);

            // Projects
            Route::post('projects',             [ProjectController::class, 'store']);
            Route::put('projects/{project}',    [ProjectController::class, 'update']);
            Route::delete('projects/{project}', [ProjectController::class, 'destroy']);

            // Tasks
            Route::post('tasks',                                        [TaskController::class, 'store']);
            Route::delete('tasks/{task}',                               [TaskController::class, 'destroy']);
            Route::post('tasks/{task}/checklist',                       [TaskController::class, 'addChecklistItem']);
            Route::delete('tasks/{task}/checklist/{item}',              [TaskController::class, 'deleteChecklistItem']);

            Route::apiResource('departments', DepartmentController::class);
            Route::apiResource('employees',   EmployeeController::class);
            Route::apiResource('shifts',      ShiftController::class);
            Route::patch('employees/{employee}/toggle-active', [EmployeeController::class, 'toggleActive']);

            // Attendance management
            Route::get('attendance/summary',  [AttendanceController::class, 'summary']);
            Route::apiResource('attendance',  AttendanceController::class);

            // Leave management
            Route::get('leave',                         [LeaveRequestController::class, 'index']);
            Route::get('leave/{leaveRequest}',          [LeaveRequestController::class, 'show']);
            Route::post('leave/{leaveRequest}/approve', [LeaveRequestController::class, 'approve']);
            Route::post('leave/{leaveRequest}/reject',  [LeaveRequestController::class, 'reject']);
            Route::post('leave-types',                  [LeaveTypeController::class, 'store']);
            Route::put('leave-types/{leaveType}',       [LeaveTypeController::class, 'update']);
            Route::delete('leave-types/{leaveType}',    [LeaveTypeController::class, 'destroy']);

            // Holiday management (admin/hr)
            Route::post('holidays', [HolidayController::class, 'store']);
            Route::put('holidays/{holiday}', [HolidayController::class, 'update']);
            Route::delete('holidays/{holiday}', [HolidayController::class, 'destroy']);

            // Overtime management
            Route::get('overtime/summary', [OvertimeController::class, 'summary']);
            Route::get('overtime', [OvertimeController::class, 'index']);
            Route::get('overtime/{overtime}', [OvertimeController::class, 'show']);
            Route::put('overtime/{overtime}', [OvertimeController::class, 'update']);
            Route::post('overtime/{overtime}/approve', [OvertimeController::class, 'approve']);
            Route::post('overtime/{overtime}/reject', [OvertimeController::class, 'reject']);

            // Settings
            Route::get('settings',  [SettingController::class, 'index']);
            Route::put('settings',  [SettingController::class, 'update']);

            // Reports (admin + hr)
            Route::prefix('reports')->group(function () {
                Route::get('overview',          [ReportController::class, 'overview']);
                Route::get('attendance',        [ReportController::class, 'attendance']);
                Route::get('leave',             [ReportController::class, 'leave']);
                Route::get('payroll',           [ReportController::class, 'payroll']);
                Route::get('overtime',          [ReportController::class, 'overtime']);
                Route::get('daily-trend',       [ReportController::class, 'dailyTrend']);
                Route::get('department-today',  [ReportController::class, 'departmentToday']);
            });

            // Face enrollment management
            Route::get('face',                    [FaceDataController::class, 'index']);
            Route::post('face/enroll',            [FaceDataController::class, 'enroll']);
            Route::post('face/enroll-image',      [FaceDataController::class, 'enrollImage']);
            Route::delete('face/{faceData}',      [FaceDataController::class, 'destroy']);

            // Announcements management
            Route::post('announcements', [AnnouncementController::class, 'store']);
            Route::put('announcements/{announcement}', [AnnouncementController::class, 'update']);
            Route::delete('announcements/{announcement}', [AnnouncementController::class, 'destroy']);

            // Audit logs
            Route::get('audit-logs', [AuditLogController::class, 'index']);

            // Expenses — admin|hr
            Route::get('expenses', [ExpenseController::class, 'index']);
            Route::get('expenses/{expense}', [ExpenseController::class, 'show']);
            Route::post('expenses/{expense}/approve', [ExpenseController::class, 'approve']);
            Route::post('expenses/{expense}/reject', [ExpenseController::class, 'reject']);

            // Payroll management
            Route::get('payroll/summary',               [PayrollController::class, 'summary']);
            Route::post('payroll/generate',             [PayrollController::class, 'generate']);
            Route::post('payroll/finalize-all',         [PayrollController::class, 'finalizeAll']);
            Route::post('payroll/mark-all-paid',        [PayrollController::class, 'markAllPaid']);
            Route::get('payroll',                       [PayrollController::class, 'index']);
            Route::get('payroll/{payroll}',             [PayrollController::class, 'show']);
            Route::put('payroll/{payroll}',             [PayrollController::class, 'update']);
            Route::delete('payroll/{payroll}',          [PayrollController::class, 'destroy']);
            Route::post('payroll/{payroll}/finalize',   [PayrollController::class, 'finalize']);
            Route::post('payroll/{payroll}/mark-paid',  [PayrollController::class, 'markPaid']);
        });
    });
});
