<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTaskRequest;
use App\Http\Requests\UpdateTaskRequest;
use App\Http\Resources\TaskResource;
use App\Models\Employee;
use App\Models\Task;
use App\Models\TaskChecklistItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user  = $request->user();
        $query = Task::query()->with(['project', 'assignee.user', 'labels']);

        if ($user->hasRole(['admin', 'hr'])) {
            // Admin/HR see all
            if ($request->filled('assigned_to')) {
                $query->where('assigned_to', $request->integer('assigned_to'));
            }
        } else {
            // Staff: only own assigned tasks
            $employee = Employee::where('user_id', $user->id)->first();
            $query->where('assigned_to', $employee?->id);
        }

        if ($request->filled('project_id')) {
            $query->where('project_id', $request->integer('project_id'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('priority')) {
            $query->where('priority', $request->string('priority'));
        }

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where('title', 'ilike', "%{$search}%");
        }

        $tasks = $query
            ->orderBy('sort_order')
            ->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'success' => true,
            'data'    => TaskResource::collection($tasks->items()),
            'meta'    => [
                'total'        => $tasks->total(),
                'per_page'     => $tasks->perPage(),
                'current_page' => $tasks->currentPage(),
                'last_page'    => $tasks->lastPage(),
            ],
        ]);
    }

    public function store(StoreTaskRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $task = Task::create(array_merge(
            collect($validated)->except(['label_ids', 'checklist_items'])->toArray(),
            ['created_by' => $request->user()->id]
        ));

        if (!empty($validated['label_ids'])) {
            $task->labels()->sync($validated['label_ids']);
        }

        if (!empty($validated['checklist_items'])) {
            $items = array_map(fn($item, $i) => [
                'task_id'    => $task->id,
                'title'      => $item['title'],
                'is_done'    => false,
                'sort_order' => $i,
                'created_at' => now(),
                'updated_at' => now(),
            ], $validated['checklist_items'], array_keys($validated['checklist_items']));

            TaskChecklistItem::insert($items);
        }

        return response()->json([
            'success' => true,
            'message' => 'Task created.',
            'data'    => new TaskResource(
                $task->load(['project', 'assignee.user', 'creator', 'labels', 'checklistItems'])
            ),
        ], 201);
    }

    public function show(Request $request, Task $task): JsonResponse
    {
        $user = $request->user();

        if (!$user->hasRole(['admin', 'hr'])) {
            $employee = Employee::where('user_id', $user->id)->first();
            if ($task->assigned_to !== $employee?->id) {
                return response()->json(['success' => false, 'message' => 'Forbidden.'], 403);
            }
        }

        return response()->json([
            'success' => true,
            'data'    => new TaskResource(
                $task->load(['project', 'assignee.user', 'creator', 'labels', 'checklistItems'])
            ),
        ]);
    }

    public function update(UpdateTaskRequest $request, Task $task): JsonResponse
    {
        $user      = $request->user();
        $validated = $request->validated();

        if (!$user->hasRole(['admin', 'hr'])) {
            // Staff: only allowed to update status on own task
            $employee = Employee::where('user_id', $user->id)->first();
            if ($task->assigned_to !== $employee?->id) {
                return response()->json(['success' => false, 'message' => 'Forbidden.'], 403);
            }
            $validated = collect($validated)->only(['status'])->toArray();
        }

        $labelIds = $validated['label_ids'] ?? null;
        $data     = collect($validated)->except(['label_ids', 'checklist_items'])->toArray();

        $task->update($data);

        if ($user->hasRole(['admin', 'hr']) && $labelIds !== null) {
            $task->labels()->sync($labelIds);
        }

        return response()->json([
            'success' => true,
            'message' => 'Task updated.',
            'data'    => new TaskResource(
                $task->load(['project', 'assignee.user', 'creator', 'labels', 'checklistItems'])
            ),
        ]);
    }

    public function destroy(Task $task): JsonResponse
    {
        $task->delete();

        return response()->json(['success' => true, 'message' => 'Task deleted.']);
    }

    // ---------------------------------------------------------------
    // Checklist
    // ---------------------------------------------------------------

    public function addChecklistItem(Request $request, Task $task): JsonResponse
    {
        $request->validate(['title' => ['required', 'string', 'max:500']]);

        $maxOrder = $task->checklistItems()->max('sort_order') ?? -1;

        $item = $task->checklistItems()->create([
            'title'      => $request->string('title'),
            'is_done'    => false,
            'sort_order' => $maxOrder + 1,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Checklist item added.',
            'data'    => ['id' => $item->id, 'title' => $item->title, 'is_done' => $item->is_done, 'sort_order' => $item->sort_order],
        ], 201);
    }

    public function toggleChecklistItem(Request $request, Task $task, TaskChecklistItem $item): JsonResponse
    {
        $user = $request->user();

        if (!$user->hasRole(['admin', 'hr'])) {
            $employee = Employee::where('user_id', $user->id)->first();
            if ($task->assigned_to !== $employee?->id) {
                return response()->json(['success' => false, 'message' => 'Forbidden.'], 403);
            }
        }

        if ($item->task_id !== $task->id) {
            return response()->json(['success' => false, 'message' => 'Item not found.'], 404);
        }

        $item->update(['is_done' => !$item->is_done]);

        return response()->json([
            'success' => true,
            'data'    => ['id' => $item->id, 'is_done' => $item->is_done],
        ]);
    }

    public function deleteChecklistItem(Task $task, TaskChecklistItem $item): JsonResponse
    {
        if ($item->task_id !== $task->id) {
            return response()->json(['success' => false, 'message' => 'Item not found.'], 404);
        }

        $item->delete();

        return response()->json(['success' => true, 'message' => 'Checklist item deleted.']);
    }
}
