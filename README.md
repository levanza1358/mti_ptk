# MTI PTK

Aplikasi internal PT Multi Terminal Indonesia (LR 2 Area Pontianak) untuk mengelola cuti, eksepsi presensi, insentif, serta data kepegawaian. Aplikasi dibangun dengan Flutter dan terintegrasi dengan Supabase sebagai backend, dan dapat dijalankan di mobile, desktop, maupun web (misalnya via GitHub Pages).

## Fitur Utama

- **Autentikasi berbasis NRP**
  - Login menggunakan NRP dan password karyawan.
  - Menyimpan sesi login menggunakan `SharedPreferences`.

- **Beranda (Dashboard)**
  - Ringkasan total insentif lembur dan premi per tahun.
  - Kartu profil karyawan (nama, NRP, jabatan, group).
  - Ringkasan data pribadi: nomor HP/WA, ukuran baju, celana, dan sepatu.
  - Tombol refresh untuk memuat ulang data dari Supabase.

- **Cuti**
  - Pengajuan cuti tahunan dan alasan penting.
  - Riwayat cuti per tahun.
  - Kalender cuti seluruh karyawan.
  - Halaman rekap “Semua Data Cuti”.
  - Cetak / download formulir cuti dalam bentuk PDF.

- **Eksepsi Presensi**
  - Pengajuan eksepsi (perubahan jam hadir/pulang).
  - Riwayat eksepsi.
  - Halaman rekap “Semua Data Eksepsi”.
  - Dokumen eksepsi dalam bentuk PDF dengan tanda tangan digital.

- **Insentif**
  - Halaman insentif lembur dan premi untuk karyawan.
  - Halaman rekap “Semua Data Insentif”.
  - Import data insentif dari file dan tampilan rekap per tahun.

- **Surat Keluar**
  - Manajemen arsip surat keluar (view dan pencarian data).

- **Data Management**
  - Manajemen data master:
    - Pegawai
    - Group
    - Jabatan (beserta permission akses menu)
    - Supervisor
  - Export data pegawai ke file **Excel (.xlsx)**.
    - Di web: file diunduh langsung via browser.
    - Di mobile/desktop: file disimpan di storage dan dibuka dengan aplikasi Excel yang tersedia.

- **Data Pribadi Karyawan**
  - Halaman khusus untuk mengubah:
    - Nomor HP / WA
    - Ukuran baju (bebas teks)
    - Ukuran celana
    - Ukuran sepatu
  - Nomor HP disimpan dalam format Indonesia standar **62xxxxxxxxxx** (contoh: `6285183293351`), walaupun user mengisi dengan variasi seperti `0851…`, `+6285…`, dll.

## Teknologi yang Digunakan

- **Flutter** (SDK minimal sesuai `pubspec.yaml`, saat ini `>=3.5.0 <4.0.0`)
- **Dart 3**
- **Supabase** (`supabase_flutter`)
- **GetX** untuk state management dan navigasi
- **Excel** (`excel` package) untuk export `.xlsx`
- **PDF & printing** (`pdf`, `printing`) untuk generate dan preview PDF
- **File & share utilities**
  - `open_filex`, `path_provider`, `share_plus`, `file_picker`

## Struktur Penting

- `lib/controller/`
  - `login_controller.dart` – logika login dan manajemen sesi user.
  - `home_controller.dart` – fetch ringkasan insentif dan detail user.
- `lib/page/`
  - `home_page.dart` – dashboard utama dan menu utama.
  - `cuti_page.dart` – pengajuan cuti.
  - `semua_data_cuti_page.dart` – rekap semua data cuti.
  - `eksepsi_page.dart` – pengajuan eksepsi.
  - `semua_data_eksepsi_page.dart` – rekap semua data eksepsi.
  - `insentif_page.dart` & `semua_data_insentif_page.dart` – insentif lembur/premi.
  - `data_management_page.dart` – manajemen pegawai, grup, jabatan, supervisor dan export Excel.
  - `data_pribadi_page.dart` – pengaturan kontak dan ukuran pribadi karyawan.
  - `pdf_preview_page.dart` – preview dan download dokumen PDF.
- `lib/services/`
  - `supabase_service.dart` – inisialisasi dan akses client Supabase.
  - `pdf_service.dart` – generator PDF untuk cuti dan eksepsi.
- `lib/utils/`
  - `top_toast.dart` – notifikasi toast di bagian atas layar.
  - `web_download.dart` – helper download file (PDF/Excel) di web.

## Konfigurasi Supabase

Konfigurasi Supabase diambil dari `SupabaseConfig`:

- File konfigurasi: `lib/config/supabase_config.dart`
  - Isi nilai:
    - `supabaseUrl`
    - `supabaseAnonKey`

Pastikan project Supabase memiliki tabel-tabel yang dibutuhkan, antara lain:

- `users`
- `cuti`
- `eksepsi`
- `insentif_lembur`
- `insentif_premi`
- `jabatan`
- `group`
- `supervisor`
- dan tabel pendukung lain sesuai skema yang digunakan aplikasi.

## Menjalankan Aplikasi (Development)

1. **Install dependency**

   ```bash
   flutter pub get
   ```

2. **Jalankan di emulator / device fisik**

   ```bash
   flutter run
   ```

3. **Jalankan di browser (mode web)**

   ```bash
   flutter run -d chrome
   ```

Pastikan Supabase sudah diinisialisasi (misalnya di `main.dart` memanggil `SupabaseService.initialize()` sebelum `runApp`).

## Build Web (untuk GitHub Pages atau hosting lain)

1. Build web release:

   ```bash
   flutter build web --release
   ```

2. Deploy hasil build (folder `build/web`) ke GitHub Pages atau hosting static lainnya.

   Pada repo ini, hasil build bisa disalin ke folder `docs/` agar otomatis dilayani oleh GitHub Pages.

## Catatan

- Project ini adalah aplikasi internal, sehingga konfigurasi Supabase (URL & anon key) dan detail skema database sebaiknya disesuaikan dengan lingkungan masing-masing.
- Jangan commit credential sensitif (API key, password, dsb) ke repository publik.
