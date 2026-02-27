<?php

namespace App\Notifications;

use App\Models\Employee;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class FakeGpsDetected extends Notification
{
    use Queueable;

    public function __construct(
        private readonly Employee $employee,
        private readonly ?float   $latitude,
        private readonly ?float   $longitude,
        private readonly ?float   $accuracy,
        private readonly string   $detectedVia, // 'is_mock_location' | 'zero_accuracy'
    ) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        $name = $this->employee->user?->name ?? $this->employee->employee_number;

        return [
            'type'          => 'fake_gps',
            'title'         => 'Percobaan Fake GPS Terdeteksi',
            'message'       => "Karyawan {$name} mencoba absensi dengan GPS palsu (via {$this->detectedVia}).",
            'employee_id'   => $this->employee->id,
            'employee_name' => $name,
            'latitude'      => $this->latitude,
            'longitude'     => $this->longitude,
            'accuracy'      => $this->accuracy,
            'link'          => '/hr/attendance-records',
        ];
    }
}
