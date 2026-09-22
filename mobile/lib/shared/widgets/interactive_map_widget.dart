import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class InteractiveMapWidget extends StatelessWidget {
  final double targetLat, targetLng, radiusMeters, currentDistance;
  final String locationName, address;
  final bool isInRadius;
  final ValueChanged<LatLng>? onLocationSelected;
  const InteractiveMapWidget(
      {super.key,
      this.targetLat = 0,
      this.targetLng = 0,
      this.locationName = 'Lokasi PKL',
      this.address = '',
      this.radiusMeters = 100,
      this.currentDistance = 0,
      this.isInRadius = false,
      this.onLocationSelected});
  Future<void> _open(BuildContext context, bool directions) async {
    final uri = Uri.https(
        'www.google.com', directions ? '/maps/dir/' : '/maps/search/', {
      'api': '1',
      directions ? 'destination' : 'query': '$targetLat,$targetLng'
    });
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
        throw Exception();
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Maps gagal dibuka.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const enabled = bool.fromEnvironment('GOOGLE_MAPS_ENABLED');
    final position = LatLng(targetLat, targetLng);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(locationName,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(address),
                  if (enabled)
                    SizedBox(
                        height: 260,
                        child: GoogleMap(
                          initialCameraPosition:
                              CameraPosition(target: position, zoom: 15),
                          zoomControlsEnabled: true,
                          onTap: onLocationSelected,
                          markers: {
                            Marker(
                                markerId: const MarkerId('location'),
                                position: position,
                                draggable: onLocationSelected != null,
                                onDragEnd: onLocationSelected,
                                infoWindow: InfoWindow(
                                    title: locationName, snippet: address))
                          },
                        ))
                  else
                    const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Peta interaktif belum dikonfigurasi. Gunakan koordinat atau buka Google Maps.')),
                  Text('$targetLat, $targetLng'),
                  Wrap(spacing: 8, children: [
                    TextButton.icon(
                        onPressed: () => _open(context, false),
                        icon: const Icon(Icons.map),
                        label: const Text('Google Maps')),
                    TextButton.icon(
                        onPressed: () => _open(context, true),
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions')),
                  ]),
                ])));
  }
}
