<?php

namespace App\Models;

use App\Models\Setting;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AttendanceRecord extends Model
{
    protected $fillable = [
        'employee_id',
        'date',
        'check_in',
        'check_out',
        'status',
        'work_hours',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'date'       => 'date',
            'check_in'   => 'datetime',
            'check_out'  => 'datetime',
            'work_hours' => 'decimal:2',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    /**
     * Calculate work hours from check_in and check_out.
     */
    public function calculateWorkHours(): float
    {
        if (!$this->check_in || !$this->check_out) {
            return 0;
        }

        return round($this->check_out->diffInMinutes($this->check_in) / 60, 2);
    }

    /**
     * Determine status based on check_in time.
     * Late if checked in after 09:00.
     */
    public static function resolveStatus(\Carbon\Carbon $checkIn): string
    {
        $threshold = Setting::get('attendance.late_threshold', '09:00');
        [$hour, $minute] = array_map('intval', explode(':', $threshold));
        $cutoff = $checkIn->copy()->setTime($hour, $minute, 0);
        return $checkIn->greaterThan($cutoff) ? 'late' : 'present';
    }
}
