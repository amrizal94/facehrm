<?php

namespace App\Notifications;

use App\Models\Task;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class TaskAssigned extends Notification
{
    use Queueable;

    public function __construct(protected Task $task) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        $project = $this->task->project?->name ?? 'No Project';

        return [
            'type'    => 'task_assigned',
            'title'   => 'New Task Assigned',
            'message' => "You have been assigned: \"{$this->task->title}\" (Project: {$project})",
            'task_id' => $this->task->id,
            'link'    => '/staff/tasks',
        ];
    }
}
