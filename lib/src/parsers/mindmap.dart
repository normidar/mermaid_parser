import 'package:petitparser/petitparser.dart';

/// Mermaid mindmap parser using PetitParser
class Mindmap extends GrammarDefinition {
  Mindmap();

  Parser backtickDescription() =>
      (string('"`') & pattern('^`').plus().flatten() & string('`"'))
          .map((values) => values[1]);

  Parser classDecl() => (string(':::') & pattern('^\n').plus().flatten())
      .map((values) => values[1].trim());

  Parser classStatement() =>
      (ref0(spaces) & ref0(classDecl) & (ref0(newline) | epsilon()))
          .map((values) {
        final spaces = values[0] as String;
        return {
          'type': 'class',
          'level': spaces.length,
          'value': values[1],
        };
      });

  Parser comment() =>
      string('%%') & Token.newlineParser().neg().star() & ref0(newline);

  Parser comments() => ref0(comment).plus();

  Parser content() => ref0(line).plus();

  Parser emptyLine() => ref0(newline).map((_) => null);

  Parser icon() =>
      (string('::icon(') & pattern('^)').plus().flatten() & char(')'))
          .map((values) => values[1]);

  Parser iconStatement() =>
      (ref0(spaces) & ref0(icon) & (ref0(newline) | epsilon())).map((values) {
        final spaces = values[0] as String;
        return {
          'type': 'icon',
          'level': spaces.length,
          'value': values[1],
        };
      });

  Parser line() =>
      ref0(spaceLine) |
      ref0(iconStatement) |
      ref0(classStatement) |
      ref0(nodeStatement) |
      ref0(emptyLine);

  Parser mindmapDocument() =>
      (ref0(comments).optional() & ref0(mindmapKeyword) & ref0(content))
          .map((values) => _buildMindmapResult(values[2] as List<dynamic>));

  Parser mindmapKeyword() =>
      (pattern('Mm').seq(string('indmap')) & ref0(newline)).flatten().trim();

  Parser newline() => char('\n');

  Parser node() => ref0(nodeWithId) | ref0(nodeWithoutId);

  Parser nodeDelimited() =>
      (ref0(nodeStart) & ref0(nodeDescription) & ref0(nodeEnd)).map(
        (values) => {
          'description': values[1],
          'nodeType': _getNodeType(values[0] as String, values[2] as String),
        },
      );

  Parser nodeDescription() =>
      ref0(quotedDescription) |
      ref0(backtickDescription) |
      ref0(plainDescription);

  Parser nodeEnd() =>
      string('-)') |
      string('(-') |
      string('))') |
      string('((') |
      string('}}') |
      char(')') |
      char(']') |
      char('(');

  Parser nodeId() =>
      (letter() | digit() | char('_') | (char('-') & char(')').not()))
          .plus()
          .flatten();

  Parser nodeStart() =>
      string('-)') |
      string('(-') |
      string('))') |
      string('((') |
      string('{{') |
      char('(') |
      char('[');

  Parser nodeStatement() =>
      (ref0(spaces) & ref0(node) & (ref0(newline) | epsilon())).map((values) {
        final spaces = values[0] as String;
        final level = spaces.length;
        final nodeData = values[1] as Map<String, dynamic>;
        return {
          'type': 'node',
          'level': level,
          'id': nodeData['id'],
          'description': nodeData['description'],
          'nodeType': nodeData['nodeType'],
        };
      });

  Parser nodeWithId() =>
      (ref0(nodeId) & ref0(nodeDelimited).optional()).map((values) {
        if (values[1] == null) {
          return {
            'id': values[0],
            'description': values[0],
            'nodeType': NodeType.DEFAULT,
          };
        } else {
          final delimited = values[1] as Map<String, dynamic>;
          return {
            'id': values[0],
            'description': delimited['description'],
            'nodeType': delimited['nodeType'],
          };
        }
      });

  Parser nodeWithoutId() => ref0(nodeDelimited).map((delimited) {
        final data = delimited as Map<String, dynamic>;
        return {
          'id': data['description'],
          'description': data['description'],
          'nodeType': data['nodeType'],
        };
      });

  MindmapResult parse(String input) {
    final parser = build();
    final result = parser.parse(input);
    if (result is Success) {
      return result.value as MindmapResult;
    } else {
      throw FormatException(
        'Parse error at ${result.position}: ${result.message}',
      );
    }
  }

  Parser plainDescription() => pattern('^)]}\n').plus().flatten().trim();

  Parser quotedDescription() =>
      (char('"') & pattern('^"').plus().flatten() & char('"'))
          .map((values) => values[1]);

  Parser spaceLine() => (ref0(spaces) &
          string('%%') &
          Token.newlineParser().neg().star() &
          (ref0(newline) | epsilon()))
      .map((_) => null);

  Parser spaces() => pattern(' \t').star().flatten();

  @override
  Parser start() => ref0(mindmapDocument).end();

  MindmapResult _buildMindmapResult(List<dynamic> statements) {
    final allNodes = <MindmapNode>[];
    final nodeStack = <MindmapNode>[];
    MindmapNode? root;

    for (final statement in statements) {
      if (statement == null) continue;

      final stmtMap = statement as Map<String, dynamic>;

      if (stmtMap['type'] == 'node') {
        final level = stmtMap['level'] as int;
        final node = MindmapNode(
          id: stmtMap['id'] as String,
          description: stmtMap['description'] as String,
          type: stmtMap['nodeType'] as NodeType,
          level: level,
        );

        allNodes.add(node);

        // Set root if this is the first node
        if (root == null) {
          root = node;
          nodeStack.add(node);
        } else {
          // Find parent based on level
          while (nodeStack.isNotEmpty && nodeStack.last.level >= level) {
            nodeStack.removeLast();
          }

          if (nodeStack.isNotEmpty) {
            nodeStack.last.children.add(node);
          }
          nodeStack.add(node);
        }
      } else if (stmtMap['type'] == 'icon') {
        // Find the node at the same level to attach the icon to
        final level = stmtMap['level'] as int;
        final node = nodeStack.lastWhere(
          (n) => n.level == level,
          orElse: () => nodeStack.last,
        );
        node.icon = stmtMap['value'] as String;
      } else if (stmtMap['type'] == 'class') {
        // Find the node at the same level to attach the class to
        final level = stmtMap['level'] as int;
        final node = nodeStack.lastWhere(
          (n) => n.level == level,
          orElse: () => nodeStack.last,
        );
        node.className = stmtMap['value'] as String;
      }
    }

    if (root == null) {
      throw const FormatException('No root node found in mindmap');
    }

    return MindmapResult(root, allNodes);
  }

  NodeType _getNodeType(String start, String end) {
    final pair = '$start$end';
    switch (pair) {
      case '()':
        return NodeType.ROUNDED;
      case '(())':
      case '((':
        return NodeType.ROUNDED;
      case '[]':
        return NodeType.RECT;
      case '{{}}':
        return NodeType.HEXAGON;
      case '(-(-':
      case '(-)':
        return NodeType.CLOUD;
      case '-)-)':
      case '-))':
        return NodeType.BANG;
      case '))':
        return NodeType.BANG;
      default:
        return NodeType.DEFAULT;
    }
  }
}

/// Represents a node in the mindmap
class MindmapNode {
  MindmapNode({
    required this.id,
    required this.description,
    required this.type,
    required this.level,
    this.icon,
    this.className,
  });
  final String id;
  final String description;
  final NodeType type;
  final int level;
  String? icon;
  String? className;

  List<MindmapNode> children = [];

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer
        .write('${'  ' * level}Node(id: $id, desc: $description, type: $type');
    if (icon != null) buffer.write(', icon: $icon');
    if (className != null) buffer.write(', class: $className');
    buffer.write(')');
    if (children.isNotEmpty) {
      buffer.write('\n');
      for (final child in children) {
        buffer.write('$child\n');
      }
    }
    return buffer.toString();
  }
}

/// Result of parsing a mindmap
class MindmapResult {
  MindmapResult(this.root, this.allNodes);
  final MindmapNode root;

  final List<MindmapNode> allNodes;

  /// Convert the mindmap back to Mermaid string format
  String toMermaidString() {
    final buffer = StringBuffer();
    buffer.writeln('mindmap');
    _writeNode(buffer, root);
    return buffer.toString();
  }

  @override
  String toString() {
    return 'MindmapResult:\n$root';
  }

  (String, String) _getDelimiters(NodeType type) {
    switch (type) {
      case NodeType.ROUNDED:
        return ('(', ')');
      case NodeType.RECT:
        return ('[', ']');
      case NodeType.HEXAGON:
        return ('{{', '}}');
      case NodeType.CLOUD:
        return ('(-', '-)');
      case NodeType.BANG:
        return ('-)', '-)');
      case NodeType.CIRCLE:
        return ('((', '))');
      case NodeType.DEFAULT:
        return ('', '');
    }
  }

  void _writeNode(StringBuffer buffer, MindmapNode node) {
    final indent = '  ' * node.level;

    // Write node with appropriate delimiter
    if (node.id == node.description && node.type == NodeType.DEFAULT) {
      // Simple node without delimiter
      buffer.writeln('$indent${node.id}');
    } else {
      // Node with delimiter
      final (start, end) = _getDelimiters(node.type);
      if (node.id != node.description) {
        // Node has custom ID
        buffer.writeln('$indent${node.id}$start${node.description}$end');
      } else {
        // Node without custom ID
        buffer.writeln('$indent$start${node.description}$end');
      }
    }

    // Write icon if present
    if (node.icon != null) {
      buffer.writeln('$indent::icon(${node.icon})');
    }

    // Write class if present
    if (node.className != null) {
      buffer.writeln('$indent:::${node.className}');
    }

    // Write children
    for (final child in node.children) {
      _writeNode(buffer, child);
    }
  }
}

/// Node types in mindmap
enum NodeType {
  DEFAULT,
  ROUNDED,
  RECT,
  CIRCLE,
  CLOUD,
  BANG,
  HEXAGON,
}
