// lib/view/field_record_screen.dart

import 'package:farmers_note/viewmodel/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmers_note/model/field_record.dart';

class FieldRecordScreen extends ConsumerStatefulWidget {
  const FieldRecordScreen({super.key});

  @override
  ConsumerState<FieldRecordScreen> createState() => _FieldRecordScreenState();
}

class _FieldRecordScreenState extends ConsumerState<FieldRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fieldName = '';
  String _cropType = '';
  int _sizePyeong = 0;
  String _diseaseStatus = '정상';
  DateTime _selectedDate = DateTime.now();

  final List<String> _diseaseOptions = [
    '정상',
    '고추 탄저병', '고추 흰가루병',
    '상추 노균병', '상추 흰가루병',
    // ... 나머지 작물들의 질병 클래스를 추가하세요.
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newRecord = FieldRecord(
        fieldName: _fieldName,
        cropType: _cropType,
        sizePyeong: _sizePyeong,
        diseaseStatus: _diseaseStatus,
        recordDate: _selectedDate.toString().split(
          ' ',
        )[0], // YYYY-MM-DD 형식으로 변환
      );

      try {
        final repo = ref.read(fieldRecordRepositoryProvider);
        await repo.addFieldRecord(newRecord);

        // 성공 시 true를 반환하며 이전 화면(FieldManagementScreen)으로 돌아감
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('새 밭 기록이 성공적으로 등록되었습니다.')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('기록 등록 실패: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 밭 기록 등록'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. 밭 이름
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '밭 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? '밭 이름을 입력해주세요.' : null,
                onSaved: (value) => _fieldName = value!,
              ),
              const SizedBox(height: 20),

              // 2. 작물 유형
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '재배 작물 유형 (예: 고추, 상추)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? '재배 작물 유형을 입력해주세요.' : null,
                onSaved: (value) => _cropType = value!,
              ),
              const SizedBox(height: 20),

              // 3. 밭 규모 (평)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '밭 규모 (단위: 평)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return '밭 규모를 입력해주세요.';
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return '유효한 평수를 입력해주세요.';
                  }
                  return null;
                },
                onSaved: (value) => _sizePyeong = int.parse(value!),
              ),
              const SizedBox(height: 20),

              // 4. 질병 발생 유형 (Dropdown)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '질병 발생 유형',
                  border: OutlineInputBorder(),
                ),
                value: _diseaseStatus,
                items: _diseaseOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _diseaseStatus = newValue!;
                  });
                },
                onSaved: (value) => _diseaseStatus = value!,
              ),
              const SizedBox(height: 20),

              // 5. 기록 날짜
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '기록 날짜: ${_selectedDate.toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('날짜 선택'),
                    onPressed: () => _selectDate(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 등록 버튼
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '기록 등록하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
