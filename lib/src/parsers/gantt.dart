import 'package:petitparser/petitparser.dart';

/// Mermaid Gantt chart parser using PetitParser
class Gantt extends GrammarDefinition {
  Gantt();

  Parser accDescrConfig() =>
      (string('accDescr') & char(':') & ref0(sp).optional() & ref0(toEol))
          .map((v) => {'type': 'accDescr', 'value': v[3]});

  Parser accTitleConfig() =>
      (string('accTitle') & char(':') & ref0(sp).optional() & ref0(toEol))
          .map((v) => {'type': 'accTitle', 'value': v[3]});

  Parser aLine() =>
      ref0(commentLine) |
      ref0(configLine) |
      ref0(sectionLine) |
      ref0(taskLine) |
      ref0(emptyLine);

  Parser axisFormatConfig() => (string('axisFormat') & ref0(sp) & ref0(toEol))
      .map((v) => {'type': 'axisFormat', 'value': v[2]});

  Parser commentLine() =>
      (ref0(sp).optional() & string('%%') & pattern('^\n').star() & ref0(nl))
          .map((_) => null);

  Parser config() =>
      ref0(titleConfig) |
      ref0(dateFormatConfig) |
      ref0(axisFormatConfig) |
      ref0(tickIntervalConfig) |
      ref0(includesConfig) |
      ref0(excludesConfig) |
      ref0(todayMarkerConfig) |
      ref0(inclusiveEndDatesConfig) |
      ref0(topAxisConfig) |
      ref0(weekdayConfig) |
      ref0(weekendConfig) |
      ref0(accTitleConfig) |
      ref0(accDescrConfig);

  Parser configLine() =>
      (ref0(sp).optional() & ref0(config) & ref0(nl)).map((v) => v[1]);

  Parser dateFormatConfig() => (string('dateFormat') & ref0(sp) & ref0(toEol))
      .map((v) => {'type': 'dateFormat', 'value': v[2]});

  Parser emptyLine() => ref0(nl).map((_) => null);

  Parser excludesConfig() => (string('excludes') & ref0(sp) & ref0(toEol))
      .map((v) => {'type': 'excludes', 'value': v[2]});

  Parser ganttDocument() =>
      (ref0(nl).optional() & string('gantt') & ref0(nl) & ref0(lines))
          .map((values) => _buildGanttResult(values[3] as List<dynamic>));

  Parser includesConfig() => (string('includes') & ref0(sp) & ref0(toEol))
      .map((v) => {'type': 'includes', 'value': v[2]});

  Parser inclusiveEndDatesConfig() => string('inclusiveEndDates')
      .map((_) => {'type': 'inclusiveEndDates', 'value': true});

  Parser lines() => ref0(aLine).star();

  Parser nl() => char('\n');

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

  Parser sectionLine() => (ref0(sp).optional() &
          string('section') &
          ref0(sp) &
          ref0(toEol) &
          ref0(nl))
      .map((v) => {'type': 'section', 'value': v[3]});

  Parser sp() => pattern(' \t').plus();

  @override
  Parser start() => ref0(ganttDocument).end();

  Parser taskData() => pattern('^\n;#').plus().flatten().trim();

  Parser taskLine() => (ref0(sp).optional() &
          ref0(taskName) &
          char(':') &
          ref0(taskData) &
          ref0(nl))
      .map((v) => {'type': 'task', 'name': v[1], 'data': v[3]});

  Parser taskName() => pattern('^:\n').plus().flatten().trim();

  Parser tickIntervalConfig() =>
      (string('tickInterval') & ref0(sp) & ref0(toEol))
          .map((v) => {'type': 'tickInterval', 'value': v[2]});

  Parser titleConfig() => (string('title') & ref0(sp) & ref0(toEol))
      .map((v) => {'type': 'title', 'value': v[2]});

  Parser todayMarkerConfig() => (string('todayMarker') & ref0(sp) & ref0(toEol))
      .map((v) => {'type': 'todayMarker', 'value': v[2]});

  Parser toEol() => pattern('^\n#;').plus().flatten().trim();

  Parser topAxisConfig() =>
      string('topAxis').map((_) => {'type': 'topAxis', 'value': true});

  Parser weekdayConfig() => (string('weekday') & ref0(sp) & ref0(weekdayName))
      .map((v) => {'type': 'weekday', 'value': v[2]});

  Parser weekdayName() => (string('monday') |
          string('tuesday') |
          string('wednesday') |
          string('thursday') |
          string('friday') |
          string('saturday') |
          string('sunday'))
      .flatten();

  Parser weekendConfig() => (string('weekend') & ref0(sp) & ref0(weekendName))
      .map((v) => {'type': 'weekend', 'value': v[2]});

  Parser weekendName() => (string('friday') | string('saturday')).flatten();

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
      }
    }

    // Build sections
    for (final entry in sectionTasks.entries) {
      if (entry.value.isNotEmpty) {
        sections.add(
          GanttSection(
            name: entry.key,
            tasks: entry.value,
          ),
        );
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
    // Parse task data: "done, 2014-01-01, 30d" or "after taskId, 20d" etc.
    final parts = data.split(',').map((s) => s.trim()).toList();

    String? startDate;
    String? endDate;
    String? duration;
    final dependencies = <String>[];
    var done = false;
    var milestone = false;
    var active = false;
    var crit = false;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;

      // Check for status keywords
      if (part == 'done') {
        done = true;
      } else if (part == 'active') {
        active = true;
      } else if (part == 'crit') {
        crit = true;
      } else if (part == 'milestone') {
        milestone = true;
      } else if (part.startsWith('after')) {
        // Dependency: "after taskId"
        final depParts = part.split(RegExp(r'\s+'));
        if (depParts.length > 1) {
          dependencies.add(depParts[1]);
        }
      } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(part)) {
        // Date format: YYYY-MM-DD
        if (startDate == null) {
          startDate = part;
        } else {
          endDate = part;
        }
      } else if (RegExp(r'^\d+[dhms]$').hasMatch(part)) {
        // Duration: 5d, 3h, 30m, 45s
        duration = part;
      } else if (part.contains(':')) {
        // Task ID with colon (e.g., "a1")
        startDate ??= part;
      } else if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(part)) {
        // Could be a task ID reference
        if (startDate == null && !done && !active && !crit && !milestone) {
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

/// Result of parsing a Gantt chart
class GanttResult {
  GanttResult({
    required this.sections,
    required this.tasks,
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
