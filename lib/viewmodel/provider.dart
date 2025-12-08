// Dio 인스턴스 (실제 앱에서는 Singleton 또는 다른 Provider로 관리해야 함)
import 'package:dio/dio.dart';
import 'package:farmers_note/api/field_repository.dart';
import 'package:farmers_note/model/field_record.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? "",
      headers: {"Content-Type": "application/json"},
      connectTimeout: Duration(milliseconds: 5000),
      receiveTimeout: Duration(milliseconds: 3000),
    ),
  ),
);

final fieldRecordRepositoryProvider = Provider((ref) {
  return FieldRecordRepository(ref.watch(dioProvider));
});

final fieldRecordsProvider = FutureProvider.autoDispose<List<FieldRecord>>((
  ref,
) async {
  final repo = ref.watch(fieldRecordRepositoryProvider);
  return repo.getFieldRecords();
});
