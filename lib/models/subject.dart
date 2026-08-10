class SubSubject {
  final String id;
  final String name;

  SubSubject({required this.id, required this.name});

  factory SubSubject.fromJson(Map<String, dynamic> json) => SubSubject(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class Chapter {
  final String id;
  final String title;
  final String? file;
  final String? subSubjectId;

  Chapter({required this.id, required this.title, this.file, this.subSubjectId});

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    file: json['file'],
    subSubjectId: json['subSubjectId'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'file': file,
    'subSubjectId': subSubjectId,
  };
}

class Subject {
  final String id;
  final String name;
  final String icon;
  final String folder;
  final List<Chapter> chapters;
  final List<SubSubject>? subSubjects;

  Subject({
    required this.id,
    required this.name,
    required this.icon,
    required this.folder,
    required this.chapters,
    this.subSubjects,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      folder: json['folder'] ?? '',
      chapters: (json['chapters'] as List?)?.map((c) => Chapter.fromJson(c)).toList() ?? [],
      subSubjects: (json['subSubjects'] as List?)?.map((s) => SubSubject.fromJson(s)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'folder': folder,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'subSubjects': subSubjects?.map((s) => s.toJson()).toList(),
  };
}
