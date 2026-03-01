# FaceHRM — Claude Quick Reference

## Project Structure
- `backend/` — Laravel 11 API (Sanctum + Spatie Permission + PostgreSQL)
- `web/` — Next.js 15 App Router (TypeScript, Tailwind, shadcn/ui, TanStack Query)
- `mobile/` — Flutter (flutter_riverpod ^3.x, GoRouter, Dio)
- `deploy/update.sh` — full prod deploy script
- `deploy-apk.ps1` — build + upload APK to server

## Production Server
- SSH: `ssh -i ~/.ssh/id_ed25519 root@45.66.153.156`
- API: `https://hrm.kreasikaryaarjuna.co.id/api/v1`
- APK: `https://hrm.kreasikaryaarjuna.co.id/app/facehrm.apk`
- PHP: `/www/server/php/83/bin/php`

## API Convention
`{ "success": bool, "message": str, "data": {...} }`

## CRITICAL Rules

### Backend
- CORS: ONLY from Laravel `config/cors.php` — NEVER nginx (duplicate header = browser block)
- Deploy: always `composer install --no-dev`; `bootstrap/cache/` is gitignored
- PHP-FPM runs as `www` user — files outside repo must be `chown www:www`
- `.env` changes need `artisan config:clear` (config:cache caches APP_DEBUG)
- Test endpoints via domain, NOT localhost

### Mobile (Flutter)
- Riverpod v3: `StateNotifier`/`StateNotifierProvider` REMOVED
  - Sync state → `Notifier<S>` + `NotifierProvider`
  - Async state → `AsyncNotifier<S>` + `AsyncNotifierProvider`
  - `build()` returns initial state; repo via `ref.read()` in methods (not constructor)
- Mutation return: `Future<String?>` — null=success, String=error
- Capture `ScaffoldMessenger.of(context)` BEFORE first await
- npm/PowerShell on Windows: `powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "..."`

### Web (Next.js)
- Zod v4: `z.string().email()` NOT `z.email()`; `z.string()` + manual parseFloat NOT `z.coerce.number()`
- Radix UI: NEVER `<SelectItem value="">` → use `value="all"/"none"/"unspecified"`
- API client: `import { api } from './api'` (NOT `@/lib/api-client`)
- DashboardLayout: needs `title` prop + optional `allowedRoles`
- ESLint `disable` comment: must be on line immediately before offending code

## Feature Status (what's done)

### Web ✅
Auth/RBAC, Employee Mgmt (+ activation toggle), Attendance, Leave, Payroll, Face Recognition (enroll+delete+audit-log tabs), Reports, Settings (company+attendance+payroll policy), Admin Dashboard, HR Dashboard, Manager Dashboard, Tasks & Projects, Shifts, Announcements (CRUD+broadcast), Expense/Reimbursement (staff /staff/expenses, admin /admin/expenses — tabs: Approvals + Expense Types), QR Attendance (QrSessionDialog di /admin/attendance), Meetings CRUD+RSVP (/admin/meetings, /staff/meetings)

### Mobile ✅
Auth, Dashboard (all 4 roles — staff/admin/hr/manager/director), Attendance (face+manual+offline sync), Face Self-Enroll, Leave, Payslip (+ PDF share), Overtime, Holidays, Notifications, Tasks, Announcements, My Shift, Face Data Management (admin/hr), Employee Account Activation (admin/hr), Employee Create/Edit, Face Audit Log (/hr/face-audit-log), Expense/Reimbursement (MyExpensesScreen summary card + API-driven types + SubmitExpenseScreen + ExpenseApprovalsScreen — live pending badge), QR Attendance (/staff/qr-scan + /hr/qr-generator), Meetings (/meetings + /meetings/detail), Force Password Change (/change-password)

### Gaps (P2)
Multi-branch

## Key Mobile Files
- Routes: `mobile/lib/core/router/app_routes.dart`
- Router: `mobile/lib/core/router/app_router.dart`
- API constants: `mobile/lib/core/constants/api_constants.dart`
- Push notifications: `mobile/lib/core/services/push_notification_service.dart`
- Feature dir pattern: `mobile/lib/features/<name>/data/{models,datasources,repositories}/` + `presentation/{providers,screens}/`

## Key Web Files
- Types: `web/types/<feature>.ts`
- API client: `web/lib/<feature>-api.ts`
- Hooks: `web/hooks/use-<feature>.ts`
- Pages: `web/app/(dashboard)/{admin,hr,staff}/<feature>/page.tsx`
