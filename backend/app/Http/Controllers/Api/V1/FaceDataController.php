<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\AttendanceResource;
use App\Http\Resources\FaceDataResource;
use App\Models\AttendanceRecord;
use App\Models\Employee;
use App\Models\FaceData;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;

class FaceDataController extends Controller
{
    // Face match threshold (Euclidean distance)
    private const THRESHOLD = 0.5;

    // ---------------------------------------------------------------
    // Admin/HR: list enrollment status for all employees
    // ---------------------------------------------------------------
    public function index(Request $request): JsonResponse
    {
        $query = Employee::query()
            ->with(['user', 'department', 'faceData.enrolledBy'])
            ->where('status', 'active');

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->whereHas('user', fn($q) => $q->where('name', 'ilike', "%{$search}%"));
        }

        if ($request->filled('department_id')) {
            $query->where('department_id', $request->integer('department_id'));
        }

        if ($request->filled('enrolled')) {
            $enrolled = filter_var($request->string('enrolled'), FILTER_VALIDATE_BOOLEAN);
            if ($enrolled) {
                $query->whereHas('faceData');
            } else {
                $query->whereDoesntHave('faceData');
            }
        }

        $employees = $query->orderByDesc('created_at')->paginate($request->integer('per_page', 20));

        $data = $employees->map(function ($emp) {
            $face = $emp->faceData;
            return [
                'employee_id'     => $emp->id,
                'employee_number' => $emp->employee_number,
                'position'        => $emp->position,
                'user'            => ['id' => $emp->user->id, 'name' => $emp->user->name, 'avatar' => $emp->user->avatar],
                'department'      => $emp->department ? ['id' => $emp->department->id, 'name' => $emp->department->name] : null,
                'is_enrolled'     => (bool) $face,
                'face_data'       => $face ? [
                    'id'          => $face->id,
                    'is_active'   => $face->is_active,
                    'enrolled_at' => $face->enrolled_at?->toISOString(),
                    'image_url'   => $face->image_path ? Storage::disk('public')->url($face->image_path) : null,
                    'enrolled_by' => $face->enrolledBy ? ['id' => $face->enrolledBy->id, 'name' => $face->enrolledBy->name] : null,
                ] : null,
            ];
        });

        return response()->json([
            'success' => true,
            'data'    => $data,
            'meta'    => [
                'total'        => $employees->total(),
                'per_page'     => $employees->perPage(),
                'current_page' => $employees->currentPage(),
                'last_page'    => $employees->lastPage(),
                'enrolled'     => FaceData::where('is_active', true)->count(),
                'not_enrolled' => Employee::where('status', 'active')->whereDoesntHave('faceData')->count(),
            ],
        ]);
    }

    // ---------------------------------------------------------------
    // Admin/HR: enroll face for an employee
    // ---------------------------------------------------------------
    public function enroll(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'employee_id'  => ['required', 'exists:employees,id'],
            'descriptor'   => ['required', 'array', 'size:128'],
            'descriptor.*' => ['required', 'numeric', 'between:-2,2'],
            'snapshot'     => ['nullable', 'string'], // base64 PNG
        ]);

        $imagePath = null;

        // Save snapshot if provided
        if (!empty($validated['snapshot'])) {
            $base64 = preg_replace('/^data:image\/\w+;base64,/', '', $validated['snapshot']);
            $imageData = base64_decode($base64);

            if ($imageData !== false) {
                $filename  = 'faces/employee_' . $validated['employee_id'] . '_' . time() . '.jpg';
                Storage::disk('public')->put($filename, $imageData);
                $imagePath = $filename;
            }
        }

        $faceData = FaceData::updateOrCreate(
            ['employee_id' => $validated['employee_id']],
            [
                'descriptor'  => json_encode($validated['descriptor']),
                'image_path'  => $imagePath,
                'is_active'   => true,
                'enrolled_by' => $request->user()->id,
                'enrolled_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Face enrolled successfully.',
            'data'    => new FaceDataResource($faceData->load(['employee.user', 'employee.department', 'enrolledBy'])),
        ], 201);
    }

    // ---------------------------------------------------------------
    // Admin/HR: delete face enrollment
    // ---------------------------------------------------------------
    public function destroy(FaceData $faceData): JsonResponse
    {
        if ($faceData->image_path) {
            Storage::disk('public')->delete($faceData->image_path);
        }

        $faceData->delete();

        return response()->json(['success' => true, 'message' => 'Face data deleted.']);
    }

    // ---------------------------------------------------------------
    // All authenticated users: identify face → return matched employee
    // ---------------------------------------------------------------
    public function identify(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'descriptor'   => ['required', 'array', 'size:128'],
            'descriptor.*' => ['required', 'numeric', 'between:-2,2'],
        ]);

        $queryDescriptor = $validated['descriptor'];

        $allFaceData = FaceData::where('is_active', true)
            ->with(['employee.user', 'employee.department'])
            ->get();

        if ($allFaceData->isEmpty()) {
            return response()->json(['success' => false, 'message' => 'No enrolled faces found.'], 404);
        }

        $bestMatch    = null;
        $bestDistance = PHP_FLOAT_MAX;

        foreach ($allFaceData as $faceData) {
            $storedDescriptor = $faceData->getDescriptorArray();
            if (count($storedDescriptor) !== 128) continue;

            $distance = FaceData::euclideanDistance($queryDescriptor, $storedDescriptor);

            if ($distance < $bestDistance) {
                $bestDistance = $distance;
                $bestMatch    = $faceData;
            }
        }

        if (!$bestMatch || $bestDistance >= self::THRESHOLD) {
            return response()->json([
                'success' => false,
                'message' => 'No matching face found. Please try again or use manual check-in.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'employee_id' => $bestMatch->employee_id,
                'employee'    => [
                    'id'              => $bestMatch->employee->id,
                    'employee_number' => $bestMatch->employee->employee_number,
                    'position'        => $bestMatch->employee->position,
                    'user'            => [
                        'id'     => $bestMatch->employee->user->id,
                        'name'   => $bestMatch->employee->user->name,
                        'avatar' => $bestMatch->employee->user->avatar,
                    ],
                    'department' => $bestMatch->employee->department
                        ? ['id' => $bestMatch->employee->department->id, 'name' => $bestMatch->employee->department->name]
                        : null,
                ],
                'confidence'  => round((1 - $bestDistance / self::THRESHOLD) * 100, 1),
                'distance'    => round($bestDistance, 4),
            ],
        ]);
    }

    // ---------------------------------------------------------------
    // All authenticated users: face check-in/out (identify + record attendance)
    // ---------------------------------------------------------------
    public function faceAttendance(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'descriptor'   => ['required', 'array', 'size:128'],
            'descriptor.*' => ['required', 'numeric', 'between:-2,2'],
            'action'       => ['required', 'in:check_in,check_out'],
        ]);

        // Identify face
        $identifyResult = $this->identifyDescriptor($validated['descriptor']);

        if (!$identifyResult) {
            return response()->json([
                'success' => false,
                'message' => 'Face not recognized. Please try again or use manual check-in.',
            ], 404);
        }

        $employee = $identifyResult['face_data']->employee;
        $today    = Carbon::today();
        $now      = Carbon::now();
        $action   = $validated['action'];

        if ($action === 'check_in') {
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
                'success'    => true,
                'message'    => "Welcome, {$employee->user->name}! Checked in at {$now->format('H:i')}.",
                'confidence' => $identifyResult['confidence'],
                'data'       => new AttendanceResource($record->load(['employee.user', 'employee.department'])),
            ], 201);
        }

        // check_out
        $record = AttendanceRecord::where('employee_id', $employee->id)
            ->whereDate('date', $today)
            ->first();

        if (!$record) {
            return response()->json(['success' => false, 'message' => 'No check-in found for today.'], 422);
        }

        if ($record->check_out) {
            return response()->json(['success' => false, 'message' => 'Already checked out today.'], 422);
        }

        $record->update([
            'check_out'  => $now,
            'work_hours' => $record->calculateWorkHours(),
        ]);

        return response()->json([
            'success'    => true,
            'message'    => "Goodbye, {$employee->user->name}! Checked out at {$now->format('H:i')}.",
            'confidence' => $identifyResult['confidence'],
            'data'       => new AttendanceResource($record->load(['employee.user', 'employee.department'])),
        ]);
    }

    // ---------------------------------------------------------------
    private function identifyDescriptor(array $queryDescriptor): ?array
    {
        $allFaceData = FaceData::where('is_active', true)
            ->with(['employee.user', 'employee.department'])
            ->get();

        $bestMatch    = null;
        $bestDistance = PHP_FLOAT_MAX;

        foreach ($allFaceData as $faceData) {
            $stored = $faceData->getDescriptorArray();
            if (count($stored) !== 128) continue;

            $dist = FaceData::euclideanDistance($queryDescriptor, $stored);
            if ($dist < $bestDistance) {
                $bestDistance = $dist;
                $bestMatch    = $faceData;
            }
        }

        if (!$bestMatch || $bestDistance >= self::THRESHOLD) {
            return null;
        }

        return [
            'face_data'  => $bestMatch,
            'distance'   => $bestDistance,
            'confidence' => round((1 - $bestDistance / self::THRESHOLD) * 100, 1),
        ];
    }
}
