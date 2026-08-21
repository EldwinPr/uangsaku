# Menjalankan opencode (GPT via CLI) — stateless & obrolan

Instruksi generik/reusable untuk menjalankan `opencode` sebagai reviewer atau sparring
partner lintas-model dari sesi Claude Code manapun. Bukan spesifik proyek ini — bisa
ditempel ke proyek lain. Kalau proyek ini nantinya punya aturan spesifik soal kapan/kenapa
dipakai (kriteria tiket tertentu, dsb.), taruh di file terpisah dan rujuk dari sini —
jangan asumsikan aturan spesifik-proyek itu sudah terdefinisi di suatu tempat sampai file
itu benar-benar dibuat.

## Prinsip dasar

- **Siapa yang menjalankan:** sesi utama Claude Code (yang punya akses Bash), bukan
  subagent read-only. Jangan tambahkan tool Bash ke subagent lain demi mengakomodasi ini.
- **Selalu verifikasi klaim opencode ke sumber asli** sebelum menerima atau menerapkannya.
  Model lain bisa salah/mengarang sama seperti model manapun — "opencode bilang X" bukan
  bukti bahwa X benar.
- **Jangan `Read` file JSON mentah hasil opencode ke context sendiri.** Outputnya bisa
  puluhan KB karena isi file yang dia baca ikut ter-echo di event `tool_use`. Selalu
  ekstrak lewat `grep`/`sed` — ambil `sessionID` dan `text` balasan akhir saja, buang sisanya.
- **Kasih pointer path + rentang baris**, bukan isi file ditempel penuh ke prompt, dan
  bukan juga "baca seluruh file" kalau section yang relevan cuma sebagian kecil.
- **Satu sesi = satu topik.** Jangan sambung sesi lama (topik A) untuk topik baru (B).
  Kalau perlu mencabang dari histori lama tanpa mengubah sesi asli, pakai `--fork`.

## Setup

Perintah dasar:

```bash
opencode run "<pesan>" --agent plan -m openai/gpt-5.6-sol --format json --title "<nama-sesi>"
```

- `--agent plan` = read-only (tidak bisa edit file). Pakai `--agent build` HANYA kalau
  eksplisit diminta untuk membuat/mengubah file.
- `--format json` menghasilkan output JSONL — jangan pernah `Read` mentah, selalu ekstrak
  (lihat bagian Ekstraksi di bawah).
- `--title` beri nama deskriptif per topik (mis. `sparring-hardware-justifikasi`,
  `audit-final-polish`) supaya mudah ditelusuri kalau perlu dilanjutkan nanti.
- `-m openai/gpt-5.6-sol` bisa diganti model lain yang tersedia di `opencode`; tujuannya
  memang model DIFFERENT dari Claude supaya blind spot-nya berbeda.
- `--variant high` bisa ditambahkan untuk reasoning effort lebih tinggi pada topik berat.

Ekstraksi `sessionID` dan teks balasan dari output JSONL (jangan `Read` filenya):

```bash
grep -o '"sessionID":"[^"]*"' out.jsonl | head -1

grep -o '"type":"text"[^}]*"text":"[^"]*\(\\.[^"]*\)*"' out.jsonl \
  | grep -o '"text":"[^"]*\(\\.[^"]*\)*"$' \
  | sed 's/^"text":"//;s/"$//' \
  | tail -1 \
  | sed 's/\\n/\n/g'
```

## Mode 1 — Obrolan (stateful, dibatasi ronde)

Dipakai untuk **tekan-uji** sesuatu sebelum difinalkan — desain, argumen, outline, draf
awal — lewat percakapan bolak-balik. **Batasi maksimal N giliran** (default 4: opencode
lempar kritik → counter/klarifikasi → opencode revisi → counter lagi, lalu berhenti apa
pun hasilnya, ambil yang terbaik yang ada). Sebutkan eksplisit di prompt kalau mau beda.

Pola yang biasanya paling bernilai: **ronde 1** opencode melempar kritik awal (sering
generik/prinsip), **ronde 2** setelah diberi konteks/constraint yang tidak dia tahu
(keputusan yang sudah final, batasan sumber daya, dll.), opencode memberi rekomendasi
jauh lebih presisi dan konkret. Dua ronde sering sudah cukup konvergen.

```bash
# Giliran 1 — mulai sesi baru, tangkap sessionID
opencode run "<peran reviewer/sparring partner + konteks proyek + pointer path (bukan
tempel isi file) + hal spesifik yang mau ditekan-uji + aturan 'JANGAN edit file apa pun'
+ batas jumlah poin jawaban>" \
  --agent plan -m openai/gpt-5.6-sol --format json --title "sparring-<topik>" \
  > /tmp/round1.jsonl 2>&1

# ekstrak sessionID + teks balasan (lihat perintah ekstraksi di atas)

# Giliran 2+ — WAJIB pakai -s <sessionID> supaya nyambung ke histori sesi yang sama
opencode run "<koreksi konteks yang dia tidak tahu + permintaan konkret/spesifik untuk
ronde ini, bukan prinsip umum lagi>" \
  -s <sessionID> --agent plan -m openai/gpt-5.6-sol --format json \
  > /tmp/round2.jsonl 2>&1
```

Setelah maksimal N giliran: rangkum jadi catatan pendek, **verifikasi tiap klaim ke
sumber aslinya**, baru terapkan yang valid. Jangan tempel transkrip mentah ke user —
laporkan poin-poin: apa yang disepakati, apa yang dikoreksi, apa yang masih terbuka.

## Mode 2 — Critique-time (stateless, sekali jalan)

Dipakai untuk **audit independen** atas sesuatu yang sudah selesai ditulis/dibuat — bukan
negosiasi, satu panggilan tanpa ronde lanjutan. Cocok dijalankan berdampingan/paralel
dengan audit dari Claude sendiri (subagent critique) untuk cross-check.

```bash
opencode run "<peran reviewer independen, sesi baru + SEMUA konteks yang dibutuhkan di
SATU prompt (pointer ke sumber kebenaran/baseline, aturan/batasan yang berlaku, file+baris
yang diaudit) + format laporan yang diminta (mis. BLOCKER/MAJOR/MINOR + lokasi + usulan
perbaikan konkret) + instruksi 'jangan mengarang, bilang tidak yakin kalau tidak yakin'>" \
  --agent plan -m openai/gpt-5.6-sol --format json --title "audit-<topik>" \
  > /tmp/audit.jsonl 2>&1
```

Karena tidak ada giliran susulan, **prompt wajib padat di awal** — beri semua konteks
sekaligus, jangan andalkan koreksi belakangan (tidak ada ronde 2 di mode ini). Setelah
dapat hasil: **verifikasi setiap BLOCKER/MAJOR ke sumber asli** sebelum menerapkan
perbaikan — jangan langsung percaya, termasuk untuk temuan yang kedengarannya masuk akal.
Kalau ada audit paralel lain (mis. subagent Claude), gabungkan temuan (dedupe manual)
jadi satu daftar sebelum melapor ke user.

## Kapan pakai yang mana

| Situasi | Mode |
|---|---|
| Draf/desain/argumen belum final, mau ditekan-uji sebelum dikunci | Obrolan (Mode 1) |
| Sesuatu sudah ditulis/dibuat, mau diaudit independen | Stateless (Mode 2) |
| Butuh opini kedua yang genuinely independen (tidak lihat riwayat) | Stateless, sesi baru |
| Butuh iterasi cepat dengan koreksi konteks bolak-balik | Obrolan, maks N giliran |

## Pengelolaan sesi

- Catat `sessionID` yang masih aktif/relevan di tempat yang persisten (mis. tracker
  proyek), bukan cuma disebut di riwayat chat — kalau context di-compact atau sesi baru
  mengambil alih, ID yang cuma ada di chat history bisa hilang.
- Setelah topik selesai, tandai sesi sebagai closed di catatan proyek (tidak perlu
  dihapus dari opencode, cukup jangan `-s` ke sesi itu lagi untuk topik lain).
