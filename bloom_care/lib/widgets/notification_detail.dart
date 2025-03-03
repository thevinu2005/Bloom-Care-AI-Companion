import 'package:flutter/material.dart';

class NotificationDetailPage extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailPage({
    Key? key,
    required this.notification,
  }) : super(key: key);

  Widget _buildMedicationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medication Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        _buildDetailCard(
          title: 'Medicine Name',
          value: 'Lisinopril',
          icon: Icons.medication_outlined,
        ),
        _buildDetailCard(
          title: 'Dosage',
          value: '10mg',
          icon: Icons.scale_outlined,
        ),
        _buildDetailCard(
          title: 'Time',
          value: '8:00 AM',
          icon: Icons.access_time,
        ),
        _buildDetailCard(
          title: 'Frequency',
          value: 'Daily',
          icon: Icons.calendar_today,
        ),
        _buildDetailCard(
          title: 'Instructions',
          value: 'Take with water on an empty stomach',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please ensure to take this medication as prescribed. If you experience any side effects, contact your doctor immediately.',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        _buildDetailCard(
          title: 'Activity Type',
          value: 'Walking',
          icon: Icons.directions_walk,
        ),
        _buildDetailCard(
          title: 'Duration',
          value: '10 minutes',
          icon: Icons.timer,
        ),
        _buildDetailCard(
          title: 'Time',
          value: '10:00 AM',
          icon: Icons.access_time,
        ),
        _buildDetailCard(
          title: 'Intensity',
          value: 'Light to Moderate',
          icon: Icons.speed,
        ),
        _buildDetailCard(
          title: 'Instructions',
          value: 'Walk at a comfortable pace in a safe area',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Remember to wear comfortable shoes and stay hydrated during your walk.',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        _buildDetailCard(
          title: 'Emergency Type',
          value: 'Emergency Button Press',
          icon: Icons.warning_amber_rounded,
        ),
        _buildDetailCard(
          title: 'Time',
          value: '3:15 PM',
          icon: Icons.access_time,
        ),
        _buildDetailCard(
          title: 'Location',
          value: 'Living Room',
          icon: Icons.location_on_outlined,
        ),
        _buildDetailCard(
          title: 'Status',
          value: 'Immediate Attention Required',
          icon: Icons.priority_high,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This is an emergency situation. Please check on Mr.Martin immediately.',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[700], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 