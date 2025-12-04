import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedGoal;
  String? _experienceLevel;

  final List<String> _fitnessGoals = [
    'Lose Weight',
    'Build Muscle',
    'Stay Fit',
    'Improve Endurance',
    'Gain Flexibility',
  ];

  final List<String> _experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  bool _loadingProfile = true;
  bool _saving = false;
  String? _error;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // load whatever is already in Firestore, but don't invent defaults
  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'No user logged in.';
        _loadingProfile = false;
      });
      return;
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        final name = (data['displayName'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          _fullNameController.text = name;
        }

        final username = (data['username'] as String?)?.trim();
        if (username != null && username.isNotEmpty) {
          _usernameController.text = username;
        }

        final bio = data['bio'] as String?;
        if (bio != null) {
          _bioController.text = bio;
        }

        final int? age = data['age'] as int?;
        final num? heightCm = data['heightCm'] as num?;
        final num? weightKg = data['weightKg'] as num?;

        if (age != null) _ageController.text = age.toString();
        if (heightCm != null) _heightController.text = heightCm.toString();
        if (weightKg != null) _weightController.text = weightKg.toString();

        final goal = (data['goal'] as String?)?.trim();
        if (goal != null && goal.isNotEmpty) {
          _selectedGoal = goal;
        }

        final exp = (data['experienceLevel'] as String?)?.trim();
        if (exp != null && exp.isNotEmpty) {
          _experienceLevel = exp;
        }
      }

      setState(() {
        _loadingProfile = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to load profile.';
        _loadingProfile = false;
      });
    }
  }

  // save only what the user actually typed/selected
  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ageText = _ageController.text.trim();
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    final int? age = ageText.isNotEmpty ? int.tryParse(ageText) : null;
    final double? heightCm = heightText.isNotEmpty
        ? double.tryParse(heightText)
        : null;
    final double? weightKg = weightText.isNotEmpty
        ? double.tryParse(weightText)
        : null;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _db.collection('users').doc(user.uid).update({
        'displayName': _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : null,
        'username': _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : null,
        'bio': _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        'goal': _selectedGoal,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'experienceLevel': _experienceLevel,
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save your profile. Try again.';
      });
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
    if (_loadingProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Text(
                      'BM',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        onPressed: () {
                          // we'll wire photo upload later
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Change Photo'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              const SizedBox(height: 32),

              // Full name
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Full Name',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fullNameController,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),

              // Username
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),

              // Bio
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bio',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 4,
                decoration: _inputDecoration(hint: 'Tell us about yourself...'),
              ),
              const SizedBox(height: 20),

              // Age / Height
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Age',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Height (cm)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weight
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Weight (kg)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),

              // Fitness goal
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fitness Goal',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              ..._fitnessGoals.map(
                (goal) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(goal),
                    trailing: _selectedGoal == goal
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1a1d2e),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedGoal = goal;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Experience level
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Experience Level',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _experienceLevel,
                decoration: _inputDecoration(),
                items: _experienceLevels
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _experienceLevel = val;
                  });
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a1d2e),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save Changes',
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
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
