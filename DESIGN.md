# SCRAPCAL Design System (`DESIGN.md`)

## Visual Philosophy
- **Mode:** Operate (Senior-Friendly Tactile Handheld Printing Calculator)
- **Scene:** Outdoor / open-air Philippine junkshop weighing station, tailored for older junkshop owners who need large type, unmistakable button boundaries, and zero-confusion labels.
- **Appearance:** High-contrast Green & Light Green Mode (`#F2FBF5` soft mint scaffold, `#15803D` deep emerald headers & primary actions, `#DCFCE7` light-green quick-add keys & active calculation banner, `#FFFFFF` pure white digit keys with `#0F172A` large bold numbers).

## Color Tokens
| Token | Hex | Purpose |
|---|---|---|
| `AppColors.scaffold` | `#F2FBF5` | Soft light-green screen background & Android launch background |
| `AppColors.primaryGreen` | `#15803D` | Header bar, active scrap chip fill, and primary `SAVE` key |
| `AppColors.primaryGreenDark` | `#14532D` | High-contrast dark green text on light-green buttons |
| `AppColors.lightGreenBg` | `#DCFCE7` | Quick-add increment keys, active calculation bar, summary banners |
| `AppColors.lightGreenBorder` | `#86EFAC` | Borders for green cards, chips, and quick-add buttons |
| `AppColors.surface` | `#FFFFFF` | Calculator digit keys, ticket tape paper, and item cards |
| `AppColors.ink` | `#0F172A` | Extra-sharp dark text for numbers and item names |
| `AppColors.danger` | `#B91C1C` | Clear (`BURA / C`), Reset ticket, and delete actions |

## Typography & Senior Accessibility
- **Extra-Large Numerals:** Keypad digits at `26sp` bold (`FontWeight.w800`), Grand Total at `26-28sp` black (`FontWeight.w900`), and ticket tape rows at `14.5sp` bold so older users can read without glasses.
- **Tabular Figures:** All numerical values, weights, piece counts, timestamps, and `₱` currency figures enforce `FontFeature.tabularFigures()`.
- **Clear Tagalog Guidance:** Visible action hints (`PUMILI NG KALAKAL`, `LISTAHAN NG CUSTOMER`, `BURA`, `+ DAGDAG SA LISTA`, `SAVE / TAPOS`) and a dedicated one-tap `Reset` button on the ticket box so users never rely on hidden gestures.
