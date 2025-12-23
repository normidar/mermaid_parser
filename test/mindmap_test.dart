import 'package:mermaid_parser/mermaid_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Mindmap Parser', () {
    test('parses simple mindmap with hierarchy', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  A
    B
    C
''');

      expect(result.allNodes.length, 4);
      expect(result.root.id, 'Root');
      expect(result.root.children.length, 1);
      expect(result.root.children[0].id, 'A');
      expect(result.root.children[0].children.length, 2);
      expect(result.root.children[0].children[0].id, 'B');
      expect(result.root.children[0].children[1].id, 'C');
    });

    test('parses nodes with different delimiters', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  A(Rounded)
  B[Rectangle]
  C{{Hexagon}}
''');

      expect(result.root.children.length, 3);
      expect(result.root.children[0].type, NodeType.ROUNDED);
      expect(result.root.children[0].description, 'Rounded');
      expect(result.root.children[1].type, NodeType.RECT);
      expect(result.root.children[1].description, 'Rectangle');
      expect(result.root.children[2].type, NodeType.HEXAGON);
      expect(result.root.children[2].description, 'Hexagon');
    });

    test('parses nodes with ID and description', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  node1(First Node)
  node2[Second Node]
''');

      expect(result.root.children.length, 2);
      expect(result.root.children[0].id, 'node1');
      expect(result.root.children[0].description, 'First Node');
      expect(result.root.children[1].id, 'node2');
      expect(result.root.children[1].description, 'Second Node');
    });

    test('parses nodes with quoted descriptions', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  A("Quoted Description")
''');

      expect(result.root.children.length, 1);
      expect(result.root.children[0].description, 'Quoted Description');
    });

    test('parses nodes with icons', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  A
  ::icon(fa fa-book)
  B
  ::icon(fa fa-home)
''');

      expect(result.root.children.length, 2);
      expect(result.root.children[0].id, 'A');
      expect(result.root.children[0].icon, 'fa fa-book');
      expect(result.root.children[1].id, 'B');
      expect(result.root.children[1].icon, 'fa fa-home');
    });

    test('parses nodes with classes', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  A
  :::important
  B
  :::highlight
''');

      expect(result.root.children.length, 2);
      expect(result.root.children[0].id, 'A');
      expect(result.root.children[0].className, 'important');
      expect(result.root.children[1].id, 'B');
      expect(result.root.children[1].className, 'highlight');
    });

    test('parses mindmap with comments', () {
      final parser = Mindmap();
      final result = parser.parse('''
%% This is a comment
mindmap
Root
  %% Another comment
  A
  B
''');

      expect(result.root.children.length, 2);
      expect(result.root.children[0].id, 'A');
      expect(result.root.children[1].id, 'B');
    });

    test('parses complex nested structure', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  Branch1
    Leaf1
    Leaf2
      SubLeaf1
      SubLeaf2
  Branch2
    Leaf3
''');

      expect(result.root.children.length, 2);
      expect(result.root.children[0].id, 'Branch1');
      expect(result.root.children[0].children.length, 2);
      expect(result.root.children[0].children[1].children.length, 2);
      expect(result.root.children[1].id, 'Branch2');
      expect(result.root.children[1].children.length, 1);
    });

    test('handles cloud and bang node types', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  A(-Cloud Node-)
  B-)Bang Node-)
''');

      expect(result.root.children.length, 2);
      expect(result.root.children[0].type, NodeType.CLOUD);
      expect(result.root.children[1].type, NodeType.BANG);
    });

    test('throws on empty mindmap', () {
      final parser = Mindmap();
      expect(
        () => parser.parse('mindmap\n'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on invalid syntax', () {
      final parser = Mindmap();
      expect(
        () => parser.parse('not a mindmap'),
        throwsA(isA<FormatException>()),
      );
    });

    test('converts result back to mermaid string - simple', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  A
  B
''');

      final mermaidString = result.toMermaidString();
      expect(mermaidString, contains('mindmap'));
      expect(mermaidString, contains('Root'));
      expect(mermaidString, contains('  A'));
      expect(mermaidString, contains('  B'));
    });

    test('converts result back to mermaid string - with delimiters', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  A(Rounded)
  B[Rectangle]
''');

      final mermaidString = result.toMermaidString();
      expect(mermaidString, contains('A(Rounded)'));
      expect(mermaidString, contains('B[Rectangle]'));
    });

    test('converts result back to mermaid string - with icons and classes', () {
      final parser = Mindmap();
      final result = parser.parse('''
mindmap
Root
  A
  ::icon(fa fa-book)
  :::important
''');

      final mermaidString = result.toMermaidString();
      expect(mermaidString, contains('::icon(fa fa-book)'));
      expect(mermaidString, contains(':::important'));
    });

    test('round-trip parsing', () {
      final parser = Mindmap();
      const input = '''
mindmap
Root
  A
    B
    C
  D
''';

      final result1 = parser.parse(input);
      final mermaidString = result1.toMermaidString();
      final result2 = parser.parse(mermaidString);

      // Verify structure is preserved
      expect(result2.root.id, result1.root.id);
      expect(result2.root.children.length, result1.root.children.length);
      expect(result2.allNodes.length, result1.allNodes.length);
    });
  });
}
