import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

ExternalLibrary? resolveRustExternalLibrary() {
  if (Platform.isMacOS) {
    return ExternalLibrary.process(
      iKnowHowToUseIt: true,
      debugInfo: 'macOS process-linked Rust symbols',
    );
  }
  return null;
}
