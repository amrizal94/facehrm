<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ResetProductionData extends Command
{
    protected $signature   = 'app:reset-production {--dry-run : Preview what will be deleted without actually deleting}';
    protected $description = 'Reset all transactional data, keeping HR and Director accounts + master data.';

    // Accounts to preserve (by email)
    private const KEEP_EMAILS = [
        'hr@example.com',
        'director@example.com',
    ];

    public function handle(): int
    {
        $isDry = $this->option('dry-run');

        $this->line('');
        $this->line('╔══════════════════════════════════════════════════════╗');
        $this->line('║         FaceHRM — Production Data Reset              ║');
        $this->line('╚══════════════════════════════════════════════════════╝');
        $this->line('');

        if ($isDry) {
            $this->warn('  [DRY RUN] No data will be deleted. Preview only.');
            $this->line('');
        }

        // ── Resolve users to keep ──────────────────────────────────────────
        $keepUsers = DB::table('users')
            ->whereIn('email', self::KEEP_EMAILS)
            ->get(['id', 'name', 'email']);

        if ($keepUsers->isEmpty()) {
            $this->error('  No matching accounts found for: ' . implode(', ', self::KEEP_EMAILS));
            $this->error('  Aborting — cannot proceed without knowing which accounts to preserve.');
            return self::FAILURE;
        }

        $keepUserIds    = $keepUsers->pluck('id')->toArray();
        $keepEmployeeIds = DB::table('employees')
            ->whereIn('user_id', $keepUserIds)
            ->pluck('id')
            ->toArray();

        // ── Summary of what will be kept ──────────────────────────────────
        $this->info('  Accounts that will be KEPT:');
        foreach ($keepUsers as $u) {
            $this->line("    ✓  {$u->name} <{$u->email}>");
        }
        $this->line('');
        $this->info('  Master data that will be KEPT:');
        $this->line('    ✓  Departments, Shifts, Leave Types, Expense Types');
        $this->line('    ✓  Settings, Roles & Permissions, Holidays');
        $this->line('');

        // ── Count what will be deleted ─────────────────────────────────────
        $counts = $this->buildDeleteCounts($keepUserIds, $keepEmployeeIds);

        $this->warn('  Data that will be DELETED:');
        foreach ($counts as $table => $count) {
            $this->line(sprintf('    ✗  %-30s %d rows', $table, $count));
        }
        $this->line('');

        $totalRows = array_sum($counts);
        $this->line("  Total rows to delete: {$totalRows}");
        $this->line('');

        // ── Dry run ends here ─────────────────────────────────────────────
        if ($isDry) {
            $this->warn('  [DRY RUN] Run without --dry-run to execute the reset.');
            return self::SUCCESS;
        }

        // ── Confirmation ──────────────────────────────────────────────────
        $this->error('  ⚠️  THIS ACTION CANNOT BE UNDONE.');
        $this->error('  ⚠️  Make sure you have a database backup before proceeding.');
        $this->line('');

        if (! $this->confirm('  Are you sure you want to delete all transactional data?')) {
            $this->line('  Aborted.');
            return self::SUCCESS;
        }

        $confirmed = $this->ask('  Type "RESET" to confirm');
        if ($confirmed !== 'RESET') {
            $this->line('  Confirmation failed. Aborted.');
            return self::SUCCESS;
        }

        // ── Execute ───────────────────────────────────────────────────────
        $this->line('');
        $this->line('  Resetting data...');

        DB::statement('SET session_replication_role = replica;'); // Disable FK checks (PostgreSQL)

        try {
            $this->deleteTransactionalData($keepUserIds, $keepEmployeeIds);
        } finally {
            DB::statement('SET session_replication_role = DEFAULT;'); // Re-enable FK checks
        }

        $this->line('');
        $this->info('  ✅ Reset complete!');
        $this->line('  Accounts preserved: ' . $keepUsers->pluck('email')->join(', '));
        $this->line('');

        return self::SUCCESS;
    }

    // ─────────────────────────────────────────────────────────────────────
    private function buildDeleteCounts(array $keepUserIds, array $keepEmployeeIds): array
    {
        return [
            'task_label (pivot)'       => DB::table('task_label')->count(),
            'task_checklist_items'     => DB::table('task_checklist_items')->count(),
            'tasks'                    => DB::table('tasks')->count(),
            'labels'                   => DB::table('labels')->count(),
            'projects'                 => DB::table('projects')->count(),
            'payroll_records'          => DB::table('payroll_records')->count(),
            'leave_requests'           => DB::table('leave_requests')->count(),
            'overtime_requests'        => DB::table('overtime_requests')->count(),
            'attendance_records'       => DB::table('attendance_records')->count(),
            'qr_sessions'              => DB::table('qr_sessions')->count(),
            'expenses'                 => DB::table('expenses')->count(),
            'face_data'                => DB::table('face_data')->count(),
            'notifications'            => DB::table('notifications')->count(),
            'audit_logs'               => DB::table('audit_logs')->count(),
            'meeting_rsvps'            => DB::table('meeting_rsvps')->count(),
            'meetings'                 => DB::table('meetings')->count(),
            'announcements'            => DB::table('announcements')->count(),
            'personal_access_tokens'   => DB::table('personal_access_tokens')
                ->whereNotIn('tokenable_id', $keepUserIds)->count(),
            'employees (non-admin/hr)' => DB::table('employees')
                ->whereNotIn('id', $keepEmployeeIds)->count(),
            'users (non-admin/hr)'     => DB::table('users')
                ->whereNotIn('id', $keepUserIds)->count(),
        ];
    }

    // ─────────────────────────────────────────────────────────────────────
    private function deleteTransactionalData(array $keepUserIds, array $keepEmployeeIds): void
    {
        // 1. Task-related (deepest first)
        $this->deleteTruncate('task_label');
        $this->deleteTruncate('task_checklist_items');
        $this->deleteTruncate('tasks');
        $this->deleteTruncate('labels');
        $this->deleteTruncate('projects');

        // 2. HR / Payroll
        $this->deleteTruncate('payroll_records');
        $this->deleteTruncate('leave_requests');
        $this->deleteTruncate('overtime_requests');

        // 3. Attendance
        $this->deleteTruncate('attendance_records');
        $this->deleteTruncate('qr_sessions');

        // 4. Expenses
        $this->deleteTruncate('expenses');

        // 5. Face data — also delete stored files from disk
        $this->deleteFaceFiles();
        $this->deleteTruncate('face_data');

        // 6. Misc
        $this->deleteTruncate('notifications');
        $this->deleteTruncate('audit_logs');
        $this->deleteTruncate('meeting_rsvps');
        $this->deleteTruncate('meetings');
        $this->deleteTruncate('announcements');

        // 7. Sanctum tokens for deleted users
        DB::table('personal_access_tokens')
            ->whereNotIn('tokenable_id', $keepUserIds)
            ->delete();
        $this->line('    ✗  personal_access_tokens (non-admin/hr)');

        // 8. Spatie role assignments for deleted users
        DB::table('model_has_roles')
            ->where('model_type', 'App\\Models\\User')
            ->whereNotIn('model_id', $keepUserIds)
            ->delete();

        // 9. Employees (keep those linked to preserved users)
        $deleted = DB::table('employees')
            ->whereNotIn('id', $keepEmployeeIds)
            ->delete();
        $this->line("    ✗  employees ({$deleted} rows)");

        // 10. Users (keep HR and director)
        $deleted = DB::table('users')
            ->whereNotIn('id', $keepUserIds)
            ->delete();
        $this->line("    ✗  users ({$deleted} rows)");

        // 11. Reset auto-increment sequences
        $this->resetSequences();
    }

    // ─────────────────────────────────────────────────────────────────────
    private function deleteTruncate(string $table): void
    {
        $count = DB::table($table)->count();
        DB::table($table)->delete();
        $this->line("    ✗  {$table} ({$count} rows)");
    }

    // ─────────────────────────────────────────────────────────────────────
    private function deleteFaceFiles(): void
    {
        try {
            $paths = DB::table('face_data')->pluck('image_path')->filter()->toArray();
            foreach ($paths as $path) {
                Storage::disk('public')->delete($path);
            }
            // Also clean up face-photos directory
            $files = Storage::disk('public')->files('face-photos');
            Storage::disk('public')->delete($files);
            $this->line('    ✗  face photo files from storage');
        } catch (\Throwable) {
            $this->warn('    ⚠  Could not clean face photo files (non-fatal)');
        }

        // Also clean task-photos
        try {
            $taskPaths = DB::table('tasks')->whereNotNull('photo_path')->pluck('photo_path')->toArray();
            foreach ($taskPaths as $path) {
                Storage::disk('public')->delete($path);
            }
            $this->line('    ✗  task photo files from storage');
        } catch (\Throwable) {
            $this->warn('    ⚠  Could not clean task photo files (non-fatal)');
        }

        // Also clean expense receipts
        try {
            $receiptPaths = DB::table('expenses')->whereNotNull('receipt_path')->pluck('receipt_path')->toArray();
            foreach ($receiptPaths as $path) {
                Storage::disk('public')->delete($path);
            }
            $this->line('    ✗  expense receipt files from storage');
        } catch (\Throwable) {
            $this->warn('    ⚠  Could not clean expense receipt files (non-fatal)');
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    private function resetSequences(): void
    {
        // Reset PostgreSQL sequences so new IDs start from 1
        $tables = [
            'tasks', 'projects', 'labels', 'payroll_records', 'leave_requests',
            'overtime_requests', 'attendance_records', 'qr_sessions', 'expenses',
            'face_data', 'meetings', 'meeting_rsvps', 'announcements', 'audit_logs',
        ];
        foreach ($tables as $table) {
            try {
                DB::statement("SELECT setval(pg_get_serial_sequence('{$table}', 'id'), 1, false)");
            } catch (\Throwable) {
                // Non-fatal — sequence may not exist
            }
        }
        $this->line('    ✓  PostgreSQL sequences reset');
    }
}
