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
