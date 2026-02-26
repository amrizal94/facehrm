<?php

namespace App\Notifications;

use App\Models\Task;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class TaskStatusChanged extends Notification
{
    use Queueable;

    public function __construct(protected Task $task) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'type'    => 'task_status',
            'title'   => 'Task Cancelled',
            'message' => "Task \"{$this->task->title}\" has been cancelled.",
            'task_id' => $this->task->id,
            'link'    => '/staff/tasks',
        ];
    }
}
