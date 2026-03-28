import 'package:equatable/equatable.dart';

class PhotoEntry extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final String photo1Path;
  final String photo2Path;
  final String photo3Path;
  final String photo4Path;
  final DateTime createdAt;
  
  const PhotoEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.photo1Path,
    required this.photo2Path,
    required this.photo3Path,
    required this.photo4Path,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'photo1_path': photo1Path,
    'photo2_path': photo2Path,
    'photo3_path': photo3Path,
    'photo4_path': photo4Path,
    'created_at': createdAt.toIso8601String(),
  };
  
  factory PhotoEntry.fromJson(Map<String, dynamic> json) {
    return PhotoEntry(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      photo1Path: json['photo1_path'],
      photo2Path: json['photo2_path'],
      photo3Path: json['photo3_path'],
      photo4Path: json['photo4_path'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  @override
  List<Object?> get props => [id, userId, date, photo1Path, photo2Path, photo3Path, photo4Path];
}