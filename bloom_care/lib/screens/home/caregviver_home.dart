import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bloom_care/widgets/navigation_bar_for_caregiver.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({super.key});

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _caregiverName = '';
  List<Map<String, dynamic>> _assignedElders = [];
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadCaregiverData();
  }

  Future<void> _loadCaregiverData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get caregiver's data
        final caregiverDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (caregiverDoc.exists) {
          setState(() {
            _caregiverName = caregiverDoc.data()?['name'] ?? 'User';
          });

          // Get assigned elders
          final assignedEldersQuery = await _firestore
              .collection('users')
              .where('assignedCaregiver', isEqualTo: user.uid)
              .where('userType', isEqualTo: 'elder')
              .get();

          final List<Map<String, dynamic>> elders = [];
          
          for (var elderDoc in assignedEldersQuery.docs) {
            // Get the latest emotion for this elder
            final latestEmotionQuery = await _firestore
                .collection('users')
                .doc(elderDoc.id)
                .collection('emotions')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

            final elderData = elderDoc.data();
            final dateOfBirth = elderData['dateOfBirth'] as String?;
            int age = 0;
            
            if (dateOfBirth != null) {
              final parts = dateOfBirth.split('/');
              if (parts.length == 3) {
                final birthDate = DateTime(
                  int.parse(parts[2]), // year
                  int.parse(parts[1]), // month
                  int.parse(parts[0]), // day
                );
                age = DateTime.now().difference(birthDate).inDays ~/ 365;
              }
            }

            elders.add({
              'id': elderDoc.id,
              'name': elderData['name'] ?? 'Unknown',
              'age': age,
              'mood': latestEmotionQuery.docs.isNotEmpty 
                ? latestEmotionQuery.docs.first.data()['emotion'] 
                : 'Unknown',
              'emergency': elderData['emergency'] ?? false,
            });
          }

          setState(() {
            _assignedElders = elders;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading caregiver data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB0C4FF),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello, Welcome',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              _caregiverName,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {},
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, color: Colors.black54),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Assigned Elders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_assignedElders.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No elders assigned yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _assignedElders.length,
                        itemBuilder: (context, index) {
                          final elder = _assignedElders[index];
                          return ElderProfileCard(
                            elder: elder,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNav_for_caregivers(currentIndex: 0),
    );
  }
}

class ElderProfileCard extends StatelessWidget {
  final Map<String, dynamic> elder;

  const ElderProfileCard({
    super.key,
    required this.elder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: elder['emergency'] ? Colors.red.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child: Text(
                elder['name'].substring(0, 1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    elder['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${elder['age']} years',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Current mood: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        elder['mood'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getMoodColor(elder['mood']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (elder['emergency'])
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Alert',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'relaxed':
        return Colors.blue;
      case 'tired':
        return Colors.orange;
      case 'stressed':
      case 'anxious':
        return Colors.red;
      case 'lonely':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

