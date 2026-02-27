<?php

namespace App\Notifications;

use App\Models\LeaveRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use NotificationChannels\FCM\FcmChannel;
use NotificationChannels\FCM\FcmMessage;
use NotificationChannels\FCM\Resources\AndroidConfig;
use NotificationChannels\FCM\Resources\Notification as FcmNotification;

class LeaveStatusChanged extends Notification
{
    use Queueable;

    public function __construct(protected LeaveRequest $leaveRequest) {}

    public function via(object $notifiable): array
    {
        return ['database', FcmChannel::class];
    }

    public function toDatabase(object $notifiable): array
    {
        $status = $this->leaveRequest->status;
        $type   = $this->leaveRequest->leaveType?->name ?? 'Leave';
        $start  = $this->leaveRequest->start_date?->toDateString();

        return [
            'type'       => 'leave_status',
            'title'      => match ($status) {
                'approved' => 'Leave Request Approved',
                'rejected' => 'Leave Request Rejected',
                'cancelled'=> 'Leave Request Cancelled',
                default    => 'Leave Request Updated',
            },
            'message'    => match ($status) {
                'approved' => "Your {$type} request starting {$start} has been approved.",
                'rejected' => "Your {$type} request starting {$start} has been rejected." .
                    ($this->leaveRequest->rejection_reason ? " Reason: {$this->leaveRequest->rejection_reason}" : ''),
                'cancelled'=> "Your {$type} request starting {$start} has been cancelled.",
                default    => "Your {$type} request status has changed to {$status}.",
            },
            'status'     => $status,
            'request_id' => $this->leaveRequest->id,
            'link'       => '/staff/leave',
        ];
    }

    public function toFcm(object $notifiable): FcmMessage
    {
        $status = $this->leaveRequest->status;
        $type   = $this->leaveRequest->leaveType?->name ?? 'Leave';
        $start  = $this->leaveRequest->start_date?->toDateString();

        $title = match ($status) {
            'approved' => 'Leave Request Approved',
            'rejected' => 'Leave Request Rejected',
            'cancelled'=> 'Leave Request Cancelled',
            default    => 'Leave Request Updated',
        };

        $body = match ($status) {
            'approved' => "Your {$type} request starting {$start} has been approved.",
            'rejected' => "Your {$type} request starting {$start} has been rejected." .
                ($this->leaveRequest->rejection_reason ? " Reason: {$this->leaveRequest->rejection_reason}" : ''),
            'cancelled'=> "Your {$type} request starting {$start} has been cancelled.",
            default    => "Your {$type} request status has changed to {$status}.",
        };

        return FcmMessage::create()
            ->setNotification(
                FcmNotification::create()->setTitle($title)->setBody($body)
            )
            ->setData([
                'type'       => 'leave_status',
                'status'     => $status,
                'request_id' => (string) $this->leaveRequest->id,
                'link'       => '/staff/leave',
            ])
            ->setAndroidConfig(
                AndroidConfig::create()->setPriority(AndroidConfig::PRIORITY_HIGH)
            );
    }
}
