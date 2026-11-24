# SCRAPCAL Design System (`DESIGN.md`)

## Visual Philosophy
- **Mode:** Operate (Spacious, Senior-Friendly Tactile Handheld Calculator)
- **Scene:** Outdoor / open-air Philippine junkshop weighing station, with both high-contrast Light Mode and low-glare Dark Mode.
- **Clamped Accessibility Scaling:** Root `MaterialApp` clamps text scaling (`minScaleFactor: 0.85`, `maxScaleFactor: 1.10`) and guards all chips, headers, and keypad keys with `Flexible` / `FittedBox(fit: BoxFit.scaleDown)` and `maxLines: 1` so large Android system fonts never break button bounds.

## Color Tokens

### Light Mode
| Token | Hex | Purpose |
|---|---|---|
| `scaffold` | `#F2FBF5` | Soft mint outdoor-readable canvas |
| `surface` | `#FFFFFF` | Calculator digit keys, ticket paper, cards |
| `headerBg` / `primary` | `#15803D` | Minimalist top bar, active scrap chip, `+ Dagdag` / `+ Add` key |
| `totalBannerBg` | `#14532D` | High-contrast Grand Total banner |
| `saveAmber` | `#D97706` | Distinct finalize `Save` button and Share action |
| `danger` | `#B91C1C` | `Ulit` / `Clear`, `Bagong Lista`, delete controls |

### Dark Mode
| Token | Hex | Purpose |
|---|---|---|
| `scaffold` | `#121212` | Deep neutral dark canvas |
| `surface` | `#1E1E1E` | Calculator keys and cards |
| `border` | `#2A2A2A` | Subtle dark borders |
| `ink` | `#FAFAFA` | Crisp primary text |
| `primary` | `#16A34A` | Active scrap chip & `+ Dagdag` / `+ Add` key |
| `saveAmber` | `#D97706` | Distinct `Save` button |

## Paper Receipt Export (`Resibo`)
- Wrapped in `RepaintBoundary` and rendered strictly as high-contrast `#FFFFFF` paper with `#111111` ink even when Dark Mode is active, captured at `pixelRatio: 3.0` to PNG for native Android MediaStore Gallery saving and Share Sheet export.
