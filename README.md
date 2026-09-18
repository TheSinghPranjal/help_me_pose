# Help me Pose

A pose-reference camera app: pick a pose (from a built-in library or your own
imported photos), see it as a faint overlay on your live camera preview,
line yourself up, and take a normal photo — the overlay is a visual guide
only and is never saved into the photo.

## Requirements

- Flutter 3.41.6 / Dart 3.11+ (stable channel)
- Xcode 16+ for iOS, Android SDK 36 / minSdk 24 for Android
- A physical device is strongly recommended for testing the camera, since
  simulators/emulators generally have no usable camera hardware.

## Getting started

```bash
flutter pub get
flutter run                # run on a connected device/simulator
```

## Architecture

Feature-first, layered by responsibility:

```
lib/
  core/          theme, spacing/typography, constants, Riverpod plumbing,
                 routing (bottom-nav shell + RouteObserver), small utils
  domain/models/ immutable data models (Pose, PoseCategory, OverlaySettings,
                 CameraState, CapturedPhoto, FilterOption, AppSettings)
  services/      thin wrappers around platform packages — camera, media
                 saving (photo_manager), permissions, local storage
                 (SharedPreferences), photo filters (image package)
  data/          repositories that combine services + local persistence
                 into app-facing operations (PoseRepository,
                 CaptureRepository, SettingsRepository)
  features/      one folder per feature (camera, poses, gallery, onboarding,
                 settings), each split into application/ (Riverpod
                 Notifiers) and presentation/ (screens + widgets)
  shared/widgets/ small reusable UI pieces used across features
```

State management is plain `flutter_riverpod` (`Notifier`/`AsyncNotifier`,
no code generation) so the app has no `build_runner` step. Widgets read
state via `ref.watch(...).select(...)` wherever a screen has several
independently-changing regions (the camera screen in particular), so
dragging the opacity slider only rebuilds the overlay/slider, never the
camera preview.

## Packages and why

| Package | Why |
|---|---|
| `flutter_riverpod` | State management (`Notifier`/`AsyncNotifier`), DI for services/repositories |
| `camera` | Live preview + still capture (front/rear, zoom, flash, focus). No video APIs are ever called. |
| `image_picker` | Importing custom pose photos and (indirectly) nothing else — uses the modern system picker (`PhotoPicker` on Android 13+, `PHPickerViewController` on iOS), which needs **no runtime permission** on current OS versions |
| `permission_handler` | Camera permission, and the minimal "add to library" photo permission before the first gallery save |
| `photo_manager` | Writing captured photos into the system photo library (and, on Android, into a named "Help me Pose" album via `MediaStore`) |
| `path_provider` / `path` | Locating and building paths under the app's documents directory for custom pose files and the recent-captures cache |
| `shared_preferences` | All metadata/settings persistence (JSON-encoded lists for poses/captures, primitives for settings) — no raw image bytes are ever stored here |
| `flutter_svg` | Rendering the built-in vector pose silhouettes (see below) |
| `image` | Baking EXIF orientation + the chosen filter into the final saved JPEG |
| `uuid` | IDs for custom poses and captures |
| `share_plus` | Optional sharing of a captured photo |
| `intl` | Grouping "Recent Captures" by date |
| `package_info_plus` | Showing the real app version in Settings |
| `mocktail` (dev) | Mocking repositories/services in unit tests |

Nothing here talks to a server, and no analytics/tracking package is
included — see **Privacy** below.

## Permissions

Only two permissions are ever requested, and only right before the
operation that needs them (never eagerly at launch):

- **Camera** — requested when the user first opens the Camera tab.
- **Photos (add-only on iOS / `READ_MEDIA_IMAGES` on Android)** —
  requested right before the *first* photo is saved to the gallery.

No microphone permission is requested. The `camera` plugin's Android
implementation unconditionally merges a `RECORD_AUDIO` permission (it
supports video recording, which this app never uses), so
`android/app/src/main/AndroidManifest.xml` explicitly removes it with
`tools:node="remove"`.

Importing a photo into "My Poses" needs **no permission at all** on modern
Android/iOS, because `image_picker` uses the system's out-of-process photo
picker, which never grants the app broad library access.

iOS `Info.plist` keys: `NSCameraUsageDescription`,
`NSPhotoLibraryAddUsageDescription`. Android manifest additions:
`CAMERA`, `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE` (`maxSdkVersion=32`,
for pre-13 devices), plus the two camera `<uses-feature>` declarations
(front camera marked `required="false"` so the app still installs on
rear-camera-only devices).

## Pose asset licensing strategy

The built-in library (10 categories × 10 poses = 100 references) is **not**
built from downloaded photographs. Sourcing ~100 correctly-licensed,
redistributable photographs and verifying each one's license would not be
reliable to do sight-unseen, and the brief explicitly allows original
illustrations as an alternative. Instead, `assets/poses/manifest.json` and every SVG under
`assets/poses/<category>/` were generated by
[`tool/generate_pose_library.py`](tool/generate_pose_library.py), a
checked-in procedural script that draws simple articulated stick-figure
silhouettes with per-category joint-angle presets (standing, sitting,
leaning, walking, full body, portrait, hand poses, couple poses, outdoor,
creative). Regenerate the whole library at any time with:

```bash
python3 tool/generate_pose_library.py assets/poses
```

This means:
- **No copyright/licensing risk** — every asset is original, generated
  in-house specifically for this app.
- Each pose in the manifest carries `"source": "Original vector
  illustration created for Help me Pose"` and
  `"license": "CC0 (created in-house, no third-party assets used)"`,
  shown on the pose detail screen.
- Assets are tiny (a full 100-pose library is ~450 KB total) and scale
  losslessly at any overlay size since they're vector, not raster.

### Adding new built-in poses

Poses are data, not code. To add more:

1. Either add a new preset function/variant to
   `tool/generate_pose_library.py` and rerun it, or hand-author a new
   entry in the `poses` array of `assets/poses/manifest.json` with a
   unique `id`, `title`, `category`, `assetPath`, `tags`, and
   `source`/`license` strings.
2. Drop the corresponding `.svg` (or `.png`/`.jpg`, setting `isSvg` false
   in the equivalent Dart-side check) under `assets/poses/<category>/`.
3. Add the category's folder to the `assets:` list in `pubspec.yaml` if
   it's a new category.
4. Run `flutter pub get` and restart the app.

`PoseRepository` treats the manifest as the single source of truth for
the built-in library — no code changes are needed to add poses to an
existing category.

## How the overlay works (and why it's never in the photo)

The camera screen is a `Stack`:

1. **Bottom layer** — `CameraPreviewLayer`, wrapping the `camera` plugin's
   `CameraPreview` widget bound to the live `CameraController`.
2. **Top layer** — `PoseOverlayLayer`, a purely presentational widget that
   paints the selected pose (from `activePoseProvider`) with opacity/
   scale/offset from `overlaySettingsProvider`, wrapped in `IgnorePointer`.

Capturing a photo calls `CameraController.takePicture()` directly — this
reads a frame from the camera sensor/pipeline and has no knowledge of, or
access to, anything Flutter has drawn on top of it. The overlay is a
separate widget subtree entirely; there is no compositing/screenshot step
that could accidentally include it. Default opacity is **10%**
(`AppConstants.defaultOverlayOpacity`), adjustable 0–100% via the slider on
the camera screen, with a **Reset** action that returns opacity, scale, and
position to their defaults.

Front-camera **mirroring**: the live preview is mirrored horizontally
(natural "mirror" feel while framing), the pose overlay is **never**
mirrored (so alignment matches the reference exactly as authored), and the
**saved** photo is *not* mirrored by default — enable "Mirror selfie
photos" in Settings to save front-camera shots mirrored to match the
viewfinder instead.

## Running tests

```bash
flutter analyze     # static analysis — currently zero issues
dart format --output=none --set-exit-if-changed lib test
flutter test         # unit + widget tests
```

Covered: pose persistence (import/update/delete, custom categories),
favorites and recently-used tracking, overlay settings (defaults,
clamping, reset), pose search/category filtering, `CameraState`
transitions, and the capture/save pipeline (filter application, gallery
save, permission-denied handling, recent-captures index self-healing) —
the last of these via mocked services, since it depends on platform
channels. The camera screen itself is verified by static analysis, a
real-device architecture review, and manual testing (see **Known
limitations**), since a genuine camera feed can't be exercised in
`flutter test` or on a simulator without hardware.

## Building for release

```bash
# Android
flutter build appbundle --release   # for Play Store
flutter build apk --release         # standalone APK

# iOS
flutter build ipa --release         # requires a configured signing team in Xcode
```

Before a real release, set a unique application id / bundle identifier
(currently `com.lazy_bear_club.help_me_pose` / a related iOS id inherited
from the starter template) and configure release signing.

## Privacy

- Captured photos and imported pose references never leave the device
  unless the user explicitly taps Share.
- No analytics, crash reporting, location, contacts, or microphone access.
- Local data (favorites, recents, custom poses/categories, settings,
  onboarding state) lives in `SharedPreferences` and the app's own
  documents directory; nothing is synced anywhere.

## Known limitations / what to verify on a real device

This was built and verified in an environment without physical camera
hardware attached. The following were validated with static analysis, a
clean `flutter analyze`, 31 passing unit/widget tests, successful debug
builds for both Android (`flutter build apk --debug`) and iOS
(`flutter build ios --simulator --no-codesign`), and a live launch on an
iOS Simulator (onboarding renders and the app does not crash). They still
need a pass on real hardware before shipping:

- Live camera preview correctness, front/rear switching, pinch-zoom and
  tap-to-focus behavior across different sensors.
- Flash availability/behavior on devices that support it.
- Photo orientation on devices with different sensor mounting.
- The permission-denied / permanently-denied / restricted flows (the
  simulator has no way to simulate "permanently denied").
- Saving into a named Android gallery album end-to-end.
