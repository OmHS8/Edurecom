import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fy_proj/providers/user_statistics_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:intl/intl.dart';

import '../resources/models.dart';

class UserStatisticsScreen extends StatefulWidget {
  const UserStatisticsScreen({super.key});

  @override
  _UserStatisticsScreenState createState() => _UserStatisticsScreenState();
}

class _UserStatisticsScreenState extends State<UserStatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load statistics when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserStatisticsProvider>(context, listen: false).loadAllStatistics();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Statistics', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          // dividerColor: Colors.white,
          indicatorColor: Colors.black,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
          controller: _tabController,
          tabs: const [
            Tab(child: Text('Overview', style: TextStyle(color: Colors.white))),
            Tab(child: Text('Performance',style: TextStyle(color: Colors.white))),
            Tab(child: Text('Time Analysis', style: TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: Consumer<UserStatisticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load statistics',
                    style: TextStyle(fontSize: 18, color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAllStatistics(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (provider.statistics == null) {
            return const Center(child: Text('No statistics available'));
          }
          
          return RefreshIndicator(
            onRefresh: () => provider.loadAllStatistics(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(provider),
                _buildPerformanceTab(provider),
                _buildTimeAnalysisTab(provider),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildOverviewTab(UserStatisticsProvider provider) {
    final stats = provider.statistics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top stats cards
          _buildStatsGrid(provider),
          
          const SizedBox(height: 24),
          
          // Progress information
          _buildSectionTitle('Your Progress'),
          const SizedBox(height: 8),
          
          // Quiz completion progress
          _buildProgressIndicator(
            'Quiz Completion',
            '${stats.quizzesCompleted}/${stats.totalQuizzesAvailable} Quizzes',
            stats.quizCompletionRate / 100,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          // Accuracy rate progress
          _buildProgressIndicator(
            'Accuracy Rate',
            '${stats.accuracyRate.toStringAsFixed(1)}%',
            stats.accuracyRate / 100,
            Colors.green,
          ),
          
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.black, width: 8),
              borderRadius: BorderRadius.circular(18)
            ),
            child: Column(
              children: [
                const Text(
                    'Subject Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                ),
                // _buildSectionTitle()/,
                const SizedBox(height: 16),
                
                if (provider.subjectPerformance.isEmpty)
                  const Center(
                    child: Text('No subject performance data available yet'),
                  )
                else
                  Container(
                    height: 200,
                    child: _buildSubjectPerformanceChart(provider),
                  ),
              ],
            ),
          ),
          
          // Subject performance
            
          const SizedBox(height: 24),
          
          // Improvement areas
          _buildSectionTitle('Areas for Improvement'),
          const SizedBox(height: 16),
          
          _buildImprovementCard(provider),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceTab(UserStatisticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Score History'),
          const SizedBox(height: 16),
          
          if (provider.timingData.isEmpty)
            const Center(
              child: Text('No quiz data available yet'),
            )
          else 
            Container(
              height: 250,
              child: _buildScoreHistoryChart(provider),
            ),
            
          const SizedBox(height: 24),
          
          _buildSectionTitle('Quiz Performance Details'),
          const SizedBox(height: 16),
          
          if (provider.timingData.isEmpty)
            const Center(
              child: Text('No quiz performance data available yet'),
            )
          else
            Column(
              children: provider.timingData.map((quiz) => 
                _buildQuizPerformanceCard(quiz)
              ).toList(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTimeAnalysisTab(UserStatisticsProvider provider) {
    final stats = provider.statistics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Time Statistics'),
          const SizedBox(height: 16),
          
          Card(
            color: Colors.black,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeStatRow(
                    'Average Completion Time', 
                    provider.formatDuration(stats.averageCompletionTime)
                  ),
                  const Divider(),
                  _buildTimeStatRow(
                    'Fastest Quiz', 
                    '${stats.fastestQuizName ?? 'N/A'} (${provider.formatDuration(stats.fastestQuizCompletion)})'
                  ),
                  const Divider(),
                  _buildTimeStatRow(
                    'Slowest Quiz', 
                    '${stats.slowestQuizName ?? 'N/A'} (${provider.formatDuration(stats.slowestQuizCompletion)})'
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Quiz Timing Analysis'),
          const SizedBox(height: 16),
          
          if (provider.timingData.isEmpty)
            const Center(
              child: Text('No quiz timing data available yet'),
            )
          else
            Container(
              height: 250,
              child: _buildQuizTimingChart(provider),
            ),
            
          const SizedBox(height: 24),
          
          _buildSectionTitle('Time vs. Accuracy'),
          const SizedBox(height: 16),
          
          if (provider.timingData.isEmpty)
            const Center(
              child: Text('No quiz timing data available yet'),
            )
          else
            Container(
              height: 250,
              child: _buildTimeVsAccuracyChart(provider),
            ),
        ],
      ),
    );
  }
  
  // Helper widgets
  
  Widget _buildStatsGrid(UserStatisticsProvider provider) {
    final stats = provider.statistics!;
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Quizzes Completed', '${stats.quizzesCompleted}', Icons.check_circle_outline, Colors.green),
        _buildStatCard('Average Score', '${stats.averageScore.toStringAsFixed(1)}%', Icons.star_outline, Colors.amber),
        _buildStatCard('Quizzes Attempted', '${stats.quizzesAttempted}', Icons.play_circle_outline, Colors.blue),
        _buildStatCard('Recommendations', '${stats.recommendationsReceived}', Icons.lightbulb_outline, Colors.orange),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.black,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 255, 254, 254),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black
      ),
    );
  }
  
  Widget _buildProgressIndicator(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  Widget _buildSubjectPerformanceChart(UserStatisticsProvider provider) {
    final subjects = provider.subjectPerformance;
    
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        minimum: 0,
        maximum: 100,
        interval: 25,
        labelFormat: '{value}%',
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        ColumnSeries<dynamic, String>(
          dataSource: subjects,
          xValueMapper: (dynamic data, _) => data.subjectName,
          yValueMapper: (dynamic data, _) => data.averageScore,
          pointColorMapper: (dynamic data, _) => 
            data.averageScore >= 70 
                ? Colors.green 
                : data.averageScore >= 50 
                    ? Colors.amber 
                    : Colors.red,
          width: 0.6,
          borderRadius: BorderRadius.circular(4),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
          name: 'Subject Performance',
        ),
      ],
    );
  }
  
  Widget _buildImprovementCard(UserStatisticsProvider provider) {
    final stats = provider.statistics!;
    
    return Card(
      color: Colors.black,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Improvement Suggestions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Weakest subject suggestion
            if (stats.weakestSubjectName != null) ...[
              Text(
                '• Focus on improving your knowledge in ${stats.weakestSubjectName}',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 8),
            ],
            
            // Low completion rate suggestion
            if (stats.quizCompletionRate < 50) ...[
              const Text(
                '• Try to complete more quizzes to improve your overall progress',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 8),
            ],
            
            // Low accuracy suggestion
            if (stats.accuracyRate < 70) ...[
              const Text(
                '• Review your answers to improve your accuracy rate',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 8),
            ],
            
            // General suggestion
            const Text(
              '• Check out personalized recommendations to enhance your learning',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreHistoryChart(UserStatisticsProvider provider) {
    final timingData = provider.timingData;
    
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(fontSize: 10),
        labelPlacement: LabelPlacement.onTicks,
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: 100,
        interval: 25,
        labelFormat: '{value}%',
        axisLine: const AxisLine(width: 1),
        majorGridLines: MajorGridLines(width: 1, color: Colors.grey.shade300),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        SplineSeries<QuizTimingData, String>(
          dataSource: timingData,
          xValueMapper: (QuizTimingData data, _) => data.quizTitle.length > 10
              ? '${data.quizTitle.substring(0, 10)}...'
              : data.quizTitle,
          yValueMapper: (QuizTimingData data, _) => data.score,
          color: Colors.blue,
          markerSettings: const MarkerSettings(isVisible: true),
          name: 'Score',
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          enableTooltip: true,
        ),
        AreaSeries<QuizTimingData, String>(
          dataSource: timingData,
          xValueMapper: (QuizTimingData data, _) => data.quizTitle.length > 10
              ? '${data.quizTitle.substring(0, 10)}...'
              : data.quizTitle,
          yValueMapper: (QuizTimingData data, _) => data.score,
          color: Colors.blue.withOpacity(0.2),
          borderColor: Colors.blue,
          borderWidth: 2,
          name: 'Score Trend',
          enableTooltip: true,
        ),
      ],
    );
  }
  
  Widget _buildTimeStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuizTimingChart(UserStatisticsProvider provider) {
    final timingData = provider.timingData;
    
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        labelFormat: '{value} min',
        axisLine: const AxisLine(width: 1),
        majorGridLines: MajorGridLines(width: 1, color: Colors.grey.shade300),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        ColumnSeries<QuizTimingData, String>(
          dataSource: timingData,
          xValueMapper: (QuizTimingData data, _) => data.quizTitle.length > 10
              ? '${data.quizTitle.substring(0, 10)}...'
              : data.quizTitle,
          yValueMapper: (QuizTimingData data, _) => data.durationMinutes,
          color: Colors.orange,
          width: 0.6,
          borderRadius: BorderRadius.circular(4),
          name: 'Duration',
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
      ],
    );
  }
  
  Widget _buildTimeVsAccuracyChart(UserStatisticsProvider provider) {
    final timingData = provider.timingData;
    
    // Create chart data for scatter plot
    List<ScatterTimeAccuracyData> scatterData = timingData.map((quiz) {
      final accuracy = quiz.questionCount > 0 
          ? (quiz.correctAnswers / quiz.questionCount) * 100 
          : 0.0;
      return ScatterTimeAccuracyData(
        quizTitle: quiz.quizTitle,
        durationMinutes: quiz.durationMinutes,
        accuracy: accuracy,
      );
    }).toList();
    
    return SfCartesianChart(
      primaryXAxis: NumericAxis(
        title: AxisTitle(text: 'Time (minutes)'),
        minimum: 0,
        axisLine: const AxisLine(width: 1),
        majorGridLines: MajorGridLines(width: 1, color: Colors.grey.shade300),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Accuracy (%)'),
        minimum: 0,
        maximum: 100,
        interval: 20,
        labelFormat: '{value}%',
        axisLine: const AxisLine(width: 1),
        majorGridLines: MajorGridLines(width: 1, color: Colors.grey.shade300),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        ScatterSeries<ScatterTimeAccuracyData, double>(
          dataSource: scatterData,
          xValueMapper: (ScatterTimeAccuracyData data, _) => data.durationMinutes,
          yValueMapper: (ScatterTimeAccuracyData data, _) => data.accuracy,
          markerSettings: const MarkerSettings(
            height: 10,
            width: 10,
            shape: DataMarkerType.circle,
            borderWidth: 2,
            borderColor: Colors.blue,
          ),
          name: 'Time vs Accuracy',
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          enableTooltip: true,
        ),
      ],
    );
  }
  
  Widget _buildQuizPerformanceCard(QuizTimingData quiz) {
    final accuracy = quiz.questionCount > 0 
        ? (quiz.correctAnswers / quiz.questionCount) * 100 
        : 0.0;
        
    return Card(
      color: Colors.black,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quiz.quizTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 8),
            Text('Date: ${quiz.date}', style: const TextStyle(color: Colors.white),),
            const SizedBox(height: 4),
            Text('Score: ${quiz.score.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text('Accuracy: ${accuracy.toStringAsFixed(1)}% (${quiz.correctAnswers}/${quiz.questionCount})', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text('Time: ${quiz.durationMinutes} minutes', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: quiz.score / 100,
              backgroundColor: Colors.blue.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                quiz.score >= 70 ? Colors.green : quiz.score >= 50 ? Colors.amber : Colors.red,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }
}

// Data class for scatter plot
class ScatterTimeAccuracyData {
  final String quizTitle;
  final double durationMinutes;
  final double accuracy;
  
  ScatterTimeAccuracyData({
    required this.quizTitle,
    required this.durationMinutes,
    required this.accuracy,
  });
}