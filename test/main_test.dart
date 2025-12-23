import 'package:mermaid_parser/mermaid_parser.dart';
import 'package:test/test.dart';

void main() {
  test('test1', () {
    final parser = Mindmap();
    final result = parser.parse('''
mindmap
Root
  A
    B
    C
''');
    print(result.runtimeType);
    print(result);
  });
}
