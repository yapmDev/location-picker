# Location Picker

A simple Flutter library that opens an interactive map allowing users to **select a location** easily.

It uses `flutter_map` (with OpenStreetMap) as the map provider, and combines **offline caching** with `flutter_map_tile_caching`, along with `geolocator` to retrieve the user's current position.

> ⚡ Lightweight, fast, and without heavy dependencies.

---

## ✨ Features

- Displays a map centered on the user's current location.
- Allows picking any point on the map by tapping.
- Saves map tiles for faster future loads (offline caching).
- Handles location permission requests, with customizable callbacks.
- Smooth animations when moving the map.
- Floating action button to re-center on the current location.
- Built on top of popular and well-supported libraries:
  - `flutter_map`
  - `geolocator`
  - `flutter_map_tile_caching (FMTC)`

---

## 🚀 Installation

Add this dependency to your `pubspec.yaml`:

```yaml
dependencies:
  location_picker:
    git:
      url: https://github.com/yapmDev/location_picker.git
```

You must initialize the FMTC backend **before** running your app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FMTCObjectBoxBackend().initialise(); // Required for FMTC
  runApp(const MyApp());
}
```

---

## 🛠️ Quick Usage

```dart
Future<void> _pickLocation(BuildContext context) async {
  final pickedLocation = await pickLocation(
    context,
    userAgentPackageName: 'com.example.app', // important for TileLayer
  );

  if (pickedLocation != null) {
    print('Latitude: ${pickedLocation.latitude}, Longitude: ${pickedLocation.longitude}');
  }
}
```

You can trigger this from a button or any UI interaction.

---

## 📋 `pickLocation` Parameters

| Name                      | Type                  | Description |
|----------------------------|-----------------------|-------------|
| `userAgentPackageName`     | `String?`              | (Recommended) The app's correct package name. Needed for tile HTTP requests. |
| `onPermissionDenied`       | `void Function()?`     | Optional callback triggered when location permission is denied. |
| `onPermissionDeniedForever`| `void Function()?`     | Optional callback triggered when location permission is permanently denied. |

---

## ⚠️ Warnings

- An **internet connection** is required the first time to load uncached tiles.
- FMTC creates a local tile cache named `'mapCache'`.
- It's recommended to handle network status changes (`NetworkChecker` or similar) to enhance UX.

---

## 📚 Tech Stack

- [`flutter_map`](https://pub.dev/packages/flutter_map)
- [`flutter_map_tile_caching`](https://pub.dev/packages/flutter_map_tile_caching)
- [`geolocator`](https://pub.dev/packages/geolocator)
- [`latlong2`](https://pub.dev/packages/latlong2)

---

## 📄 License

[MIT](LICENSE)

---

## 🤝 Credits

Special thanks to the libraries and the Flutter community for making this possible.  
Created with ❤️ by [@yapmDev](https://github.com/yapmDev).
