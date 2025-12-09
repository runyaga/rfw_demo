import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rfw/rfw.dart';

/// Version constant for Map widgets capability handshake
const String kMapRegistryVersion = '1.0.0';

/// Creates the Map widget library for GIS functionality.
///
/// Per Stage 9: Extended Widget Library
/// Provides FlutterMap integration for RFW.
///
/// Note: Requires network access for tile loading.
/// On macOS, ensure com.apple.security.network.client entitlement is set.
LocalWidgetLibrary createMapWidgets() {
  return LocalWidgetLibrary(<String, LocalWidgetBuilder>{
    // FlutterMap for GIS Map Viewer (Stage 9)
    'FlutterMap': (BuildContext context, DataSource source) {
      final latitude = source.v<double>(['latitude']) ?? 0.0;
      final longitude = source.v<double>(['longitude']) ?? 0.0;
      final zoom = source.v<double>(['zoom']) ?? 13.0;
      final minZoom = source.v<double>(['minZoom']) ?? 1.0;
      final maxZoom = source.v<double>(['maxZoom']) ?? 18.0;
      final enableTapToSelect = source.v<bool>(['enableTapToSelect']) ?? false;
      final markerCount = source.v<int>(['markerCount']) ?? 0;
      final showAttribution = source.v<bool>(['showAttribution']) ?? true;

      // Build markers from data
      final List<Marker> markers = [];
      for (int i = 0; i < markerCount; i++) {
        final markerLat = source.v<double>(['markers', i, 'lat']) ?? 0.0;
        final markerLng = source.v<double>(['markers', i, 'lng']) ?? 0.0;
        final markerLabel = source.v<String>(['markers', i, 'label']) ?? '';
        final markerColor = source.v<int>(['markers', i, 'color']) ?? 0xFFF44336;
        final markerId = source.v<String>(['markers', i, 'id']) ?? 'marker_$i';

        markers.add(Marker(
          point: LatLng(markerLat, markerLng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: source.handler(
              ['onMarkerTap'],
              (HandlerTrigger trigger) => () => trigger(<String, Object?>{
                'markerId': markerId,
                'lat': markerLat,
                'lng': markerLng,
                'label': markerLabel,
              }),
            ),
            child: Tooltip(
              message: markerLabel,
              child: Icon(
                Icons.location_on,
                color: Color(markerColor),
                size: 40,
              ),
            ),
          ),
        ));
      }

      return FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(latitude, longitude),
          initialZoom: zoom,
          minZoom: minZoom,
          maxZoom: maxZoom,
          onTap: enableTapToSelect
              ? (tapPosition, latLng) {
                  final handler = source.handler(
                    ['onMapTap'],
                    (HandlerTrigger trigger) => () => trigger(<String, Object?>{
                      'lat': latLng.latitude,
                      'lng': latLng.longitude,
                    }),
                  );
                  if (handler != null) {
                    handler();
                  }
                }
              : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.rfw_spike',
          ),
          if (markers.isNotEmpty)
            MarkerLayer(markers: markers),
          if (showAttribution)
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                ),
              ],
            ),
        ],
      );
    },

    // Simple map marker widget for composing markers
    'MapMarker': (BuildContext context, DataSource source) {
      final label = source.v<String>(['label']) ?? '';
      final color = source.v<int>(['color']) ?? 0xFFF44336;

      return Tooltip(
        message: label,
        child: Icon(
          Icons.location_on,
          color: Color(color),
          size: 40,
        ),
      );
    },
  });
}
