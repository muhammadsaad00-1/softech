import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatelessWidget {
  final String userId;
  const ProgressScreen({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Tracker'),
        backgroundColor: Colors.orange[800],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getProgressData(userId), // Your async function
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStreakBar(data['currentStreak'], data['longestStreak']),
                SizedBox(height: 24),
                _buildCategoryPie(data['categoryDistribution']),
                SizedBox(height: 24),
                _buildAchievements(data['achievements']),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakBar(int current, int longest) {
    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Task Streaks', style: TextStyle(fontSize: 18)),
              SizedBox(height: 12),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [
                        BarChartRodData(toY: current.toDouble(), color: Colors.orange)
                      ]),
                      BarChartGroupData(x: 1, barRods: [
                        BarChartRodData(toY: longest.toDouble(), color: Colors.blue)
                      ]),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) {
                          return Text(value == 0 ? 'Current' : 'Longest');
                        }),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPie(Map<String, int> categories) {
    final total = categories.values.fold(0, (a, b) => a + b);
    return SizedBox(
      height: 300,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Task Load Balance', style: TextStyle(fontSize: 18)),
              SizedBox(height: 12),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: categories.entries.map((entry) {
                      final percent = (entry.value / total) * 100;
                      return PieChartSectionData(
                        color: _getCategoryColor(entry.key),
                        value: percent,
                        title: '${entry.key}\n${percent.toStringAsFixed(1)}%',
                        radius: 40,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievements(List achievements) {
    if (achievements.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No achievements yet. Keep going!'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievements', style: TextStyle(fontSize: 18)),
            ...achievements.map((a) => ListTile(
              leading: Text(a['icon'], style: TextStyle(fontSize: 24)),
              title: Text(a['name']),
            )),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Academic': return Colors.blue;
      case 'Personal': return Colors.orange;
      case 'Health': return Colors.green;
      case 'Sports': return Colors.red;
      case 'Hobby': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

// Example async data function (replace with your real logic)
Future<Map<String, dynamic>> getProgressData(String userId) async {
  // ... fetch and process your Firestore data here
  // For demo purposes:
  return {
    'currentStreak': 3,
    'longestStreak': 7,
    'categoryDistribution': {
      'Academic': 10,
      'Personal': 5,
      'Health': 3,
      'Sports': 2,
      'Hobby': 1,
    },
    'achievements': [
      {'name': '5-Day Streak', 'icon': '🏆'},
      {'name': 'Task Master', 'icon': '🎯'},
    ],
  };
}
