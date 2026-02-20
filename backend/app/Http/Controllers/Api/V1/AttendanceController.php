<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreAttendanceRequest;
use App\Http\Requests\UpdateAttendanceRequest;
use App\Http\Resources\AttendanceResource;
use App\Models\AttendanceRecord;
use App\Models\Employee;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class AttendanceController extends Controller
{
    // ---------------------------------------------------------------
    // Admin/HR: list all attendance records with filters
    // ---------------------------------------------------------------
    public function index(Request $request): JsonResponse
    {
        $query = AttendanceRecord::query()
            ->with(['employee.user', 'employee.department']);

        if ($request->filled('date')) {
            $query->whereDate('date', $request->string('date'));
        } elseif ($request->filled('date_from') || $request->filled('date_to')) {
            $query->when($request->filled('date_from'), fn($q) => $q->whereDate('date', '>=', $request->string('date_from')))
                  ->when($request->filled('date_to'),   fn($q) => $q->whereDate('date', '<=', $request->string('date_to')));
        }

        if ($request->filled('employee_id')) {
            $query->where('employee_id', $request->integer('employee_id'));
        }

        if ($request->filled('department_id')) {
            $query->whereHas('employee', fn($q) => $q->where('department_id', $request->integer('department_id')));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->whereHas('employee.user', fn($q) => $q->where('name', 'ilike', "%{$search}%"));
        }

        $records = $query
            ->orderByDesc('date')
            ->orderByDesc('check_in')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'success' => true,
            'data'    => AttendanceResource::collection($records->items()),
            'meta'    => [
                'total'        => $records->total(),
                'per_page'     => $records->perPage(),
                'current_page' => $records->currentPage(),
                'last_page'    => $records->lastPage(),
            ],
        ]);
    }

    // ---------------------------------------------------------------
    // Admin/HR: manual attendance entry
    // ---------------------------------------------------------------
    public function store(StoreAttendanceRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $record = AttendanceRecord::updateOrCreate(
            [
                'employee_id' => $validated['employee_id'],
                'date'        => $validated['date'],
            ],
            [
                'check_in'  => $validated['check_in'],
                'check_out' => $validated['check_out'] ?? null,
                'status'    => $validated['status'] ?? AttendanceRecord::resolveStatus(
                    Carbon::parse($validated['check_in'])
                ),
                'work_hours' => isset($validated['check_out'])
                    ? $this->calcHours($validated['check_in'], $validated['check_out'])
                    : null,
                'notes' => $validated['notes'] ?? null,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Attendance record saved.',
            'data'    => new AttendanceResource($record->load(['employee.user', 'employee.department'])),
        ], 201);
    }

    // ---------------------------------------------------------------
    // Show single record
    // ---------------------------------------------------------------
    public function show(AttendanceRecord $attendance): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => new AttendanceResource($attendance->load(['employee.user', 'employee.department'])),
        ]);
    }

    // ---------------------------------------------------------------
    // Admin/HR: update/correct attendance record
    // ---------------------------------------------------------------
    public function update(UpdateAttendanceRequest $request, AttendanceRecord $attendance): JsonResponse
    {
        $validated = $request->validated();

        $checkIn  = $validated['check_in']  ?? $attendance->check_in?->format('Y-m-d H:i:s');
        $checkOut = $validated['check_out'] ?? $attendance->check_out?->format('Y-m-d H:i:s');

        $attendance->update([
            'check_in'   => $checkIn,
            'check_out'  => $checkOut,
            'status'     => $validated['status'] ?? (
                $checkIn ? AttendanceRecord::resolveStatus(Carbon::parse($checkIn)) : $attendance->status
            ),
            'work_hours' => ($checkIn && $checkOut) ? $this->calcHours($checkIn, $checkOut) : null,
            'notes'      => $validated['notes'] ?? $attendance->notes,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Attendance updated.',
            'data'    => new AttendanceResource($attendance->load(['employee.user', 'employee.department'])),
        ]);
    }

    // ---------------------------------------------------------------
    // Admin: delete attendance record
    // ---------------------------------------------------------------
    public function destroy(AttendanceRecord $attendance): JsonResponse
    {
        $attendance->delete();

        return response()->json([
            'success' => true,
            'message' => 'Attendance record deleted.',
        ]);
    }

    // ---------------------------------------------------------------
    // Staff: check in
    // ---------------------------------------------------------------
    public function checkIn(Request $request): JsonResponse
    {
        $employee = $this->getAuthEmployee($request);
        if (!$employee) {
            return response()->json(['success' => false, 'message' => 'No employee record found for this user.'], 404);
        }

        $today = Carbon::today();
        $now   = Carbon::now();

        if (AttendanceRecord::where('employee_id', $employee->id)->whereDate('date', $today)->exists()) {
            return response()->json(['success' => false, 'message' => 'Already checked in today.'], 422);
        }

        $record = AttendanceRecord::create([
            'employee_id' => $employee->id,
            'date'        => $today->toDateString(),
            'check_in'    => $now,
            'status'      => AttendanceRecord::resolveStatus($now),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Check-in recorded at ' . $now->format('H:i'),
            'data'    => new AttendanceResource($record->load(['employee.user', 'employee.department'])),
        ], 201);
    }

    // ---------------------------------------------------------------
    // Staff: check out
    // ---------------------------------------------------------------
    public function checkOut(Request $request): JsonResponse
    {
        $employee = $this->getAuthEmployee($request);
        if (!$employee) {
            return response()->json(['success' => false, 'message' => 'No employee record found for this user.'], 404);
        }

        $record = AttendanceRecord::where('employee_id', $employee->id)
            ->whereDate('date', Carbon::today())
            ->first();

        if (!$record) {
            return response()->json(['success' => false, 'message' => 'No check-in found for today.'], 422);
        }

        if ($record->check_out) {
            return response()->json(['success' => false, 'message' => 'Already checked out today.'], 422);
        }

        $now = Carbon::now();
        $record->update([
            'check_out'  => $now,
            'work_hours' => $record->calculateWorkHours(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Check-out recorded at ' . $now->format('H:i'),
            'data'    => new AttendanceResource($record->load(['employee.user', 'employee.department'])),
        ]);
    }

    // ---------------------------------------------------------------
    // Staff: get today's attendance record
    // ---------------------------------------------------------------
    public function today(Request $request): JsonResponse
    {
        $employee = $this->getAuthEmployee($request);
        if (!$employee) {
            return response()->json(['success' => false, 'message' => 'No employee record found.'], 404);
        }

        $record = AttendanceRecord::where('employee_id', $employee->id)
            ->whereDate('date', Carbon::today())
            ->with(['employee.user', 'employee.department'])
            ->first();

        return response()->json([
            'success' => true,
            'data'    => $record ? new AttendanceResource($record) : null,
        ]);
    }

    // ---------------------------------------------------------------
    // Staff: own attendance history
    // ---------------------------------------------------------------
    public function myAttendance(Request $request): JsonResponse
    {
        $employee = $this->getAuthEmployee($request);
        if (!$employee) {
            return response()->json(['success' => false, 'message' => 'No employee record found.'], 404);
        }

        $query = AttendanceRecord::where('employee_id', $employee->id)
            ->with(['employee.user', 'employee.department']);

        if ($request->filled('date_from')) {
            $query->whereDate('date', '>=', $request->string('date_from'));
        }
        if ($request->filled('date_to')) {
            $query->whereDate('date', '<=', $request->string('date_to'));
        }
        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        $records = $query
            ->orderByDesc('date')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'success' => true,
            'data'    => AttendanceResource::collection($records->items()),
            'meta'    => [
                'total'        => $records->total(),
                'per_page'     => $records->perPage(),
                'current_page' => $records->currentPage(),
                'last_page'    => $records->lastPage(),
            ],
        ]);
    }

    // ---------------------------------------------------------------
    // Admin/HR: summary stats for a given date (default today)
    // ---------------------------------------------------------------
    public function summary(Request $request): JsonResponse
    {
        $date = $request->filled('date')
            ? Carbon::parse($request->string('date'))->toDateString()
            : Carbon::today()->toDateString();

        $totalEmployees = Employee::where('status', 'active')->count();

        $records = AttendanceRecord::whereDate('date', $date)->get();

        $present  = $records->whereIn('status', ['present', 'late', 'half_day'])->count();
        $late     = $records->where('status', 'late')->count();
        $onLeave  = $records->where('status', 'on_leave')->count();
        $absent   = max(0, $totalEmployees - $present - $onLeave);

        return response()->json([
            'success' => true,
            'data'    => [
                'date'            => $date,
                'total_employees' => $totalEmployees,
                'present'         => $present,
                'late'            => $late,
                'absent'          => $absent,
                'on_leave'        => $onLeave,
            ],
        ]);
    }

    // ---------------------------------------------------------------
    private function getAuthEmployee(Request $request): ?Employee
    {
        return Employee::where('user_id', $request->user()->id)->first();
    }

    private function calcHours(string $checkIn, string $checkOut): float
    {
        return round(Carbon::parse($checkOut)->diffInMinutes(Carbon::parse($checkIn)) / 60, 2);
    }
}
