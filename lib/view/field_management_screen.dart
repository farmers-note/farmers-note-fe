// lib/view/field_management_screen.dart

import 'package:farmers_note/api/field_repository.dart';
import 'package:farmers_note/view/field_record_screen.dart';
import 'package:farmers_note/viewmodel/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmers_note/model/field_record.dart';

class FieldManagementScreen extends ConsumerWidget {
  const FieldManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 밭 기록 목록을 비동기적으로 가져옴
    final recordsAsync = ref.watch(fieldRecordsProvider);
    final repo = ref.watch(fieldRecordRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 밭 기록 관리'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: recordsAsync.when(
        // 데이터 로딩 중
        loading: () => const Center(child: CircularProgressIndicator()),

        // 데이터 로드 실패
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '기록을 불러오는 데 실패했습니다.',
                style: TextStyle(color: Colors.red),
              ),
              Text(err.toString(), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(fieldRecordsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),

        // 데이터 로드 성공
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text(
                '아직 밭 기록이 없습니다.\n플러스 버튼을 눌러 새 기록을 등록하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text(
                    '${record.fieldName} (${record.cropType})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '규모: ${record.sizePyeong}평 | 상태: ${record.diseaseStatus}\n기록일: ${record.recordDate}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, ref, repo, record),
                  ),
                ),
              );
            },
          );
        },
      ),

      // 새 밭 기록 등록 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // FieldRecordScreen으로 이동 후, 기록이 성공적으로 추가되면 목록 새로고침
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FieldRecordScreen()),
          );
          if (result == true) {
            ref.invalidate(fieldRecordsProvider);
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 삭제 확인 다이얼로그
  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FieldRecordRepository repo,
    FieldRecord record,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 삭제'),
        content: Text('${record.fieldName}의 기록을 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                if (record.id != null) {
                  await repo.deleteFieldRecord(record.id!);
                  // 삭제 성공 시 목록 새로고침
                  ref.invalidate(fieldRecordsProvider);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('기록이 삭제되었습니다.')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('삭제 실패: ${e.toString()}')),
                );
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
