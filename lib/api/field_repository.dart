import 'package:dio/dio.dart';
import 'package:farmers_note/api/repository.dart';
import 'package:farmers_note/model/field_record.dart';

class FieldRecordRepository extends Repository {
  final Dio dio;

  FieldRecordRepository(this.dio);

  // 1. 밭 기록 추가 (POST /records)
  Future<int> addFieldRecord(FieldRecord request) async {
    try {
      final response = await dio.post(
        '/records',
        data: request.toJson(), // FieldRecord 모델에 toJson() 메서드가 있어야 함
      );
      print('/records POST success: ${response.data}');

      // 서버 응답에서 새로 생성된 ID를 추출하여 반환
      // 서버는 {"message": "Record added successfully", "id": new_id} 형태를 반환한다고 가정
      final newId = response.data['id'];
      if (newId is int) {
        return newId;
      }
      throw Exception("Invalid ID format from server response");
    } on DioException catch (e) {
      print('/records POST error: ${e.response?.data} $e');
      throw handleApiException(e);
    } catch (e) {
      print('/records POST unknown error: $e');
      throw handleUnknownException(e);
    }
  }

  // 2. 밭 기록 조회 (GET /records)
  Future<List<FieldRecord>> getFieldRecords() async {
    try {
      final response = await dio.get('/records');
      print('/records GET success: ${response.data}');

      // 서버 응답은 {"total_count": X, "records": [{}, {}]} 형태를 반환한다고 가정
      final recordsJson = response.data['records'] as List;

      return recordsJson
          .map(
            (record) => FieldRecord.fromJson(record),
          ) // FieldRecord 모델에 fromJson() 메서드가 있어야 함
          .toList();
    } on DioException catch (e) {
      print('/records GET error: ${e.response?.data} $e');
      throw handleApiException(e);
    } catch (e) {
      print('/records GET unknown error: $e');
      throw handleUnknownException(e);
    }
  }

  // 3. 밭 기록 삭제 (DELETE /records/{record_id})
  Future<void> deleteFieldRecord(int recordId) async {
    try {
      final response = await dio.delete('/records/$recordId');
      print('/records/$recordId DELETE success: ${response.data}');
    } on DioException catch (e) {
      // 404 Not Found (기록 없음) 등의 에러도 여기서 처리
      print('/records DELETE error: ${e.response?.data} $e');
      throw handleApiException(e);
    } catch (e) {
      print('/records DELETE unknown error: $e');
      throw handleUnknownException(e);
    }
  }

  // 4. (옵션) 모델 추론 API 연동 예시
  // 이 기능은 일반적으로 별도의 Repository를 사용하지만, 구조 통일을 위해 예시로 포함
  Future<String> predictCrop(String modelKey, FormData formData) async {
    try {
      // Dio를 사용하여 파일이 포함된 POST 요청을 보냄
      final response = await dio.post(
        '/predict/$modelKey',
        data: formData, // FormData에는 파일 데이터가 포함되어야 함
      );
      print('/predict/$modelKey success: ${response.data}');

      // 서버는 {"prediction_class": "..."}를 반환한다고 가정
      return response.data['prediction_class'];
    } on DioException catch (e) {
      print('/predict error: ${e.response?.data} $e');
      throw handleApiException(e);
    } catch (e) {
      print('/predict unknown error: $e');
      throw handleUnknownException(e);
    }
  }
}
