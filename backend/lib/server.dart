import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart' as dio;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final _dio = dio.Dio();

Future<void> main() async {
  final env = dotenv.DotEnv(includePlatformEnvironment: true)..load(['.env']);
  final apiKey = env['ACCUWEATHER_API_KEY'] ?? '';

  if (apiKey.isEmpty) {
    stderr.writeln('Missing ACCUWEATHER_API_KEY in backend/.env');
    exitCode = 64;
    return;
  }

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(_router(apiKey));

  final server = await shelf_io.serve(handler, 'localhost', 8080);
  // ignore: avoid_print
  print('Server running on http://localhost:${server.port}');
}

Response _jsonResponse(dynamic data) {
  return Response.ok(
    jsonEncode(data),
    headers: {'Content-Type': 'application/json'},
  );
}

Router _router(String apiKey) {
  final router = Router();

  router.get('/health', (Request request) {
    return Response.ok('{"status":"ok"}');
  });

  router.get('/location/<query>', (Request request, String query) async {
    try {
      final response = await _dio.get(
        'https://dataservice.accuweather.com/locations/v1/cities/search',
        queryParameters: {
          'q': query,
          'apikey': apiKey,
          'language': 'en-us',
          'details': false,
          'format': 'json',
        },
      );
      return _jsonResponse(response.data);
    } catch (e) {
      return Response.internalServerError(
        body: '{"error":"Failed to search location"}',
      );
    }
  });

  router.get('/geoposition/<lat>/<lon>', (Request request, String lat, String lon) async {
    try {
      final response = await _dio.get(
        'https://dataservice.accuweather.com/locations/v1/cities/geoposition/search',
        queryParameters: {
          'q': '$lat,$lon',
          'apikey': apiKey,
          'language': 'en-us',
          'details': false,
          'format': 'json',
        },
      );
      return _jsonResponse(response.data);
    } catch (e) {
      return Response.internalServerError(
        body: '{"error":"Failed to get location"}',
      );
    }
  });

  router.get('/current/<locationKey>', (Request request, String locationKey) async {
    try {
      final response = await _dio.get(
        'https://dataservice.accuweather.com/currentconditions/v1/$locationKey',
        queryParameters: {
          'apikey': apiKey,
          'language': 'en-us',
          'details': true,
          'format': 'json',
        },
      );
      return _jsonResponse(response.data);
    } catch (e) {
      return Response.internalServerError(
        body: '{"error":"Failed to get current conditions"}',
      );
    }
  });

  router.get('/hourly/<locationKey>', (Request request, String locationKey) async {
    try {
      final response = await _dio.get(
        'https://dataservice.accuweather.com/forecasts/v1/hourly/12hour/$locationKey',
        queryParameters: {
          'apikey': apiKey,
          'language': 'en-us',
          'metric': true,
          'details': true,
          'format': 'json',
        },
      );
      return _jsonResponse(response.data);
    } catch (e) {
      return Response.internalServerError(
        body: '{"error":"Failed to get hourly forecast"}',
      );
    }
  });

  router.get('/daily/<locationKey>', (Request request, String locationKey) async {
    try {
      final response = await _dio.get(
        'https://dataservice.accuweather.com/forecasts/v1/daily/5day/$locationKey',
        queryParameters: {
          'apikey': apiKey,
          'language': 'en-us',
          'metric': true,
          'details': true,
          'format': 'json',
        },
      );
      return _jsonResponse(response.data);
    } catch (e) {
      return Response.internalServerError(
        body: '{"error":"Failed to get daily forecast"}',
      );
    }
  });

  return router;
}
