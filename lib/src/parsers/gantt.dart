import 'package:petitparser/petitparser.dart';

/// Represents a task in the Gantt chart
class GanttTask {
  GanttTask({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.duration,
    this.dependencies = const [],
    this.done = false,
    this.milestone = false,
    this.active = false,
    this.crit = false,
    this.link,
    this.tooltip,
    this.clickEvent,
    this.clickArgs,
  });

  final String id;
  final String name;
  String? startDate;
  String? endDate;
  String? duration;
  List<String> dependencies;
  bool done;
  bool milestone;
  bool active;
  bool crit;
  String? link;
  String? tooltip;
  String? clickEvent;
  String? clickArgs;

  @override
  String toString() {
    final buffer = StringBuffer('Task($id: $name');
    if (startDate != null) buffer.write(', start: $startDate');
    if (endDate != null) buffer.write(', end: $endDate');
    if (duration != null) buffer.write(', duration: $duration');
    if (dependencies.isNotEmpty) buffer.write(', deps: $dependencies');
    if (done) buffer.write(', done');
    if (milestone) buffer.write(', milestone');
    if (crit) buffer.write(', critical');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Represents a section in the Gantt chart
class GanttSection {
  GanttSection({
    required this.name,
    required this.tasks,
  });

  final String name;
  final List<GanttTask> tasks;

  @override
  String toString() {
    return 'Section($name, tasks: ${tasks.length})';
  }
}

/// Result of parsing a Gantt chart
class GanttResult {
  GanttResult({
    this.title,
    this.dateFormat,
    this.axisFormat,
    this.tickInterval,
    this.includes,
    this.excludes,
    this.todayMarker,
    this.inclusiveEndDates = false,
    this.topAxis = false,
    this.weekday,
    this.weekend,
    required this.sections,
    required this.tasks,
    this.accTitle,
    this.accDescription,
  });

  String? title;
  String? dateFormat;
  String? axisFormat;
  String? tickInterval;
  String? includes;
  String? excludes;
  String? todayMarker;
  bool inclusiveEndDates;
  bool topAxis;
  String? weekday;
  String? weekend;
  List<GanttSection> sections;
  List<GanttTask> tasks;
  String? accTitle;
  String? accDescription;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('GanttResult:');
    if (title != null) buffer.writeln('  Title: $title');
    if (dateFormat != null) buffer.writeln('  DateFormat: $dateFormat');
    buffer.writeln('  Sections: ${sections.length}');
    for (final section in sections) {
      buffer.writeln('    $section');
    }
    buffer.writeln('  Total Tasks: ${tasks.length}');
    return buffer.toString();
  }
}

/// Mermaid Gantt chart parser using PetitParser
class Gantt extends GrammarDefinition {
  Gantt();

  GanttResult parse(String input) {
    final parser = build();
    final result = parser.parse(input);
    if (result is Success) {
      return result.value as GanttResult;
    } else {
      throw FormatException(
        'Parse error at ${result.position}: ${result.message}',
      );
    }
  }

  @override
  Parser start() => ref0(ganttDocument).end();

  Parser ganttDocument() =>
      (ref0(ganttKeyword) & ref0(newline).optional() & ref0(statements))
          .map((values) {
        final statements = values[2] as List<dynamic>;
        return _buildGanttResult(statements);
      });

  Parser ganttKeyword() => string('gantt').trim();

  Parser statements() => ref0(statement).star();

  Parser statement() =>
      ref0(commentLine) |
      ref0(titleStatement) |
      ref0(dateFormatStatement) |
      ref0(inclusiveEndDatesStatement) |
      ref0(topAxisStatement) |
      ref0(axisFormatStatement) |
      ref0(tickIntervalStatement) |
      ref0(includesStatement) |
      ref0(excludesStatement) |
      ref0(todayMarkerStatement) |
      ref0(weekdayStatement) |
      ref0(weekendStatement) |
      ref0(accTitleStatement) |
      ref0(accDescrStatement) |
      ref0(sectionStatement) |
      ref0(clickStatement) |
      ref0(taskStatement) |
      ref0(emptyLine);

  Parser titleStatement() =>
      (string('title') & ref0(spaces) & ref0(textToEol) & ref0(newline))
          .map((values) => {
                'type': 'title',
                'value': values[2],
              });

  Parser dateFormatStatement() =>
      (string('dateFormat') & ref0(spaces) & ref0(textToEol) & ref0(newline))
          .map((values) => {
                'type': 'dateFormat',
                'value': values[2],
              });

  Parser inclusiveEndDatesStatement() =>
      (string('inclusiveEndDates') & ref0(newline)).map((_) => {
            'type': 'inclusiveEndDates',
            'value': true,
          });

  Parser topAxisStatement() =>
      (string('topAxis') & ref0(newline)).map((_) => {
            'type': 'topAxis',
            'value': true,
          });

  Parser axisFormatStatement() =>
      (string('axisFormat') & ref0(spaces) & ref0(textToEol) & ref0(newline))
          .map((values) => {
                'type': 'axisFormat',
                'value': values[2],
              });

  Parser tickIntervalStatement() =>
      (string('tickInterval') &
              ref0(spaces) &
              ref0(textToEol) &
              ref0(newline))
          .map((values) => {
                'type': 'tickInterval',
                'value': values[2],
              });

  Parser includesStatement() =>
      (string('includes') & ref0(spaces) & ref0(textToEol) & ref0(newline))
          .map((values) => {
                'type': 'includes',
                'value': values[2],
              });

  Parser excludesStatement() =>
      (string('excludes') & ref0(spaces) & ref0(textToEol) & ref0(newline))
          .map((values) => {
                'type': 'excludes',
                'value': values[2],
              });

  Parser todayMarkerStatement() =>
      (string('todayMarker') & ref0(spaces) & ref0(textToEol) & ref0(newline))
          .map((values) => {
                'type': 'todayMarker',
                'value': values[2],
              });

  Parser weekdayStatement() =>
      (string('weekday') & ref0(spaces) & ref0(weekdayName) & ref0(newline))
          .map((values) => {
                'type': 'weekday',
                'value': values[2],
              });

  Parser weekdayName() =>
      string('monday') |
      string('tuesday') |
      string('wednesday') |
      string('thursday') |
      string('friday') |
      string('saturday') |
      string('sunday');

  Parser weekendStatement() =>
      (string('weekend') & ref0(spaces) & ref0(weekendName) & ref0(newline))
          .map((values) => {
                'type': 'weekend',
                'value': values[2],
              });

  Parser weekendName() => string('friday') | string('saturday');

  Parser accTitleStatement() =>
      (string('accTitle') &
              char(':') &
              ref0(spaces).optional() &
              ref0(textToEol) &
              ref0(newline))
          .map((values) => {
                'type': 'accTitle',
                'value': values[3],
              });

  Parser accDescrStatement() =>
      (string('accDescr') &
              char(':') &
              ref0(spaces).optional() &
              ref0(textToEol) &
              ref0(newline))
          .map((values) => {
                'type': 'accDescr',
                'value': values[3],
              });

  Parser sectionStatement() =>
      (string('section') & ref0(spaces) & ref0(textToEol) & ref0(newline))
          .map((values) => {
                'type': 'section',
                'value': values[2],
              });

  Parser clickStatement() =>
      (string('click') &
              ref0(spaces) &
              ref0(taskId) &
              ref0(spaces) &
              ref0(clickArgs) &
              ref0(newline))
          .map((values) => {
                'type': 'click',
                'taskId': values[2],
                'args': values[4],
              });

  Parser clickArgs() =>
      (string('href') & ref0(spaces) & ref0(quotedString))
          .map((values) => {'href': values[2]}) |
      (ref0(callbackName) &
              char('(') &
              ref0(callbackArgsList).optional() &
              char(')'))
          .map((values) => {
                'callback': values[0],
                'args': values[2],
              });

  Parser callbackName() => pattern('a-zA-Z0-9_').plus().flatten();

  Parser callbackArgsList() => pattern('^)').plus().flatten();

  Parser taskStatement() =>
      (ref0(spaces).optional() &
              ref0(taskText) &
              char(':') &
              ref0(taskData) &
              ref0(newline))
          .map((values) => {
                'type': 'task',
                'name': values[1],
                'data': values[3],
              });

  Parser taskText() => pattern('^:\n').plus().flatten().trim();

  Parser taskData() => pattern('^\n').plus().flatten().trim();

  Parser taskId() => pattern('a-zA-Z0-9_-').plus().flatten();

  Parser quotedString() =>
      (char('"') & pattern('^"').star().flatten() & char('"'))
          .map((values) => values[1]);

  Parser textToEol() => pattern('^\n#;').plus().flatten().trim();

  Parser commentLine() =>
      (ref0(spaces).optional() &
              string('%%') &
              pattern('^\n').star() &
              ref0(newline))
          .map((_) => null);

  Parser emptyLine() =>
      (ref0(spaces).optional() & ref0(newline)).map((_) => null);

  Parser spaces() => pattern(' \t').plus().flatten();

  Parser newline() => char('\n');

  GanttResult _buildGanttResult(List<dynamic> statements) {
    final sections = <GanttSection>[];
    final allTasks = <GanttTask>[];
    var currentSection = 'default';
    final sectionTasks = <String, List<GanttTask>>{};
    sectionTasks[currentSection] = [];

    String? title;
    String? dateFormat;
    String? axisFormat;
    String? tickInterval;
    String? includes;
    String? excludes;
    String? todayMarker;
    var inclusiveEndDates = false;
    var topAxis = false;
    String? weekday;
    String? weekend;
    String? accTitle;
    String? accDescription;

    var taskCounter = 0;

    for (final statement in statements) {
      if (statement == null) continue;

      final stmtMap = statement as Map<String, dynamic>;

      switch (stmtMap['type']) {
        case 'title':
          title = stmtMap['value'] as String;
        case 'dateFormat':
          dateFormat = stmtMap['value'] as String;
        case 'inclusiveEndDates':
          inclusiveEndDates = true;
        case 'topAxis':
          topAxis = true;
        case 'axisFormat':
          axisFormat = stmtMap['value'] as String;
        case 'tickInterval':
          tickInterval = stmtMap['value'] as String;
        case 'includes':
          includes = stmtMap['value'] as String;
        case 'excludes':
          excludes = stmtMap['value'] as String;
        case 'todayMarker':
          todayMarker = stmtMap['value'] as String;
        case 'weekday':
          weekday = stmtMap['value'] as String;
        case 'weekend':
          weekend = stmtMap['value'] as String;
        case 'accTitle':
          accTitle = stmtMap['value'] as String;
        case 'accDescr':
          accDescription = stmtMap['value'] as String;
        case 'section':
          currentSection = stmtMap['value'] as String;
          sectionTasks[currentSection] = [];
        case 'task':
          final taskName = stmtMap['name'] as String;
          final taskData = stmtMap['data'] as String;
          final taskId = 'task${taskCounter++}';

          final task = _parseTaskData(taskId, taskName, taskData);
          sectionTasks[currentSection]!.add(task);
          allTasks.add(task);
        case 'click':
          final taskId = stmtMap['taskId'] as String;
          final args = stmtMap['args'] as Map<String, dynamic>;

          // Find task and update click info
          for (final task in allTasks) {
            if (task.id == taskId || task.name == taskId) {
              if (args.containsKey('href')) {
                task.link = args['href'] as String;
              }
              if (args.containsKey('callback')) {
                task.clickEvent = args['callback'] as String;
                task.clickArgs = args['args'] as String?;
              }
            }
          }
      }
    }

    // Build sections
    for (final entry in sectionTasks.entries) {
      if (entry.value.isNotEmpty) {
        sections.add(GanttSection(
          name: entry.key,
          tasks: entry.value,
        ));
      }
    }

    return GanttResult(
      title: title,
      dateFormat: dateFormat,
      axisFormat: axisFormat,
      tickInterval: tickInterval,
      includes: includes,
      excludes: excludes,
      todayMarker: todayMarker,
      inclusiveEndDates: inclusiveEndDates,
      topAxis: topAxis,
      weekday: weekday,
      weekend: weekend,
      sections: sections,
      tasks: allTasks,
      accTitle: accTitle,
      accDescription: accDescription,
    );
  }

  GanttTask _parseTaskData(String id, String name, String data) {
    final parts = data.split(',').map((s) => s.trim()).toList();

    String? startDate;
    String? endDate;
    String? duration;
    final dependencies = <String>[];
    var done = false;
    var milestone = false;
    var active = false;
    var crit = false;

    for (final part in parts) {
      if (part.isEmpty) continue;

      // Check for keywords
      if (part == 'done') {
        done = true;
      } else if (part == 'active') {
        active = true;
      } else if (part == 'crit') {
        crit = true;
      } else if (part == 'milestone') {
        milestone = true;
      } else if (part.contains('after')) {
        // Dependency: "after taskId"
        final depMatch = RegExp(r'after\s+(\S+)').firstMatch(part);
        if (depMatch != null) {
          dependencies.add(depMatch.group(1)!);
        }
      } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(part)) {
        // Date format: YYYY-MM-DD
        startDate ??= part;
      } else if (part.endsWith('d') || part.endsWith('h') || part.endsWith('m')) {
        // Duration: 5d, 3h, 30m
        duration = part;
      } else {
        // Could be start date or task name reference
        if (startDate == null) {
          startDate = part;
        }
      }
    }

    return GanttTask(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      duration: duration,
      dependencies: dependencies,
      done: done,
      milestone: milestone,
      active: active,
      crit: crit,
    );
  }
}

