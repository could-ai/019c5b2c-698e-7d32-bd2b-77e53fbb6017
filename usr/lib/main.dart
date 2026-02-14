import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/analysis_entry.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Placement Readiness Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },
    );
  }
}

enum PageState { form, results, history }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageState _pageState = PageState.form;
  final _formKey = GlobalKey<FormState>();
  final _jdController = TextEditingController();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();

  AnalysisEntry? _currentAnalysis;
  List<AnalysisEntry> _history = [];
  bool _isJdShort = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('analysis_history') ?? [];
    List<AnalysisEntry> loadedHistory = [];
    for (var jsonStr in historyJson) {
      try {
        final entry = AnalysisEntry.fromJson(json.decode(jsonStr));
        loadedHistory.add(entry);
      } catch (e) {
        // Corrupted entry, skip
      }
    }
    setState(() {
      _history = loadedHistory;
    });
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('analysis_history', historyJson);
  }

  void _analyze() {
    if (!_formKey.currentState!.validate()) return;
    final jdText = _jdController.text;
    final company = _companyController.text;
    final role = _roleController.text;

    // Mock analysis
    final analysis = _performAnalysis(jdText, company, role);

    setState(() {
      _currentAnalysis = analysis;
      _pageState = PageState.results;
      _history.add(analysis);
      _saveHistory();
    });
  }

  AnalysisEntry _performAnalysis(String jdText, String company, String role) {
    // Mock skill extraction
    Map<String, List<String>> extractedSkills = {
      'coreCS': ['Algorithms', 'Data Structures'],
      'languages': ['Python', 'Java'],
      'web': ['HTML', 'CSS'],
      'data': ['SQL'],
      'cloud': ['AWS'],
      'testing': ['Unit Testing'],
      'other': [],
    };

    if (extractedSkills.values.every((list) => list.isEmpty)) {
      extractedSkills['other'] = ['Communication', 'Problem solving', 'Basic coding', 'Projects'];
    }

    // Mock other data
    final now = DateTime.now().toIso8601String();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    return AnalysisEntry(
      id: id,
      createdAt: now,
      company: company,
      role: role,
      jdText: jdText,
      extractedSkills: extractedSkills,
      roundMapping: [
        {'roundTitle': 'Technical Interview', 'focusAreas': ['Coding', 'System Design'], 'whyItMatters': 'To assess technical skills'}
      ],
      checklist: [
        {'roundTitle': 'Resume Review', 'items': ['Update resume', 'Highlight projects']}
      ],
      plan7Days: [
        {'day': 1, 'focus': 'Algorithms', 'tasks': ['Solve LeetCode problems']}
      ],
      questions: ['What is your experience?', 'Why this company?'],
      baseScore: 70,
      skillConfidenceMap: {},
      finalScore: 70,
      updatedAt: now,
    );
  }

  void _updateConfidence(String skill, String level) {
    if (_currentAnalysis == null) return;
    setState(() {
      _currentAnalysis!.skillConfidenceMap[skill] = level;
      // Calculate finalScore based on confidence (simple mock: know +10, practice +5)
      _currentAnalysis!.finalScore = _currentAnalysis!.baseScore +
        _currentAnalysis!.skillConfidenceMap.values.where((v) => v == 'know').length * 10 +
        _currentAnalysis!.skillConfidenceMap.values.where((v) => v == 'practice').length * 5;
      _currentAnalysis!.updatedAt = DateTime.now().toIso8601String();
      _saveHistory();
    });
  }

  void _goToHistory() {
    setState(() {
      _pageState = PageState.history;
    });
  }

  void _backToForm() {
    setState(() {
      _pageState = PageState.form;
      _currentAnalysis = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_pageState) {
      case PageState.form:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Placement Readiness'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: _goToHistory,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(labelText: 'Company (Optional)'),
                  ),
                  TextFormField(
                    controller: _roleController,
                    decoration: const InputDecoration(labelText: 'Role (Optional)'),
                  ),
                  TextFormField(
                    controller: _jdController,
                    decoration: const InputDecoration(labelText: 'Job Description'),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Job Description is required';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _isJdShort = value.length < 200;
                      });
                    },
                  ),
                  if (_isJdShort)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.yellow[100],
                      child: const Text(
                        'This JD is too short to analyze deeply. Paste full JD for better output.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _analyze,
                    child: const Text('Analyze'),
                  ),
                ],
              ),
            ),
          ),
        );
      case PageState.results:
        if (_currentAnalysis == null) return const SizedBox();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Analysis Results'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _backToForm,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Company: ${_currentAnalysis!.company}'),
                Text('Role: ${_currentAnalysis!.role}'),
                Text('Base Score: ${_currentAnalysis!.baseScore}'),
                Text('Final Score: ${_currentAnalysis!.finalScore}'),
                // Add more display for skills, etc.
                const Text('Skills:'),
                ..._currentAnalysis!.extractedSkills.entries.map((e) => Text('${e.key}: ${e.value.join(', ')}')),
                // For skill confidence
                const Text('Skill Confidence:'),
                ..._currentAnalysis!.extractedSkills.values.expand((l) => l).map((skill) => Row(
                  children: [
                    Text(skill),
                    DropdownButton<String>(
                      value: _currentAnalysis!.skillConfidenceMap[skill] ?? 'know',
                      items: const [
                        DropdownMenuItem(value: 'know', child: Text('Know')),
                        DropdownMenuItem(value: 'practice', child: Text('Practice')),
                      ],
                      onChanged: (value) {
                        if (value != null) _updateConfidence(skill, value);
                      },
                    ),
                  ],
                )),
                // Add roundMapping, checklist, etc.
              ],
            ),
          ),
        );
      case PageState.history:
        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _backToForm,
            ),
          ),
          body: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final entry = _history[index];
              return ListTile(
                title: Text('${entry.company} - ${entry.role}'),
                subtitle: Text('Score: ${entry.finalScore}'),
                onTap: () {
                  setState(() {
                    _currentAnalysis = entry;
                    _pageState = PageState.results;
                  });
                },
              );
            },
          ),
        );
    }
  }
}