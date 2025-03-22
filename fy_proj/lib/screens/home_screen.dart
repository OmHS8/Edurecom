import 'package:flutter/material.dart';
import 'package:fy_proj/screens/chat_screen.dart';
import 'package:fy_proj/screens/quiz_list_screen.dart'; // Import the new screen
import 'package:fy_proj/widgets/fact_widget.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/quiz_screen.dart';
import '../services/shared_prefs_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SharedPrefsService sharedPrefsService = SharedPrefsService();
  int? selectedSubjectId;
  String? selectedSubjectName;

  // List to hold screens for bottom navigation
  final List<Widget> _screens = [
    const QuizScreen(), // Quiz Screen as home
    const ProfileScreen(), // Profile Screen
    const StatsScreen(), // Stats Screen
  ];

  int _selectedIndex = 0; // State to track the selected index

  final List<String> subjects = [
    "Operating Systems",
    "Compiler Design",
    "Computer networks"
  ];

  // Method to handle subject selection
  void onSubjectSelected(String name) {
    int index = subjects.indexOf(name);
    setState(() {
      selectedSubjectId = index;
      selectedSubjectName = subjects[index];
    });
    index++; // Incrementing to match the expected subject ID logic
    print("Setting subject id to $index");
    sharedPrefsService.setSubjectId(index);
    
    // Navigate to the quiz list screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizListScreen(
            subjectId: index,
            subjectName: name,
          ),
        ),
      );
    }
  }

  // Method to handle bottom navigation item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {   
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edurecom'),
            centerTitle: true,
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            shadowColor: Colors.black,
            elevation: 10,
          ),
          drawer: Drawer(
            child: ListView(
              children: <Widget>[
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 174, 218, 255),
                  ),
                  child: Icon(
                    Icons.account_circle,
                    size: 60,
                  ),
                ),
                ListTile(
                  title: const Text('ChatBot'),
                  onTap: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChatScreen()));
                  },
                ),
                ListTile(
                  title: const Text('Settings'),
                  onTap: () async {},
                ),
                ListTile(
                  title: const Text('Socials'),
                  onTap: () async {},
                ),
                ListTile(
                  title: const Text('About'),
                  onTap: () async {},
                ),
                ListTile(
                  title: const Text('Logout'),
                  onTap: () async {
                    await authProvider.logout();
                    print("Logout successful");
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ],
            ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.white,
              ),
              SafeArea(
                child: _selectedIndex == 0 // Show Quiz Screen with subject selection
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            FactOfTheDay(),
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'Selected: GATE EXAM',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black),
                              ),
                            ),
                            SizedBox(
                              height: 180, // Adjust height as needed
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: subjects.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => onSubjectSelected(subjects[index]),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        width: 160,
                                        decoration: BoxDecoration(
                                          color: selectedSubjectId == index
                                              ? Colors.teal
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 5,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.book,
                                              size: 50,
                                              color: selectedSubjectId == index
                                                  ? Colors.white
                                                  : Colors.blue,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              subjects[index],
                                              style: GoogleFonts.lato(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: selectedSubjectId == index
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      )
                    : _screens[_selectedIndex],
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            iconSize: 30,
            selectedFontSize: 20,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Quiz',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color.fromARGB(255, 36, 104, 99),
            onTap: _onItemTapped, // Handle taps
          ),
        );
      }
    );
  }
}