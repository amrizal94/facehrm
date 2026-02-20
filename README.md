# FaceHRM

Face Recognition Human Resource Management System

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Laravel 11 + Sanctum + Spatie Permission |
| Mobile | Flutter + Riverpod + GoRouter |
| Database | PostgreSQL 16 |
| Cache | Redis 7 |
| Container | Docker + Nginx |

## Project Structure

```
FaceHRM/
├── backend/     ← Laravel 11 API
├── mobile/      ← Flutter app
└── docker/      ← Docker configs
    ├── docker-compose.yml
    ├── nginx/default.conf
    └── php/Dockerfile
```

## Getting Started

### 1. Start Docker services

```bash
cd docker
docker-compose up -d
```

### 2. Setup Laravel backend

```bash
# Install PHP dependencies
docker exec facehrm_app composer install

# Generate app key
docker exec facehrm_app php artisan key:generate

# Run migrations and seed default users
docker exec facehrm_app php artisan migrate --seed
```

### 3. Run Flutter app

```bash
cd mobile
flutter pub get
flutter run
```

## Default Users

| Email | Password | Role |
|-------|----------|------|
| admin@example.com | 12345678 | admin |
| hr@example.com | 12345678 | hr |
| staff@example.com | 12345678 | staff |

## API Base URL

```
http://localhost/api/v1
```

## Auth Flow

```
App Start → Check token → GET /me
  ✓ Valid   → Dashboard (role-based redirect)
  ✗ Invalid → Clear token → Login screen

Login → POST /login → Save token → Dashboard
Logout → POST /logout → Clear token → Login screen
```
