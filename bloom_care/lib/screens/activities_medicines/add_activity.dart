import 'package:flutter/material.dart';

class Caregiver {
  final String id;
  final String name;
  final String imageUrl;
  final bool isAdded;

  Caregiver({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isAdded = false,
  });
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

  @override
  void initState() {
    super.initState();
    // Mock data with temporary profile pictures
    _allCaregivers = [
      Caregiver(
        id: '1',
        name: 'Mr. Richard Thomsan',
        imageUrl:
            'https://familydoctor.org/wp-content/uploads/2018/02/41808433_l-848x566.jpg',
      ),
      Caregiver(
        id: '2',
        name: 'Mr. David Wilson',
        imageUrl:
            'https://img.freepik.com/free-photo/portrait-smiling-male-doctor_171337-1532.jpg',
      ),
      Caregiver(
        id: '3',
        name: 'Sarah Johnson',
        imageUrl:
            'https://img.freepik.com/free-photo/woman-doctor-wearing-lab-coat-with-stethoscope-isolated_1303-29791.jpg',
      ),
      Caregiver(
        id: '4',
        name: 'Michael Brown',
        imageUrl:
            'https://img.freepik.com/free-photo/doctor-with-his-arms-crossed-white-background_1368-5790.jpg',
      ),
    ];

    _searchController.addListener(() {
      _filterCaregivers();
    });
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

  void _addCaregiver(String caregiverId) {
    setState(() {
      final index = _allCaregivers.indexWhere((c) => c.id == caregiverId);
      if (index != -1) {
        final caregiver = _allCaregivers[index];
        final bool wasAdded = caregiver.isAdded; // Store previous state

        _allCaregivers[index] = Caregiver(
          id: caregiver.id,
          name: caregiver.name,
          imageUrl: caregiver.imageUrl,
          isAdded: !caregiver.isAdded,
        );

        // Also update in filtered list if present
        final filteredIndex =
            _filteredCaregivers.indexWhere((c) => c.id == caregiverId);
        if (filteredIndex != -1) {
          _filteredCaregivers[filteredIndex] = _allCaregivers[index];
        }

        // Show dialog for both adding and removing
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
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: wasAdded ? Colors.red : Color(0xFF80FF80),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        wasAdded ? Icons.close : Icons.check,
                        color: wasAdded ? Colors.red : Color(0xFF80FF80),
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      wasAdded
                          ? 'Successfully canceled caregiver'
                          : 'Request sent successfully to caregiver',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('OK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: wasAdded ? Colors.red : Colors.blue,
                        minimumSize: Size(100, 40),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFE6F0FF),
        elevation: 0,
        title: Text(
          'Add Your Caregiver',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Navigate back
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.people_alt_outlined,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Color(0xFFE6F0FF),
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Caregiver',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: Icon(Icons.search),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? ListView.builder(
                    itemCount: _filteredCaregivers.length,
                    itemBuilder: (context, index) {
                      final caregiver = _filteredCaregivers[index];
                      return _buildCaregiverCard(caregiver);
                    },
                  )
                : Center(
                    child: Text(
                      'Search for caregivers to add',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverCard(Caregiver caregiver) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Color(0xFFE6F0FF),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: caregiver.imageUrl.startsWith('http')
                  ? NetworkImage(caregiver.imageUrl) as ImageProvider
                  : AssetImage(caregiver.imageUrl),
              backgroundColor: Colors.grey.shade300,
              onBackgroundImageError: (_, __) {
                // Handle error silently
              },
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Text(
                caregiver.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // View caregiver profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFFF80),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  child: Text('View'),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () => _addCaregiver(caregiver.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        caregiver.isAdded ? Colors.grey : Color(0xFF80FF80),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  child: Text(caregiver.isAdded ? 'Added' : 'Add +'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
