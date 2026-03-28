import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/photo_entry.dart' as app_photo;
import '../../services/local_database/local_database.dart';
import '../../widgets/custom_button.dart';

class AddPhotosScreen extends StatefulWidget {
  const AddPhotosScreen({super.key});
  
  @override
  _AddPhotosScreenState createState() => _AddPhotosScreenState();
}

class _AddPhotosScreenState extends State<AddPhotosScreen> {
  final List<File?> _photos = List.filled(4, null);
  bool _hasPhotosToday = false;
  app_photo.PhotoEntry? _todayPhotos;
  bool _isLoading = true;
  bool _isSaving = false;
  
  final LocalDatabase _localDb = LocalDatabase();
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _checkTodayPhotos();
  }
  
  Future<void> _checkTodayPhotos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final today = DateTime.now();
        final photos = await _localDb.photoDao.getPhotoEntryByDate(
          session.user.id,
          today,
        );
        
        if (mounted) {
          setState(() {
            _hasPhotosToday = photos != null;
            _todayPhotos = photos;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking photos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _pickPhoto(int index) async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Необходимо разрешение для доступа к фото'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null && mounted) {
      setState(() {
        _photos[index] = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _savePhotos() async {
    if (_photos.any((photo) => photo == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Добавьте все 4 фото'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    if (!mounted) return;
    setState(() => _isSaving = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final photoEntry = app_photo.PhotoEntry(
          id: const Uuid().v4(),
          userId: session.user.id,
          date: DateTime.now(),
          photo1Path: _photos[0]!.path,
          photo2Path: _photos[1]!.path,
          photo3Path: _photos[2]!.path,
          photo4Path: _photos[3]!.path,
          createdAt: DateTime.now(),
        );
        
        await _localDb.photoDao.insertPhotoEntry(photoEntry);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Фото сохранены')),
          );
          await _checkTodayPhotos();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_hasPhotosToday && _todayPhotos != null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Фото на сегодня уже добавлены',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Следующее добавление фото будет доступно завтра',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить фото'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Добавьте 4 фото',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Фотографии помогут отслеживать визуальные изменения тела',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return GestureDetector(
                  onTap: () => _pickPhoto(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: photo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              photo,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Фото ${index + 1}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            CustomButton(
              text: 'Сохранить фото',
              onPressed: _savePhotos,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}