import 'package:flutter_test/flutter_test.dart';
import 'package:bijec_bet/src/rust/api.dart';
import 'package:bijec_bet/src/rust/frb_generated.dart';

void main() {
  test('Rust bridge ping smoke test', () async {
    // Initialize the library
    await RustLib.init();
    
    // Call the ping function (sync in FRB v2 by default if marked)
    final result = ping();
    
    // Verify the result
    expect(result, 'pong');
  });
}
