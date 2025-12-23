# mermaid_parser

[![GitHub](https://img.shields.io/github/license/normidar/mermaid_parser.svg)](https://github.com/normidar/mermaid_parser/blob/main/LICENSE)
[![pub package](https://img.shields.io/pub/v/mermaid_parser.svg)](https://pub.dartlang.org/packages/mermaid_parser)
[![GitHub Stars](https://img.shields.io/github/stars/normidar/mermaid_parser.svg)](https://github.com/normidar/mermaid_parser/stargazers)
[![Twitter](https://img.shields.io/twitter/url/https/twitter.com/normidar.svg?style=social&label=Follow%20%40normidar)](https://twitter.com/normidar)
[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/normidar)

A Mermaid diagram parser library for Dart, built with PetitParser.

## Features

- ✅ Parse Mermaid mindmap diagrams
- ✅ Support for hierarchical node structures
- ✅ Multiple node types (rounded, rectangle, hexagon, cloud, bang)
- ✅ Node descriptions with various delimiters
- ✅ Icons and CSS classes for nodes
- ✅ Comment support
- ✅ Quoted descriptions

## Usage

### Basic Mindmap Parsing

```dart
import 'package:mermaid_parser/mermaid_parser.dart';

void main() {
  final parser = Mindmap();
  final result = parser.parse('''
mindmap
Root
  A
    B
    C
  D
''');

  print(result.root.id); // Root
  print(result.root.children.length); // 2
  print(result.allNodes.length); // 4
}
```

### Node Types

```dart
final result = parser.parse('''
mindmap
Root
  A(Rounded Node)
  B[Rectangle Node]
  C{{Hexagon Node}}
  D(-Cloud Node-)
  E-)Bang Node-)
''');

// Access node types
print(result.root.children[0].type); // NodeType.ROUNDED
print(result.root.children[1].type); // NodeType.RECT
print(result.root.children[2].type); // NodeType.HEXAGON
print(result.root.children[3].type); // NodeType.CLOUD
print(result.root.children[4].type); // NodeType.BANG
```

### Node IDs and Descriptions

```dart
final result = parser.parse('''
mindmap
Root
  node1(Custom Description)
  node2[Another Description]
''');

print(result.root.children[0].id); // node1
print(result.root.children[0].description); // Custom Description
```

### Icons and Classes

```dart
final result = parser.parse('''
mindmap
Root
  A
  ::icon(fa fa-book)
  :::important
  B
  ::icon(fa fa-home)
''');

print(result.root.children[0].icon); // fa fa-book
print(result.root.children[0].className); // important
```

### Comments

```dart
final result = parser.parse('''
%% This is a comment
mindmap
Root
  %% Another comment
  A
  B
''');
```

## API Reference

### Classes

#### `Mindmap`

The main parser class.

- `MindmapResult parse(String input)` - Parses a Mermaid mindmap string and returns a result.

#### `MindmapResult`

Contains the parsing result.

- `MindmapNode root` - The root node of the mindmap
- `List<MindmapNode> allNodes` - All nodes in the mindmap (flat list)

#### `MindmapNode`

Represents a node in the mindmap.

- `String id` - The node's identifier
- `String description` - The node's description text
- `NodeType type` - The node's visual type
- `int level` - The indentation level (0 for root)
- `String? icon` - Optional icon identifier
- `String? className` - Optional CSS class name
- `List<MindmapNode> children` - Child nodes

#### `NodeType`

Enum representing node visual types:

- `DEFAULT` - Plain text node
- `ROUNDED` - Round parentheses `()`
- `RECT` - Square brackets `[]`
- `HEXAGON` - Double braces `{{}}`
- `CLOUD` - Cloud style `(-  -)`
- `BANG` - Bang/explosion style `-)  -)`
- `CIRCLE` - Circle (reserved)

## Implementation

This parser is implemented using [PetitParser](https://pub.dev/packages/petitparser), a dynamic parser combinator library. It translates the Mermaid mindmap Jison/Lex grammar into PetitParser combinators.

## License

See [LICENSE](LICENSE) file.
