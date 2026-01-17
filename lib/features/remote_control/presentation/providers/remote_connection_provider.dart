import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karrolle/features/remote_control/data/websocket_client.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class RemoteConnectionState {
  final ConnectionStatus status;
  final String? errorMessage;
  final String? connectedIp;

  const RemoteConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.errorMessage,
    this.connectedIp,
  });

  RemoteConnectionState copyWith({
    ConnectionStatus? status,
    String? errorMessage,
    String? connectedIp,
  }) {
    return RemoteConnectionState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      connectedIp: connectedIp ?? this.connectedIp,
    );
  }
}

class RemoteConnectionNotifier extends Notifier<RemoteConnectionState> {
  KarrolleWebSocketClient? _client;

  @override
  RemoteConnectionState build() {
    ref.onDispose(() {
      _client?.disconnect();
    });
    return const RemoteConnectionState();
  }

  Future<void> connect(String ip) async {
    state = state.copyWith(status: ConnectionStatus.connecting);

    _client = KarrolleWebSocketClient(
      onMessage: _handleMessage,
      onConnected: () {
        state = state.copyWith(
          status: ConnectionStatus.connected,
          connectedIp: ip,
        );
      },
      onDisconnected: () {
        state = state.copyWith(status: ConnectionStatus.disconnected);
      },
      onError: (error) {
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: error,
        );
      },
    );

    await _client!.connect(ip);
  }

  void _handleMessage(Map<String, dynamic> message) {
    // Handle incoming messages from server (e.g., scene updates)
    // For now, we just log them
  }

  void sendNext() => _client?.sendNext();
  void sendPrevious() => _client?.sendPrevious();
  void sendGoto(int index) => _client?.sendGoto(index);

  Future<void> disconnect() async {
    await _client?.disconnect();
    _client = null;
    state = state.copyWith(status: ConnectionStatus.disconnected);
  }
}

final remoteConnectionProvider =
    NotifierProvider<RemoteConnectionNotifier, RemoteConnectionState>(
      RemoteConnectionNotifier.new,
    );
