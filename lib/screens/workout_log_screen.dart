import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'workout_history_screen.dart';

import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/challenge_service.dart';

class LogWorkoutScreen extends StatelessWidget {
  const LogWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1a1d2e);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Log Workout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'B E A S T  M O D E',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a1d2e),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Personalize your workout, track progress, and crush your fitness goals.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 60),
            _ActionTile(
              title: 'Quick Log',
              subtitle:
                  'Personalize your workout with custom exercises and details.',
              icon: Icons.flash_on,
              backgroundColor: const Color.fromARGB(204, 26, 29, 46),
              iconColor: Colors.white,
              textColor: Colors.white,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WorkoutEditorScreen(
                      mode: WorkoutEditorMode.quick,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            _ActionTile(
              title: 'Template Workout',
              subtitle: 'Use a structured plan with pre-filled exercises.',
              icon: Icons.view_agenda,
              backgroundColor: const Color.fromARGB(193, 61, 66, 92),
              iconColor: Colors.white,
              textColor: Colors.white,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WorkoutEditorScreen(
                      mode: WorkoutEditorMode.template,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            _ActionTile(
              title: 'Repeat Previous',
              subtitle: 'Easily log a past workout from your history.',
              icon: Icons.refresh,
              backgroundColor: const Color.fromARGB(184, 74, 81, 105),
              iconColor: Colors.white,
              textColor: Colors.white,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RepeatPreviousScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            _ActionTile(
              title: 'Workout History',
              subtitle: 'Review or edit your past training sessions.',
              icon: Icons.history,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              iconColor: Colors.white,
              textColor: const Color.fromARGB(255, 0, 0, 0),
              showBorder: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WorkoutHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum WorkoutEditorMode { quick, template, repeat, edit }

class WorkoutEditorScreen extends StatefulWidget {
  final WorkoutEditorMode mode;
  final Map<String, dynamic>? initialData;
  final String? workoutId;

  const WorkoutEditorScreen({
    super.key,
    required this.mode,
    this.initialData,
    this.workoutId,
  });

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  late List<_ExerciseFormData> _exercises;

  @override
  void initState() {
    super.initState();
    _applyInitialData();
  }

  void _applyInitialData() {
    final data = widget.initialData;

    if (data != null) {
      _titleController.text = (data['title'] as String?) ?? '';
      final duration = data['durationMinutes'];
      if (duration != null) {
        _durationController.text = duration.toString();
      }

      final ts = data['date'];
      if (ts is Timestamp) {
        _selectedDate = ts.toDate();
      } else {
        _selectedDate = DateTime.now();
      }

      final rawExercises = (data['exercises'] as List?) ?? [];
      _exercises = rawExercises.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        return _ExerciseFormData(
          name: (m['name'] ?? '').toString(),
          sets: m['sets'] != null ? m['sets'].toString() : '',
          reps: m['reps'] != null ? m['reps'].toString() : '',
          weight: m['weight'] != null ? m['weight'].toString() : '',
          restSeconds: m['restSeconds'] != null
              ? m['restSeconds'].toString()
              : '',
        );
      }).toList();

      if (_exercises.isEmpty) {
        _exercises = [_ExerciseFormData()];
      }
      return;
    }

    if (widget.mode == WorkoutEditorMode.template) {
      _titleController.text = 'Full Body Strength';
      _durationController.text = '45';
      _selectedDate = DateTime.now();
      _exercises = [
        _ExerciseFormData(
          name: 'Squats',
          sets: '4',
          reps: '8',
          weight: '',
          restSeconds: '90',
        ),
        _ExerciseFormData(
          name: 'Bench Press',
          sets: '4',
          reps: '8',
          weight: '',
          restSeconds: '90',
        ),
        _ExerciseFormData(
          name: 'Bent-over Rows',
          sets: '4',
          reps: '8',
          weight: '',
          restSeconds: '90',
        ),
        _ExerciseFormData(
          name: 'Shoulder Press',
          sets: '3',
          reps: '10',
          weight: '',
          restSeconds: '60',
        ),
      ];
    } else {
      _selectedDate = DateTime.now();
      _exercises = [_ExerciseFormData()];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
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

  void _addExercise() {
    setState(() {
      _exercises.add(_ExerciseFormData());
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      if (_exercises.isEmpty) {
        _exercises.add(_ExerciseFormData());
      }
    });
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

    int? durationMinutes;
    if (_durationController.text.trim().isNotEmpty) {
      durationMinutes = int.tryParse(_durationController.text.trim());
    }

    final exerciseMaps = _exercises.where((e) => e.name.trim().isNotEmpty).map((
      e,
    ) {
      final sets = int.tryParse(e.sets.trim());
      final reps = int.tryParse(e.reps.trim());
      final weight = double.tryParse(e.weight.trim());
      final rest = int.tryParse(e.restSeconds.trim());

      return <String, dynamic>{
        'name': e.name.trim(),
        'sets': sets ?? 0,
        'reps': reps ?? 0,
        'weight': weight ?? 0.0,
        'restSeconds': e.restSeconds.trim().isEmpty ? null : rest,
      };
    }).toList();

    if (exerciseMaps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise.')),
      );
      return;
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

      final workoutsRef = FirebaseFirestore.instance.collection('workouts');
      final payload = {
        'userId': user.uid,
        'title': title,
        'date': Timestamp.fromDate(_selectedDate),
        'durationMinutes': durationMinutes,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'userName': displayName,
        'userGoal': goal,
        'exercises': exerciseMaps,
      };

      if (widget.mode == WorkoutEditorMode.edit && widget.workoutId != null) {
        // For now we only update the workout document when editing.
        // Challenge progress is driven by new logs, not edits.
        await workoutsRef.doc(widget.workoutId!).update(payload);
      } else {
        // Create a new workout, then update challenges based on it.
        final docRef = await workoutsRef.add(payload);

        final exercises = exerciseMaps.map((m) {
          return Exercise(
            name: (m['name'] as String?) ?? '',
            sets: (m['sets'] as int?) ?? 0,
            reps: (m['reps'] as int?) ?? 0,
            weight: (m['weight'] as num?)?.toDouble() ?? 0.0,
            restSeconds: m['restSeconds'] as int?,
          );
        }).toList();

        final workout = Workout(
          id: docRef.id,
          userId: user.uid,
          title: title,
          date: _selectedDate,
          durationMinutes: durationMinutes,
          exercises: exercises,
        );

        final challengeService = ChallengeService();
        await challengeService.updateChallengesForWorkout(
          workout: workout,
          userId: user.uid,
        );
      }

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

  @override
  Widget build(BuildContext context) {
    String title;
    const primary = Color(0xFF1a1d2e);
    final borderColor = Colors.grey[300]!;

    switch (widget.mode) {
      case WorkoutEditorMode.quick:
        title = 'Quick Log';
        break;
      case WorkoutEditorMode.template:
        title = 'Template Workout';
        break;
      case WorkoutEditorMode.repeat:
        title = 'Repeat Workout';
        break;
      case WorkoutEditorMode.edit:
        title = 'Edit Workout';
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
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: primary, width: 1.2),
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
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: primary, width: 1.2),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
            Column(
              children: List.generate(_exercises.length, (index) {
                final ex = _exercises[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Exercise ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_exercises.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeExercise(index),
                              splashRadius: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: ex.name,
                        onChanged: (v) => ex.name = v,
                        decoration: InputDecoration(
                          hintText: 'Squats, Bench Press...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: primary, width: 1.1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: ex.sets,
                              onChanged: (v) => ex.sets = v,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Sets',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: primary,
                                    width: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: ex.reps,
                              onChanged: (v) => ex.reps = v,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Reps',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: primary,
                                    width: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: ex.weight,
                              onChanged: (v) => ex.weight = v,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Weight',
                                hintText: 'lbs or kg',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: primary,
                                    width: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: ex.restSeconds,
                              onChanged: (v) => ex.restSeconds = v,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Rest (sec)',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: primary,
                                    width: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a1d2e),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class _ExerciseFormData {
  String name;
  String sets;
  String reps;
  String weight;
  String restSeconds;

  _ExerciseFormData({
    this.name = '',
    this.sets = '',
    this.reps = '',
    this.weight = '',
    this.restSeconds = '',
  });
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

              final exercises = (data['exercises'] as List?) ?? [];
              final exerciseCount = exercises.length;

              String subtitle = dateLabel;
              if (exerciseCount > 0) {
                subtitle += ' • $exerciseCount exercises';
              }
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

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final bool showBorder;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    this.showBorder = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: showBorder
              ? Border.all(color: const Color(0xFF1a1d2e), width: 1)
              : null,
          boxShadow: showBorder
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor == Colors.white
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: textColor, size: 22),
          ],
        ),
      ),
    );
  }
}
