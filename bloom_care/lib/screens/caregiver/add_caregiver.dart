import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:bloom_care/widgets/navigation_bar.dart';

class Caregiver {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isAdded;
  final String userType;
  final DateTime? createdAt;
  final String? dateOfBirth;

  Caregiver({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isAdded = false,
    required this.userType,
    this.createdAt,
    this.dateOfBirth,
  });

  factory Caregiver.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Caregiver(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      imageUrl: data['profileImageUrl'] ?? data['imageUrl'],
      userType: data['userType'] ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      dateOfBirth: data['dateOfBirth'],
    );
  }
}

class AddCaregiverScreen extends StatefulWidget {
  const AddCaregiverScreen({super.key});

  @override
  State<AddCaregiverScreen> createState() => _AddCaregiverScreenState();
}

class _AddCaregiverScreenState extends State<AddCaregiverScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Caregiver> _filteredCaregivers = [];
  List<Caregiver> _allCaregivers = [];
  bool _isSearching = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  void initState() {
    super.initState();
    _loadCaregiversFromFirebase();
    
    _searchController.addListener(() {
      _filterCaregivers();
    });
  }

  // Update the _loadCaregiversFromFirebase method to also check for accepted requests
  Future<void> _loadCaregiversFromFirebase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Get current user's data to check which caregivers are already added
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final List<String> assignedCaregiverIds = [];
      
      if (userData != null && userData.containsKey('assignedCaregivers')) {
        assignedCaregiverIds.addAll(List<String>.from(userData['assignedCaregivers'] ?? []));
      }
      
      // Get all caregiver requests (pending, accepted, and declined)
      final caregiverRequestsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('caregiver_requests')
          .get();
        
      final Map<String, String> requestStatuses = {};
      for (var doc in caregiverRequestsSnapshot.docs) {
        final data = doc.data();
        requestStatuses[doc.id] = data['status'] as String? ?? 'pending';
      }
      
      // Fetch caregivers and family members
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userType', whereIn: ['caregiver', 'family_member'])
          .get();
    
      final List<Caregiver> caregivers = [];
      
      for (var doc in snapshot.docs) {
        final caregiver = Caregiver.fromFirestore(doc);
        
        // Check if this caregiver is already assigned or has a request
        final bool isAssigned = assignedCaregiverIds.contains(caregiver.id);
        final String requestStatus = requestStatuses[caregiver.id] ?? '';
        final bool hasPendingRequest = requestStatus == 'pending';
        final bool isAccepted = requestStatus == 'accepted';
        
        // A caregiver is considered "added" if they're assigned, have a pending request, or have an accepted request
        final bool isAdded = isAssigned || hasPendingRequest || isAccepted;
        
        caregivers.add(Caregiver(
          id: caregiver.id,
          name: caregiver.name,
          imageUrl: caregiver.imageUrl,
          isAdded: isAdded,
          userType: caregiver.userType,
          createdAt: caregiver.createdAt,
          dateOfBirth: caregiver.dateOfBirth,
        ));
      }
      
      setState(() {
        _allCaregivers = caregivers;
        _filteredCaregivers = _isSearching ? _filteredCaregivers : [];
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading caregivers: $e');
      setState(() {
        _errorMessage = 'Failed to load caregivers: $e';
        _isLoading = false;
      });
    }
  }

  void _filterCaregivers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
        _filteredCaregivers = [];
      } else {
        _isSearching = true;
        _filteredCaregivers = _allCaregivers
            .where((caregiver) => caregiver.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _toggleCaregiverAssignment(Caregiver caregiver) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // If already added, we'll remove the caregiver
      if (caregiver.isAdded) {
        final userRef = _firestore.collection('users').doc(currentUser.uid);
        final userDoc = await userRef.get();
        
        if (!userDoc.exists) {
          throw Exception('User document not found');
        }
        
        final userData = userDoc.data() as Map<String, dynamic>;
        List<String> assignedCaregivers = List<String>.from(userData['assignedCaregivers'] ?? []);
        
        // Remove caregiver
        assignedCaregivers.remove(caregiver.id);
        
        // Update in Firestore
        await userRef.update({
          'assignedCaregivers': assignedCaregivers
        });
        
        // Also check if there's a pending request and delete it
        final requestDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('caregiver_requests')
            .doc(caregiver.id)
            .get();
            
        if (requestDoc.exists) {
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('caregiver_requests')
              .doc(caregiver.id)
              .delete();
        }
        
        // Update local state
        setState(() {
          final index = _allCaregivers.indexWhere((c) => c.id == caregiver.id);
          if (index != -1) {
            _allCaregivers[index] = Caregiver(
              id: caregiver.id,
              name: caregiver.name,
              imageUrl: caregiver.imageUrl,
              isAdded: false,
              userType: caregiver.userType,
              createdAt: caregiver.createdAt,
              dateOfBirth: caregiver.dateOfBirth,
            );
          }
          
          final filteredIndex = _filteredCaregivers.indexWhere((c) => c.id == caregiver.id);
          if (filteredIndex != -1) {
            _filteredCaregivers[filteredIndex] = _allCaregivers[index];
          }
        });
        
        // Show success dialog
        _showToggleSuccessDialog(caregiver.name, true);
      } else {
        // If not added, we'll send a request to the caregiver
        // Get elder's data
        final elderDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (!elderDoc.exists) {
          throw Exception('Elder profile not found');
        }

        final elderData = elderDoc.data()!;
        final elderName = elderData['name'] ?? 'Unknown Elder';
        final elderProfileImage = elderData['profileImage'] ?? 'assets/default_avatar.png';

        // Check if there's already a pending request
        final existingRequestQuery = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('caregiver_requests')
            .doc(caregiver.id)
            .get();
            
        if (existingRequestQuery.exists) {
          final requestData = existingRequestQuery.data();
          if (requestData != null && requestData['status'] == 'pending') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You already have a pending request for this caregiver'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }

        // Create a request in the caregiver's notifications collection
        await _firestore
            .collection('users')
            .doc(caregiver.id)
            .collection('notifications')
            .add({
          'type': 'caregiver_request',
          'title': 'Caregiver Request',
          'message': '$elderName is requesting to assign you as their caregiver',
          'elderName': elderName,
          'elderId': currentUser.uid,
          'elderImage': elderProfileImage,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'color': const Color(0xFFE2D9F3).value, // Convert to int for Firestore
          'textColor': const Color(0xFF6A359C).value,
          'icon': 'person_add', // Store icon name as string
          'iconColor': Colors.purple.value,
        });

        // Also store the request in the elder's sent requests
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('caregiver_requests')
            .doc(caregiver.id)
            .set({
          'caregiverId': caregiver.id,
          'caregiverName': caregiver.name,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update local state to show as added (pending)
        setState(() {
          final index = _allCaregivers.indexWhere((c) => c.id == caregiver.id);
          if (index != -1) {
            _allCaregivers[index] = Caregiver(
              id: caregiver.id,
              name: caregiver.name,
              imageUrl: caregiver.imageUrl,
              isAdded: true,
              userType: caregiver.userType,
              createdAt: caregiver.createdAt,
              dateOfBirth: caregiver.dateOfBirth,
            );
          }
          
          final filteredIndex = _filteredCaregivers.indexWhere((c) => c.id == caregiver.id);
          if (filteredIndex != -1) {
            _filteredCaregivers[filteredIndex] = _allCaregivers[index];
          }
        });
        
        // Show success dialog
        _showToggleSuccessDialog(caregiver.name, false);
      }
      
    } catch (e) {
      print('Error toggling caregiver assignment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showToggleSuccessDialog(String caregiverName, bool wasAdded) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: wasAdded ? Colors.red : const Color(0xFF80FF80),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    wasAdded ? Icons.close : Icons.check,
                    color: wasAdded ? Colors.red : const Color(0xFF80FF80),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  wasAdded
                      ? 'Successfully canceled the request that was sent to caregiver $caregiverName'
                      : 'Request sent to caregiver $caregiverName successfully. They will need to accept your request.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wasAdded ? Colors.red : Colors.blue,
                    minimumSize: const Size(100, 40),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCaregiverProfile(Caregiver caregiver) {
    // Calculate age from date of birth if available
    String ageText = 'Age not available';
    if (caregiver.dateOfBirth != null) {
      try {
        final parts = caregiver.dateOfBirth!.split('/');
        if (parts.length == 3) {
          final birthDate = DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
          final age = DateTime.now().difference(birthDate).inDays ~/ 365;
          ageText = '$age years';
        }
      } catch (e) {
        print('Error calculating age: $e');
      }
    }
    
    // Format created date
    String createdDateText = 'Join date not available';
    if (caregiver.createdAt != null) {
      createdDateText = 'Joined on ${DateFormat('MMMM d, yyyy').format(caregiver.createdAt!)}';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: caregiver.imageUrl != null && caregiver.imageUrl!.isNotEmpty
                      ? NetworkImage(caregiver.imageUrl!) as ImageProvider
                      : null,
                  child: caregiver.imageUrl == null || caregiver.imageUrl!.isEmpty
                      ? Text(
                          caregiver.name.isNotEmpty ? caregiver.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 40, color: Colors.grey.shade700),
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  caregiver.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  caregiver.userType == 'caregiver' ? 'Caregiver' : 'Family Member',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Age:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            ageText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Joined:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            createdDateText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Replace the _showAlreadyAddedDialog method with this updated version
void _showAlreadyAddedDialog(Caregiver caregiver) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<DocumentSnapshot>(
        future: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .collection('caregiver_requests')
            .doc(caregiver.id)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Checking request status...'),
                  ],
                ),
              ),
            );
          }
          
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final status = data?['status'] as String? ?? 'pending';
          
          if (status == 'pending') {
            // Show dialog for pending request with option to cancel
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.pending_actions,
                        color: Colors.orange,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pending Request',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You have already sent a request to ${caregiver.name}. Would you like to cancel this request?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Keep Waiting'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _cancelCaregiverRequest(caregiver);
                          },
                          child: const Text('Cancel Request'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else if (status == 'accepted') {
            // Show dialog for accepted request with option to reassign
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Caregiver Already Assigned',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${caregiver.name} is already your assigned caregiver. Would you like to remove them?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
      
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: -1), // Assuming 2 is the index for the caregiver/settings tab
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

