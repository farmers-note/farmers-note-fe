// lib/model/field_record.dart

class FieldRecord {
  final int? id; // 서버에서 받을 때만 사용 (삭제/수정용)
  final String fieldName;
  final String cropType;
  final int sizePyeong;
  final String diseaseStatus;
  final String recordDate; // 'YYYY-MM-DD' 형식의 문자열

  FieldRecord({
    this.id,
    required this.fieldName,
    required this.cropType,
    required this.sizePyeong,
    required this.diseaseStatus,
    required this.recordDate,
  });

  // 서버에 데이터를 보낼 때 사용 (POST)
  Map<String, dynamic> toJson() => {
    'fieldName': fieldName,
    'cropType': cropType,
    'sizePyeong': sizePyeong,
    'diseaseStatus': diseaseStatus,
    'recordDate': recordDate,
  };

  // 서버에서 데이터를 받을 때 사용 (GET)
  factory FieldRecord.fromJson(Map<String, dynamic> json) => FieldRecord(
    id: json['id'] as int?,
    fieldName: json['field_name'] as String,
    cropType: json['crop_type'] as String,
    sizePyeong: json['size_pyeong'] as int,
    diseaseStatus: json['disease_status'] as String,
    recordDate: json['record_date'] as String,
  );
}
