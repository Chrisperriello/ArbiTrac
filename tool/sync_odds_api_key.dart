import 'dart:io';

final RegExp _oddsApiKeyPattern = RegExp(r'^[A-Za-z0-9]{32}$');

void main(List<String> arguments) {
  final key = _resolveKey(arguments);
  if (key == null) {
    stderr.writeln(
      'Missing key. Use --key=<ODDS_API_KEY> or set ODDS_API_KEY in your shell.',
    );
    exitCode = 64;
    return;
  }

  final normalized = key.trim();
  if (!_oddsApiKeyPattern.hasMatch(normalized)) {
    stderr.writeln(
      'Invalid key format. Expected a 32-character alphanumeric OddsAPI key.',
    );
    exitCode = 64;
    return;
  }

  final envFile = File('.env');
  final lines = envFile.existsSync()
      ? envFile.readAsLinesSync()
      : <String>['ODDS_API_KEY=replace_with_api_key'];
  final updated = _upsertOddsApiKey(lines, normalized);
  envFile.writeAsStringSync('${updated.join('\n')}\n');
  stdout.writeln('Updated .env with ODDS_API_KEY for local development.');
}

String? _resolveKey(List<String> args) {
  for (var index = 0; index < args.length; index++) {
    final value = args[index];
    if (value.startsWith('--key=')) {
      return value.substring('--key='.length);
    }
    if (value == '--key' && index + 1 < args.length) {
      return args[index + 1];
    }
  }
  return Platform.environment['ODDS_API_KEY'];
}

List<String> _upsertOddsApiKey(List<String> lines, String key) {
  var replaced = false;
  final next = lines
      .map((line) {
        if (line.startsWith('ODDS_API_KEY=')) {
          replaced = true;
          return 'ODDS_API_KEY=$key';
        }
        return line;
      })
      .toList(growable: true);
  if (!replaced) {
    next.add('ODDS_API_KEY=$key');
  }
  return next;
}
