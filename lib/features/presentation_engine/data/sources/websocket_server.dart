import 'dart:convert';
import 'dart:io';
import 'package:karrolle/core/logger/app_logger.dart';
import 'package:karrolle/features/presentation_engine/domain/models/remote_command.dart';

class KarrolleWebSocketServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final Function(RemoteCommand) onCommandReceived;

  KarrolleWebSocketServer({required this.onCommandReceived});

  Future<String?> start({int port = 8080}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      logger.i('WebSocket Server started on port $port');

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final webSocket = await WebSocketTransformer.upgrade(request);
          _handleConnection(webSocket);
        } else {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..close();
        }
      });

      return _server!.address.address;
    } catch (e) {
      logger.e('Error starting server', error: e);
      return null;
    }
  }

  void _handleConnection(WebSocket webSocket) {
    _clients.add(webSocket);
    logger.i('New client connected. Total clients: ${_clients.length}');

    webSocket.listen(
      (data) {
        try {
          final json = jsonDecode(data as String);
          final command = RemoteCommand.fromJson(json as Map<String, dynamic>);
          onCommandReceived(command);
        } catch (e) {
          logger.w('Error parsing command', error: e);
        }
      },
      onDone: () {
        _clients.remove(webSocket);
        logger.i('Client disconnected. Remaining clients: ${_clients.length}');
      },
      onError: (error) {
        _clients.remove(webSocket);
        logger.e('Client error', error: error);
      },
    );
  }

  void broadcast(Map<String, dynamic> data) {
    final message = jsonEncode(data);
    for (final client in _clients) {
      client.add(message);
    }
  }

  Future<void> stop() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close();
    _server = null;
    logger.i('WebSocket Server stopped');
  }

  bool get isRunning => _server != null;
}
