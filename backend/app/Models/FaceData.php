<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FaceData extends Model
{
    protected $fillable = [
        'employee_id',
        'descriptor',
        'image_path',
        'is_active',
        'enrolled_by',
        'enrolled_at',
    ];

    protected function casts(): array
    {
        return [
            'is_active'   => 'boolean',
            'enrolled_at' => 'datetime',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function enrolledBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'enrolled_by');
    }

    /**
     * Get descriptor as float array.
     */
    public function getDescriptorArray(): array
    {
        return json_decode($this->descriptor, true) ?? [];
    }

    /**
     * Compute Euclidean distance between two 128-float descriptors.
     */
    public static function euclideanDistance(array $a, array $b): float
    {
        $sum = 0.0;
        foreach ($a as $i => $v) {
            $diff  = $v - ($b[$i] ?? 0);
            $sum  += $diff * $diff;
        }
        return sqrt($sum);
    }
}
