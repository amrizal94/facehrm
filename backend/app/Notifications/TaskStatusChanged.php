<?php

namespace App\Notifications;

use App\Models\Task;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use NotificationChannels\FCM\FcmChannel;
use NotificationChannels\FCM\FcmMessage;
use NotificationChannels\FCM\Resources\AndroidConfig;
use NotificationChannels\FCM\Resources\Notification as FcmNotification;

class TaskStatusChanged extends Notification
{
    use Queueable;

    public function __construct(protected Task $task) {}

    public function via(object $notifiable): array
    {
        return ['database', FcmChannel::class];
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

    public function toFcm(object $notifiable): FcmMessage
    {
        return FcmMessage::create()
            ->setNotification(
                FcmNotification::create()
                    ->setTitle('Task Cancelled')
                    ->setBody("Task \"{$this->task->title}\" has been cancelled.")
            )
            ->setData([
                'type'    => 'task_status',
                'task_id' => (string) $this->task->id,
                'link'    => '/staff/tasks',
            ])
            ->setAndroidConfig(
                AndroidConfig::create()->setPriority(AndroidConfig::PRIORITY_HIGH)
            );
    }
}
