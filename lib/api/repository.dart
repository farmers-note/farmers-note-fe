import 'package:dio/dio.dart';
import 'package:farmers_note/exception/api_exception.dart';
import 'package:flutter/material.dart';

class Repository {
  @protected
  ApiException handleApiException(DioException e) {
    // 반환 타입 안정성 체크
    final data = e.response?.data;
    final Map<String, dynamic> mapData = data is Map<String, dynamic>
        ? data
        : {};

    print('[${e.response?.statusCode}] DioException: $data $e');

    if (mapData.isEmpty) {
      mapData['message'] = '서버에 알 수 없는 문제가 발생했습니다 :500';
    }

    return ApiException(
      message: mapData['message'] ?? '알 수 없는 오류가 발생했습니다.',
      status: mapData['status'] ?? 500,
      errors: mapData['errors'] ?? {},
    );
  }

  @protected
  ApiException handleUnknownException(Object e) {
    print('Unknown exception: $e');
    return ApiException(message: '알 수 없는 오류가 발생했습니다.', status: 500, errors: {});
  }
}
