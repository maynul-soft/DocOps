import 'dart:convert';

class DocumentModel {
  final String id;
  String name;
  final String folderPath;
  final List<String> imagePaths;
  final DateTime createdAt;
  DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.name,
    required this.folderPath,
    required this.imagePaths,
    required this.createdAt,
    required this.updatedAt,
  });

  int get pageCount => imagePaths.length;
  String? get firstPageThumbnail => imagePaths.isNotEmpty ? imagePaths.first : null;

  DocumentModel copyWith({
    String? id,
    String? name,
    String? folderPath,
    List<String>? imagePaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      folderPath: folderPath ?? this.folderPath,
      imagePaths: imagePaths ?? List<String>.from(this.imagePaths),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'folderPath': folderPath,
      'imagePaths': imagePaths,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      name: map['name'] as String,
      folderPath: map['folderPath'] as String,
      imagePaths: List<String>.from(map['imagePaths'] as List),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory DocumentModel.fromJson(String source) =>
      DocumentModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
