import 'package:flutter/material.dart';

class DiseaseDiagnosisScreen extends StatefulWidget {
  const DiseaseDiagnosisScreen({super.key});

  @override
  State<DiseaseDiagnosisScreen> createState() => _DiseaseDiagnosisScreenState();
}

class _DiseaseDiagnosisScreenState extends State<DiseaseDiagnosisScreen> {
  // 6가지 지원 작물 리스트
  final List<String> _crops = ['토마토', '감자', '옥수수', '딸기', '오이', '벼'];
  String? _selectedCrop; // 현재 선택된 작물

  @override
  void initState() {
    super.initState();
    _selectedCrop = _crops.first; // 기본값으로 토마토 설정
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
              '$_selectedCrop의 질병 진단을 위해 카메라로 촬영하거나 이미지를 선택해 주세요.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

            // 이미지 선택 버튼 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 카메라 실행 로직 구현
                    _showSnackBar(context, '카메라 실행 예정 (선택 작물: $_selectedCrop)');
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('사진 촬영'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 갤러리 선택 로직 구현
                    _showSnackBar(context, '갤러리 선택 예정 (선택 작물: $_selectedCrop)');
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('갤러리에서 선택'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // 결과 표시 영역
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '여기에 촬영된 이미지 및 질병 진단 결과가 표시됩니다.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
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
          value: _selectedCrop,
          items: _crops.map((String crop) {
            return DropdownMenuItem<String>(value: crop, child: Text(crop));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCrop = newValue;
            });
          },
        ),
      ],
    );
  }
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
