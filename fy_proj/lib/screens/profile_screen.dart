import 'package:flutter/material.dart';
import 'package:fy_proj/providers/auth_provider.dart';
import 'package:fy_proj/services/shared_prefs_service.dart';
import 'package:provider/provider.dart'; // Import your service for fetching data

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Sample user data, you can replace this with actual fetched data from your service or settings
  String userName = "John Doe";
  String email = "john.doe@example.com";
  String profilePictureUrl = "https://www.w3schools.com/w3images/avatar2.png"; // Sample image URL
  String bio = "";

  final SharedPrefsService sharedPrefsService = SharedPrefsService(); // Service to fetch user details

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data on screen load
  }

  // Fetch user details from SharedPrefs or any other service you have
  
  void _fetchUserData() async {
    AuthProvider _authProvider = AuthProvider();
    await _authProvider.getUserProfile();
    print("Authorized user: ${_authProvider.user}");
    setState(() {
      userName = _authProvider.user!['username'];
      email = _authProvider.user!['email'];
      bio = _authProvider.user?['bio'] == null ? '' : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    // final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body:  Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authProvider.user == null) {
            return const Center(
              child: Text('User information not available.'),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile picture and basic info
                    _buildProfileCard(),
                    const SizedBox(height: 30),
                    _buildDetailsCard(),
                  ],
                ),
              ),
            ),
          );
        }
      )
    );
  }

  // Profile section with profile picture and username
  Widget _buildProfileCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: const Color.fromARGB(255, 255, 255, 255), // White color for the card
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(profilePictureUrl),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card displaying additional user information (phone, address, etc.)
  Widget _buildDetailsCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: const Color.fromARGB(255, 255, 255, 255), // White color for the card
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Additional Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            _buildDetailRow("Bio", bio),
            const Divider(),
            _buildDetailRow("Phone", "+1 (555) 123-4567"), // Dynamic data example
            const Divider(),
            _buildDetailRow("Address", "1234 Elm Street, Springfield, IL"), // Dynamic data example
            const Divider(),
            _buildDetailRow("Joined", "January 2025"), // Dynamic data example
          ],
        ),
      ),
    );
  }

  // Helper method to create rows for additional details
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
