import 'package:flutter_test/flutter_test.dart';
import 'package:arbitrac/src/rust/api.dart';
import 'package:arbitrac/src/rust/frb_generated.dart';

void main() {
  test('Rust bridge ping smoke test', () async {
    // Initialize the library
    await RustLib.init();
    
    // Call the ping function
    final result = await ping();
    
    // Verify the result
    expect(result, 'pong');
  });
}
