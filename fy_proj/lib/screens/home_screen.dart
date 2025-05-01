import 'package:flutter/material.dart';
import 'package:fy_proj/screens/chat_screen.dart';
import 'package:fy_proj/screens/past_recommendations_screen.dart';
import 'package:fy_proj/screens/quiz_list_screen.dart';
import 'package:fy_proj/services/quiz_api.dart';
import 'package:fy_proj/widgets/home_screen_widgets.dart';
import 'package:fy_proj/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_screen.dart';
import '../screens/quiz_screen.dart';
import '../services/shared_prefs_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'user_statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SharedPrefsService sharedPrefsService = SharedPrefsService();
  int? selectedSubjectId;
  String? selectedSubjectName;
  String selectedExam = "GATE EXAM";
  bool _isLoading = true;
  bool _showAllSubjects = false;
  int _initialSubjectsCount = 4;

  final List<Widget> _screens = [
    const QuizScreen(), 
    const PastRecommendationsScreen(),
    const UserStatisticsScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = ["EDUREC", "Past Recommendations", "Stats", "Chatbot", "Profile"];

  int _selectedIndex = 0;

  List<String> subjects = [];
  Map<int, String> subjectss = {};
  Map<String, dynamic> stats = {};

  void onSubjectSelected(String name) {
    int index = subjects.indexOf(name);
    setState(() {
      selectedSubjectId = index;
      selectedSubjectName = name;
    });
    int subjectid = subjectss.keys.firstWhere((k) => subjectss[k] == name);
    print("Setting subject id to $subjectid");
    sharedPrefsService.setSubjectId(subjectid);
    
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizListScreen(
            subjectId: subjectid,
            subjectName: name,
          ),
        ),
      ).then((_) {
        setState(() {
          selectedSubjectId = null;
          selectedSubjectName = null;
        });
      });
    }
  }

  void _loadSubjects() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      var data = await QuizApiService().fetchSubjects();
      var statsData = await QuizApiService().fetchStatsOverView();

      setState(() {
        subjectss = data;
        stats = statsData;
        subjects = data.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading subjects: $e");
      setState(() {
        _isLoading = false;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load subjects: ${e.toString()}")),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {   
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: (_selectedIndex == 0) ? Text(
              _titles[_selectedIndex],
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 32,
              )) : Text(
              _titles[_selectedIndex],
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 24,
              )
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          drawer: Drawer(
            backgroundColor: Colors.white,
            child: Column(
              children: <Widget>[
                Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.black,
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.account_circle,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        authProvider.user != null ? authProvider.user!["username"] : "Guest", 
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(Icons.settings, 'Settings', () {}),
                      _buildDrawerItem(Icons.group, 'Socials', () {}),
                      _buildDrawerItem(Icons.info_outline, 'About', () {}),
                      const Divider(height: 1),
                      _buildDrawerItem(Icons.logout, 'Logout', () async {
                        await authProvider.logout();
                        print("Logout successful");
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: _selectedIndex == 0 
              ? SafeArea(
                  child: _isLoading 
                    ? const Center(child: SimpleLoadingWidget())
                    : _buildHomeContent(),
                )
              : SafeArea(child: _screens[_selectedIndex]),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  label: 'Past Rec',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.query_stats_rounded),
                  label: 'Stats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  label: 'Bot',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600, 
                fontSize: 12,
              ),
              unselectedLabelStyle: GoogleFonts.montserrat(
                fontSize: 11,
              ),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              onTap: _onItemTapped,
            ),
          ),
        );
      }
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedExam,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Change',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subjects',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllSubjects = !_showAllSubjects;
                        });
                      },
                      child: Text(
                        _showAllSubjects ? 'Show Less' : 'Show All',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Grid view
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: _showAllSubjects ? subjects.length : _initialSubjectsCount.clamp(0, subjects.length),
                  itemBuilder: (context, index) {
                    final isSelected = selectedSubjectId == index;
                    return GestureDetector(
                      onTap: () => onSubjectSelected(subjects[index]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            if (!isSelected)
                              Positioned(
                                top: -15,
                                right: -15,
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getSubjectIcon(subjects[index]),
                                      size: 28,
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          subjects[index],
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? Colors.white : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '5 quizzes',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: isSelected ? Colors.white54 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Show/hide button (alternative to the header button)
                if (!_showAllSubjects && subjects.length > _initialSubjectsCount)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllSubjects = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Show ${subjects.length - _initialSubjectsCount} more subjects',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.keyboard_arrow_down, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
            child: Text(
              'Overview',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildStatsCard(),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
            child: Text(
              'Recent Articles',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const RecentArticlesCard(),
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
            child: Text(
              'To-Do List',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const TodoListCard(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics Overview',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('${stats['completion_rate']}%', 'Quiz Completion'),
              _buildStatItem(stats['quizzes_taken'] , 'Quizzes Taken'),
              _buildStatItem('${stats['accuracy']}%', 'Accuracy Rate'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'View Detailed Stats',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
  
  IconData _getSubjectIcon(String subject) {
    // Map subject names to appropriate icons
    final Map<String, IconData> iconMap = {
      'Mathematics': Icons.calculate_rounded,
      'Physics': Icons.science_rounded,
      'Chemistry': Icons.biotech_rounded,
      'Computer Science': Icons.computer_rounded,
      'Engineering': Icons.engineering_rounded,
    };
    
    // Match subject name (case insensitive partial match)
    for (var entry in iconMap.entries) {
      if (subject.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Default icon if no match
    return Icons.book_rounded;
  }
}