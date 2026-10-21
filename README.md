# Kapper

Flutter salon app with Supabase-backed vendor accounts and a local customer demo.

The phone OTP screen is a static demo preview (`123456`) and never creates a Supabase Auth session. Configure `config/supabase.json` and run `./scripts/run_app.sh` for confirmed email/password vendor accounts.

Run `flutter pub get` then `flutter run`. For the customer demo, choose User, enter any valid phone number, use demo OTP **123456**, and complete the profile. Demo password login accepts six or more characters. Social providers are not connected. Payment offers a demo approval/decline path and never charges money.

`flutter analyze` and `flutter test` validate source, navigation, layout, and booking guards. To regenerate visual snapshots, run `flutter test test/visual_capture_test.dart --dart-define=CAPTURE_UI=true --update-goldens`. Snapshot font rendering is platform-dependent; they are not exact-reference goldens.

See [implementation tracker](VENDOR_IMPLEMENTATION_TRACKER.md), [screen registry](SCREEN_REGISTRY.md), [navigation](NAVIGATION_MAP.md), and [asset accuracy report](ASSET_ACCURACY_REPORT.md) for coverage and outstanding work. Live customer discovery, salon favorites, and pay-at-salon appointment reservation require migration `202610200002_customer_discovery.sql`; a vendor must explicitly enable “Show in customer discovery” and publish at least one enabled service. Online payments, customer cancellation/rescheduling, and AR remain unimplemented until their trusted providers and backend flows are integrated. Live vendor account data persists in Supabase and refreshes from scoped Realtime changes; appointments reserved by customers are stored in the vendor appointment table and appear in the vendor workspace. Static OTP demo data is in-memory only. Customer demo data resets on restart. Apply the additive migrations only after checking the remote migration history; never rerun the initial table-creation migration against an existing project.
# kapper-vendor-app

Customer availability uses `202610200004_customer_availability.sql` to return the vendor’s published dates and unreserved slots without disclosing other customers. For an existing vendor database missing customer setup, `supabase/enable_customer_booking.sql` bundles customer migrations 001–004 in order. Apply it in the matching Supabase project, then retry discovery. Vendors must enable “Show in customer discovery” and save enabled services and availability. Chat conversations are linked to real appointments. Run `202610220001_customer_avatar_snapshots.sql` and `202610220002_customer_avatar_storage.sql` as well so customer avatars and uploaded profile photos persist and can be displayed in vendor conversations.
