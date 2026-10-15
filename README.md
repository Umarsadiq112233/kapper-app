# Kapper

Flutter customer/vendor salon frontend using flutter_bloc and an explicitly mocked in-memory repository.

Run `flutter pub get` then `flutter run`. Choose a role, enter any valid phone number, use demo OTP **123456**, and complete the profile. Demo password login accepts six or more characters. Social providers are not connected. Payment offers a demo approval/decline path and never charges money.

`flutter analyze` and `flutter test` validate source, navigation, layout, and booking guards. To regenerate visual snapshots, run `flutter test test/visual_capture_test.dart --dart-define=CAPTURE_UI=true --update-goldens`. Snapshot font rendering is platform-dependent; they are not exact-reference goldens.

See [screen registry](SCREEN_REGISTRY.md), [navigation](NAVIGATION_MAP.md), and [asset accuracy report](ASSET_ACCURACY_REPORT.md) for implementation coverage and outstanding work. The app is a UI prototype, not a production-connected booking/payment/AR system. Session data resets on restart.
# kapper-app
