import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'workout_history_screen.dart';

class LogWorkoutScreen extends StatelessWidget {
  const LogWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Log Workout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Add a workout with sets, reps, and weight, or reuse a previous one.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // BIG main button – this is your "Add Workout"
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WorkoutEditorScreen(
                        mode: WorkoutEditorMode.quick,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Workout',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Secondary options: Template + Repeat
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WorkoutEditorScreen(
                            mode: WorkoutEditorMode.template,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text(
                      'From Template',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RepeatPreviousScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text(
                      'Repeat Previous',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WorkoutHistoryScreen(),
                  ),
                );
              },
              child: const Text(
                'View Workout History',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color(0xFF1a1d2e),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum WorkoutEditorMode { quick, template, repeat }

class WorkoutEditorScreen extends StatefulWidget {
  final WorkoutEditorMode mode;
  final Map<String, dynamic>? initialData;

  const WorkoutEditorScreen({super.key, required this.mode, this.initialData});

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  final List<_ExerciseFieldData> _exercises = [];

  @override
  void initState() {
    super.initState();
    _applyInitialData();
  }

  void _applyInitialData() {
    final data = widget.initialData;

    if (data != null) {
      // For repeat mode: fill from existing workout
      _titleController.text = (data['title'] as String?) ?? '';
      final duration = data['durationMinutes'];
      if (duration != null) {
        _durationController.text = duration.toString();
      }
      final ts = data['date'];
      if (ts is Timestamp) {
        _selectedDate = ts.toDate();
      }

      final rawExercises = (data['exercises'] as List?) ?? [];
      if (rawExercises.isNotEmpty) {
        for (final e in rawExercises) {
          final map = Map<String, dynamic>.from(e as Map);
          _addExerciseRow(
            name: map['name'] as String?,
            sets: (map['sets'] as num?)?.toInt(),
            reps: (map['reps'] as num?)?.toInt(),
            weight: (map['weight'] as num?)?.toDouble(),
            restSeconds: (map['restSeconds'] as num?)?.toInt(),
          );
        }
      }
    }

    // Template mode with no initial data: prefill common workout
    if (widget.mode == WorkoutEditorMode.template && data == null) {
      _titleController.text = 'Full Body Strength';
      _durationController.text = '45';
      _selectedDate = DateTime.now();

      _addExerciseRow(
        name: 'Squats',
        sets: 4,
        reps: 8,
        weight: 95,
        restSeconds: 90,
      );
      _addExerciseRow(
        name: 'Bench Press',
        sets: 4,
        reps: 8,
        weight: 75,
        restSeconds: 90,
      );
      _addExerciseRow(
        name: 'Bent-over Rows',
        sets: 4,
        reps: 8,
        weight: 65,
        restSeconds: 90,
      );
      _addExerciseRow(
        name: 'Shoulder Press',
        sets: 3,
        reps: 10,
        weight: 45,
        restSeconds: 60,
      );
      _addExerciseRow(
        name: 'Lat Pulldowns',
        sets: 3,
        reps: 10,
        weight: 60,
        restSeconds: 60,
      );
      _addExerciseRow(
        name: 'Plank',
        sets: 3,
        reps: 1,
        weight: 0,
        restSeconds: 60,
      );
    }

    // Quick mode or anything else with no exercises -> start with one empty row
    if (_exercises.isEmpty) {
      _addExerciseRow();
    }
  }

  void _addExerciseRow({
    String? name,
    int? sets,
    int? reps,
    double? weight,
    int? restSeconds,
  }) {
    _exercises.add(
      _ExerciseFieldData(
        name: TextEditingController(text: name ?? ''),
        sets: TextEditingController(text: sets?.toString() ?? ''),
        reps: TextEditingController(text: reps?.toString() ?? ''),
        weight: TextEditingController(
          text: weight != null ? weight.toString() : '',
        ),
        rest: TextEditingController(
          text: restSeconds != null ? restSeconds.toString() : '',
        ),
      ),
    );
    setState(() {});
  }

  void _removeExerciseRow(int index) {
    if (_exercises.length == 1) return; // keep at least one row
    final row = _exercises.removeAt(index);
    row.dispose();
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save workouts.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your workout a title.')),
      );
      return;
    }

    // Build exercises list from rows
    final List<Map<String, dynamic>> exercises = [];
    for (final row in _exercises) {
      final name = row.name.text.trim();
      if (name.isEmpty) continue;

      final sets = int.tryParse(row.sets.text.trim()) ?? 0;
      final reps = int.tryParse(row.reps.text.trim()) ?? 0;
      final weight = double.tryParse(row.weight.text.trim()) ?? 0.0;
      final restSeconds = row.rest.text.trim().isNotEmpty
          ? int.tryParse(row.rest.text.trim())
          : null;

      exercises.add({
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'restSeconds': restSeconds,
      });
    }

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one exercise before saving.'),
        ),
      );
      return;
    }

    int? durationMinutes;
    if (_durationController.text.trim().isNotEmpty) {
      durationMinutes = int.tryParse(_durationController.text.trim());
    }

    setState(() {
      _saving = true;
    });

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final userSnap = await userRef.get();
      final profile = userSnap.data();

      final displayName =
          (profile?['displayName'] as String?) ??
          user.email ??
          'Beast Mode Athlete';
      final goal = profile?['goal'] as String?;

      // simple "notes" summary for feed/history
      final exerciseNames = exercises.map((e) => e['name'] as String).toList();
      final notes = exerciseNames.isEmpty
          ? null
          : (exerciseNames.length <= 3
                ? exerciseNames.join(', ')
                : '${exerciseNames.take(3).join(', ')} + more');

      final workoutsRef = FirebaseFirestore.instance.collection('workouts');
      await workoutsRef.add({
        'userId': user.uid,
        'title': title,
        'notes': notes,
        'date': Timestamp.fromDate(_selectedDate),
        'durationMinutes': durationMinutes,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'userName': displayName,
        'userGoal': goal,
        'exercises': exercises,
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save workout. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    switch (widget.mode) {
      case WorkoutEditorMode.quick:
        title = 'Add Workout';
        break;
      case WorkoutEditorMode.template:
        title = 'Template Workout';
        break;
      case WorkoutEditorMode.repeat:
        title = 'Repeat Workout';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Title',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Leg Day, Push Day, Cardio...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Duration (minutes)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '45',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Exercises',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // dynamic exercise rows
            ...List.generate(_exercises.length, (index) {
              final row = _exercises[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: row.name,
                            decoration: const InputDecoration(
                              labelText: 'Exercise',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_exercises.length > 1)
                          IconButton(
                            onPressed: () => _removeExerciseRow(index),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: row.sets,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Sets',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: row.reps,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Reps',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: row.weight,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight',
                              suffixText: 'lb',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: row.rest,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Rest',
                              suffixText: 's',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addExerciseRow(),
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a1d2e),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Workout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

class _ExerciseFieldData {
  final TextEditingController name;
  final TextEditingController sets;
  final TextEditingController reps;
  final TextEditingController weight;
  final TextEditingController rest;

  _ExerciseFieldData({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.rest,
  });

  void dispose() {
    name.dispose();
    sets.dispose();
    reps.dispose();
    weight.dispose();
    rest.dispose();
  }
}

class RepeatPreviousScreen extends StatelessWidget {
  const RepeatPreviousScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _userWorkoutsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('workouts')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Repeat Previous',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: Text('Please log in to view your previous workouts.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Repeat Previous',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _userWorkoutsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load workouts.'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('You have no workouts to repeat yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final title = (data['title'] as String?) ?? 'Workout';
              final duration = data['durationMinutes'] as int?;
              final ts = data['date'];
              DateTime date;
              if (ts is Timestamp) {
                date = ts.toDate();
              } else {
                date = DateTime.now();
              }

              final dateLabel = '${date.month}/${date.day}/${date.year}';
              String subtitle = dateLabel;
              if (duration != null) {
                subtitle += ' • $duration min';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkoutEditorScreen(
                          mode: WorkoutEditorMode.repeat,
                          initialData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
