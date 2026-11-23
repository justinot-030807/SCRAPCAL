# SCRAPCAL Design System (`DESIGN.md`)

## Visual Philosophy
- **Mode:** Operate (Tactile Handheld Printing Calculator)
- **Scene:** Outdoor / open-air Philippine junkshop weighing station under direct sunlight.
- **Appearance:** High-contrast Light Mode only (`#FAFAFA` scaffold, `#FFFFFF` keys/tape, `#111111` primary ink, `#E4E4E7` 1px hairline borders).

## Color Tokens
| Token | Hex | Purpose |
|---|---|---|
| `AppColors.scaffold` | `#FAFAFA` | Main screen background & Android window launch background |
| `AppColors.surface` | `#FFFFFF` | Calculator keys, ticket tape paper, and cards |
| `AppColors.keySecondary` | `#F4F4F5` | Quick-add increment keys, secondary controls, tape header |
| `AppColors.ink` | `#111111` | Primary text, active chip fill, primary `SAVE` key |
| `AppColors.inkSecondary` | `#52525B` | Unit rates, timestamps, section headers |
| `AppColors.inkMuted` | `#71717A` | Empty state hints and input placeholders |
| `AppColors.border` | `#E4E4E7` | 1px hairline key borders and list dividers |
| `AppColors.danger` | `#DC2626` | Clear (`C`), Reset ticket, and delete actions |

## Typography & Numerals
- All numerical values, weights, piece counts, timestamps, and `₱` currency figures enforce `FontFeature.tabularFigures()` so digits align vertically in running tapes and live subtotals without horizontal jitter.

## Tactile & Ergonomic Rules
- Single-screen non-scrolling keypad layout: Header (`48dp`), Ticket Tape & Live Display (`Expanded`), Scrap Selector Strip (`40dp`), Context-Aware Quick-Add Row (`38dp`), and 4-Column Numpad (`Expanded`).
- Every keypad, quick-add, and chip interaction triggers `HapticFeedback.lightImpact()`.
