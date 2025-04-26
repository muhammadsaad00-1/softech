import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';


import 'mood_model.dart';

class MoodInsights extends StatefulWidget {
  @override
  _MoodInsightsState createState() => _MoodInsightsState();
}

class _MoodInsightsState extends State<MoodInsights> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _timeRange = 'week'; // 'week', 'month', or 'year'

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("Please log in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Mood Insights"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _timeRange = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'week', child: Text("Last Week")),
                PopupMenuItem(value: 'month', child: Text("Last Month")),
                PopupMenuItem(value: 'year', child: Text("Last Year")),
              ];
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _getMoodData(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final moods = snapshot.data!.docs
              .map((doc) => MoodEntry.fromFirestore(doc))
              .toList();

          if (moods.isEmpty) {
            return Center(child: Text("No mood data available"));
          }

          // Process data for charts
          final moodCounts = _calculateMoodCounts(moods);
          final weeklyTrends = _calculateWeeklyTrends(moods);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMoodDistributionChart(moodCounts),
                SizedBox(height: 30),
                _buildMoodTrendChart(weeklyTrends),
                SizedBox(height: 20),
                _buildCommonMoodsList(moodCounts),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to get mood color
  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return Colors.yellow;
      case 'sad': return Colors.blue;
      case 'angry': return Colors.red;
      case 'excited': return Colors.orange;
      case 'tired': return Colors.grey;
      case 'loving': return Colors.pink;
      case 'productive': return Colors.green;
      case 'lazy': return Colors.brown;
      default: return Colors.purple;
    }
  }

  // Calculate weekly mood trends
  List<WeeklyTrend> _calculateWeeklyTrends(List<MoodEntry> moods) {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));

    // Filter moods from last week and group by day
    final lastWeekMoods = moods.where((mood) => mood.date.isAfter(weekAgo)).toList();

    // Create a map of day numbers (0-6) to average mood intensity
    final dayAverages = <int, double>{};

    for (int i = 0; i < 7; i++) {
      final day = weekAgo.add(Duration(days: i)).weekday;
      final dayMoods = lastWeekMoods.where((mood) => mood.date.weekday == day);

      if (dayMoods.isNotEmpty) {
        final average = dayMoods.map((m) => m.intensity ?? 3).reduce((a, b) => a + b) /
            dayMoods.length;
        dayAverages[day] = average;
      } else {
        dayAverages[day] = 0; // No data for this day
      }
    }

    return dayAverages.entries.map((e) => WeeklyTrend(e.key, e.value)).toList();
  }

  // Build mood trend line chart
  Widget _buildMoodTrendChart(List<WeeklyTrend> trends) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Weekly Mood Trend",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            Container(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = DateFormat.E().format(
                              DateTime.now().subtract(Duration(days: 7 - value.toInt()))
                          );
                          return Text(day);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.map((t) => FlSpot(t.day.toDouble() - 1, t.value)).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 4,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build list of common moods
  Widget _buildCommonMoodsList(Map<String, int> moodCounts) {
    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Most Frequent Moods",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            Column(
              children: sortedMoods.take(3).map((entry) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getMoodColor(entry.key),
                    child: Text(
                      _getMoodEmoji(entry.key),
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(entry.key),
                  trailing: Text("${entry.value} times"),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get mood emoji
  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'angry': return '😠';
      case 'excited': return '🤩';
      case 'tired': return '😴';
      case 'loving': return '🥰';
      case 'productive': return '💪';
      case 'lazy': return '🦥';
      default: return '😐';
    }
  }

  Future<QuerySnapshot> _getMoodData(String userId) {
    DateTime rangeDate;
    switch (_timeRange) {
      case 'week':
        rangeDate = DateTime.now().subtract(Duration(days: 7));
        break;
      case 'month':
        rangeDate = DateTime.now().subtract(Duration(days: 30));
        break;
      case 'year':
        rangeDate = DateTime.now().subtract(Duration(days: 365));
        break;
      default:
        rangeDate = DateTime.now().subtract(Duration(days: 7));
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .where('date', isGreaterThan: rangeDate)
        .get();
  }

  Map<String, int> _calculateMoodCounts(List<MoodEntry> moods) {
    final counts = <String, int>{};
    for (final mood in moods) {
      counts[mood.mood] = (counts[mood.mood] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildMoodDistributionChart(Map<String, int> moodCounts) {
    final List<BarChartGroupData> barGroups = moodCounts.entries.map((entry) {
      return BarChartGroupData(
        x: moodCounts.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: _getMoodColor(entry.key),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mood Distribution",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              moodCounts.keys.elementAt(value.toInt()),
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklyTrend {
  final int day; // 1-7 (Monday-Sunday)
  final double value; // Average mood intensity

  WeeklyTrend(this.day, this.value);
}