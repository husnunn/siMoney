# Rencana Penyusunan SiMoney Web

Rencana langkah demi langkah dari awal sampai rilis. Semua pilihan teknologi
sengaja dikosongkan sebagai slot `[isi]`; langkah-langkahnya berlaku apa pun
teknologi yang dipilih nanti.

Acuan tampilan: mockup di https://claude.ai/artifact/31Jgr52pwU8Ro4Ttzj4FLH
(5 layar desktop dan 4 layar ponsel).

## Slot teknologi (diisi di Tahap 1)

| Slot | Pilihan | Alasan |
|---|---|---|
| Kerangka antarmuka web | `[isi]` | `[isi]` |
| Bahasa pemrograman | `[isi]` | `[isi]` |
| Autentikasi | `[isi]` | `[isi]` |
| Basis data dan sinkronisasi realtime | `[isi]` | `[isi]` |
| Hosting | `[isi]` | `[isi]` |
| Pustaka grafik | `[isi]` | `[isi]` |
| Alat uji (unit dan antarmuka) | `[isi]` | `[isi]` |
| Sumber data inflasi dan cara memperbaruinya | `[isi]` | `[isi]` |

## Keputusan yang harus diambil lebih dulu

- [ ] Data web dipakai bersama aplikasi ponsel yang sudah ada, atau terpisah.
      Keputusan ini menentukan hampir semua slot teknologi.
- [ ] Pengguna hanya kamu dan orang dekat, atau publik. Ini menentukan
      seberapa ketat Tahap 2 dan Tahap 7.
- [ ] Nasib cabang kode Flutter `claude/focused-newton-bhurl2`: dipakai sebagai
      acuan rumus saja, dilanjutkan, atau dihapus.

## Tahap 0: Kunci ruang lingkup

- [ ] Tetapkan fitur versi pertama: masuk akun, buku kas bersama dan undangan,
      transaksi, kategori, ringkasan dan analitik, tabungan dua jenis, ekspor CSV.
- [ ] Putuskan data bersama atau terpisah dengan aplikasi ponsel.
- [ ] Tetapkan mockup sebagai acuan tampilan dan catat bagian yang masih ingin
      diubah sebelum mulai membangun.
- [ ] Perbarui PRD (`docs/PRD.md` masih menyebut "tidak ada rencana versi web").

**Selesai bila:** ada satu dokumen ruang lingkup yang disetujui.

## Tahap 1: Keputusan teknis

- [ ] Isi tabel slot teknologi, satu baris alasan per pilihan.
- [ ] Tentukan struktur folder dan pemisahan lapisan: data, logika hitung, tampilan.
- [ ] Tulis konvensi hitungan sebagai aturan tetap:
  - 1 tahun = 365 hari, 1 bulan = 365/12 hari.
  - Aturan pembulatan rupiah untuk tampilan.
  - Inflasi dihitung sejak tanggal harga ditetapkan, bukan sejak hari ini.
- [ ] Siapkan repositori, cabang kerja, dan pemeriksaan otomatis (analisis kode
      dan uji) di setiap perubahan.

**Selesai bila:** proyek kosong bisa dibangun dan diuji secara otomatis.

## Tahap 2: Model data dan keamanan

- [ ] Rancang skema: pengguna, buku kas, anggota, transaksi, kategori, target
      tabungan, setoran/tarikan.
- [ ] Field target tabungan: jenis (akhir/berkala), nominal, tenggat, nominal
      per periode, periode, tanggal mulai, saklar inflasi, tingkat inflasi
      (kosong = otomatis), imbal hasil, tanggal harga.
- [ ] Tulis aturan akses: hanya anggota yang boleh membaca dan menulis buku kas;
      transaksi hanya diubah pembuatnya.
- [ ] Perbaiki celah undangan di aturan lama (`firestore.rules`): pengguna yang
      sudah masuk bisa menambahkan dirinya ke buku kas mana pun tanpa
      membuktikan punya kode. Proses gabung harus memverifikasi kode.
- [ ] Uji aturan akses dengan skenario "orang luar mencoba membaca/bergabung".

**Selesai bila:** semua uji aturan akses lulus, termasuk skenario penyusup.

## Tahap 3: Mesin hitung tabungan (tanpa tampilan)

- [ ] Konversi periode: nominal per hari/minggu/bulan menjadi keempat periode.
- [ ] Target Akhir: target setelah inflasi, setoran yang dibutuhkan per periode,
      pengaruh imbal hasil, selisih terhadap laju setoran terkini, perbandingan
      tenor, "kapan tercapai".
- [ ] Target Berkala: proyeksi 1 bulan sampai 10 tahun, nilai daya beli,
      konsistensi (beruntun, terlewat, kekurangan dari jadwal).
- [ ] Data inflasi: deret tahunan, angka terkini, asumsi otomatis menurut
      tenor, tiga skenario (rendah, dasar, tinggi).
- [ ] Tulis uji dengan angka harapan yang dihitung terpisah. Versi Dart di
      `lib/state/planning/` pada cabang `claude/focused-newton-bhurl2` bisa
      menjadi acuan rumus dan kasus uji.

**Selesai bila:** semua rumus teruji dan hasilnya cocok dengan angka di mockup.

## Tahap 4: Fondasi aplikasi

- [ ] Masuk dan keluar akun; penjagaan halaman yang butuh login.
- [ ] Kerangka tata letak: sidebar di layar lebar, navigasi bawah di ponsel.
- [ ] Token desain: warna, tipografi, jarak, radius, sesuai mockup.
- [ ] Komponen dasar: tombol, kartu, kolom isian nominal, pil status, kisi
      empat periode, keadaan kosong/memuat/galat.
- [ ] Buat/gabung buku kas, pindah buku kas, undang anggota.

**Selesai bila:** dua akun bisa masuk dan berbagi satu buku kas.

## Tahap 5: Fitur inti keuangan

- [ ] Tambah, ubah, hapus transaksi; daftar realtime dengan nama pencatat.
- [ ] Kategori bawaan dan kategori buatan sendiri.
- [ ] Beranda: saldo, pemasukan, pengeluaran, transaksi terkini.
- [ ] Halaman Pemasukan dan Pengeluaran dengan filter harian/mingguan/bulanan.
- [ ] Analitik per kategori.
- [ ] Ekspor CSV sebagai unduhan berkas.

**Selesai bila:** setara dengan aplikasi ponsel untuk bagian non-tabungan.

## Tahap 6: Tabungan

- [ ] Halaman Tabungan dengan dua tab dan ringkasan per tab.
- [ ] Form target baru: pilih jenis, isian berbeda per jenis, pratinjau
      hitungan langsung.
- [ ] Setor dan tarik, termasuk sumber dana (saldo aplikasi atau eksternal).
- [ ] Detail Target Akhir: setoran per periode, asumsi, rincian, grafik,
      perbandingan tenor, "kapan tercapai".
- [ ] Detail Target Berkala: setara per periode, simulasi, proyeksi,
      konsistensi, riwayat.
- [ ] Aturan status: target akhir selesai saat saldo menutup harga saat ini;
      target berkala tidak pernah selesai otomatis.
- [ ] Arsip, aktifkan kembali, hapus.

**Selesai bila:** setiap layar mockup punya padanan yang berfungsi dengan data nyata.

## Tahap 7: Kualitas

- [ ] Responsif: uji di lebar 320, 390, 768, 1280, dan 1440 piksel.
- [ ] Aksesibilitas: navigasi papan ketik, kontras teks, ukuran sentuh minimal
      44 piksel, teks tetap rapi saat huruf diperbesar.
- [ ] Uji antarmuka untuk alur utama: masuk, catat transaksi, buat kedua jenis
      target, setor.
- [ ] Uji dua pengguna bersamaan: sinkronisasi berjalan dan tidak ada data ganda.
- [ ] Cocokkan data inflasi 2016–2022 ke bps.go.id (saat riset, angka itu
      diambil dari media yang mengutip BPS, belum dari sumber langsung).
- [ ] Tambahkan catatan "simulasi, bukan nasihat keuangan" di layar proyeksi.

**Selesai bila:** tidak ada temuan terbuka yang menghalangi rilis.

## Tahap 8: Rilis dan pemeliharaan

- [ ] Rilis ke lingkungan uji dan coba dengan data asli selama beberapa hari.
- [ ] Rilis ke publik dan pasang pemantauan galat.
- [ ] Tetapkan rutinitas bulanan memperbarui angka inflasi setelah rilis BPS.
- [ ] Perbarui README, PRD, dan dokumen skema.
- [ ] Sinkronkan aplikasi ponsel bila skema data berubah.

## Urutan dan ketergantungan

- Tahap 0 → 1 → 2 harus berurutan.
- Tahap 3 bisa dikerjakan paralel dengan Tahap 4 karena tidak butuh tampilan.
- Tahap 5 dan 6 butuh Tahap 4; Tahap 6 juga butuh Tahap 3.
- Tahap 7 berjalan sepanjang Tahap 5 dan 6, lalu dituntaskan sebelum Tahap 8.

## Data acuan inflasi (per 16 Nov 2026)

| Tahun | Inflasi (%) | | Tahun | Inflasi (%) |
|---|---|---|---|---|
| 2016 | 3,02 | | 2021 | 1,87 |
| 2017 | 3,61 | | 2022 | 5,51 |
| 2018 | 3,13 | | 2023 | 2,61 |
| 2019 | 2,72 | | 2024 | 1,57 |
| 2020 | 1,68 | | 2025 | 2,92 |

- Terkini: 3,23% yoy (Oktober 2026).
- Rata-rata geometrik 2016–2025: 2,86%.
- Target pemerintah dan BI 2026–2027: 2,5% ±1%.
- Asumsi otomatis menurut tenor (3,2 / 3,1 / 3,0 / 2,9%) adalah interpolasi
  rancangan, bukan angka resmi.
