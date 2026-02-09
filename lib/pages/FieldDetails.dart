import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:letsplay/widgets/App_Bottom_Nav.dart';
import 'package:letsplay/widgets/logobutton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'PhotoViewer.dart';
import '../services/language.dart';
import 'management/AddFieldScreen.dart';

class FieldDetailsScreen extends StatefulWidget {
  final LocaleController ctrl;
  final Map<String, dynamic> field;
  final String? userRole;
  const FieldDetailsScreen({
    super.key,
    required this.ctrl,
    required this.field,
    this.userRole,
  });

  @override
  State<FieldDetailsScreen> createState() => _FieldDetailsScreenState();
}

class _FieldDetailsScreenState extends State<FieldDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      child: const SizedBox.shrink(),
      builder: (context, child) {
        final ar = widget.ctrl.isArabic;
        final theme = Theme.of(context);
        // Permission logic: only admin can edit
        bool isAdmin = false;
        if (widget.userRole != null) {
          final normalized = widget.userRole!.toLowerCase().trim();
          isAdmin = normalized == 'admin';
        }
        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color:
                      theme.appBarTheme.foregroundColor ??
                      theme.textTheme.bodyLarge?.color,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                ar ? 'تفاصيل الملعب' : 'Field Details',
                style: TextStyle(
                  color:
                      theme.appBarTheme.foregroundColor ??
                      theme.textTheme.bodyLarge?.color,
                ),
              ),
              centerTitle: true,
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color:
                          theme.appBarTheme.foregroundColor ??
                          theme.textTheme.bodyLarge?.color,
                    ),
                    onPressed: () {
                      // Navigate to edit screen (AddFieldScreen with initial data)
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => _EditFieldScreen(
                                ctrl: widget.ctrl,
                                field: widget.field,
                              ),
                            ),
                          )
                          .then((updatedField) {
                            if (updatedField != null && mounted) {
                              setState(() {
                                // Refresh the screen with updated data
                              });
                            }
                          });
                    },
                    tooltip: ar ? 'تعديل' : 'Edit',
                  ),
                const LogoButton(),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photos
                  if (widget.field['photos'] != null &&
                      (widget.field['photos'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (widget.field['photos'] as List).length,
                          itemBuilder: (_, i) {
                            final p = (widget.field['photos'] as List)[i];
                            Widget img;
                            if (p is List<int> || p is Uint8List) {
                              final bytes = p is Uint8List
                                  ? p
                                  : Uint8List.fromList(p as List<int>);
                              img = Image.memory(
                                bytes,
                                width: 200,
                                height: 140,
                                fit: BoxFit.cover,
                              );
                            } else if (p is String) {
                              // Check if it's a URL or file path
                              if (p.startsWith('http://') ||
                                  p.startsWith('https://')) {
                                // It's a URL from Cloudinary
                                img = Image.network(
                                  p,
                                  width: 200,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 140,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 40,
                                      ),
                                    );
                                  },
                                );
                              } else if (!kIsWeb) {
                                // It's a local file path (mobile only)
                                img = Image.file(
                                  File(p),
                                  width: 200,
                                  height: 140,
                                  fit: BoxFit.cover,
                                );
                              } else {
                                // Fallback for web with local path (shouldn't happen)
                                img = Container(
                                  width: 200,
                                  height: 140,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 40),
                                );
                              }
                            } else {
                              img = Container(
                                width: 200,
                                height: 140,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 40),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  final photos = List.of(
                                    widget.field['photos'] as List<dynamic>,
                                  );
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PhotoViewerScreen(
                                        photos: photos,
                                        initialIndex: i,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: img,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Amenities Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      ar ? 'المرافق' : 'Amenities',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child:
                        (widget.field['amenities'] != null &&
                            (widget.field['amenities'] as List).isNotEmpty)
                        ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (widget.field['amenities'] as List)
                                .map<Widget>(
                                  (a) => _buildAmenityCardSimple(
                                    context,
                                    ar,
                                    a.toString(),
                                  ),
                                )
                                .toList(),
                          )
                        : Text(
                            ar ? 'لا توجد مرافق مضافة' : 'No amenities added',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                  ),

                  // Location Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      ar ? 'الموقع' : 'Location',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 200,
                      child: _buildMapWidget(context, ar),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const AppBottomNav(index: 3),
          ),
        );
      },
    );
  }

  Future<void> _launchMaps(String location) async {
    final query = Uri.encodeComponent(location);
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $googleMapsUrl');
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
    }
  }

  Widget _buildMapWidget(BuildContext context, bool isArabic) {
    final theme = Theme.of(context);
    double? lat;
    double? lng;
    if (widget.field.containsKey('coords') && widget.field['coords'] is Map) {
      final c = widget.field['coords'] as Map;
      lat = (c['lat'] is num) ? (c['lat'] as num).toDouble() : null;
      lng = (c['lng'] is num) ? (c['lng'] as num).toDouble() : null;
    } else if (widget.field.containsKey('lat') &&
        widget.field.containsKey('lng')) {
      lat = (widget.field['lat'] is num)
          ? (widget.field['lat'] as num).toDouble()
          : null;
      lng = (widget.field['lng'] is num)
          ? (widget.field['lng'] as num).toDouble()
          : null;
    }

    if (lat == null || lng == null) {
      // Fallback: If no coordinates, try to show a button to launch maps with location string
      final locationStr = widget.field['location']?.toString();
      if (locationStr != null && locationStr.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: InkWell(
            onTap: () => _launchMaps(locationStr),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    isArabic ? 'عرض الموقع على الخريطة' : 'View on Maps',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      locationStr,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Center(
            child: Text(
              isArabic ? 'لا يتوفر موقع' : 'Location not available',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ),
        ),
      );
    }

    final initial = LatLng(lat, lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: initial,
          initialZoom: 15.0,
          minZoom: 3.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.letsplay',
            maxZoom: 18,
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: initial,
                width: 40.0,
                height: 40.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityCardSimple(
    BuildContext context,
    bool isArabic,
    String amenity,
  ) {
    final theme = Theme.of(context);
    IconData icon = Icons.info;
    String en = amenity;
    String ar = amenity;
    switch (amenity) {
      case 'Parking':
        icon = Icons.local_parking;
        ar = 'موقف سيارات';
        break;
      case 'Restrooms':
        icon = Icons.wc;
        ar = 'حمامات';
        break;
      case 'Lighting':
        icon = Icons.lightbulb_outline;
        ar = 'إضاءة';
        break;
      case 'Locker Rooms':
        icon = Icons.door_front_door;
        ar = 'غرف تبديل الملابس';
        break;
      case 'Water':
        icon = Icons.water_drop;
        ar = 'مياه';
        break;
      case 'Shower':
        icon = Icons.shower;
        ar = 'دش';
        break;
      case 'Cafeteria':
        icon = Icons.restaurant;
        ar = 'كافتيريا';
        break;
      case 'WiFi':
        icon = Icons.wifi;
        ar = 'واي فاي';
        break;
      default:
        icon = Icons.info_outline;
        ar = amenity;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.textTheme.bodyMedium?.color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isArabic ? ar : en,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Edit field screen wrapper
class _EditFieldScreen extends StatelessWidget {
  final LocaleController ctrl;
  final Map<String, dynamic> field;

  const _EditFieldScreen({required this.ctrl, required this.field});

  @override
  Widget build(BuildContext context) {
    // For now, navigate to AddFieldScreen
    return AddFieldScreen(ctrl: ctrl);
  }
}
