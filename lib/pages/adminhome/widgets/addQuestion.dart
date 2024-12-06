import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:project_444/firebase_options.dart';
import 'dart:io';
import '../../models/questions.dart';

class AddQuestion extends StatefulWidget {
  final Function(Question) onAddQuestion;

  const AddQuestion({super.key, required this.onAddQuestion});

  @override
  AddQuestionState createState() => AddQuestionState();
}

class AddQuestionState extends State<AddQuestion> {
  final _formKey = GlobalKey<FormState>();
  String _questionType = '';
  String _questionText = '';
  String _questionGrade = '';
  List<String> _options = ['', '', '', ''];
  String? _correctAnswer;
  File? _imageFile;
  String? _imageUrl;

  final ImagePicker _picker = ImagePicker();
  final Logger _logger = Logger();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _logger.i('Image picked: ${pickedFile.path}');
      }
    } catch (e) {
      _logger.e('Image picking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_imageFile == null) {
      _logger.e('No image file selected');
      return null;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _imageFile!.path.split('.').last;
      String fileName = 'question_images/image_$timestamp.$extension';

      _logger.i('Starting upload to path: $fileName');

      Reference reference =
          FirebaseStorage.instance.refFromURL(Bucket.ID).child(fileName);

      final TaskSnapshot snapshot = await reference.putFile(_imageFile!);

      final downloadUrl = await snapshot.ref.getDownloadURL();
      _logger.i("URL=> $downloadUrl");
      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('Firebase upload error: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      _logger.e('General upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed')),
        );
      }
      return null;
    }
  }

  bool _validateOptions() {
    final nonEmptyOptions =
        _options.where((opt) => opt.trim().isNotEmpty).toList();

    return nonEmptyOptions.toSet().length == nonEmptyOptions.length;
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile != null) {
      _imageUrl = await _uploadImageToFirebase();
    }

    switch (_questionType) {
      case 'Multiple Choice':
        if (_correctAnswer == null || !_validateOptions()) {
          _showValidationError(
              'Please fill all options and select a correct answer');
          return;
        }
        break;
      case 'True/False':
        if (_correctAnswer == null) {
          _showValidationError('Please select True or False');
          return;
        }
        break;
    }

    final newQuestion = Question(
      questionId: DateTime.now().millisecondsSinceEpoch.toString(),
      questionType: _questionType,
      questionText: _questionText,
      options: _options,
      correctAnswer: _correctAnswer,
      grade: _questionGrade,
      imageUrl: _imageUrl,
    );

    if (mounted) {
      widget.onAddQuestion(newQuestion);
      Navigator.of(context).pop();
    }
  }

  void _showValidationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Question'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _questionType.isEmpty ? null : _questionType,
                decoration: InputDecoration(labelText: 'Question Type'),
                items: [
                  'Multiple Choice',
                  'True/False',
                  'Short Answer',
                  'Essay'
                ]
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                validator: (value) =>
                    value == null ? 'Please select a question type' : null,
                onChanged: (value) {
                  setState(() {
                    _questionType = value!;
                    _correctAnswer = null;
                    _options = ['', '', '', ''];
                  });
                },
              ),
              if (_imageFile == null)
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Add Image (Optional)'),
                )
              else
                Column(
                  children: [
                    Image.file(_imageFile!, height: 100, width: 100),
                    TextButton(
                      onPressed: () => setState(() => _imageFile = null),
                      child: Text('Remove Image'),
                    ),
                  ],
                ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Enter Question'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Question cannot be empty'
                    : null,
                onChanged: (value) => _questionText = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Question Grade'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value == null || value.isEmpty
                    ? 'Grade cannot be empty'
                    : null,
                onChanged: (value) => _questionGrade = value,
              ),
              if (_questionType == 'Multiple Choice')
                ...List.generate(
                    4,
                    (index) => Row(
                          children: [
                            Radio<String>(
                              value: _options[index],
                              groupValue: _correctAnswer,
                              onChanged: _options[index].isNotEmpty
                                  ? (value) =>
                                      setState(() => _correctAnswer = value)
                                  : null,
                            ),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Option ${index + 1}',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _options[index] = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        )),
              if (_questionType == 'True/False')
                Column(
                  children: ['True', 'False']
                      .map((option) => RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: _correctAnswer,
                            onChanged: (value) =>
                                setState(() => _correctAnswer = value),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitQuestion,
          child: Text('Add Question'),
        ),
      ],
    );
  }
}
