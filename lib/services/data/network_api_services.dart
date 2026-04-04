import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:retro_route/services/data/app_exception.dart';
import 'package:retro_route/services/data/base_api_services.dart';

class NetworkApiServices extends BaseApiServices {
  final http.Client _client;

  NetworkApiServices() : _client = http.Client();

  @override
  Future<dynamic> getApi(String url, String? token) async {
    dynamic responseJson;

    try {
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer ${token.trim()}';
      }

      final response = await _client
          .send(request)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw RequestTimeOutException('Request timed out'),
          );

      final httpResponse = await http.Response.fromStream(response);

      responseJson = returnResponse(httpResponse);
    } on SocketException {
      throw InternetException('No Internet connection');
    } catch (e) {
      throw FetchDataException('$e');
    }

    if (kDebugMode) {
      log('GET Response: $responseJson');
    }
    return responseJson;
  }

  @override
  Future<dynamic> postApi(
    dynamic data,
    String url,
    String? token, {
    bool isJson = true,
    List<File>? files,
    List<String>? fileFields,
  }) async {
    if (kDebugMode) {
      log("POST URL: $url");
      log("POST Data: $data");
      log(
        "Content-Type: ${isJson ? 'application/json' : 'multipart/form-data'}",
      );
      log("File Fields: $fileFields");
      if (token != null) log("Authorization: Bearer ${token.trim()}");
    }

    dynamic responseJson;

    try {
      final uri = Uri.parse(url);

      if (isJson) {
        final response = await _client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (token != null) 'Authorization': 'Bearer ${token.trim()}',
              },
              body: jsonEncode(data),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw RequestTimeOutException('Request timed out'),
            );

        responseJson = returnResponse(response);
      } else if (files != null && files.isNotEmpty) {
        final request = http.MultipartRequest('POST', uri)
          ..headers['Accept'] = 'application/json';
        if (token != null) {
          request.headers['Authorization'] = 'Bearer ${token.trim()}';
        }

        // Add text fields
        if (data is Map) {
          data.forEach((key, value) {
            request.fields[key] = value.toString();
            log("Adding text field: $key = $value");
          });
        }

        // Validate fileFields length
        if (fileFields != null && fileFields.length != files.length) {
          log(
            "Warning: fileFields length (${fileFields.length}) does not match files length (${files.length})",
          );
        }

        // Add files
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          final fieldName = fileFields != null && i < fileFields.length
              ? fileFields[i]
              : 'image_$i';
          final fileStream = http.ByteStream(file.openRead());
          final fileLength = await file.length();
          final multipartFile = http.MultipartFile(
            fieldName,
            fileStream,
            fileLength,
            filename: file.uri.pathSegments.last,
            contentType: http.MediaType(
              'image',
              'jpeg',
            ), // Adjust based on API requirements
          );
          request.files.add(multipartFile);
          log("Adding file field: $fieldName = ${file.path}");
        }

        final response = await _client
            .send(request)
            .timeout(
              const Duration(seconds: 120),
              onTimeout: () =>
                  throw RequestTimeOutException('Request timed out'),
            );

        final httpResponse = await http.Response.fromStream(response);

        responseJson = returnResponse(httpResponse);
      } else {
        final response = await _client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
                if (token != null) 'Authorization': 'Bearer ${token.trim()}',
              },
              body: data is Map
                  ? data.map((k, v) => MapEntry(k, v.toString()))
                  : data,
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw RequestTimeOutException('Request timed out'),
            );

        responseJson = returnResponse(response);
      }
    } on SocketException {
      throw InternetException('No Internet connection');
    } catch (e) {
      throw FetchDataException('$e');
    }

    return responseJson;
  }

  
  @override
  Future<dynamic> putApi(
    dynamic data,
    String url,
    String? token, {
    bool isJson = true,
    List<File>? files,
    List<String>? fileFields,
  }) async {
    if (kDebugMode) {
      log("PUT URL: $url");
      log("PUT Data: $data");
      log(
        "Content-Type: ${isJson ? 'application/json' : files != null && files.isNotEmpty ? 'multipart/form-data' : 'application/x-www-form-urlencoded'}",
      );
      log("File Fields: $fileFields");
      if (token != null) log("Authorization: Bearer ${token.trim()}");
    }

    dynamic responseJson;

    try {
      final uri = Uri.parse(url);

      if (isJson) {
        final response = await _client
            .put(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (token != null) 'Authorization': 'Bearer ${token.trim()}',
              },
              body: jsonEncode(data),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw RequestTimeOutException('Request timed out'),
            );

        responseJson = returnResponse(response);
      } else if (files != null && files.isNotEmpty) {
        final request = http.MultipartRequest('PUT', uri)
          ..headers['Accept'] = 'application/json';
        if (token != null) {
          request.headers['Authorization'] = 'Bearer ${token.trim()}';
        }

        // Add text fields
        if (data is Map) {
          data.forEach((key, value) {
            request.fields[key] = value.toString();
            log("Adding text field: $key = $value");
          });
        }

        // Validate fileFields length
        if (fileFields != null && fileFields.length != files.length) {
          log(
            "Warning: fileFields length (${fileFields.length}) does not match files length (${files.length})",
          );
        }

        // Add files
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          final fieldName = fileFields != null && i < fileFields.length
              ? fileFields[i]
              : 'image_$i';
          final fileStream = http.ByteStream(file.openRead());
          final fileLength = await file.length();
          final multipartFile = http.MultipartFile(
            fieldName,
            fileStream,
            fileLength,
            filename: file.uri.pathSegments.last,
            contentType: http.MediaType(
              'image',
              'jpeg',
            ), // Adjust based on API requirements
          );
          request.files.add(multipartFile);
          log("Adding file field: $fieldName = ${file.path}");
        }

        final response = await _client
            .send(request)
            .timeout(
              const Duration(seconds: 120),
              onTimeout: () =>
                  throw RequestTimeOutException('Request timed out'),
            );

        final httpResponse = await http.Response.fromStream(response);

        responseJson = returnResponse(httpResponse);
      } else {
        final response = await _client
            .put(
              uri,
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
                if (token != null) 'Authorization': 'Bearer ${token.trim()}',
              },
              body: data is Map
                  ? data.map((k, v) => MapEntry(k, v.toString()))
                  : data,
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw RequestTimeOutException('Request timed out'),
            );

        responseJson = returnResponse(response);
      }
    } on SocketException {
      throw InternetException('No Internet connection');
    } catch (e) {
      throw FetchDataException('$e');
    }

    return responseJson;
  }





  @override
  Future<dynamic> patchApi(
    dynamic data,
    String url,
    String? token, {
    bool isJson = true,
  }) async {
    if (kDebugMode) {
      log("PATCH URL: $url");
      log("PATCH Data: $data");
      log(
        "Content-Type: ${isJson ? 'application/json' : 'application/x-www-form-urlencoded'}",
      );
      if (token != null) log("Authorization: Bearer ${token.trim()}");
    }

    dynamic responseJson;

    try {
      final uri = Uri.parse(url);
      final response = await _client
          .patch(
            uri,
            headers: {
              'Content-Type': isJson
                  ? 'application/json'
                  : 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer ${token.trim()}',
            },
            body: isJson
                ? jsonEncode(data)
                : data is Map
                ? data.map((k, v) => MapEntry(k, v.toString()))
                : data,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw RequestTimeOutException('Request timed out'),
          );

      responseJson = returnResponse(response);
    } on SocketException {
      throw InternetException('No Internet connection');
    } catch (e) {
      throw FetchDataException('$e');
    }

    return responseJson;
  }

  @override
  Future<dynamic> deleteApi(String url, String? token,dynamic? data) async {
    if (kDebugMode) {
      log("DELETE URL: $url");
      if (token != null) log("Authorization: Bearer ${token.trim()}");
    }

    dynamic responseJson;

    try {
      final uri = Uri.parse(url);

      final response = await _client
          .delete(
            uri,
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer ${token.trim()}',

            },
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw RequestTimeOutException('Request timed out'),
          );

      responseJson = returnResponse(response);
    } on SocketException {
      throw InternetException('No Internet connection');
    } catch (e) {
      throw FetchDataException('$e');
    }

    if (kDebugMode) {
      log("DELETE Response: $responseJson");
    }

    return responseJson;
  }

  dynamic returnResponse(http.Response response) {
    dynamic responseJson;
    try {
      responseJson = jsonDecode(response.body);
      log("Full response JSON: $responseJson"); // Debug full response
    } catch (e) {
      throw FetchDataException('Failed to response: ${response.body}');
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return responseJson;
      case 400:
        throw BadRequestException(responseJson['message'] ?? 'Bad request');
      case 401:
        throw BadRequestException(responseJson['message'] ?? 'Unauthorized');
      case 403:
        throw UnAuthorizedException(responseJson['message'] ?? 'Forbidden');
      case 404:
        throw UnAuthorizedException(responseJson['message'] ?? 'Not Found');
      case 429:
        throw UnAuthorizedException(
          responseJson['message'] ?? 'Too Many Requests',
        );
      case 408:
        throw RequestTimeOutException(
          responseJson['message'] ?? 'Request Timed Out',
        );
      case 500:
        throw ServerException(
          responseJson['message'] ?? 'Internal Server Error',
        );
      default:
        throw FetchDataException(responseJson['message'] ?? '');
    }
  }
}
