class AnalysisEntry {
  final String id;
  final String createdAt;
  String company;
  String role;
  final String jdText;
  final Map<String, List<String>> extractedSkills;
  final List<Map<String, dynamic>> roundMapping;
  final List<Map<String, dynamic>> checklist;
  final List<Map<String, dynamic>> plan7Days;
  final List<String> questions;
  final int baseScore;
  final Map<String, String> skillConfidenceMap;
  int finalScore;
  String updatedAt;

  AnalysisEntry({
    required this.id,
    required this.createdAt,
    required this.company,
    required this.role,
    required this.jdText,
    required this.extractedSkills,
    required this.roundMapping,
    required this.checklist,
    required this.plan7Days,
    required this.questions,
    required this.baseScore,
    required this.skillConfidenceMap,
    required this.finalScore,
    required this.updatedAt,
  });

  factory AnalysisEntry.fromJson(Map<String, dynamic> json) {
    return AnalysisEntry(
      id: json['id'],
      createdAt: json['createdAt'],
      company: json['company'] ?? '',
      role: json['role'] ?? '',
      jdText: json['jdText'],
      extractedSkills: Map<String, List<String>>.from(json['extractedSkills']),
      roundMapping: List<Map<String, dynamic>>.from(json['roundMapping']),
      checklist: List<Map<String, dynamic>>.from(json['checklist']),
      plan7Days: List<Map<String, dynamic>>.from(json['plan7Days']),
      questions: List<String>.from(json['questions']),
      baseScore: json['baseScore'],
      skillConfidenceMap: Map<String, String>.from(json['skillConfidenceMap']),
      finalScore: json['finalScore'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'company': company,
      'role': role,
      'jdText': jdText,
      'extractedSkills': extractedSkills,
      'roundMapping': roundMapping,
      'checklist': checklist,
      'plan7Days': plan7Days,
      'questions': questions,
      'baseScore': baseScore,
      'skillConfidenceMap': skillConfidenceMap,
      'finalScore': finalScore,
      'updatedAt': updatedAt,
    };
  }
}