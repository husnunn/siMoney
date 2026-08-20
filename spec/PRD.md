# Product Requirements Document (PRD)
## Aplikasi Pencatatan Keuangan Bersama

**Versi:** 1.0
**Tanggal:** 28 Juli 2026
**Pemilik Produk:** -

---

## 1. Latar Belakang & Tujuan

Aplikasi ini dibuat untuk mencatat pemasukan dan pengeluaran secara sederhana, dengan kemampuan satu buku kas (ledger) diisi oleh lebih dari satu pengguna secara realtime. Cocok digunakan untuk mengelola keuangan bersama pasangan, keluarga, atau kelompok kecil (misal kos bersama, patungan).

### Tujuan Utama
- Memudahkan pencatatan transaksi keuangan harian tanpa ribet.
- Memberi gambaran jelas mengenai selisih pemasukan dan pengeluaran.
- Memungkinkan beberapa orang mencatat ke buku kas yang sama secara transparan.

### Tujuan yang TIDAK ingin dicapai (Out of Scope untuk MVP)
- Integrasi dengan rekening bank / e-wallet otomatis (open banking).
- Fitur investasi atau tracking aset.
- Fitur budgeting/anggaran otomatis dengan AI.
- Mode offline penuh (MVP mengasumsikan koneksi internet tersedia).

---

## 2. Target Pengguna

| Persona | Deskripsi | Kebutuhan Utama |
|---|---|---|
| Individu | Mencatat keuangan pribadi | Simpel, cepat input |
| Pasangan/Keluarga | Kelola keuangan bersama | Transparansi, realtime, siapa input apa |
| Kelompok kecil (kos, patungan) | Catat kas bersama | Multi-user, riwayat jelas |

---

## 3. Platform

- **Android** dan **iOS** (aplikasi mobile cross-platform).
- Tidak ada rencana versi web/desktop di MVP.

---

## 4. Fitur Produk

### 4.1 MVP (Prioritas Tinggi — Wajib Ada)

| ID | Fitur | Deskripsi |
|---|---|---|
| F1 | Autentikasi | Registrasi & login (email/password, opsional Google Sign-In) |
| F2 | Buat Ledger | User dapat membuat "buku kas" baru dengan nama tertentu |
| F3 | Undang Member | Owner ledger bisa mengundang user lain via kode/link untuk join ledger yang sama |
| F4 | Tambah Transaksi | Input pemasukan atau pengeluaran: nominal, kategori, tanggal, catatan |
| F5 | Daftar Transaksi | Menampilkan seluruh transaksi dalam ledger (realtime, urut waktu terbaru), lengkap dengan nama user yang menginput |
| F6 | Ringkasan Saldo | Menampilkan total pemasukan, total pengeluaran, dan selisih (saldo) — bisa difilter per bulan |
| F7 | Edit/Hapus Transaksi | User dapat mengubah/menghapus transaksi yang ia buat sendiri |
| F8 | Kategori Transaksi | Daftar kategori default (Makan, Transport, Gaji, dll) + bisa tambah kategori custom |

### 4.2 Fase 2 (Setelah MVP Berjalan)

| ID | Fitur | Deskripsi |
|---|---|---|
| F9 | Grafik & Laporan | Visualisasi pengeluaran per kategori (pie chart), tren bulanan (line/bar chart) |
| F10 | Multi-Ledger | User bisa punya lebih dari satu ledger (misal: pribadi + keluarga) dan berpindah antar ledger |
| F11 | Notifikasi | Notifikasi realtime saat member lain menambah transaksi |
| F12 | Export Data | Export riwayat transaksi ke CSV/PDF |
| F13 | Role & Permission | Owner ledger bisa atur siapa boleh edit/hapus transaksi orang lain |

### 4.3 Ide Masa Depan (Belum Diprioritaskan)

- Target/goal nabung bersama.
- Reminder input transaksi harian.
- Split bill / pembagian tagihan otomatis antar member.
- Mode gelap (dark mode).

---

## 5. User Stories (MVP)

1. **Sebagai pengguna baru**, saya ingin mendaftar dan login, agar data saya tersimpan dan aman.
2. **Sebagai pengguna**, saya ingin membuat ledger baru, agar saya punya tempat mencatat transaksi.
3. **Sebagai owner ledger**, saya ingin mengundang orang lain ke ledger saya, agar kami bisa mencatat bersama.
4. **Sebagai anggota ledger**, saya ingin menambahkan transaksi pemasukan/pengeluaran, agar catatan keuangan selalu update.
5. **Sebagai anggota ledger**, saya ingin melihat siapa yang menginput setiap transaksi, agar tetap transparan.
6. **Sebagai anggota ledger**, saya ingin melihat total saldo (pemasukan − pengeluaran), agar tahu kondisi keuangan saat ini.
7. **Sebagai anggota ledger**, saya ingin mengedit atau menghapus transaksi yang saya buat, jika ada kesalahan input.

---

## 6. Kebutuhan Non-Fungsional

| Aspek | Kebutuhan |
|---|---|
| Performa | Sinkronisasi transaksi antar user maksimal ~2 detik (realtime) |
| Keamanan | Data ledger hanya bisa diakses oleh member yang diundang; autentikasi wajib |
| Skalabilitas | Mendukung minimal 10 member per ledger, ribuan transaksi per ledger |
| Ketersediaan | Aplikasi membutuhkan koneksi internet (belum ada mode offline di MVP) |
| Kompatibilitas | Android 8+ dan iOS 14+ |

---

## 7. Model Data (Ringkas)

```
User
 - id, nama, email

Ledger
 - id, nama, ownerId, daftar memberId

Transaction
 - id, ledgerId, type (income/expense), amount,
   category, note, createdBy (userId), createdAt
```

Saldo ledger = Σ(income) − Σ(expense) dari seluruh transaksi dalam ledger tersebut.

---

## 8. Metrik Keberhasilan (Success Metrics)

Karena ini untuk pemakaian pribadi/kelompok kecil (bukan produk komersial), metrik lebih ke arah kualitas pemakaian:

- Setiap transaksi tercatat dan tersinkron ke semua member dalam < 2 detik.
- Tidak ada data hilang/duplikat saat 2 user input bersamaan.
- Waktu input 1 transaksi < 15 detik dari buka app.

---

## 9. Risiko & Batasan

- **Konflik data**: dua user input transaksi hampir bersamaan — perlu dipastikan Firestore/backend menangani secara atomik (tidak overwrite).
- **Privasi**: pastikan security rules ketat agar ledger hanya bisa diakses member yang diundang, bukan sembarang user.
- **Belum offline-first**: jika tanpa internet, user belum bisa mencatat (jadi risiko untuk pemakaian di lokasi tanpa sinyal).

---

## 10. Rencana Rilis (Sugesti)

| Tahap | Ruang Lingkup | Estimasi |
|---|---|---|
| Sprint 1 | Auth + buat ledger + undang member | 1 minggu |
| Sprint 2 | Tambah/list/edit/hapus transaksi | 1 minggu |
| Sprint 3 | Ringkasan saldo + kategori | 3-4 hari |
| Sprint 4 | Polish UI, testing, rilis internal (MVP selesai) | 3-4 hari |

*(Estimasi bisa disesuaikan dengan waktu luang kamu sebagai developer solo.)*