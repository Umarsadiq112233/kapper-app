# Asset accuracy and visual correction report

## Audit

The repository contained eight JPEGs, no original logo, no SVG icon set, no bundled reference font, and no hairstyle overlays. The app entry point was the Flutter counter template, while feature widgets existed separately and three files contained syntax errors. The reference images attached in chat were inspected; their macOS temporary paths are permission-protected, so they have not been copied into this repository.

## Corrections made

Connected the existing BLoC features through named routes and role-specific bottom navigation; repaired syntax; centralized the existing palette; matched the vertical purple authentication gradient; drew scissors/comb and customer role illustrations; added individual OTP boxes; changed favorites to a grid; replaced filter sliders with range inputs; replaced standard availability pickers with compact date/time/selection dialogs; retained existing service images during editing; honored reduced motion; fixed narrow-card overflow. Bundled the SDK's Apache-licensed Roboto with its license for consistent body text.

## Accuracy limits

| Asset | Current implementation | Exact source needed |
|---|---|---|
| Kapper logo | Gold Georgia text, platform fallback | Original vector logo |
| Body typography | Bundled Roboto | Reference family and weight files |
| Role illustrations | Hand-drawn Flutter paths based on reference motifs | Original vectors for precise shapes |
| Navigation/action icons | Existing outlined Material icons | Original icon set; some shapes differ |
| Salon/service/gallery photographs | Existing eight project JPEGs, aspect-preserving crop | All corresponding original design images |
| Phone background | Existing barber photo with purple overlay | Purple-lit tools image |
| Vendor background | Existing salon photo with overlay | Original collage |
| Hairstyle preview | Clearly labeled inspiration gallery | Same-subject photos, transparent hair assets, tracking technology |

No source photograph was claimed to be recovered from the small screenshots. Photos such as the nail, beauty, and hairstyle cards remain visibly different; those are not approved final asset matches. No generated image or external stock asset was added.

## Visual QA

Flutter captures are saved under test/captures. Reviewed role selection, dashboard, salon, OTP and date/time dialogs directly; these confirm real text, images, icons and controls render. All capture targets are checked for Flutter layout exceptions. This is not exhaustive manual side-by-side signoff on every state. The supplied design still differs in original assets, typography, some spacing, payment presentation, profile editing, and hairstyle preview. Pixel-perfect completion is not claimed.
