<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = [
            [
                'name' => 'Administrator',
                'email' => 'admin@example.com',
                'password' => Hash::make('12345678'),
                'phone' => '+62811000001',
                'is_active' => true,
                'role' => 'admin',
            ],
            [
                'name' => 'HR Manager',
                'email' => 'hr@example.com',
                'password' => Hash::make('12345678'),
                'phone' => '+62811000002',
                'is_active' => true,
                'role' => 'hr',
            ],
            [
                'name' => 'Staff Employee',
                'email' => 'staff@example.com',
                'password' => Hash::make('12345678'),
                'phone' => '+62811000003',
                'is_active' => true,
                'role' => 'staff',
            ],
        ];

        foreach ($users as $userData) {
            $role = $userData['role'];
            unset($userData['role']);

            $user = User::updateOrCreate(
                ['email' => $userData['email']],
                $userData
            );

            // Assign role
            $user->syncRoles([$role]);

            $this->command->info("User created: {$user->email} → role: {$role}");
        }
    }
}
