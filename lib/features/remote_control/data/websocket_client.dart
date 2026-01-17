import 'dart:convert';
import 'dart:io';
import 'package:karrolle/core/logger/app_logger.dart';

class KarrolleWebSocketClient {
  WebSocket? _socket;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function() onConnected;
  final void Function() onDisconnected;
  final void Function(String) onError;

  KarrolleWebSocketClient({
    required this.onMessage,
    required this.onConnected,
    required this.onDisconnected,
    required this.onError,
  });

  bool get isConnected => _socket != null;

  Future<void> connect(String ip, {int port = 8080}) async {
    try {
      logger.i('Connecting to ws://$ip:$port');
      _socket = await WebSocket.connect('ws://$ip:$port');
      logger.i('Connected to server');
      onConnected();

      _socket!.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            onMessage(json);
          } catch (e) {
            logger.w('Error parsing message', error: e);
          }
        },
        onDone: () {
          logger.i('Disconnected from server');
          _socket = null;
          onDisconnected();
        },
        onError: (error) {
          logger.e('WebSocket error', error: error);
          _socket = null;
          onError(error.toString());
        },
      );
    } catch (e) {
      logger.e('Connection failed', error: e);
      onError(e.toString());
    }
  }

  void sendCommand(String type, [Map<String, dynamic>? data]) {
    if (_socket == null) {
      logger.w('Cannot send command: not connected');
      return;
    }

    final payload = {'type': type, ...?data};
    _socket!.add(jsonEncode(payload));
    logger.d('Sent command: $type');
  }

  void sendNext() => sendCommand('next');
  void sendPrevious() => sendCommand('previous');
  void sendGoto(int index) => sendCommand('goto', {'index': index});
  void sendPointer(double x, double y) =>
      sendCommand('pointer', {'x': x, 'y': y});
  void sendZoom(double scale) => sendCommand('zoom', {'scale': scale});

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }
}
