import 'package:flutter_test/flutter_test.dart';
import 'package:mock_master/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(MockMasterApp, isNotNull);
  });
}
