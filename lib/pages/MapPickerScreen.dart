import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:letsplay/services/language.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
    required LocaleController ctrl,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _selectedLocation;
  late MapController _mapController;
  late Set<Marker> _markers;
  bool _isLoadingLocation = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _selectedAddress = 'Loading address...';
  bool _isLoadingAddress = false;
  Timer? _debounce;
  Timer? _mapMoveDebounce;

  @override
  void initState() {
    super.initState();
    // Default to Amman, Jordan
    _selectedLocation =
        widget.initialLocation ?? const LatLng(31.9454, 35.9284);
    _mapController = MapController();
    _markers = {
      Marker(
        point: _selectedLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 32),
      ),
    };
    // Get address for initial location
    _getAddressFromCoordinates(_selectedLocation);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapMoveDebounce?.cancel();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedLocation = position;
      _markers = {
        Marker(
          point: position,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 32),
        ),
      };
    });
    // Get address for tapped location
    _getAddressFromCoordinates(position);
  }

  void _confirmSelection() {
    Navigator.of(context).pop({
      'lat': _selectedLocation.latitude,
      'lng': _selectedLocation.longitude,
      'address': _selectedAddress,
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Location services are disabled');
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage('Location permission permanently denied');
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _markers = {
          Marker(
            point: _selectedLocation,
            width: 40,
            height: 40,
            child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
          ),
        };
      });

      // Move camera to current location
      _mapController.move(_selectedLocation, 15.0);

      // Get address for current location
      _getAddressFromCoordinates(_selectedLocation);

      _showMessage('Current location set');
    } catch (e) {
      _showMessage('Error getting location: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    if (kIsWeb) {
      setState(() {
        _selectedAddress =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
      return;
    }

    setState(() {
      _isLoadingAddress = true;
      // Keep last successful address visible or hidden by loader, but don't overwrite with "Loading..."
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'LetsPlay/1.0 (com.letsplay.app)'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          final displayName = data['display_name'] ?? 'Unknown location';
          setState(() {
            _selectedAddress = displayName;
          });
        } else {
          _showMessage('Invalid response format');
        }
      } else if (response.statusCode == 429 || response.statusCode == 403) {
        _showMessage('Too many requests. Please try again later.');
      } else {
        _showMessage('Unable to get address (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showMessage('Error loading address: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    if (kIsWeb) return;

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'LetsPlay/1.0 (com.letsplay.app)'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is! List) {
          _showMessage('Invalid search response');
          return;
        }

        setState(() {
          _searchResults = data.map((item) {
            final lat = item['lat'];
            final lon = item['lon'];
            return {
              'display_name': item['display_name'] ?? 'Unknown',
              'lat': lat is String
                  ? double.tryParse(lat) ?? 0.0
                  : (lat is num ? lat.toDouble() : 0.0),
              'lon': lon is String
                  ? double.tryParse(lon) ?? 0.0
                  : (lon is num ? lon.toDouble() : 0.0),
            };
          }).toList();
        });
        if (_searchResults.isEmpty) {
          _showMessage('No results found');
        }
      } else if (response.statusCode == 429 || response.statusCode == 403) {
        _showMessage('Search limit reached. Please wait a moment.');
      } else {
        _showMessage('Search failed (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showMessage('Error searching location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final latLng = LatLng(result['lat'], result['lon']);
    setState(() {
      _selectedLocation = latLng;
      _markers = {
        Marker(
          point: latLng,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 32),
        ),
      };
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(latLng, 15.0);
    // Get address for selected search result
    _getAddressFromCoordinates(latLng);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.ltr, // Map picker always LTR
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          title: const Text('Select Location'),
          centerTitle: true,
          actions: [
            if (_isLoadingLocation)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _confirmSelection,
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                enabled: !kIsWeb,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: kIsWeb
                      ? 'Search is disabled on web. Move map to select.'
                      : 'Search for a location...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 800), () {
                    if (value.length > 2) {
                      _searchLocation(value);
                    } else {
                      setState(() {
                        _searchResults = [];
                      });
                    }
                  });
                },
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Main Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _selectedLocation,
                zoom: 15.0,
                maxZoom: 18.0,
                minZoom: 3.0,
                onTap: _onMapTap,
                interactiveFlags: InteractiveFlag.all,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture && position.center != null) {
                    _mapMoveDebounce?.cancel();
                    _mapMoveDebounce = Timer(
                      const Duration(milliseconds: 800),
                      () {
                        if (mounted) {
                          setState(() {
                            _selectedLocation = position.center!;
                            _markers = {
                              Marker(
                                point: _selectedLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ),
                            };
                          });
                          _getAddressFromCoordinates(_selectedLocation);
                        }
                      },
                    );
                  }
                },
              ),
              children: [
                // OpenStreetMap Tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.letsplay.app',
                ),

                // Selected Location Marker
                MarkerLayer(markers: _markers.toList()),

                // Current Location Marker (if available)
                // You can add current location marker here if needed
              ],
            ),

            // Center Crosshair
            Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.red, size: 12),
              ),
            ),

            // Search Results
            if (_searchResults.isNotEmpty)
              Positioned(
                top: 4,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                          ),
                          title: Text(
                            result['display_name'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Location Info Card
            Positioned(
              top: _searchResults.isNotEmpty ? 300 : 16,
              left: 16,
              right: 16,
              child: Card(
                color: theme.cardColor.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selected Location',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      if (_isLoadingAddress)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(
                          _selectedAddress,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.5,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  // Current Location Button
                  FloatingActionButton(
                    backgroundColor: theme.colorScheme.primary,
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    heroTag: 'current_location',
                    child: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 12),
                  // Center Button
                  FloatingActionButton(
                    backgroundColor: theme.colorScheme.secondary,
                    onPressed: () {
                      _mapController.move(_selectedLocation, 15.0);
                    },
                    heroTag: 'center',
                    child: const Icon(Icons.center_focus_strong),
                  ),
                ],
              ),
            ),

            // Confirm Button
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _confirmSelection,
                icon: const Icon(Icons.check),
                label: const Text('Confirm Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
