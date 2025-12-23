import 'package:mermaid_parser/mermaid_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Gantt Parser', () {
    test('parses simple gantt chart', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    title A Gantt Diagram
    dateFormat YYYY-MM-DD
    section Section
    A task           :a1, 2014-01-01, 30d
    Another task     :after a1, 20d
''');

      expect(result.title, 'A Gantt Diagram');
      expect(result.dateFormat, 'YYYY-MM-DD');
      expect(result.sections.length, 1);
      expect(result.sections[0].name, 'Section');
      expect(result.tasks.length, 2);
      expect(result.tasks[0].name, 'A task');
      expect(result.tasks[1].name, 'Another task');
    });

    test('parses task with done status', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    section Section
    Completed task :done, 2014-01-01, 2014-01-06
''');

      expect(result.tasks.length, 1);
      expect(result.tasks[0].done, true);
    });

    test('parses task with critical status', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    section Section
    Critical task :crit, 2014-01-01, 5d
''');

      expect(result.tasks.length, 1);
      expect(result.tasks[0].crit, true);
    });

    test('parses task with milestone', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    section Section
    Milestone :milestone, 2014-01-01, 0d
''');

      expect(result.tasks.length, 1);
      expect(result.tasks[0].milestone, true);
    });

    test('parses multiple sections', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    section Section 1
    Task 1 :2014-01-01, 30d
    section Section 2
    Task 2 :2014-01-15, 20d
    Task 3 :2014-02-01, 10d
''');

      expect(result.sections.length, 2);
      expect(result.sections[0].name, 'Section 1');
      expect(result.sections[0].tasks.length, 1);
      expect(result.sections[1].name, 'Section 2');
      expect(result.sections[1].tasks.length, 2);
    });

    test('parses axisFormat', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    axisFormat %Y-%m-%d
    section Section
    Task :2014-01-01, 30d
''');

      expect(result.axisFormat, '%Y-%m-%d');
    });

    test('parses inclusiveEndDates', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    inclusiveEndDates
    section Section
    Task :2014-01-01, 30d
''');

      expect(result.inclusiveEndDates, true);
    });

    test('parses topAxis', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    topAxis
    section Section
    Task :2014-01-01, 30d
''');

      expect(result.topAxis, true);
    });

    test('parses excludes', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    excludes weekends
    section Section
    Task :2014-01-01, 30d
''');

      expect(result.excludes, 'weekends');
    });

    test('parses todayMarker', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    todayMarker off
    section Section
    Task :2014-01-01, 30d
''');

      expect(result.todayMarker, 'off');
    });

    test('parses weekday setting', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    weekday monday
    section Section
    Task :2014-01-01, 30d
''');

      expect(result.weekday, 'monday');
    });

    test('handles comments', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    %% This is a comment
    title My Gantt
    %% Another comment
    section Section
    Task :2014-01-01, 30d
''');

      expect(result.title, 'My Gantt');
      expect(result.tasks.length, 1);
    });

    test('parses accessibility title and description', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    accTitle: Gantt Chart Title
    accDescr: This is a Gantt chart description
    section Section
    Task :2014-01-01, 30d
''');

      expect(result.accTitle, 'Gantt Chart Title');
      expect(result.accDescription, 'This is a Gantt chart description');
    });

    test('parses complex example', () {
      final parser = Gantt();
      final result = parser.parse('''
gantt
    title Project Timeline
    dateFormat YYYY-MM-DD
    section Planning
    Research :done, 2014-01-01, 2014-01-06
    Design :crit, active, 2014-01-07, 3d
    section Development
    Coding :2014-01-10, 10d
    Testing :5d
    section Deployment
    Release :milestone, 2014-01-25, 0d
''');

      expect(result.title, 'Project Timeline');
      expect(result.sections.length, 3);
      expect(result.tasks.length, 5);
      expect(result.tasks[0].done, true);
      expect(result.tasks[1].crit, true);
      expect(result.tasks[1].active, true);
      expect(result.tasks[4].milestone, true);
    });

    test('throws on invalid syntax', () {
      final parser = Gantt();
      expect(
        () => parser.parse('not a gantt chart'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

