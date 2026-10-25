import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  final String? code;
  final Object? error;

  ApiException(this.status, this.message, {this.code, this.error});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // --dart-define takes precedence over frontend/.env.
  static final List<String> _candidateBaseUrls = _resolveBaseUrlCandidates();
  static final String baseUrl = _candidateBaseUrls.first;

  static List<String> _resolveBaseUrlCandidates() {
    const compileTimeUrl = String.fromEnvironment('API_BASE_URL');
    final configuredUrl = compileTimeUrl.isNotEmpty
        ? compileTimeUrl
        : dotenv.env['API_BASE_URL']?.trim();

    final candidates = <String>[];
    if (configuredUrl != null && configuredUrl.isNotEmpty) {
      candidates.add(configuredUrl.replaceFirst(RegExp(r'/+$'), ''));
    }

    final hostCandidates = <String>[];
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      hostCandidates.addAll(['10.0.2.2', 'localhost', '127.0.0.1']);
    } else {
      hostCandidates.addAll(['localhost', '127.0.0.1']);
    }

    for (final host in hostCandidates) {
      for (final port in [4000, 3000]) {
        final candidate = 'http://$host:$port/api';
        if (!candidates.contains(candidate)) candidates.add(candidate);
      }
    }

    return candidates.isEmpty ? ['http://localhost:4000/api'] : candidates;
  }

  String? _token;
  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<http.Response> _sendWithFallback(
    String path, {
    required Future<http.Response> Function(Uri uri) requestFactory,
    Map<String, String>? query,
  }) async {
    Object? lastError;
    for (final candidate in _candidateBaseUrls) {
      final uri = Uri.parse('$candidate$path').replace(queryParameters: query);
      try {
        return await requestFactory(uri);
      } on http.ClientException catch (error) {
        lastError = error;
      }
    }
    throw ApiException(
      0,
      'Cannot reach the GUZO API at $baseUrl. '
      'Check that the backend API is running.',
      error: lastError,
    );
  }

  // ── GET (object) ──────────────────────────────────────────
  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query}) async {
    final res = await _sendWithFallback(path,
      requestFactory: (uri) => http.get(uri, headers: _headers),
      query: query,
    );
    final body = _handle(res);
    if (body is! Map) {
      throw ApiException(res.statusCode, 'Expected object response');
    }
    return body.cast<String, dynamic>();
  }

  // ── GET (list) — for hotel and admin collections ─────────
  Future<List<dynamic>> getList(String path,
      {Map<String, String>? query}) async {
    final res = await _sendWithFallback(path,
      requestFactory: (uri) => http.get(uri, headers: _headers),
      query: query,
    );
    final body = _handle(res);
    if (body is! List) {
      throw ApiException(res.statusCode, 'Expected list response');
    }
    return body;
  }

  // ── POST ──────────────────────────────────────────────────
  Future<dynamic> post(String path, {Object? body}) async {
    final res = await _sendWithFallback(path,
      requestFactory: (uri) => http.post(
        uri,
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _handle(res);
  }

  // ── PATCH ─────────────────────────────────────────────────
  Future<dynamic> patch(String path, {Object? body}) async {
    final res = await _sendWithFallback(path,
      requestFactory: (uri) => http.patch(
        uri,
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _sendWithFallback(path,
      requestFactory: (uri) => http.delete(uri, headers: _headers),
    );
    return _handle(res);
  }

  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    List<XFile> images = const [],
  }) =>
      _sendMultipart(path, fields: fields, images: images, method: 'POST');

  Future<dynamic> patchMultipart(
    String path, {
    required Map<String, String> fields,
    List<XFile> images = const [],
  }) =>
      _sendMultipart(path, fields: fields, images: images, method: 'PATCH');

  Future<dynamic> _sendMultipart(
    String path, {
    required Map<String, String> fields,
    required List<XFile> images,
    required String method,
  }) async {
    Object? lastError;
    for (final candidate in _candidateBaseUrls) {
      final request = http.MultipartRequest(method, Uri.parse('$candidate$path'))
        ..fields.addAll(fields);
      if (_token != null) request.headers['Authorization'] = 'Bearer $_token';

      try {
        for (final image in images) {
          final contentType = _imageContentType(image);
          request.files.add(http.MultipartFile.fromBytes(
            'images',
            await image.readAsBytes(),
            filename: image.name,
            contentType: MediaType.parse(contentType),
          ));
        }
        final response = await http.Response.fromStream(await request.send());
        return _handle(response);
      } on http.ClientException catch (error) {
        lastError = error;
      }
    }

    throw ApiException(
      0,
      'Cannot reach the GUZO API at $baseUrl. '
      'Check that the backend API is running.',
      error: lastError,
    );
  }

  String _imageContentType(XFile image) {
    final suppliedType = image.mimeType?.split(';').first.trim().toLowerCase();
    final normalizedType =
        suppliedType == 'image/jpg' ? 'image/jpeg' : suppliedType;
    const allowedTypes = {
      'image/jpeg',
      'image/png',
      'image/webp',
    };
    if (normalizedType != null && allowedTypes.contains(normalizedType)) {
      return normalizedType;
    }
    if (suppliedType != null &&
        suppliedType.isNotEmpty &&
        suppliedType != 'application/octet-stream') {
      throw ApiException(
        0,
        'Unsupported photo format. Choose a JPEG, PNG, or WebP image.',
      );
    }

    final extension = image.name.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw ApiException(
          0,
          'Could not identify this photo format. Choose a JPEG, PNG, or WebP image.',
        ),
    };
  }

  dynamic _handle(http.Response res) {
    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = res.body;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // Support both raw and {data: ...} wrapped responses.
      if (body is Map && body.containsKey('data')) return body['data'];
      return body;
    }

    String message = 'Request failed (${res.statusCode})';
    String? code;

    if (body is Map) {
      final err = body['error'];
      if (err is Map) {
        message = (err['message'] ?? message).toString();
        code = err['code']?.toString();
      } else if (err is String) {
        message = err;
      }
    } else if (body is String && body.isNotEmpty) {
      message = body;
    }

    throw ApiException(res.statusCode, message, code: code);
  }
}
