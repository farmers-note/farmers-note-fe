// lib/screens/disease_diagnosis_screen.dart

import 'dart:io';
import 'dart:typed_data'; // Uint8List 사용
import 'package:farmers_note/exception/api_exception.dart';
import 'package:farmers_note/viewmodel/provider.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiseaseDiagnosisScreen extends ConsumerStatefulWidget {
  const DiseaseDiagnosisScreen({super.key});

  @override
  ConsumerState<DiseaseDiagnosisScreen> createState() =>
      _DiseaseDiagnosisScreenState();
}

class _DiseaseDiagnosisScreenState
    extends ConsumerState<DiseaseDiagnosisScreen> {
  // 지원 작물 리스트 및 서버 모델 키 매핑
  final List<String> _cropNames = ['토마토', '감자', '옥수수', '딸기', '오이', '벼'];
  final Map<String, String> _cropModelKeys = {
    '토마토': 'tomato',
    '감자': 'potato',
    '옥수수': 'corn',
    '딸기': 'strawberry',
    '오이': 'cucumber',
    '벼': 'rice',
  };

  String _selectedCropName = '토마토';

  // 🚨 웹/모바일 통합 상태 변수
  XFile? _pickedFile;
  Uint8List? _imageBytes; // 웹 미리보기 및 FormData 생성을 위해 사용

  String _result = '작물을 선택하고, 이미지 촬영/선택 후 질병을 진단하세요.';
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // 1. 이미지 선택 및 추론 로직
  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;

    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      // 웹 환경인 경우 바이트 데이터 미리 로드 (미리보기 용)
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }

      setState(() {
        _pickedFile = pickedFile;
        // _imageFile 사용 제거 (웹/모바일 통합)
        _result = '$_selectedCropName 질병 분류 중...';
        _isLoading = true;
      });

      final modelKey = _cropModelKeys[_selectedCropName]!;
      await _predict(modelKey, pickedFile);
    } else {
      _showSnackBar('이미지 선택이 취소되었습니다.');
    }
  }

  // 2. 모델 추론 API 호출 (XFile 기반으로 FormData 생성)
  Future<void> _predict(String modelKey, XFile pickedFile) async {
    final repository = ref.read(fieldRecordRepositoryProvider);

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
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(
            pickedFile.path,
            filename: pickedFile.name,
          ),
        });
      }

      final prediction = await repository.predictCrop(modelKey, formData);

      setState(() {
        _result = '진단 결과: $prediction';
      });
    } on ApiException catch (e) {
      setState(() {
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
        title: const Text('작물 질병 분류'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 작물 선택 드롭다운
            _buildCropSelectionDropdown(),
            const SizedBox(height: 30),

            Text(
              '$_selectedCropName의 질병 진단을 위해 이미지를 선택해 주세요.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

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
    return Container(
      height: 300,
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
                          '진단 중...',
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
    );
  }

  Widget _buildCropSelectionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '진단할 작물 선택:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
          ),
          value: _selectedCropName,
          items: _cropNames.map((String crop) {
            return DropdownMenuItem<String>(value: crop, child: Text(crop));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCropName = newValue!;
              _result = '$_selectedCropName을(를) 선택했습니다. 이미지를 선택해 주세요.';
              _pickedFile = null; // 작물 변경 시 이미지 초기화
              _imageBytes = null;
            });
          },
        ),
      ],
    );
  }
}
