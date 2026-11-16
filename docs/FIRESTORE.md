# Firestore setup (SiMoney)

Project: `finance-e346c` (Spark / free tier)

## 1. Enable Firestore

Firebase Console → Build → Firestore Database → Create database → Production mode → choose region.

## 2. Deploy security rules

From project root (Firebase CLI already installed):

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
firebase login   # if needed
firebase deploy --only firestore:rules
```

Rules file: [`firestore.rules`](firestore.rules)

## 3. Auth providers

Authentication → Sign-in method → enable **Google** only (email/password tidak dipakai di app).

Android: add SHA-1 debug fingerprint for Google Sign-In.

## 4. Verify

1. User A: login → buka tab **Akun** → **Buat buku kas** → tambah transaksi  
2. User A: buat ledger kedua, lalu **switch ledger** di tab Akun → data transaksi berubah sesuai ledger aktif (F10)  
3. Copy invite code dari Akun → Undang anggota → User B **Gabung** (kode)  
4. User B menambah transaksi ke ledger aktif → User A melihat **snackbar in-app realtime** (F11)  
5. User A: tab Akun → **Export CSV** → file berisi **semua transaksi all-time** pada ledger aktif (F12)  
6. User non-creator kategori custom tidak bisa menghapus kategori pihak lain (rules bekerja)

## 7. Skema tabungan (`ledgers/{id}/savingsGoals`)

Dua jenis target berbagi satu koleksi. Field baru bersifat opsional, jadi
dokumen lama (tanpa field ini) terbaca sebagai target akhir biasa tanpa inflasi.
`firestore.rules` tidak perlu diubah: anggota ledger sudah boleh menulis dokumen
ini dan rules tidak memvalidasi isi field.

| Field | Tipe | Keterangan |
|---|---|---|
| `kind` | `target` \| `periodic` | Jenis target. Default `target`. |
| `targetAmount` | int | Target akhir: nominal pada harga `priceDate`. Target berkala: `0`. |
| `targetDate` | timestamp? | Tenggat target akhir. Target berkala: `null`. |
| `periodicAmount` | int? | Target berkala: nominal tetap per periode. |
| `periodUnit` | `day` \| `week` \| `month` | Target berkala: periode menabung. |
| `startDate` | timestamp? | Target berkala: awal periode pertama (konsistensi dihitung sejak ini). |
| `adjustForInflation` | bool | Target akhir: naikkan nominal sesuai inflasi. Target berkala: tampilkan nilai daya beli. |
| `inflationRate` | number? | Persen per tahun. `null` = otomatis menurut tenor. |
| `expectedReturn` | number | Imbal hasil tempat menabung, persen per tahun. Default `0`. |
| `priceDate` | timestamp? | Tanggal `targetAmount` dipatok; inflasi dihitung sejak tanggal ini. Berubah saat nominal diedit. |

Konvensi hitungan: 1 tahun = 365 hari, 1 bulan = 365/12 hari, sehingga hari,
minggu, bulan, dan tahun saling konsisten. Data inflasi (BPS/BI) disimpan di
`lib/state/inflation_data.dart` dan diperbarui manual tiap BPS merilis data baru.
