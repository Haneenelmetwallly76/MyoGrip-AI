import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5080',
);

final class ApiClient {
  ApiClient({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri = baseUri ?? Uri.parse(apiBaseUrl);

  final http.Client _client;
  final Uri _baseUri;

  Future<Map<String, dynamic>> get(
    String path, {
    String? accessToken,
  }) => _send('GET', path, accessToken: accessToken);

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, Object?> body,
    String? accessToken,
  }) => _send('POST', path, body: body, accessToken: accessToken);

  Future<Map<String, dynamic>> put(
    String path, {
    required Map<String, Object?> body,
    String? accessToken,
  }) => _send('PUT', path, body: body, accessToken: accessToken);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    final uri = _baseUri.resolve(path);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };

    try {
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = body == null ? '' : jsonEncode(body);
      final streamed = await _client.send(request).timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object from the API.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          code: decoded['code'] as String?,
          message: decoded['message'] as String?,
        );
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on FormatException {
      rethrow;
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('API request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const ApiConnectionException();
    } on SocketException catch (error, stackTrace) {
      debugPrint('API request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const ApiConnectionException();
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('API request timed out: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const ApiConnectionException();
    }
  }
}

final class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    this.code,
    this.message,
  });

  final int statusCode;
  final String? code;
  final String? message;
}

final class ApiConnectionException implements Exception {
  const ApiConnectionException();
}
