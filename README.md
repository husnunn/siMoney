<p align="center">
  <img src="Logo SiMoney.png" width="120" alt="SiMoney logo">
</p>

<h1 align="center">SiMoney</h1>

<p align="center">
  <b>Keuangan bersama, sederhana.</b><br>
  <sub>Shared finances, made simple.</sub>
</p>

<p align="center">
  🇮🇩 <a href="#bahasa-indonesia">Bahasa Indonesia</a> | 🇬🇧 <a href="#english">English</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Firestore-Realtime-orange?style=flat&logo=firebase&logoColor=white" alt="Firestore">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?style=flat&logo=android&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/License-Personal%20Project-lightgrey?style=flat" alt="License">
</p>

---

## Bahasa Indonesia

### Tentang

**SiMoney** adalah aplikasi pencatatan keuangan bersama berbasis Flutter. Aplikasi ini dibuat untuk mencatat pemasukan dan pengeluaran secara sederhana, dengan satu buku kas (*ledger*) yang bisa diisi oleh lebih dari satu pengguna secara realtime — cocok untuk mengelola keuangan pasangan, keluarga, atau kelompok kecil (kos bersama, patungan, dll).

Setiap transaksi yang dicatat oleh satu anggota langsung tersinkron ke seluruh anggota ledger lain melalui Cloud Firestore, lengkap dengan informasi siapa yang menginput — sehingga pencatatan tetap transparan.

### Fitur Utama

- **Autentikasi** — masuk dengan email/password atau Google Sign-In.
- **Buku Kas (Ledger) Bersama** — buat ledger baru atau gabung ke ledger milik orang lain lewat kode undangan.
- **Kelola Anggota** — undang anggota lain ke dalam ledger yang sama.
- **Catat Transaksi** — tambah, edit, dan hapus transaksi pemasukan/pengeluaran lengkap dengan nominal, kategori, dan catatan.
- **Riwayat Realtime** — daftar transaksi terurut waktu, menampilkan nama anggota yang menginput setiap transaksi.
- **Kategori** — kategori bawaan (Makan, Transport, Gaji, Tagihan, dll) ditambah kategori custom buatan pengguna.
- **Ringkasan & Analitik** — ringkasan saldo (pemasukan − pengeluaran) per periode (harian/mingguan/bulanan) serta breakdown kategori dalam bentuk donut chart dan ranking kategori.
- **Target Tabungan** — dua jenis target bersama dalam dua tab, dengan catatan setor/tarik dan progres:
  - **Target Akhir** — kumpulkan sejumlah uang sampai tenggat. Aplikasi menghitung berapa yang perlu ditabung per hari, minggu, bulan, dan tahun; bisa disesuaikan dengan inflasi Indonesia (data BPS/BI, otomatis menurut tenor atau skenario rendah/dasar/tinggi) dan imbal hasil opsional. Dilengkapi grafik proyeksi saldo vs harga, perbandingan tenor, dan kalkulator "kapan tercapai".
  - **Target Berkala** — nabung dengan nominal tetap per hari/minggu/bulan tanpa tenggat (mis. Rp120.000 per minggu). Aplikasi menghitung setaranya per hari/minggu/bulan/tahun, proyeksi 1 bulan sampai 10 tahun (termasuk nilai daya beli), serta konsistensi (beruntun, terlewat, kekurangan dari jadwal).
- **Ekspor Data** — ekspor riwayat transaksi ke CSV dan bagikan lewat fitur share bawaan perangkat.
- **Privasi Saldo** — tombol untuk menyembunyikan/menampilkan nominal saldo di layar utama.

### Teknologi & Arsitektur

- **Flutter & Dart** — UI Material 3 (`uses-material-design`), font kustom via `google_fonts`.
- **State Management** — `AppStore` kustom berbasis `ChangeNotifier` (`lib/state/app_store.dart`) yang mendengarkan stream Firestore secara realtime; tanpa dependensi paket state management eksternal (Provider/Riverpod/Bloc).
- **Firebase**
  - `firebase_auth` + `google_sign_in` untuk autentikasi.
  - `cloud_firestore` sebagai database realtime (ledger, transaksi, kategori, target tabungan, kontribusi).
- **Pola Arsitektur** — pemisahan layer yang jelas: `models/` (entity + mapping Firestore), `services/` (repository per entitas: `LedgerRepository`, `TransactionRepository`, `CategoryRepository`, `SavingsRepository`, `UserRepository`), `state/` (store & kalkulator analitik/tabungan), `screens/` (per fitur: auth, onboarding, flow, savings, analytics, account), `widgets/` (komponen UI reusable), `theme/` (token warna & spacing).
- **Keamanan Data** — aturan akses di `firestore.rules` memastikan ledger hanya bisa diakses anggotanya, transaksi hanya bisa diedit/dihapus oleh pembuatnya, dan kontribusi tabungan bersifat *immutable* setelah dibuat.
- **Lainnya** — `share_plus` untuk ekspor/share CSV, `flutter_launcher_icons` untuk ikon aplikasi.

### Platform yang Didukung

Target utama aplikasi adalah **Android** dan **iOS** (konfigurasi Firebase nyata tersedia untuk kedua platform ini di `lib/firebase_options.dart`). Folder `macos/`, `windows/`, `linux/`, dan `web/` merupakan scaffolding bawaan Flutter dan belum menjadi target rilis.

### Struktur Proyek

```
lib/
├── main.dart              # Entry point, routing, splash screen
├── firebase_options.dart  # Konfigurasi Firebase per platform
├── models/                # Entity: User, Ledger, Transaction, Category, Savings
├── services/              # Repository Firestore & auth service
├── state/                 # AppStore (ChangeNotifier) + kalkulator analitik/tabungan
├── screens/               # Layar per fitur (auth, onboarding, flow, savings, analytics, account, dll)
├── widgets/                # Komponen UI reusable (chart, kartu, tombol, dll)
├── theme/                 # Warna, spacing, tipografi
└── utils/                 # Formatter & utilitas lain

design-system/   # Dokumentasi design system (palet warna, tipografi, dial desain)
docs/, spec/     # PRD & dokumentasi skema Firestore
referensi/       # Rujukan desain HTML per layar
```

### Cara Menjalankan

**Prasyarat:** Flutter SDK (channel stable, Dart `^3.12.2`), akun Firebase dengan project Firestore + Authentication aktif.

```bash
# 1. Install dependencies
flutter pub get

# 2. Siapkan Firebase (jika belum punya konfigurasi sendiri)
#    Hubungkan project lewat FlutterFire CLI:
flutterfire configure

# 3. Jalankan aplikasi (pilih device Android/iOS)
flutter run
```

Pastikan `firestore.rules` dan `firestore.indexes.json` sudah di-deploy ke project Firebase kamu:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### Kontak

- GitHub: [github.com/husnunn](https://github.com/husnunn)
- Email: [muhammadhusnunniam20@gmail.com](mailto:muhammadhusnunniam20@gmail.com)

---

## English

### About

**SiMoney** is a Flutter-based shared finance tracking app. It was built to log income and expenses simply, with a single ledger that can be shared by more than one user in realtime — ideal for managing finances as a couple, a family, or a small group (shared boarding house, pooled funds, etc).

Every transaction logged by one member syncs instantly to the rest of the ledger's members via Cloud Firestore, along with who recorded it — keeping the bookkeeping transparent.

### Key Features

- **Authentication** — sign in with email/password or Google Sign-In.
- **Shared Ledger** — create a new ledger or join an existing one via an invite code.
- **Member Management** — invite other users into the same ledger.
- **Transaction Logging** — add, edit, and delete income/expense entries with amount, category, and notes.
- **Realtime History** — chronological transaction list showing which member logged each entry.
- **Categories** — default categories (Food, Transport, Salary, Bills, etc.) plus user-created custom categories.
- **Summary & Analytics** — balance summary (income − expense) filterable by day/week/month, with category breakdowns shown as a donut chart and ranked list.
- **Savings Goals** — two kinds of shared goals in two tabs, with deposit/withdrawal logging and progress:
  - **Target Akhir (final target)** — reach a total amount by a deadline. The app works out what to save per day, week, month and year; it can adjust for Indonesian inflation (BPS/BI data, automatic by horizon or low/base/high scenarios) and an optional yield. Includes a balance-vs-price projection chart, a tenor comparison and a "when is it reached" calculator.
  - **Target Berkala (periodic target)** — save a fixed amount per day/week/month with no deadline (e.g. Rp120,000 per week). The app derives the per-day/week/month/year equivalents, projections from 1 month to 10 years (including purchasing power) and consistency (streak, missed periods, gap to schedule).
- **Data Export** — export transaction history to CSV and share it via the device's native share sheet.
- **Balance Privacy** — a toggle to hide/show the balance amount on the home screen.

### Tech Stack & Architecture

- **Flutter & Dart** — Material 3 UI (`uses-material-design`), custom fonts via `google_fonts`.
- **State Management** — a hand-rolled `AppStore` built on `ChangeNotifier` (`lib/state/app_store.dart`) that listens to Firestore streams in realtime; no external state management package (no Provider/Riverpod/Bloc).
- **Firebase**
  - `firebase_auth` + `google_sign_in` for authentication.
  - `cloud_firestore` as the realtime database (ledgers, transactions, categories, savings goals, contributions).
- **Architecture Pattern** — a clear layered separation: `models/` (entities + Firestore mapping), `services/` (one repository per entity: `LedgerRepository`, `TransactionRepository`, `CategoryRepository`, `SavingsRepository`, `UserRepository`), `state/` (the store plus analytics/savings calculators), `screens/` (grouped by feature: auth, onboarding, flow, savings, analytics, account), `widgets/` (reusable UI components), `theme/` (color & spacing tokens).
- **Data Security** — access rules in `firestore.rules` ensure a ledger is readable only by its members, transactions can only be edited/deleted by their creator, and savings contributions are immutable once written.
- **Other** — `share_plus` for CSV export/sharing, `flutter_launcher_icons` for app icon generation.

### Supported Platforms

The app's primary targets are **Android** and **iOS** (real Firebase configuration exists for both in `lib/firebase_options.dart`). The `macos/`, `windows/`, `linux/`, and `web/` folders are default Flutter scaffolding and are not current release targets.

### Project Structure

```
lib/
├── main.dart              # Entry point, routing, splash screen
├── firebase_options.dart  # Per-platform Firebase configuration
├── models/                # Entities: User, Ledger, Transaction, Category, Savings
├── services/              # Firestore repositories & auth service
├── state/                 # AppStore (ChangeNotifier) + analytics/savings calculators
├── screens/               # Feature screens (auth, onboarding, flow, savings, analytics, account, etc.)
├── widgets/                # Reusable UI components (charts, cards, buttons, etc.)
├── theme/                 # Colors, spacing, typography
└── utils/                 # Formatters & other utilities

design-system/   # Design system docs (color palette, typography, design dials)
docs/, spec/     # PRD & Firestore schema documentation
referensi/       # HTML design references per screen
```

### Getting Started

**Prerequisites:** Flutter SDK (stable channel, Dart `^3.12.2`), a Firebase project with Firestore + Authentication enabled.

```bash
# 1. Install dependencies
flutter pub get

# 2. Set up Firebase (if you don't already have your own config)
#    Connect the project via the FlutterFire CLI:
flutterfire configure

# 3. Run the app (pick an Android/iOS device)
flutter run
```

Make sure `firestore.rules` and `firestore.indexes.json` are deployed to your own Firebase project:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### Contact

- GitHub: [github.com/husnunn](https://github.com/husnunn)
- Email: [muhammadhusnunniam20@gmail.com](mailto:muhammadhusnunniam20@gmail.com)
