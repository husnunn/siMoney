# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** SiMoney
**Generated:** 2026-07-28
**Category:** Personal Finance Tracker (shared ledger)
**Design Dials:** Variance 3/10 (Centered / Minimal) | Motion 3/10 (Subtle) | Density 4/10 (Standard)
**Mode:** Light only (dark mode out of scope for MVP)

---

## Global Rules

### Color Palette (Banking Light)

| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#0F172A` | CTA, app bar, FAB, primary text |
| On Primary | `#FFFFFF` | Text on primary |
| Accent | `#1E40AF` | Links, focus ring, selected chips |
| Background | `#F8FAFC` | Screen background |
| Surface | `#FFFFFF` | Cards, sheets, inputs |
| Foreground | `#020617` | Body text |
| Muted | `#64748B` | Secondary text, captions |
| Border | `#E2E8F0` | Dividers, input borders |
| Income | `#059669` | Pemasukan amounts |
| Expense | `#DC2626` | Pengeluaran amounts |
| Destructive | `#DC2626` | Delete actions |
| Muted Surface | `#E8ECF1` | Chip backgrounds, subtle fills |

**Color Notes:** Trust navy + soft slate background. Avoid pure white full-bleed screens; use `#F8FAFC`.

### Typography

- **Heading Font:** IBM Plex Sans (600–700)
- **Body Font:** IBM Plex Sans (400–500)
- **Mood:** financial, trustworthy, professional, calm
- **Balance hero:** 32–40px, weight 600, letter-spacing slight negative

### Spacing Variables

*Density: 4/10 — Standard*

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | `4px` | Tight gaps |
| `--space-sm` | `8px` | Icon gaps, inline spacing |
| `--space-md` | `16px` | Standard padding |
| `--space-lg` | `24px` | Section padding |
| `--space-xl` | `32px` | Large gaps |
| `--space-2xl` | `48px` | Section margins |

### Style

- **Pattern:** Minimal single column with bottom navigation (4 tabs)
- **Bottom nav:** Beranda · Pemasukan · Pengeluaran · Akun (logout di Akun)
- **Motion:** 200–300ms fade/slide page transitions
- **Icons:** Material outline only — no emoji as icons
- **Language:** Indonesian UI copy

### Avoid (Anti-patterns)

- Pure white backgrounds without soft depth
- Purple/glow generic AI aesthetics
- Card stacking in balance hero
- More than 5 bottom nav destinations
- Placeholder-only form labels
- Hiding logout only in overflow menus

---

## Screen Map (MVP)

1. Login (Google Sign-In only)
2. Buat / Gabung Ledger
3. Main shell (bottom nav)
   - Beranda: saldo + semua transaksi + FAB
   - Pemasukan: total + list filter income
   - Pengeluaran: total + list filter expense
   - Akun: profil, undang, kategori, keluar
4. Tambah / Edit Transaksi
5. Undang Member
6. Kelola Kategori
