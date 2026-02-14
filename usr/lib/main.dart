import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        '/prp/07-test': (context) => const TestChecklistScreen(),
        '/prp/08-ship': (context) => const ShipScreen(),
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
          drawer: const AppDrawer(),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy Analysis',
                onPressed: () {
                  final text = 'Company: ${_currentAnalysis!.company}\nRole: ${_currentAnalysis!.role}\nScore: ${_currentAnalysis!.finalScore}\nSkills: ${_currentAnalysis!.extractedSkills.entries.map((e) => "${e.key}: ${e.value.join(", ")}").join("\n")}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                },
              ),
            ],
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

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Placement Readiness', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Test Checklist'),
            onTap: () => Navigator.pushReplacementNamed(context, '/prp/07-test'),
          ),
          ListTile(
            leading: const Icon(Icons.rocket),
            title: const Text('Ship'),
            onTap: () => Navigator.pushReplacementNamed(context, '/prp/08-ship'),
          ),
        ],
      ),
    );
  }
}

class TestChecklistScreen extends StatefulWidget {
  const TestChecklistScreen({super.key});

  @override
  State<TestChecklistScreen> createState() => _TestChecklistScreenState();
}

class _TestChecklistScreenState extends State<TestChecklistScreen> {
  final List<String> _tests = [
    'JD required validation works',
    'Short JD warning shows for <200 chars',
    'Skills extraction groups correctly',
    'Round mapping changes based on company + skills',
    'Score calculation is deterministic',
    'Skill toggles update score live',
    'Changes persist after refresh',
    'History saves and loads correctly',
    'Export buttons copy the correct content',
    'No console errors on core pages',
  ];
  final List<String> _hints = [
    'Try analyzing with empty JD.',
    'Enter short text and check for yellow warning.',
    'Check if skills appear in correct categories.',
    'Verify rounds match the context.',
    'Same inputs should yield same base score.',
    'Change confidence and watch Final Score.',
    'Reload app and check history.',
    'Verify list in History tab.',
    'Use Copy button in results.',
    'Check debug console.',
  ];
  List<bool> _checked = List.filled(10, false);

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  void _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('test_checklist_status');
    if (saved != null && saved.length == 10) {
      setState(() {
        _checked = saved.map((e) => e == '1').toList();
      });
    }
  }

  void _saveChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final toSave = _checked.map((e) => e ? '1' : '0').toList();
    await prefs.setStringList('test_checklist_status', toSave);
  }

  void _reset() async {
    setState(() {
      _checked = List.filled(10, false);
    });
    _saveChecklist();
  }

  @override
  Widget build(BuildContext context) {
    int passed = _checked.where((e) => e).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Test Checklist')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Tests Passed: $passed / 10', style: Theme.of(context).textTheme.headlineSmall),
                if (passed < 10)
                  const Text('Fix issues before shipping.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _reset, child: const Text('Reset checklist')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  title: Text(_tests[index]),
                  subtitle: Text(_hints[index]),
                  value: _checked[index],
                  onChanged: (val) {
                    setState(() {
                      _checked[index] = val ?? false;
                    });
                    _saveChecklist();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ShipScreen extends StatefulWidget {
  const ShipScreen({super.key});

  @override
  State<ShipScreen> createState() => _ShipScreenState();
}

class _ShipScreenState extends State<ShipScreen> {
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('test_checklist_status');
    if (saved != null && saved.length == 10 && saved.every((e) => e == '1')) {
      setState(() {
        _isLocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ship Status')),
      drawer: const AppDrawer(),
      body: Center(
        child: _isLocked
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('Locked. Complete all tests.', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/prp/07-test');
                    },
                    child: const Text('Go to Checklist'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch, size: 64, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text('Ready to Ship! 🚀', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
