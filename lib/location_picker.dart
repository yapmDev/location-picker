library;

/*
  author: yapmDev
  lastModifiedDate: 17/02/25
  repository: https://github.com/yapmDev/location_picker
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

///Open a map view to select any location, by default it opens at the current location.
///
/// It is based on [flutter_map] package with [openstreetmap] as tile provider, it uses
/// [geolocator] for location service and [FMTC] for efficient caching, so credit to them.
///
/// @Warning It uses a [FMTCStore] with ['mapCache'] as key.
///
/// @Params
///
/// [userAgentPackageName] : Is a [TileLayer] parameter, which should be passed the application's
/// correct package name, such as 'com.example.app'.
/// See https://docs.fleaflet.dev/layers/tile-layer#useragentpackagename for more information.
///
/// [onPermissionDenied] : An optional callback called when the location permission was denied by
/// the user.
///
/// [onPermissionDeniedForever] : An optional callback called when the location permission was
/// denied [forever] by the user.
///
///@Use
///
///[main.dart]
///```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await FMTCObjectBoxBackend().initialise();
///   runApp(const MyApp());
/// }
///```
///```dart
/// Future<void> _pickLocation(BuildContext context) async {
///   final pickedLocation = await pickLocation(context,
///     userAgentPackageName: 'com.example.app'
///   );
///   if (pickedLocation != null) setState(() => _location = pickedLocation);
/// }
///```
///
///I recommend using some network checker to improve the user experience with some feedbacks
///against uncached tiles, mainly when the map is first loaded.
///
/// @See [NetworkChecker] also from this package.
Future<LatLng?> pickLocation(BuildContext context, {
  String? userAgentPackageName,
  void Function()? onPermissionDenied,
  void Function()? onPermissionDeniedForever
}) async {
  LocationPermission permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied) {
    onPermissionDenied?.call();
    return null;
  } else if (permission == LocationPermission.deniedForever) {
    onPermissionDeniedForever?.call();
    return null;
  } else {
    if (!context.mounted) {
      return null;
    } else {
      return await showModalBottomSheet<LatLng>(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        builder: (_) => _LocationPicker(userAgentPackageName: userAgentPackageName),
      );
    }
  }
}

class _LocationPicker extends StatefulWidget {
  const _LocationPicker({
    this.userAgentPackageName,

  });

  final String? userAgentPackageName;

  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> with TickerProviderStateMixin {
  late final MapController _mapController;
  LatLng? _currentPosition;
  bool _isLoading = false;
  bool _isLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeTileCache();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeTileCache() async {
    await const FMTCStore('mapCache').manage.create();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    Position position = await Geolocator.getCurrentPosition(
        locationSettings: Platform.isIOS ? AppleSettings() : AndroidSettings());
    setState(() {
      _isLoading = false;
      _currentPosition = LatLng(position.latitude, position.longitude);
      if(_isLoadedOnce){
        _animatedMapMove(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 17);
      } else {
        _isLoadedOnce = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if(_currentPosition == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Obtaining location from GPS and sensors..."),
              SizedBox(height: 8.0),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    else {
      return Scaffold(
        appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange),
                SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    "Internet connection is required to load sites that have not been previously "
                        "browsed.",
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            titleTextStyle: Theme.of(context).textTheme.bodySmall,
            actions: [
              IconButton(
                  icon: const Icon(Icons.check_outlined),
                  onPressed: () => Navigator.of(context).pop(_currentPosition)
              )
            ]
        ),
        body: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialZoom: 17.0,
            initialCenter: _currentPosition!,
            onTap: (tapPosition, latLng) {
              setState(() {
                _animatedMapMove(latLng, 17);
                _currentPosition = latLng;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              tileProvider: const FMTCStore('mapCache').getTileProvider(),
              userAgentPackageName: widget.userAgentPackageName ?? 'unknown',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 60,
                  height: 60,
                  point: _currentPosition!,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            _getCurrentLocation();
          },
          child: !_isLoading ?
          const Icon(Icons.my_location_outlined) : const CircularProgressIndicator(),
        ),
      );
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
    controller.addListener(() {
      _mapController.move(
        LatLng(
          latTween.evaluate(animation),
          lngTween.evaluate(animation),
        ),
        zoomTween.evaluate(animation),
      );
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });
    controller.forward();
  }
}