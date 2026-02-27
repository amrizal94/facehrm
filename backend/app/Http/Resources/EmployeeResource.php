<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmployeeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                      => $this->id,
            'employee_number'         => $this->employee_number,
            'position'                => $this->position,
            'employment_type'         => $this->employment_type,
            'status'                  => $this->status,
            'join_date'               => $this->join_date?->toDateString(),
            'end_date'                => $this->end_date?->toDateString(),
            'basic_salary'            => $this->basic_salary,
            'gender'                  => $this->gender,
            'birth_date'              => $this->birth_date?->toDateString(),
            'address'                 => $this->address,
            'emergency_contact_name'  => $this->emergency_contact_name,
            'emergency_contact_phone' => $this->emergency_contact_phone,
            'bank_name'               => $this->bank_name,
            'bank_account_number'     => $this->bank_account_number,
            'tax_id'                  => $this->tax_id,
            'national_id'             => $this->national_id,
            'user'                    => $this->whenLoaded('user', fn() => [
                'id'        => $this->user->id,
                'name'      => $this->user->name,
                'email'     => $this->user->email,
                'phone'     => $this->user->phone,
                'avatar'    => $this->user->avatar,
                'is_active' => $this->user->is_active,
            ]),
            'department'              => $this->whenLoaded('department', fn() => [
                'id'   => $this->department?->id,
                'name' => $this->department?->name,
                'code' => $this->department?->code,
            ]),
            'created_at'              => $this->created_at?->toISOString(),
            'updated_at'              => $this->updated_at?->toISOString(),
        ];
    }
}
