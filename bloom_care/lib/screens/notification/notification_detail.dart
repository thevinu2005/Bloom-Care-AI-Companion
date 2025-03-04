import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';

class NotificationDetailPage extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailPage({
    Key? key,
    required this.notification,
  }) : super(key: key);

  void _openLocation(double latitude, double longitude) {
    try {
      print('Opening maps with coordinates: $latitude, $longitude');
      MapsLauncher.launchCoordinates(latitude, longitude);
    } catch (e) {
      print('Error launching maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Print the entire notification for debugging
    print('Notification data received: $notification');
    
    // Safely extract location data with extensive error handling
    Map<String, dynamic>? location;
    String room = 'Unknown location';
    double? latitude;
    double? longitude;
    
    try {
      if (notification.containsKey('location')) {
        final locationData = notification['location'];
        print('Location data: $locationData');
        
        if (locationData is Map) {
          location = Map<String, dynamic>.from(locationData);
          room = location['room']?.toString() ?? 'Unknown location';
          
          // Handle latitude
          if (location.containsKey('latitude')) {
            final lat = location['latitude'];
            if (lat is double) {
              latitude = lat;
            } else if (lat is int) {
              latitude = lat.toDouble();
            } else if (lat is String) {
              latitude = double.tryParse(lat);
            }
          }
          
          // Handle longitude
          if (location.containsKey('longitude')) {
            final lng = location['longitude'];
            if (lng is double) {
              longitude = lng;
            } else if (lng is int) {
              longitude = lng.toDouble();
            } else if (lng is String) {
              longitude = double.tryParse(lng);
            }
          }
          
          print('Extracted location - Room: $room, Lat: $latitude, Lng: $longitude');
        } else {
          print('Location is not a Map: ${locationData.runtimeType}');
        }
      } else {
        print('No location key in notification');
      }
    } catch (e) {
      print('Error extracting location: $e');
    }
    
    // Safely format the timestamp with extensive error handling
    String formattedTime = 'Unknown time';
    try {
      print('Timestamp data: ${notification['timestamp']}');
      print('Timestamp type: ${notification['timestamp']?.runtimeType}');
      
      if (notification.containsKey('timestamp')) {
        final timestamp = notification['timestamp'];
        
        if (timestamp is String) {
          try {
            final dateTime = DateTime.parse(timestamp);
            formattedTime = DateFormat('h:mm a').format(dateTime);
          } catch (e) {
            print('Error parsing timestamp string: $e');
          }
        } else if (timestamp is DateTime) {
          formattedTime = DateFormat('h:mm a').format(timestamp);
        } else if (timestamp is int) {
          try {
            final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            formattedTime = DateFormat('h:mm a').format(dateTime);
          } catch (e) {
            print('Error parsing timestamp int: $e');
          }
        } else if (timestamp is Map) {
          // Handle Firestore Timestamp object
          try {
            if (timestamp.containsKey('seconds') && timestamp.containsKey('nanoseconds')) {
              final seconds = timestamp['seconds'];
              final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
              formattedTime = DateFormat('h:mm a').format(dateTime);
            }
          } catch (e) {
            print('Error parsing Firestore timestamp: $e');
          }
        }
      }
      
      // Fallback to pre-formatted time if available
      if (formattedTime == 'Unknown time' && notification.containsKey('formattedTime')) {
        final preFormatted = notification['formattedTime'];
        if (preFormatted is String) {
          formattedTime = preFormatted;
        }
      }
      
      print('Formatted time: $formattedTime');
    } catch (e) {
      print('Error formatting time: $e');
      // Final fallback
      try {
        formattedTime = notification['formattedTime']?.toString() ?? 'Unknown time';
      } catch (e) {
        print('Error getting formatted time: $e');
      }
    }
    
    // Safely get other fields with error handling
    String emergencyType = 'Unknown';
    String elderStatus = 'Unknown status';
    String elderName = 'the elder';
    String message = 'Emergency Alert';
    
    try {
      emergencyType = notification['emergencyType']?.toString() ?? 'Unknown';
      elderStatus = notification['elderStatus']?.toString() ?? 'Unknown status';
      elderName = notification['elderName']?.toString() ?? 'the elder';
      message = notification['message']?.toString() ?? 'Emergency Alert';
    } catch (e) {
      print('Error getting notification fields: $e');
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Notification Details',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Alert Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE7E7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Emergency Details Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Emergency Type
                  _buildDetailCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Emergency Type',
                    value: emergencyType,
                  ),
                  
                  // Time
                  _buildDetailCard(
                    icon: Icons.access_time,
                    title: 'Time',
                    value: formattedTime,
                  ),
                  
                  // Location
                  _buildDetailCard(
                    icon: Icons.location_on,
                    title: 'Location',
                    value: room,
                    onTap: (latitude != null && longitude != null && 
                            latitude != 0.0 && longitude != 0.0)
                        ? () => _openLocation(latitude!, longitude!)
                        : null,
                  ),
                  
                  // Status
                  _buildDetailCard(
                    icon: Icons.info_outline,
                    title: 'Status',
                    value: elderStatus,
                    valueColor: Colors.red,
                  ),
                ],
              ),
            ),

            // Warning Message
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE7E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is an emergency situation. Please check on $elderName immediately.',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: valueColor ?? Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

