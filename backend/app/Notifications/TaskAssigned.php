<?php

namespace App\Notifications;

use App\Models\Task;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use NotificationChannels\FCM\FcmChannel;
use NotificationChannels\FCM\FcmMessage;
use NotificationChannels\FCM\Resources\AndroidConfig;
use NotificationChannels\FCM\Resources\Notification as FcmNotification;

class TaskAssigned extends Notification
{
    use Queueable;

    public function __construct(protected Task $task) {}

    public function via(object $notifiable): array
    {
        return ['database', FcmChannel::class];
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

    public function toFcm(object $notifiable): FcmMessage
    {
        $project = $this->task->project?->name ?? 'No Project';

        return FcmMessage::create()
            ->setNotification(
                FcmNotification::create()
                    ->setTitle('New Task Assigned')
                    ->setBody("You have been assigned: \"{$this->task->title}\" (Project: {$project})")
            )
            ->setData([
                'type'    => 'task_assigned',
                'task_id' => (string) $this->task->id,
                'link'    => '/staff/tasks',
            ])
            ->setAndroidConfig(
                AndroidConfig::create()->setPriority(AndroidConfig::PRIORITY_HIGH)
            );
    }
}
