import 'package:mermaid_parser/mermaid_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Flow Parser', () {
    test('parses simple flowchart with direction', () {
      final parser = Flow();
      final result = parser.parse('''
flowchart TD
    A
    B
''');

      expect(result.direction, FlowDirection.TD);
      expect(result.nodes.length, 2);
      expect(result.nodes[0].id, 'A');
      expect(result.nodes[1].id, 'B');
    });

    test('parses flowchart with different directions', () {
      final directions = {
        'TB': FlowDirection.TB,
        'TD': FlowDirection.TD,
        'BT': FlowDirection.BT,
        'LR': FlowDirection.LR,
        'RL': FlowDirection.RL,
      };

      for (final entry in directions.entries) {
        final parser = Flow();
        final result = parser.parse('flowchart ${entry.key}\n    A\n');
        expect(result.direction, entry.value);
      }
    });

    test('parses nodes with different shapes', () {
      final parser = Flow();
      final result = parser.parse('''
flowchart TD
    A[Rectangle]
    B(Round)
    C{Diamond}
    D{{Hexagon}}
''');

      expect(result.nodes.length, 4);
      expect(result.nodes[0].shape, FlowNodeShape.RECT);
      expect(result.nodes[0].text?.text, 'Rectangle');
      expect(result.nodes[1].shape, FlowNodeShape.ROUND);
      expect(result.nodes[1].text?.text, 'Round');
      expect(result.nodes[2].shape, FlowNodeShape.RHOMBUS);
      expect(result.nodes[2].text?.text, 'Diamond');
      expect(result.nodes[3].shape, FlowNodeShape.HEXAGON);
      expect(result.nodes[3].text?.text, 'Hexagon');
    });

    test('parses special shapes', () {
      final parser = Flow();
      final result = parser.parse('''
flowchart TD
    A([Stadium])
    B[[Subroutine]]
    C[(Cylinder)]
    D((Circle))
    E(((Double Circle)))
''');

      expect(result.nodes.length, 5);
      expect(result.nodes[0].shape, FlowNodeShape.STADIUM);
      expect(result.nodes[1].shape, FlowNodeShape.SUBROUTINE);
      expect(result.nodes[2].shape, FlowNodeShape.CYLINDRICAL);
      expect(result.nodes[3].shape, FlowNodeShape.CIRCLE);
      expect(result.nodes[4].shape, FlowNodeShape.DOUBLE_CIRCLE);
    });

    test('parses nodes without text', () {
      final parser = Flow();
      final result = parser.parse('''
flowchart LR
    Start
    End
''');

      expect(result.nodes.length, 2);
      expect(result.nodes[0].id, 'Start');
      expect(result.nodes[0].text, null);
      expect(result.nodes[1].id, 'End');
    });

    test('handles comments', () {
      final parser = Flow();
      final result = parser.parse('''
flowchart TD
    %% This is a comment
    A[Node A]
    %% Another comment
    B[Node B]
''');

      expect(result.nodes.length, 2);
      expect(result.nodes[0].id, 'A');
      expect(result.nodes[1].id, 'B');
    });

    test('parses graph keyword', () {
      final parser = Flow();
      final result = parser.parse('''
graph LR
    A
    B
''');

      expect(result.direction, FlowDirection.LR);
      expect(result.nodes.length, 2);
    });

    test('throws on invalid syntax', () {
      final parser = Flow();
      expect(
        () => parser.parse('not a flowchart'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

