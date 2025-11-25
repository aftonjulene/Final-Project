class Exercise {
  final String name;
  final int sets;
  final int reps;
  final double weight;
  final int? restSeconds;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    this.restSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'restSeconds': restSeconds,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> data) {
    return Exercise(
      name: data['name'] as String,
      sets: data['sets'] as int,
      reps: data['reps'] as int,
      weight: (data['weight'] as num).toDouble(),
      restSeconds: data['restSeconds'] as int?,
    );
  }
}
