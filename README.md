# FaceHRM

Face Recognition Human Resource Management System

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Laravel 11 + Sanctum + Spatie Permission + PostgreSQL 16 + Redis 7 |
| Web | Next.js 15, TypeScript, Tailwind CSS, shadcn/ui, TanStack Query |
| Mobile | Flutter + Riverpod + GoRouter + MLKit Face Detection |
| Infrastructure | aaPanel + Nginx + PHP 8.3 FPM + PM2 + Node.js Face Service |

## Project Structure

```
FaceHRM/
├── backend/        ← Laravel 11 API
├── web/            ← Next.js 15 web frontend
├── mobile/         ← Flutter Android app
├── deploy/         ← Deploy scripts & nginx configs
│   ├── update.sh       # deploy/update script for production
│   └── *.conf          # nginx config examples
└── docker/         ← Docker configs (local dev)
```

## Production

| Item | Value |
|------|-------|
| URL | https://hrm.kreasikaryaarjuna.co.id |
| Android APK | https://hrm.kreasikaryaarjuna.co.id/app/facehrm.apk |
| Server | 45.66.153.156 (aaPanel, Ubuntu) |
| PHP | `/www/server/php/83/bin/php` (8.3 FPM) |
| Web process | PM2 `facehrm-web` (Next.js standalone) |
| Face service | PM2 `face-service` (Node.js port 3003) |

## Default Users

| Email | Password | Role |
|-------|----------|------|
| admin@example.com | 12345678 | Admin |
| hr@example.com | 12345678 | HR |
| staff@example.com | 12345678 | Staff (EMP000) |
| budi.santoso@example.com | EMP001 | Staff (EMP001) |
| siti.rahayu@example.com | EMP002 | Staff (EMP002) |
| ahmad.fauzi@example.com | EMP003 | Staff (EMP003) |

## Local Dev Setup

### Backend
```bash
cd docker && docker-compose up -d
docker exec facehrm_app composer install
docker exec facehrm_app php artisan key:generate
docker exec facehrm_app php artisan migrate --seed
```

### Web
```bash
cd web && npm install
npm run dev   # runs on port 3002
```

### Mobile
```bash
cd mobile && flutter pub get
flutter run   # connect Android device via USB
```

## Deploy to Production

```bash
ssh -i ~/.ssh/id_ed25519 root@45.66.153.156
cd /www/wwwroot/facehrm && bash deploy/update.sh
```

The `update.sh` script:
1. `git fetch + reset --hard origin/main`
2. `composer install --no-dev --optimize-autoloader`
3. `php artisan migrate --force && config:cache && route:cache`
4. `npm install && npm run build` (Next.js)
5. `pm2 restart facehrm-web`
6. Purge nginx proxy cache

> **Note:** For mobile changes, build and deploy APK separately using the dedicated script:
> ```powershell
> .\deploy-apk.ps1   # Windows PowerShell
> # or
> bash deploy-apk.sh  # Linux/macOS
> ```
> The script builds a versioned APK (`facehrm-v1.0.0-b{N}.apk`), uploads it, and updates `version.txt` so the login page shows the latest version.

## API Convention

All responses:
```json
{ "success": bool, "message": "string", "data": { ... } }
```
Base URL: `https://hrm.kreasikaryaarjuna.co.id/api/v1`

## CI/CD

GitHub Actions: `.github/workflows/ci.yml` → `.github/workflows/deploy.yml`
- CI: PHP syntax check + Laravel bootstrap + ESLint + TypeScript + Next.js build
- Deploy: SSH → `bash deploy/update.sh` — only runs if CI passes

## Auth Flow

```
App Start → GET /me
  ✓ token valid   → role-based dashboard redirect
  ✗ token invalid → Login screen

Login → POST /auth/login → save token → redirect
Logout → POST /auth/logout → clear token → Login screen
```
