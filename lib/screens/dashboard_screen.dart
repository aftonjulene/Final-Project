import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _workoutsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _workoutsStream = FirebaseFirestore.instance
          .collection('workouts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .snapshots();
    }
  }

  // Calculate current streak
  int _calculateStreak(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> workouts,
  ) {
    if (workouts.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final workoutDates =
        workouts
            .map((doc) {
              final ts = doc.data()['date'];
              if (ts is! Timestamp) return null;
              final date = ts.toDate();
              return DateTime(date.year, date.month, date.day);
            })
            .whereType<DateTime>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (workoutDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = today;

    if (workoutDates.first.isBefore(today)) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    for (final workoutDate in workoutDates) {
      if (workoutDate.isAtSameMomentAs(checkDate) ||
          workoutDate.isAfter(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int _countWorkoutsInRange(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> workouts,
    DateTime start,
    DateTime end,
  ) {
    return workouts.where((doc) {
      final ts = doc.data()['date'];
      if (ts is! Timestamp) return false;
      final date = ts.toDate();
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).length;
  }

  Map<int, int> _getWeeklyFrequency(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> workouts,
  ) {
    final frequency = <int, int>{};
    for (int i = 0; i < 7; i++) {
      frequency[i] = 0;
    }

    for (final doc in workouts) {
      final ts = doc.data()['date'];
      if (ts is! Timestamp) continue;
      final date = ts.toDate();
      // weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
      // Map to index: 0=Monday, 1=Tuesday, ..., 6=Sunday
      final dayOfWeek = (date.weekday - 1) % 7;
      frequency[dayOfWeek] = (frequency[dayOfWeek] ?? 0) + 1;
    }

    return frequency;
  }

  List<double> _getVolumeOverTime(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> workouts,
  ) {
    final now = DateTime.now();
    final weeks = <double>[];

    for (int weekOffset = 3; weekOffset >= 0; weekOffset--) {
      final weekStart = now.subtract(Duration(days: weekOffset * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      double totalVolume = 0.0;
      for (final doc in workouts) {
        final ts = doc.data()['date'];
        if (ts is! Timestamp) continue;
        final date = ts.toDate();
        if (date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            date.isBefore(weekEnd)) {
          final exercises = doc.data()['exercises'] as List?;
          if (exercises != null) {
            for (final ex in exercises) {
              final sets = (ex['sets'] as num?)?.toInt() ?? 0;
              final reps = (ex['reps'] as num?)?.toInt() ?? 0;
              final weight = (ex['weight'] as num?)?.toDouble() ?? 0.0;
              totalVolume += sets * reps * weight;
            }
          }
        }
      }
      weeks.add(totalVolume);
    }

    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: Text('Please log in to view your dashboard.'),
        ),
      );
    }

    if (_workoutsStream == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _workoutsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final workouts = snapshot.data?.docs ?? [];

          // Calculate stats
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endOfMonth = DateTime(now.year, now.month + 1, 0);

          final streak = _calculateStreak(workouts);
          final thisWeekCount = _countWorkoutsInRange(
            workouts,
            startOfWeek,
            now,
          );
          final thisMonthCount = _countWorkoutsInRange(
            workouts,
            startOfMonth,
            endOfMonth,
          );
          final weeklyFrequency = _getWeeklyFrequency(workouts);
          final volumeOverTime = _getVolumeOverTime(workouts);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- CURRENT STREAK CARD ----------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.red[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CURRENT STREAK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 8),
                          Text(
                            '$streak',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'days in a row',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ---------------- STATS ROW ----------------
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'THIS WEEK',
                        value: '$thisWeekCount',
                        label: 'workouts',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'THIS MONTH',
                        value: '$thisMonthCount',
                        label: 'workouts',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ---------------- WEEKLY FREQUENCY ----------------
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WEEKLY FREQUENCY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 150,
                        child: _buildWeeklyFrequencyChart(weeklyFrequency),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Text(
                            'Mon',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Tue',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Wed',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Thu',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Fri',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Sat',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Sun',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ---------------- VOLUME OVER TIME ----------------
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VOLUME OVER TIME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 150,
                        child: _buildVolumeChart(volumeOverTime),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Week 1',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Week 2',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Week 3',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Week 4',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------
  // WEEKLY FREQUENCY BAR CHART
  // ----------------------------------------------------------------
  Widget _buildWeeklyFrequencyChart(Map<int, int> frequency) {
    if (frequency.values.every((v) => v == 0)) {
      return Center(
        child: Text(
          'No workout data yet',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      );
    }

    final maxValue = frequency.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) {
      return Center(
        child: Text(
          'No workout data yet',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final value = frequency[index] ?? 0;
        final height = maxValue > 0 ? (value / maxValue) * 120 : 0.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1d2e),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (value > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$value',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        );
      }),
    );
  }

  // ----------------------------------------------------------------
  // VOLUME OVER TIME LINE CHART
  // ----------------------------------------------------------------
  Widget _buildVolumeChart(List<double> volumes) {
    if (volumes.isEmpty || volumes.every((v) => v == 0)) {
      return Center(
        child: Text(
          'No volume data yet',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      );
    }

    final maxVolume = volumes.reduce((a, b) => a > b ? a : b);
    if (maxVolume == 0) {
      return Center(
        child: Text(
          'No volume data yet',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 150),
      painter: _VolumeChartPainter(volumes, maxVolume),
    );
  }
}

// Custom painter for line chart
class _VolumeChartPainter extends CustomPainter {
  final List<double> volumes;
  final double maxVolume;

  _VolumeChartPainter(this.volumes, this.maxVolume);

  @override
  void paint(Canvas canvas, Size size) {
    if (volumes.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF1a1d2e)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF1a1d2e).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = const Color(0xFF1a1d2e)
      ..style = PaintingStyle.fill;

    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);
    final stepX = chartWidth / (volumes.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < volumes.length; i++) {
      final x = padding + (i * stepX);
      final normalizedValue = maxVolume > 0 ? volumes[i] / maxVolume : 0.0;
      final y = size.height - padding - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final path = Path()
        ..moveTo(points.first.dx, size.height - padding)
        ..lineTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.lineTo(points.last.dx, size.height - padding);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Draw line
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw volume labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < volumes.length; i++) {
      final volume = volumes[i];
      if (volume > 0) {
        final label = volume >= 1000
            ? '${(volume / 1000).toStringAsFixed(1)}k'
            : volume.toStringAsFixed(0);
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(points[i].dx - (textPainter.width / 2), points[i].dy - 16),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_VolumeChartPainter oldDelegate) {
    return oldDelegate.volumes != volumes || oldDelegate.maxVolume != maxVolume;
  }
}
