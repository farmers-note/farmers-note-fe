// lib/screens/crop_identification_screen.dart

import 'dart:io';
import 'dart:typed_data'; // Uint8List 사용
import 'package:farmers_note/exception/api_exception.dart'; // 이미 존재하는 Exception
import 'package:farmers_note/viewmodel/provider.dart'; // fieldRecordRepositoryProvider 정의
import 'package:flutter/foundation.dart'; // kIsWeb 사용
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CropIdentificationScreen extends ConsumerStatefulWidget {
  const CropIdentificationScreen({super.key});

  @override
  ConsumerState<CropIdentificationScreen> createState() =>
      _CropIdentificationScreenState();
}

class _CropIdentificationScreenState
    extends ConsumerState<CropIdentificationScreen> {
  // 모바일: File, 웹: 바이트 데이터 또는 URL을 사용해야 함
  XFile? _pickedFile;
  Uint8List? _imageBytes; // 웹에서 이미지 미리보기를 위해 사용

  String _result = '촬영된 이미지 및 분류 결과가 여기에 표시됩니다.';
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final String _modelKey = 'crop'; // 작물 분류 모델 키 고정

  // 1. 이미지 선택 및 추론 로직
  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;

    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      // 웹 환경에 맞게 바이트 데이터 로드 (미리보기 용)
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }

      setState(() {
        _pickedFile = pickedFile;
        _result = '작물 분류 중...';
        _isLoading = true;
      });

      await _predict(pickedFile);
    } else {
      _showSnackBar('이미지 선택이 취소되었습니다.');
    }
  }

  // 2. 모델 추론 API 호출 (XFile 기반으로 FormData 생성)
  Future<void> _predict(XFile pickedFile) async {
    final repository = ref.read(fieldRecordRepositoryProvider); // Riverpod 사용

    try {
      FormData formData;

      if (kIsWeb) {
        // 🚨 웹 환경: MultipartFile.fromBytes 사용
        final bytes = await pickedFile.readAsBytes();
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(bytes, filename: pickedFile.name),
        });
      } else {
        // 🚨 모바일 환경: MultipartFile.fromFile 사용
        // dart:io의 File 대신 XFile.path를 직접 사용 가능
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(
            pickedFile.path,
            filename: pickedFile.name,
          ),
        });
      }

      final prediction = await repository.predictCrop(_modelKey, formData);

      setState(() {
        _result = '분류 결과: $prediction';
      });
    } on ApiException catch (e) {
      setState(() {
        // `ApiException`에 `status` 대신 `statusCode` 필드를 사용하는 경우를 대비하여 수정
        // (제공해주신 코드에는 e.status로 되어있지만 일반적으로 statusCode를 사용합니다.)
        // 기존 코드의 변수명을 유지합니다.
        _result = 'API 오류 발생 (Status ${e.status}): ${e.message}';
      });
    } on Exception catch (e) {
      setState(() {
        _result = '알 수 없는 오류 발생: ${e}';
      });
    } catch (e) {
      setState(() {
        _result = '예외 발생: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('작물 분류'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const Text(
                '카메라로 작물을 촬영하거나 갤러리에서 이미지를 선택해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),

              // 이미지 선택 버튼 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildImageButton(
                    icon: Icons.camera_alt,
                    label: '사진 촬영',
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  _buildImageButton(
                    icon: Icons.photo_library,
                    label: '갤러리에서 선택',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 결과 표시 영역
              _buildResultArea(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }

  Widget _buildResultArea(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Expanded(
              child: (_pickedFile == null)
                  ? Center(child: Text(_result, textAlign: TextAlign.center))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: kIsWeb
                          ? Image.memory(
                              _imageBytes!, // 🚨 웹: Image.memory 사용
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Image.file(
                              // 🚨 모바일: Image.file 사용
                              File(_pickedFile!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '분류 중...',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      _result,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
