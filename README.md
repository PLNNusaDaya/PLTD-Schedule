# PLTD Engineering Schedule v2 — Tamu & Admin

Website **3 bulan** dengan **2 tab** (Schedule Website & Schedule Aplikasi), Gantt, histori, bukti pekerjaan, dan login Admin. Siap deploy sebagai situs statis **GitHub Pages**.

## Hak akses

| Fitur | Tamu (tanpa password) | Admin (password Supabase) |
| --- | --- | --- |
| Lihat jadwal Website / Aplikasi, Gantt, progres dan histori | ✅ | ✅ |
| Buka detail, lihat/unduh bukti pekerjaan | ✅ | ✅ |
| Ekspor CSV read-only | ✅ | ✅ |
| Edit tanggal, status, progres, PIC dan deskripsi | ❌ | ✅ |
| Tambah/hapus kegiatan, upload/hapus bukti | ❌ | ✅ |
| Ubah tanggal mulai proyek, impor/overwrite backup, simpan | ❌ | ✅ |

**Tidak ada password default dan tidak ada password di HTML/JS/GitHub.** Login memakai akun **Supabase Authentication (email + password)**. Hak Admin ditentukan tabel `pltd_admins` dan ditegakkan oleh **Postgres Row Level Security (RLS)**. Sekadar mengetahui URL dan publishable key tidak memberikan hak edit.

## Pengaturan pertama kali (wajib supaya admin dapat login dan tamu melihat jadwal ONLINE)

1. Buat proyek di [Supabase](https://supabase.com), lalu di **SQL Editor** jalankan seluruh file `database/supabase.sql`.
2. Buka **Authentication → Users → Add user** (atau Invite user), buat akun admin dengan email dan **password yang Anda tentukan sendiri**. Pastikan akun emailnya sudah aktif/confirmed. Matikan pendaftaran publik bila hanya ingin satu Admin.
3. Jalankan SQL ini di SQL Editor, **ganti alamat email** dengan email akun yang dibuat:
   ```sql
   insert into public.pltd_admins (user_id)
   select id from auth.users
   where lower(email) = lower('EMAIL_ADMIN_ANDA@CONTOH.COM')
   on conflict (user_id) do nothing;
   ```
4. Ambil **Supabase Project URL** dan **publishable key** (bukan secret/service_role) dari dashboard Supabase.
5. Buka `config.js` dan isi nilai `url` serta `key`. **Kedua nilai ini aman dicantumkan di frontend** asalkan aturan RLS dari file SQL sudah dipasang. Jangan isi password di sini.
6. Buka website, klik **Masuk Admin**, isikan email dan password langkah 2. Pada login Admin pertama, jadwal awal 46 kegiatan akan diterbitkan ke database jika belum ada jadwal online. Setelah itu, semua pengunjung otomatis dapat **membaca** jadwal bersama yang sama.

> Jika sebelumnya Anda memakai v1, **buat backup JSON** dari v1 terlebih dahulu. Di v2, setelah login Admin, pilih **Pengaturan Proyek → Impor Backup & Timpa** untuk memindahkan jadwal + lampiran v1. Lampiran yang berasal dari penyimpanan cloud v1 harus dicadangkan dari v1 terlebih dahulu; file privat v1 tidak otomatis menjadi publik.

## Jalankan secara lokal

Buka `index.html` untuk melihat demo jadwal sebagai **Tamu**. Agar IndexedDB berfungsi konsisten, jalankan `python -m http.server 8000` di folder ini, kemudian buka `http://localhost:8000`. **Untuk mengedit**, perlu terhubung ke Supabase dan login Admin; ini disengaja supaya situs publik tidak memiliki password yang bisa dilihat di source code.

## Upload GitHub Pages

1. Buat repositori baru, upload **isi folder ZIP** ke root repositori (`index.html`, `styles.css`, `app.js`, `config.js`, folder `database/`, `README.md`, `.nojekyll`).
2. Buka **Settings → Pages → Deploy from a branch**, pilih `main` dan `/(root)`.
3. Buka tautan situs terbitan GitHub Pages. Tamu tidak perlu login; tombol **Masuk Admin** membuka formulir password.
4. Sesudah Admin menyimpan perubahan, Tamu bisa tekan **Muat Terbaru** atau *refresh* halaman untuk mengambil versi online paling baru.

## Perhatian keamanan dan data

- **GitHub Pages bukan database**. Supabase menyimpan jadwal dan file bukti bersama; browser tetap memiliki cache untuk kondisi offline.
- Semua informasi dalam jadwal yang diterbitkan (nama PIC, catatan, histori, lampiran) **terbuka bagi siapapun yang mengakses alamat situs**, termasuk URL file bukti. Jangan upload data rahasia, dokumen personel, atau dokumen operasional sensitif. Jika ingin guest privat berbasis undangan, perlu kebijakan akses lain.
- Jangan masukkan **service_role**, secret API key, atau password Admin ke `config.js`, source code, atau README.
- RLS memastikan akun tak dikenal tidak dapat menulis. Riwayat event berbasis data proyek; Admin dapat menimpa history via impor backup, jadi ini bukan log audit yang tak bisa dimodifikasi.
- Sistem memakai satu dokumen state pada database (*last-write-wins*). Sebaiknya satu editor dalam satu waktu; untuk multi-admin simultan perlu version conflict control.
- Login disimpan di **sessionStorage** (sesi browser), konfigurasi URL/key publik di `localStorage` bila diatur lewat layar login. Jangan gunakan opsi penyimpanan password otomatis di komputer umum.
- Jadwal awal: 19 Oktober 2026 – 18 Januari 2027, baseline 46 tugas dan bisa digeser oleh Admin.
- Batas berkas bukti 15 MB; contoh ini menyimpan dokumen di public bucket. Untuk dokumen rahasia, jangan gunakan bucket publik.

## Berkas

- `index.html` — struktur UI tamu/admin, jadwal, Gantt, detail pekerjaan
- `styles.css` — tema responsive
- `app.js` — 46 kegiatan, edit/status, IndexedDB cache, otorisasi, cloud, bukti, history
- `config.js` — URL dan **public key** Supabase untuk semua pengunjung
- `database/supabase.sql` — skema, admin allowlist, RLS, dan bucket bukti
- `.nojekyll` — GitHub Pages
