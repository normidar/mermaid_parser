import 'package:petitparser/petitparser.dart';

/// Direction of the flowchart
enum FlowDirection {
  TB, // Top to Bottom
  BT, // Bottom to Top
  LR, // Left to Right
  RL, // Right to Left
  TD, // Top Down (same as TB)
}

/// Shape types for flowchart nodes
enum FlowNodeShape {
  DEFAULT, // Just text
  RECT, // [text]
  ROUND, // (text)
  STADIUM, // ([text])
  SUBROUTINE, // [[text]]
  CYLINDRICAL, // [(text)]
  CIRCLE, // ((text))
  ASYMMETRIC, // >text]
  RHOMBUS, // {text}
  HEXAGON, // {{text}}
  PARALLELOGRAM, // [/text/]
  PARALLELOGRAM_ALT, // [\text\]
  TRAPEZOID, // [/text\]
  TRAPEZOID_ALT, // [\text/]
  DOUBLE_CIRCLE, // (((text)))
}

/// Link/Edge types
enum FlowLinkType {
  ARROW, // -->
  OPEN, // ---
  DOTTED, // -.->
  THICK, // ==>
}

/// Link/Edge stroke style
enum FlowLinkStroke {
  NORMAL,
  THICK,
  DOTTED,
}

/// Text type for rendering
enum FlowTextType {
  TEXT,
  STRING,
  MARKDOWN,
}

/// Represents text with its type
class FlowText {
  FlowText(this.text, this.type);
  final String text;
  final FlowTextType type;

  @override
  String toString() => text;
}

/// Represents a node in the flowchart
class FlowNode {
  FlowNode({
    required this.id,
    this.text,
    this.shape = FlowNodeShape.DEFAULT,
    this.classes = const [],
    this.styles,
    this.link,
    this.linkTarget,
    this.tooltip,
    this.clickEvent,
    this.clickArgs,
  });

  final String id;
  FlowText? text;
  FlowNodeShape shape;
  List<String> classes;
  String? styles;
  String? link;
  String? linkTarget;
  String? tooltip;
  String? clickEvent;
  String? clickArgs;

  @override
  String toString() {
    final buffer = StringBuffer('Node($id');
    if (text != null) buffer.write(', text: ${text!.text}');
    if (shape != FlowNodeShape.DEFAULT) buffer.write(', shape: $shape');
    if (classes.isNotEmpty) buffer.write(', classes: $classes');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Represents a link/edge between nodes
class FlowLink {
  FlowLink({
    required this.from,
    required this.to,
    this.type = FlowLinkType.ARROW,
    this.stroke = FlowLinkStroke.NORMAL,
    this.length = 1,
    this.text,
    this.id,
  });

  final String from;
  final String to;
  final FlowLinkType type;
  final FlowLinkStroke stroke;
  final int length;
  FlowText? text;
  String? id;

  @override
  String toString() {
    final buffer = StringBuffer('Link($from -> $to');
    if (text != null) buffer.write(', text: ${text!.text}');
    if (type != FlowLinkType.ARROW) buffer.write(', type: $type');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Represents a subgraph
class FlowSubgraph {
  FlowSubgraph({
    required this.nodes, required this.links, this.id,
    this.title,
    this.subgraphs = const [],
  });

  final String? id;
  final FlowText? title;
  final List<FlowNode> nodes;
  final List<FlowLink> links;
  final List<FlowSubgraph> subgraphs;

  @override
  String toString() {
    final buffer = StringBuffer('Subgraph(');
    if (id != null) buffer.write('id: $id, ');
    if (title != null) buffer.write('title: ${title!.text}, ');
    buffer.write('nodes: ${nodes.length}, links: ${links.length}');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Result of parsing a flowchart
class FlowchartResult {
  FlowchartResult({
    required this.direction,
    required this.nodes,
    required this.links,
    this.subgraphs = const [],
    this.accTitle,
    this.accDescription,
  });

  final FlowDirection direction;
  final List<FlowNode> nodes;
  final List<FlowLink> links;
  final List<FlowSubgraph> subgraphs;
  String? accTitle;
  String? accDescription;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('FlowchartResult:');
    buffer.writeln('  Direction: $direction');
    buffer.writeln('  Nodes: ${nodes.length}');
    for (final node in nodes) {
      buffer.writeln('    $node');
    }
    buffer.writeln('  Links: ${links.length}');
    for (final link in links) {
      buffer.writeln('    $link');
    }
    if (subgraphs.isNotEmpty) {
      buffer.writeln('  Subgraphs: ${subgraphs.length}');
    }
    return buffer.toString();
  }
}

/// Mermaid flowchart parser using PetitParser
class Flow extends GrammarDefinition {
  Flow();

  FlowchartResult parse(String input) {
    final parser = build();
    final result = parser.parse(input);
    if (result is Success) {
      return result.value as FlowchartResult;
    } else {
      throw FormatException(
        'Parse error at ${result.position}: ${result.message}',
      );
    }
  }

  @override
  Parser start() => ref0(flowDocument).end();

  Parser flowDocument() =>
      (ref0(graphConfig) & ref0(statements)).map((values) {
        final direction = values[0] as FlowDirection;
        final statements = values[1] as List<dynamic>;
        return _buildFlowchartResult(direction, statements);
      });

  Parser graphConfig() =>
      (ref0(spaces).optional() &
              ref0(graphKeyword) &
              ref0(directionSpec) &
              ref0(newline))
          .map((values) => values[2] as FlowDirection);

  Parser graphKeyword() =>
      (string('flowchart') | string('graph') | string('flowchart-elk'))
          .flatten()
          .trim();

  Parser directionSpec() =>
      (ref0(spaces) & ref0(direction)).map((values) => values[1]) |
      epsilon().map((_) => FlowDirection.TB);

  Parser direction() =>
      string('TD').map((_) => FlowDirection.TD) |
      string('TB').map((_) => FlowDirection.TB) |
      string('BT').map((_) => FlowDirection.BT) |
      string('LR').map((_) => FlowDirection.LR) |
      string('RL').map((_) => FlowDirection.RL);

  Parser statements() => ref0(statement).star();

  Parser statement() =>
      ref0(commentLine) |
      ref0(nodeStatement) |
      ref0(emptyLine);

  Parser nodeStatement() =>
      (ref0(spaces) &
              ref0(nodeId) &
              ref0(nodeShape).optional() &
              (ref0(newline) | epsilon()))
          .map((values) {
        final id = values[1] as String;
        final shape = values[2] as Map<String, dynamic>?;
        return {
          'type': 'node',
          'id': id,
          'text': shape?['text'],
          'shape': shape?['shape'] ?? FlowNodeShape.DEFAULT,
        };
      });

  Parser nodeId() =>
      (letter() | digit() | pattern('_-')).plus().flatten().trim();

  Parser nodeShape() =>
      ref0(rectShape) |
      ref0(roundShape) |
      ref0(diamondShape) |
      ref0(hexagonShape) |
      ref0(stadiumShape) |
      ref0(subroutineShape) |
      ref0(cylinderShape) |
      ref0(circleShape) |
      ref0(doubleCircleShape);

  Parser rectShape() =>
      (char('[') & ref0(textContent) & char(']')).map((values) => {
            'shape': FlowNodeShape.RECT,
            'text': values[1],
          },);

  Parser roundShape() =>
      (char('(') & ref0(textContent) & char(')')).map((values) => {
            'shape': FlowNodeShape.ROUND,
            'text': values[1],
          },);

  Parser diamondShape() =>
      (char('{') & ref0(textContent) & char('}')).map((values) => {
            'shape': FlowNodeShape.RHOMBUS,
            'text': values[1],
          },);

  Parser hexagonShape() =>
      (string('{{') & ref0(textContent) & string('}}')).map((values) => {
            'shape': FlowNodeShape.HEXAGON,
            'text': values[1],
          },);

  Parser stadiumShape() =>
      (string('([') & ref0(textContent) & string('])')).map((values) => {
            'shape': FlowNodeShape.STADIUM,
            'text': values[1],
          },);

  Parser subroutineShape() =>
      (string('[[') & ref0(textContent) & string(']]')).map((values) => {
            'shape': FlowNodeShape.SUBROUTINE,
            'text': values[1],
          },);

  Parser cylinderShape() =>
      (string('[(') & ref0(textContent) & string(')]')).map((values) => {
            'shape': FlowNodeShape.CYLINDRICAL,
            'text': values[1],
          },);

  Parser circleShape() =>
      (string('((') & ref0(textContent) & string('))')).map((values) => {
            'shape': FlowNodeShape.CIRCLE,
            'text': values[1],
          },);

  Parser doubleCircleShape() =>
      (string('(((') & ref0(textContent) & string(')))'))
          .map((values) => {
                'shape': FlowNodeShape.DOUBLE_CIRCLE,
                'text': values[1],
              },);

  Parser textContent() => pattern('^][)(}{').plus().flatten().trim();

  Parser commentLine() =>
      (ref0(spaces).optional() &
              string('%%') &
              Token.newlineParser().neg().star() &
              (ref0(newline) | epsilon()))
          .map((_) => null);

  Parser emptyLine() => (ref0(spaces).optional() & ref0(newline)).map((_) => null);

  Parser spaces() => pattern(' \t').plus().flatten();

  Parser newline() => char('\n');

  FlowchartResult _buildFlowchartResult(
    FlowDirection direction,
    List<dynamic> statements,
  ) {
    final nodes = <FlowNode>[];
    final links = <FlowLink>[];
    final nodeMap = <String, FlowNode>{};

    for (final statement in statements) {
      if (statement == null) continue;

      final stmtMap = statement as Map<String, dynamic>;

      if (stmtMap['type'] == 'node') {
        final id = stmtMap['id'] as String;
        final text = stmtMap['text'] as String?;
        final shape = stmtMap['shape'] as FlowNodeShape;

        final node = FlowNode(
          id: id,
          text: text != null ? FlowText(text, FlowTextType.TEXT) : null,
          shape: shape,
        );

        nodes.add(node);
        nodeMap[id] = node;
      }
    }

    return FlowchartResult(
      direction: direction,
      nodes: nodes,
      links: links,
    );
  }
}

