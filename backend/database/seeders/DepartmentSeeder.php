<?php

namespace Database\Seeders;

use App\Models\Department;
use Illuminate\Database\Seeder;

class DepartmentSeeder extends Seeder
{
    public function run(): void
    {
        $departments = [
            ['name' => 'Human Resources',    'code' => 'HR',  'description' => 'Manages recruitment, employee relations, and HR policies.'],
            ['name' => 'Information Technology', 'code' => 'IT', 'description' => 'Handles all technology infrastructure and software development.'],
            ['name' => 'Finance & Accounting', 'code' => 'FIN', 'description' => 'Manages financial planning, accounting, and budgeting.'],
            ['name' => 'Operations',          'code' => 'OPS', 'description' => 'Oversees day-to-day operational activities.'],
            ['name' => 'Marketing',           'code' => 'MKT', 'description' => 'Manages brand, campaigns, and market growth.'],
        ];

        foreach ($departments as $data) {
            Department::updateOrCreate(
                ['code' => $data['code']],
                array_merge($data, ['is_active' => true])
            );
            $this->command->info("Department seeded: {$data['name']} ({$data['code']})");
        }
    }
}
