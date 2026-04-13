import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class VehiclesApi {
  VehiclesApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get<dynamic>('/vehicles');
    return unwrapApiList(res.data);
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required String number,
    String vehicleType = 'car',
    DateTime? purchaseDate,
    double? purchasePrice,
    double? currentValue,
    DateTime? insuranceExpiryDate,
  }) async {
    final res = await _dio.post<dynamic>(
      '/vehicles',
      data: {
        'name': name,
        'number': number,
        'vehicleType': vehicleType,
        'purchaseDate': purchaseDate?.toUtc().toIso8601String(),
        'purchasePrice': purchasePrice,
        'currentValue': currentValue,
        'insuranceExpiryDate': insuranceExpiryDate?.toUtc().toIso8601String(),
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  /// Full asset update (nulls clear optional fields).
  Future<Map<String, dynamic>> updateVehicle({
    required String id,
    required String name,
    required String number,
    required String vehicleType,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? currentValue,
    DateTime? insuranceExpiryDate,
  }) async {
    final res = await _dio.patch<dynamic>(
      '/vehicles/$id',
      data: {
        'name': name,
        'number': number,
        'vehicleType': vehicleType,
        'purchaseDate': purchaseDate?.toUtc().toIso8601String(),
        'purchasePrice': purchasePrice,
        'currentValue': currentValue,
        'insuranceExpiryDate': insuranceExpiryDate?.toUtc().toIso8601String(),
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> addCost({
    required String vehicleId,
    required String type,
    required double amount,
    required String dateIso,
  }) async {
    final res = await _dio.post<dynamic>(
      '/vehicles/$vehicleId/costs',
      data: {'type': type, 'amount': amount, 'date': dateIso},
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<String> totalCost(String vehicleId) async {
    final res = await _dio.get<dynamic>('/vehicles/$vehicleId/total-cost');
    final m = unwrapApiMap(res.data) ?? <String, dynamic>{};
    return m['totalCost']?.toString() ?? '0';
  }
}

final vehiclesApiProvider = Provider<VehiclesApi>(
  (ref) => VehiclesApi(ref.watch(dioProvider)),
);
