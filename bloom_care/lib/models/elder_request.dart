class CaregiverRequest {
  final String id;
  final String elderName;
  final String elderId;
  final String elderImage;
  final String caregiverName;
  final String caregiverId;
  final DateTime timestamp;
  final String status; // 'pending', 'accepted', 'declined'

  CaregiverRequest({
    required this.id,
    required this.elderName,
    required this.elderId,
    required this.elderImage,
    required this.caregiverName,
    required this.caregiverId,
    required this.timestamp,
    required this.status,
  });

  factory CaregiverRequest.fromMap(Map<String, dynamic> map, String id) {
    return CaregiverRequest(
      id: id,
      elderName: map['elderName'] ?? '',
      elderId: map['elderId'] ?? '',
      elderImage: map['elderImage'] ?? 'assets/default_avatar.png',
      caregiverName: map['caregiverName'] ?? '',
      caregiverId: map['caregiverId'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'elderName': elderName,
      'elderId': elderId,
      'elderImage': elderImage,
      'caregiverName': caregiverName,
      'caregiverId': caregiverId,
      'timestamp': timestamp,
      'status': status,
    };
  }
}

