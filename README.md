# SCRAPCAL

**SCRAPCAL** is a fast, lightweight, 100% offline native Android junkshop calculator built with **Flutter (Dart)**. It launches straight into a high-contrast, sunlight-readable calculator screen with zero login, zero onboarding, and zero network dependencies.

---

## Core Features

- **Instant Launch & 100% Offline-First:** Opens directly to the calculator with `#FAFAFA` Android launch theme background. All scrap items, prices, running tickets, and transaction history are stored locally via `shared_preferences`.
- **Pre-Seeded Philippine Junkshop Defaults (`₱`):**
  - **Bakal** — `₱15.00 / kg`
  - **Plastic** — `₱10.00 / kg`
  - **Tanso** — `₱350.00 / kg`
  - **Bote** — `₱1.00 / piraso (pc)` — counted by piece, not weighed by kilo.
- **Context-Aware Quick-Add Row:**
  - **Per Kilo (`kg`):** Fractional weight increment keys (`+1/4` / `+0.25`, `+1/2` / `+0.50`, `+3/4` / `+0.75`, `+1` / `+1.00`) with automatic fraction labels (`¼`, `½`, `¾`, `1¼`).
  - **Per Piraso (`pc`):** Automatically switches to whole-piece increment keys (`+1`, `+5`, `+10`, `+20`) and disables the decimal point key (`.`).
- **Running Ticket Tape & Live Display:**
  - View itemized customer lines (`Bakal · 1.25 kg (1¼) × ₱15.00 = ₱18.75`), remove individual entries with `×`, append multiple scrap types with `+ DAGDAG`, and finalize payouts with `SAVE`.
- **`Presyo` (Price & Scrap Manager):**
  - Edit prices inline with auto-save, toggle units (`Per Kilo (kg)` vs `Per Piraso (pcs)`), add custom scrap items (`Aluminum`, `Alloy`, `Karton`, `Yero`, `Battery`, etc.), or reset defaults.
- **`History` (Offline Transaction Ledger):**
  - Displays **Total Ngayon** (today's total payout in `₱` and transaction count) and a reverse-chronological list of itemized transactions.

---

## How to Download & Install `SCRAPCAL.apk` from GitHub Actions

Every push to `main` (or manual trigger) automatically compiles a signed, ready-to-install `SCRAPCAL.apk` via GitHub Actions:

1. Push this repository to GitHub on the `main` branch.
2. Open your repository on GitHub and click the **Actions** tab.
3. Click the latest **Build SCRAPCAL Android APK** workflow run (or click **Run workflow** to trigger one manually).
4. Scroll down to the **Artifacts** section at the bottom of the completed workflow run and click **`SCRAPCAL-apk`** to download the zip archive.
5. Extract **`SCRAPCAL.apk`**, transfer it to any Android phone (via Bluetooth, USB, Messenger, or ShareIt), and tap to install.

---

## Local Development

```bash
flutter pub get
flutter test
flutter build apk --release
```
