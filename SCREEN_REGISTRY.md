# Kapper screen registry

Reference batch: 14 October 2026, 18:39–18:43. Image numbers refer to the 15 attachments in the request. UI is interactive Flutter with session-only mock data. “Implemented” below means a reachable UI, not an exact asset match or live integration.

| ID | Reference | Route / presentation | Implementation and remaining fidelity work |
|---|---|---|---|
| A01 | 1–3, 7 | `/role` | User/vendor selection, purple gradient, gold selection, custom vector illustrations; original illustrations/logo needed |
| A02 | 3, 7 | `/auth/phone` | Validated phone input and provider buttons; providers explicitly unavailable |
| A03 | 1, 3, 7 | `/auth/otp` | Six digit boxes, resend cooldown, edit number, validation/loading; demo code 123456 |
| A04 | 3, 7 | `/auth/complete` | Role-specific validated form; original vendor collage needed |
| A05 | 3, 7 | `/auth/signin` | Password/OTP entry, demo login; original vendor collage needed |
| U01 | 1, 4 | `/home` customer | Nearby grid, favorites, notifications, search, persistent bottom tabs |
| U02 | 5 | `/search` | Search, maximum price/distance filtering, reset; min range fixed at zero |
| U03 | 5 | Filter dialog | Two compact range rows, validation and apply/reset |
| S01 | 4, 8 | `/salon`, vendor home | Header and Services/Portfolio/Reviews tabs, service/date/time selection; photos differ |
| S02 | 4, 8 | Portfolio tab | Album galleries, image preview, vendor upload access |
| S03 | 4 | Reviews tab | Seed reviews and reviews from completed demo appointments |
| B01 | 4 | Booking details dialog | Name, gender, birthdate, relationship, notes UI; only booking identity/service/date/time retained in model |
| B02 | 4 | `/payment` | Demo card payment/decline/retry, duplicate slot check; full-page layout still differs from reference bottom popup |
| B03 | 14 | `/booking/confirmed` | Confirmed booking summary and appointments navigation |
| B04 | 5, 10 | `/appointments`, home tab | Upcoming/completed/cancelled tabs; chat, cancel, reschedule, vendor completion |
| B05 | 5, 10 | `/chat` | Appointment-keyed messages and keyboard-aware input; session-only |
| B06 | 5, 9 | Confirmation / reschedule dialogs | Yes/no cancellation/delete confirmation; reschedule date/time |
| B07 | 4 | Review dialog | Five selectable stars, text, completed-appointment guard |
| P01 | 6, 11 | `/profile`, home tab | Role-specific identity and account menu |
| P02 | 11 | `/profile/edit` | Name/email/address save; cover-photo editing and vendor phone field pending |
| P03 | 6, 11 | `/notifications` | Appointment/message entries navigate to relevant features |
| P04 | 6 | `/favorites` | Two-column saved salon grid, empty state |
| P05 | 6, 11 | `/transactions` | Session booking-derived demo ledger; no financial processor records |
| P06 | 6, 11 | `/transactions/detail` | Demo transaction details |
| C01 | 6 | `/styles/preview` | Selectable image carousel; original same-person hairstyle variants and AR not available |
| V01 | 8 | `/vendor/upload` | Native image picker and album selection; live vendor uploads to private Supabase Storage, demo remains local |
| V02 | 8 | Create Album dialog | Validated name, session album creation |
| V03 | 8 | `/vendor/availability` | Compact date tiles and slot chips, draft edits and save |
| V04 | 9 | Add/Edit Date dialog | Day/month/year controls and past-date validation |
| V05 | 8, 9 | Edit Time Slot dialog | Time/period form, validation, delete confirmation |
| V06 | 9 | Select Time Slots dialog | Multiple selection and save |
| V07 | 8, 9 | Add/Edit Service dialog | Image picker, name, duration, description, price; existing thumbnail shown |
| V08 | 12 | `/vendor/styles`, home tab | Custom style list and create action |
| V09 | 12 | Create Style dialog | Image, name, description and session save |
| V10 | Dashboard 2 | Vendor home, tab 0 | Purple gradient appointment summary, database-derived appointment/customer/service counts, popularity from bookings, availability, schedule, shortcuts and Realtime; no fabricated earnings |

## Validation

- Navigation widget tests: customer/vendor at 320 and 430 logical pixels, role preservation and customer access guard.
- BLoC tests: duplicate slot rejection, role permissions, cross-role service edits, completion and review state.
- Rendering sweep: 24 screens and 11 dialogs at 390 × 844; PNGs in `test/captures` are implementation snapshots, not proof of screenshot parity.
- Snapshot generation: `flutter test test/visual_capture_test.dart --dart-define=CAPTURE_UI=true --update-goldens`.
- Reference screen thumbnails have varying sizes and some labels are unreadable. No exact pixel-difference score is claimed.

## Outstanding production work

Persistent session/auth backend, provider credentials, remote messaging, per-salon/per-date availability storage, payment processor/tokenization/webhooks and refunds, original design assets/fonts, actual camera/AR tracking, platform-device testing, and remaining visual differences noted above. Data resets on process restart. Only the Danial vendor is editable. Other demo salons keep their own fixture catalog and availability; edits to Danial do not change them. Time slots still apply uniformly to each available date within that salon.

Vendor Realtime subscriptions are scoped to the authenticated owner and cover workspace, appointments, messages, reviews, and notifications. Database triggers create booking/status/message notifications; vendors can persist read state. Migration `202610150004_vendor_realtime.sql` adds these records and publication membership without deleting existing data. Apply it and verify Realtime is enabled in the target Supabase project. Static OTP remains a local demo path and never creates a Supabase Auth session. Push delivery is not configured.
