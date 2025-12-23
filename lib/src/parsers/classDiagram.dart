import 'package:petitparser/petitparser.dart';

/// Mermaid class diagram parser using PetitParser
///
/// Parses Mermaid class diagram syntax and returns a structured representation.
///
/// Example usage:
/// ```dart
/// final parser = ClassDiagram();
/// final input = '''
/// classDiagram
///   class Animal {
///     +String name
///     +makeSound()
///   }
///   class Dog {
///     +bark()
///   }
///   Animal <|-- Dog
/// ''';
/// final result = parser.parse(input);
/// print('Classes: ${result.classes.length}');
/// print('Relations: ${result.relations.length}');
/// ```
///
/// Supports:
/// - Class definitions with members (properties and methods)
/// - Relationships: inheritance (<|--), composition (*--), aggregation (o--), dependency (<--)
/// - Annotations (<<interface>>)
/// - Notes
/// - Directions (TB, BT, LR, RL)
/// - Generic types (Class~T~)
/// - Class labels and CSS classes
/// - Comments (%%)
class ClassDiagram extends GrammarDefinition {
  ClassDiagram();

  Parser alphaNumToken() =>
      (letter() | digit() | pattern('_-')).plus().flatten();

  // Annotation statement
  Parser annotationStatement() => (ref0(spaces) &
              string('<<') &
              ref0(alphaNumToken) &
              string('>>') &
              ref0(spaces) &
              ref0(className))
          .map((values) {
        return {
          'type': 'annotation',
          'annotation': values[2],
          'class': values[5],
        };
      });

  Parser callbackArgs() => pattern('^)').plus().flatten();

  Parser callbackName() =>
      ref0(alphaNumToken) &
      (char('(') & ref0(callbackArgs).optional() & char(')')).optional();

  Parser classBody() => (char('{') &
          ref0(whitespaceOrNewlines).optional() &
          ref0(members).optional() &
          ref0(whitespaceOrNewlines).optional() &
          char('}'))
      .map((values) => values[2] ?? <String>[]);

  // ClassDef statement
  Parser classDefStatement() => (ref0(spaces) &
              string('classDef') &
              ref0(spaces) &
              ref0(classList) &
              ref0(spaces) &
              ref0(styles))
          .map((values) {
        return {
          'type': 'classDef',
          'classes': values[3],
          'styles': values[5],
        };
      });

  Parser classDiagramDocument() => (ref0(newline).optional() &
              ref0(graphConfig) &
              ref0(statements) &
              ref0(whitespace))
          .map((values) {
        final statements = values[2] as List<dynamic>;
        return _buildClassDiagramResult(statements);
      });

  Parser classLabel() =>
      (char('[') & ref0(stringLiteral) & char(']')).map((values) => values[1]);

  Parser classList() =>
      (ref0(alphaNumToken) & (char(',') & ref0(alphaNumToken)).star())
          .map((values) {
        final first = values[0] as String;
        final rest = values[1] as List;
        final result = [first];
        for (final item in rest) {
          result.add(item[1] as String);
        }
        return result;
      });

  Parser className() => (ref0(alphaNumToken) &
          ((char('.') & ref0(className)) |
                  (ref0(genericType)) |
                  (ref0(alphaNumToken)))
              .optional())
      .flatten();

  // Class statement
  Parser classStatement() => (ref0(spaces) &
              string('class') &
              ref0(spaces) &
              ref0(className) &
              ref0(classLabel).optional() &
              (ref0(styleMarker) & ref0(alphaNumToken)).optional() &
              (ref0(spaces).optional() & ref0(classBody)).optional())
          .map((values) {
        final name = values[3] as String;
        final labelOpt = values[4];
        final styleOpt = values[5];
        final bodyOpt = values[6];

        return {
          'type': 'class',
          'name': name,
          'label': labelOpt,
          'cssClass': styleOpt != null ? styleOpt[1] : null,
          'members': bodyOpt != null ? bodyOpt[1] : <String>[],
        };
      });

  // Click statement
  Parser clickStatement() => (ref0(spaces) &
              (string('click') | string('link') | string('callback')) &
              ref0(spaces) &
              ref0(className) &
              ref0(spaces) &
              (ref0(stringLiteral) |
                  ref0(callbackName) |
                  (string('href') & ref0(spaces) & ref0(stringLiteral))
                      .map((v) => v[2])) &
              (ref0(spaces) & ref0(stringLiteral)).optional() &
              (ref0(spaces) & ref0(linkTarget)).optional())
          .map((values) {
        final action = values[1] as String;
        final className = values[3] as String;
        final target = values[5];
        final tooltipOpt = values[6];
        final linkTargetOpt = values[7];

        return {
          'type': 'click',
          'action': action,
          'class': className,
          'target': target,
          'tooltip': tooltipOpt != null ? tooltipOpt[1] : null,
          'linkTarget': linkTargetOpt != null ? linkTargetOpt[1] : null,
        };
      });

  Parser commentLine() => (ref0(spaces).optional() &
          string('%%') &
          Token.newlineParser().neg().star())
      .map((_) => null);

  // CSS class statement
  Parser cssClassStatement() => (ref0(spaces) &
              string('cssClass') &
              ref0(spaces) &
              ref0(stringLiteral) &
              ref0(spaces) &
              ref0(alphaNumToken))
          .map((values) {
        return {
          'type': 'cssClass',
          'class': values[3],
          'cssClass': values[5],
        };
      });

  // Direction statements
  Parser directionStatement() => (ref0(spaces).optional() &
              (string('direction TB') |
                  string('direction BT') |
                  string('direction LR') |
                  string('direction RL')))
          .map((values) {
        final dir = values[1] as String;
        return {
          'type': 'direction',
          'value': dir.split(' ')[1],
        };
      });

  Parser emptyLine() =>
      (ref0(spaces).optional() & ref0(newline)).map((_) => null);

  Parser genericType() =>
      (char('~') & pattern('^~').plus().flatten() & char('~'))
          .map((values) => '~${values[1]}~');

  Parser graphConfig() =>
      (ref0(spaces).optional() & ref0(graphKeyword) & ref0(newline))
          .map((values) => null);

  Parser graphKeyword() =>
      (string('classDiagram-v2') | string('classDiagram')).flatten();

  Parser labelText() => pattern('^:\n').plus().flatten().map((s) => s.trim());

  Parser lineType() =>
      string('--').map((_) => 'LINE') | string('..').map((_) => 'DOTTED_LINE');

  Parser linkTarget() =>
      string('_self') | string('_blank') | string('_parent') | string('_top');

  Parser member() => (ref0(spaces).optional() &
          pattern('^{}\n').plus().flatten() &
          ref0(spaces).optional())
      .map((values) => (values[1] as String).trim())
      .where((s) => s.isNotEmpty);

  Parser members() =>
      (ref0(member) & (ref0(whitespaceOrNewlines) & ref0(member)).star())
          .map((values) {
        final first = values[0] as String;
        final rest = values[1] as List;
        final result = <String>[first];
        for (final item in rest) {
          result.add(item[1] as String);
        }
        return result;
      });

  // Member statement
  Parser memberStatement() => (ref0(spaces) &
              ref0(className) &
              ref0(spaces) &
              char(':') &
              ref0(spaces).optional() &
              ref0(memberText))
          .map((values) {
        return {
          'type': 'member',
          'class': values[1],
          'member': values[5],
        };
      });

  Parser memberText() => pattern('^\n').plus().flatten().map((s) => s.trim());

  Parser namespaceName() => ref0(className);

  // Namespace statement
  Parser namespaceStatement() => (ref0(spaces) &
              string('namespace') &
              ref0(spaces) &
              ref0(namespaceName) &
              ref0(spaces).optional() &
              char('{') &
              ref0(whitespaceOrNewlines).optional() &
              ref0(namespaceStatements).optional() &
              ref0(whitespaceOrNewlines).optional() &
              char('}'))
          .map((values) {
        final name = values[3] as String;
        final statements = values[7] ?? <dynamic>[];
        return {
          'type': 'namespace',
          'name': name,
          'classes': statements,
        };
      });

  Parser namespaceStatement_() =>
      ref0(classStatement) | ref0(noteStatement) | ref0(commentLine);

  Parser namespaceStatements() =>
      ((ref0(namespaceStatement_) &
              (ref0(whitespaceOrNewlines) & ref0(namespaceStatement_)).star())
          .map((values) {
        final first = values[0];
        final rest = values[1] as List;
        final result = <dynamic>[first];
        for (final item in rest) {
          result.add(item[1]);
        }
        return result.where((s) => s != null).toList();
      })) |
      epsilon().map((_) => <dynamic>[]);

  Parser newline() => char('\n');

  // Note statement
  Parser noteStatement() => (ref0(spaces) &
              (string('note for') | string('note')) &
              (ref0(spaces) & ref0(className)).optional() &
              ref0(spaces).optional() &
              ref0(noteText))
          .map((values) {
        final keyword = values[1] as String;
        final classOpt = values[2];
        final text = values[4] as String;

        return {
          'type': 'note',
          'for': keyword == 'note for' && classOpt != null ? classOpt[1] : null,
          'text': text,
        };
      });

  Parser noteText() => ref0(stringLiteral);

  /// Parse the input string and return a ClassDiagramResult
  ClassDiagramResult parse(String input) {
    final parser = build();
    final result = parser.parse(input);
    if (result is Success) {
      return result.value as ClassDiagramResult;
    } else {
      throw FormatException(
        'Parse error at ${result.position}: ${result.message}',
      );
    }
  }

  Parser relation() => (ref0(relationType).optional() &
              ref0(lineType) &
              ref0(relationType).optional())
          .map((values) {
        return {
          'type1': values[0] ?? 'none',
          'lineType': values[1],
          'type2': values[2] ?? 'none',
        };
      });

  // Relation statement
  Parser relationStatement() => (ref0(spaces) &
              ref0(className) &
              (ref0(spaces) & ref0(stringLiteral)).optional() &
              ref0(spaces).optional() &
              ref0(relation) &
              (ref0(spaces) & ref0(stringLiteral)).optional() &
              ref0(spaces).optional() &
              ref0(className) &
              (ref0(spaces) & char(':') & ref0(labelText)).optional())
          .map((values) {
        final from = values[1] as String;
        final label1Opt = values[2];
        final relation = values[4] as Map<String, dynamic>;
        final label2Opt = values[5];
        final to = values[7] as String;
        final labelOpt = values[8];

        return {
          'type': 'relation',
          'from': from,
          'to': to,
          'relation': relation,
          'label1': label1Opt != null ? label1Opt[1] : null,
          'label2': label2Opt != null ? label2Opt[1] : null,
          'label': labelOpt != null ? labelOpt[2] : null,
        };
      });

  Parser relationType() =>
      string('<|').map((_) => 'EXTENSION') |
      string('|>').map((_) => 'EXTENSION') |
      char('<').map((_) => 'DEPENDENCY') |
      char('>').map((_) => 'DEPENDENCY') |
      char('*').map((_) => 'COMPOSITION') |
      char('o').map((_) => 'AGGREGATION') |
      string('()').map((_) => 'LOLLIPOP');

  Parser spaces() => pattern(' \t').plus();

  @override
  Parser start() => ref0(classDiagramDocument).end();

  Parser statement() =>
      ref0(commentLine) |
      ref0(directionStatement) |
      ref0(namespaceStatement) |
      ref0(annotationStatement) |
      ref0(noteStatement) |
      ref0(classStatement) |
      ref0(relationStatement) |
      ref0(memberStatement) |
      ref0(clickStatement) |
      ref0(styleStatement) |
      ref0(cssClassStatement) |
      ref0(classDefStatement);

  Parser statements() =>
      ((ref0(statement) &
              ((ref0(emptyLine) | ref0(newline)).plus() & ref0(statement))
                  .star() &
              (ref0(emptyLine) | ref0(newline)).star())
          .map((values) {
        final first = values[0];
        final rest = values[1] as List;
        final result = <dynamic>[first];
        for (final item in rest) {
          result.add(item[1]);
        }
        return result.where((s) => s != null).toList();
      })) |
      ((ref0(emptyLine) | ref0(newline)).star().map((_) => <dynamic>[]));

  Parser stringContent() => pattern('^"').star().flatten();

  Parser stringLiteral() =>
      (char('"') & ref0(stringContent) & char('"')).map((values) => values[1]);

  Parser styleItem() => (pattern('^\n,').plus() & ref0(spaces).optional())
      .flatten()
      .map((s) => s.trim());

  // Helper parsers
  Parser styleMarker() => string(':::');

  Parser styles() =>
      (ref0(styleItem) & (char(',') & ref0(styleItem)).star()).map((values) {
        final first = values[0] as String;
        final rest = values[1] as List;
        final result = [first];
        for (final item in rest) {
          result.add(item[1] as String);
        }
        return result.join(',');
      });

  // Style statement
  Parser styleStatement() => (ref0(spaces) &
              string('style') &
              ref0(spaces) &
              ref0(alphaNumToken) &
              ref0(spaces) &
              ref0(styles))
          .map((values) {
        return {
          'type': 'style',
          'class': values[3],
          'styles': values[5],
        };
      });

  Parser whitespace() => pattern(' \t\n').star();

  Parser whitespaceOrNewlines() => (ref0(spaces) | ref0(newline)).plus();

  ClassDiagramResult _buildClassDiagramResult(List<dynamic> statements) {
    final classes = <ClassNode>[];
    final relations = <ClassRelation>[];
    final namespaces = <ClassNamespace>[];
    final notes = <ClassNote>[];
    String? direction;

    final classMap = <String, ClassNode>{};

    for (final statement in statements) {
      if (statement == null) continue;

      final stmtMap = statement as Map<String, dynamic>;
      final type = stmtMap['type'];

      switch (type) {
        case 'direction':
          direction = stmtMap['value'] as String;

        case 'class':
          final name = stmtMap['name'] as String;
          final label = stmtMap['label'] as String?;
          final cssClass = stmtMap['cssClass'] as String?;
          final members = stmtMap['members'] as List<String>;

          final classNode = ClassNode(
            name: name,
            label: label,
            members: members,
            cssClass: cssClass,
          );

          classes.add(classNode);
          classMap[name] = classNode;

        case 'relation':
          final from = stmtMap['from'] as String;
          final to = stmtMap['to'] as String;
          final relation = stmtMap['relation'] as Map<String, dynamic>;
          final label = stmtMap['label'] as String?;
          final label1 = stmtMap['label1'] as String?;
          final label2 = stmtMap['label2'] as String?;

          // Ensure classes exist
          classMap.putIfAbsent(from, () {
            final node = ClassNode(name: from);
            classes.add(node);
            return node;
          });
          classMap.putIfAbsent(to, () {
            final node = ClassNode(name: to);
            classes.add(node);
            return node;
          });

          relations.add(
            ClassRelation(
              from: from,
              to: to,
              type1: relation['type1'] as String,
              type2: relation['type2'] as String,
              lineType: relation['lineType'] as String,
              label: label,
              label1: label1,
              label2: label2,
            ),
          );

        case 'member':
          final className = stmtMap['class'] as String;
          final member = stmtMap['member'] as String;

          var classNode = classMap[className];
          if (classNode == null) {
            classNode = ClassNode(name: className);
            classes.add(classNode);
            classMap[className] = classNode;
          }
          classNode.members.add(member);

        case 'annotation':
          final annotation = stmtMap['annotation'] as String;
          final className = stmtMap['class'] as String;

          var classNode = classMap[className];
          if (classNode == null) {
            classNode = ClassNode(name: className);
            classes.add(classNode);
            classMap[className] = classNode;
          }
          classNode.annotations.add(annotation);

        case 'note':
          notes.add(
            ClassNote(
              text: stmtMap['text'] as String,
              forClass: stmtMap['for'] as String?,
            ),
          );

        case 'namespace':
          final namespaceName = stmtMap['name'] as String;
          final namespaceClasses = stmtMap['classes'] as List;

          final nsClasses = <String>[];
          for (final nsClass in namespaceClasses) {
            if (nsClass is Map<String, dynamic> && nsClass['type'] == 'class') {
              nsClasses.add(nsClass['name'] as String);
            }
          }

          namespaces.add(
            ClassNamespace(
              name: namespaceName,
              classes: nsClasses,
            ),
          );

        case 'click':
        case 'style':
        case 'cssClass':
        case 'classDef':
          // These are handled but not stored in the simplified model
          break;
      }
    }

    return ClassDiagramResult(
      classes: classes,
      relations: relations,
      namespaces: namespaces,
      notes: notes,
      direction: direction,
    );
  }
}

/// Result of parsing a class diagram
class ClassDiagramResult {
  ClassDiagramResult({
    required this.classes,
    required this.relations,
    this.namespaces = const [],
    this.notes = const [],
    this.direction,
    this.accTitle,
    this.accDescription,
  });

  final List<ClassNode> classes;
  final List<ClassRelation> relations;
  final List<ClassNamespace> namespaces;
  final List<ClassNote> notes;
  final String? direction;
  String? accTitle;
  String? accDescription;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ClassDiagramResult:');
    if (direction != null) {
      buffer.writeln('  Direction: $direction');
    }
    buffer.writeln('  Classes: ${classes.length}');
    for (final classNode in classes) {
      buffer.writeln('    $classNode');
    }
    buffer.writeln('  Relations: ${relations.length}');
    for (final relation in relations) {
      buffer.writeln('    $relation');
    }
    if (namespaces.isNotEmpty) {
      buffer.writeln('  Namespaces: ${namespaces.length}');
      for (final ns in namespaces) {
        buffer.writeln('    $ns');
      }
    }
    if (notes.isNotEmpty) {
      buffer.writeln('  Notes: ${notes.length}');
      for (final note in notes) {
        buffer.writeln('    $note');
      }
    }
    return buffer.toString();
  }
}

/// Represents a namespace containing classes
class ClassNamespace {
  ClassNamespace({
    required this.name,
    required this.classes,
  });

  final String name;
  final List<String> classes;

  @override
  String toString() => 'Namespace($name, classes: ${classes.join(", ")})';
}

/// Represents a class in the diagram
class ClassNode {
  ClassNode({
    required this.name,
    this.label,
    List<String>? members,
    List<String>? annotations,
    this.cssClass,
    this.link,
    this.tooltip,
    this.clickEvent,
  })  : members = members ?? [],
        annotations = annotations ?? [];

  final String name;
  String? label;
  final List<String> members;
  final List<String> annotations;
  String? cssClass;
  String? link;
  String? tooltip;
  String? clickEvent;

  @override
  String toString() {
    final buffer = StringBuffer('Class($name');
    if (label != null) buffer.write(', label: $label');
    if (members.isNotEmpty) buffer.write(', members: ${members.length}');
    if (annotations.isNotEmpty) buffer.write(', annotations: $annotations');
    if (cssClass != null) buffer.write(', cssClass: $cssClass');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Represents a note in the diagram
class ClassNote {
  ClassNote({
    required this.text,
    this.forClass,
  });

  final String text;
  final String? forClass;

  @override
  String toString() {
    if (forClass != null) {
      return 'Note(for: $forClass, text: $text)';
    }
    return 'Note(text: $text)';
  }
}

/// Represents a relationship between classes
class ClassRelation {
  ClassRelation({
    required this.from,
    required this.to,
    required this.type1,
    required this.type2,
    required this.lineType,
    this.label,
    this.label1,
    this.label2,
  });

  final String from;
  final String to;
  final String
      type1; // EXTENSION, COMPOSITION, AGGREGATION, DEPENDENCY, LOLLIPOP, or 'none'
  final String type2;
  final String lineType; // LINE or DOTTED_LINE
  final String? label;
  final String? label1;
  final String? label2;

  @override
  String toString() {
    final buffer = StringBuffer('Relation($from ');
    if (type1 != 'none') buffer.write('$type1 ');
    buffer.write(lineType);
    if (type2 != 'none') buffer.write(' $type2');
    buffer.write(' $to');
    if (label != null) buffer.write(', label: $label');
    if (label1 != null) buffer.write(', label1: $label1');
    if (label2 != null) buffer.write(', label2: $label2');
    buffer.write(')');
    return buffer.toString();
  }
}
