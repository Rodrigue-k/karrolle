sealed class RemoteCommand {
  const RemoteCommand();

  factory RemoteCommand.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'next' => const NextCommand(),
      'previous' => const PreviousCommand(),
      'goto' => GotoCommand(index: json['index'] as int),
      'pointer' => PointerCommand(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      ),
      'zoom' => ZoomCommand(scale: (json['scale'] as num).toDouble()),
      _ => throw Exception('Unknown command type: $type'),
    };
  }
}

class NextCommand extends RemoteCommand {
  const NextCommand();
}

class PreviousCommand extends RemoteCommand {
  const PreviousCommand();
}

class GotoCommand extends RemoteCommand {
  final int index;
  const GotoCommand({required this.index});
}

class PointerCommand extends RemoteCommand {
  final double x;
  final double y;
  const PointerCommand({required this.x, required this.y});
}

class ZoomCommand extends RemoteCommand {
  final double scale;
  const ZoomCommand({required this.scale});
}
