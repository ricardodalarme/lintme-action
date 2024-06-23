@TestOn('vm')
import 'package:action_app/github_checkrun_utils.dart';
import 'package:action_app/github_workflow_utils.dart';
import 'package:github/github.dart' as github;
import 'package:lintme/lint_analyzer.dart' as dcm;
import 'package:mocktail/mocktail.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

class GitHubWorkflowUtilsMock extends Mock implements GitHubWorkflowUtils {}

void main() {
  group('GitHubCheckRunUtils', () {
    late GitHubWorkflowUtilsMock workflowUtilsMock;

    setUp(() {
      workflowUtilsMock = GitHubWorkflowUtilsMock();
    });

    group('issueToAnnotation returns', () {
      const absolutePath = '/home/developer/project/source.dart';

      setUp(() {
        when(workflowUtilsMock.currentPathToRepoRoot)
            .thenReturn('/home/developer/project');
      });

      test('github annotation from lintme multi line issue', () {
        final utils = GitHubCheckRunUtils(workflowUtilsMock);

        final issue = dcm.Issue(
          ruleId: 'rule',
          documentation: Uri(),
          location: SourceSpan(
            SourceLocation(
              1,
              sourceUrl: Uri.parse('file://$absolutePath'),
              line: 1,
              column: 2,
            ),
            SourceLocation(
              1,
              sourceUrl: Uri.parse('file://$absolutePath'),
              line: 3,
              column: 4,
            ),
            '',
          ),
          severity: dcm.Severity.none,
          message: 'message',
        );

        final annotation = utils.issueToAnnotation(absolutePath, issue);

        expect(annotation.path, equals('source.dart'));
        expect(annotation.startLine, equals(1));
        expect(annotation.endLine, equals(3));
        expect(annotation.startColumn, isNull);
        expect(annotation.endColumn, isNull);
        expect(
          annotation.annotationLevel,
          equals(github.CheckRunAnnotationLevel.notice),
        );
        expect(annotation.message, equals('message'));
        expect(annotation.title, isEmpty);
        expect(annotation.rawDetails, isNull);
      });

      test('github annotation from lintme single line issue', () {
        final utils = GitHubCheckRunUtils(workflowUtilsMock);

        final issue = dcm.Issue(
          ruleId: 'rule',
          documentation: Uri(),
          location: SourceSpan(
            SourceLocation(
              1,
              sourceUrl: Uri.parse('file://$absolutePath'),
              line: 1,
              column: 2,
            ),
            SourceLocation(
              1,
              sourceUrl: Uri.parse('file://$absolutePath'),
              line: 1,
              column: 4,
            ),
            '',
          ),
          severity: dcm.Severity.none,
          message: 'message',
          verboseMessage: 'verbose message',
          suggestion: const dcm.Replacement(
            comment: 'replacement comment',
            replacement: 'new code',
          ),
        );

        final annotation = utils.issueToAnnotation(absolutePath, issue);

        expect(annotation.path, equals('source.dart'));
        expect(annotation.startLine, equals(1));
        expect(annotation.endLine, equals(1));
        expect(annotation.startColumn, equals(2));
        expect(annotation.endColumn, equals(4));
        expect(
          annotation.annotationLevel,
          equals(github.CheckRunAnnotationLevel.notice),
        );
        expect(
          annotation.message,
          equals('verbose message\nreplacement comment'),
        );
        expect(annotation.title, equals('message'));
        expect(annotation.rawDetails, isNull);
      });
    });

    test(
      'severityToAnnotationLevel returns github annotation level from lintme severity',
      () {
        final utils = GitHubCheckRunUtils(workflowUtilsMock);

        expect(
          utils.severityToAnnotationLevel(dcm.Severity.warning),
          equals(github.CheckRunAnnotationLevel.warning),
        );
      },
    );
  });
}
