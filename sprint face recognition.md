Siap mas Ari, ini aku susunin Sprint Face Recognition FaceHRM yang realistis dan siap buat dibawa ke Claude nanti 💙

🎯 Sprint Goal (2 minggu)

Deliver fitur Face Check-In/Check-Out di mobile yang:

• bisa capture wajah dari kamera,
• kirim ke backend untuk verifikasi,
• hasilnya update attendance dengan UX yang clean buat demo client.

───

📅 Rencana 2 Minggu (praktis)

Week 1 — Core implementation

Day 1

• Setup dependency: camera, google_mlkit_face_detection, image (compress)
• Android permission + device compatibility check

Day 2

• Build screen kamera attendance + overlay frame wajah (oval/guide)

Day 3

• Face detection real-time (1 wajah valid, posisi pas, jarak pas)

Day 4

• Capture pipeline + kompres gambar (<500KB target)

Day 5

• Integrasi API verify-face untuk check-in

Week 2 — Production-ready demo

Day 6

• Integrasi check-out pakai flow yang sama

Day 7

• Error handling lengkap (low light, no face, multi-face, timeout)

Day 8

• Anti-spoof basic (liveness sederhana: blink/head move challenge)

Day 9

• UX polish (loading state, success/fail feedback, retry flow)

Day 10

• QA multi-device + rehearsal demo 10 menit

───

🧱 Backlog Prioritas

P0 (wajib demo)

• Camera attendance screen
• Face detection + validasi 1 wajah
• API verify face (check-in / check-out)
• Update status attendance realtime di dashboard staff

P1 (strong value)

• Liveness basic
• Better error copy (bahasa manusia)
• Face registration flow (enroll wajah)

P2 (next sprint)

• Offline queue
• Auto-capture saat wajah stabil
• Monitoring score/history untuk admin

───

🔌 Usulan API Contract (FE-BE)

1. POST /face/register

• multipart: user_id, image

2. POST /attendance/verify-face

• multipart: user_id, image, type (check-in|check-out)
• optional: lat, lng, device_id

Response minimal:

• success, match_score, message, attendance_record

───

✅ Acceptance Criteria (buat Definition of Done)

• User bisa check-in/out via kamera dari mobile
• Tombol submit aktif hanya saat wajah valid
• Face mismatch ditolak dengan pesan jelas
• Setelah sukses, UI attendance langsung sinkron
• Flow stabil di minimal 3 tier device (budget/mid/flagship)

───

⚠️ Risiko & mitigasi

• Low light → brightness check + prompt “Pencahayaan kurang”
• Device kamera berbeda → QA 3 tier device
• Latency upload → image compression + timeout + retry
• Overclaim ke client → jelaskan level liveness saat ini “basic”

───

🗣️ Script demo 10 menit (client)

1. Login staff
2. Face check-in sukses
3. Coba face mismatch (ditolak)
4. Check-out sukses
5. Tunjukkan attendance update di dashboard/report
6. Tutup dengan roadmap (offline + advanced liveness)

───

Kalau mas Ari mau, next aku bisa bikin versi Sprint Board siap eksekusi (format: To Do / In Progress / Done + estimasi jam per task) biar langsung dipakai tim.