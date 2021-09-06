import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'html_elements.dart';

const String dartLinterDocsBaseURL = 'https://dart.dev/tools/linter-rules';

const String argsInput = 'input';
const String argsOutput = 'output';
const String argsBranch = 'branch';
const String argsRepository = 'repository';
const String argsProvider = 'provider';
const String argsHelp = 'help';

Future<void> main(List<String> arguments) async {
  exitCode = 0;

  final ArgParser parser = ArgParser()
    ..addOption(argsInput, abbr: 'i')
    ..addOption(argsOutput, abbr: 'o')
    ..addOption(argsBranch, abbr: 'b')
    ..addOption(argsRepository, abbr: 'r')
    ..addOption(argsProvider, abbr: 'p')
    // TODO(ybbond): implement flag --dart or -d, for `dart analyze` result
    ..addFlag(argsHelp, negatable: false, defaultsTo: false, abbr: 'h');

  final ArgResults argResults = parser.parse(arguments);

  final bool flagHelp = argResults[argsHelp] as bool;

  if (flagHelp) {
    _displayHelp();
    return;
  }

  try {
    await htmlParser(argResults: argResults);
  } catch (e, s) {
    exitCode = 1;
    _handleError(e, s);
    return;
  }
}

Future<void> htmlParser({
  required ArgResults argResults,
}) async {
  final String? optionInput = argResults[argsInput] as String?;
  final String? optionOutput = argResults[argsOutput] as String?;
  final String? optionBranch = argResults[argsBranch] as String?;
  final String? optionRepository = argResults[argsRepository] as String?;
  final String? optionProvider = argResults[argsProvider] as String?;

  final List<String> resultListString = await _inputGetter(path: optionInput);

  final Map<String, List<List<String>>> allResults =
      <String, List<List<String>>>{};

  for (final String resultLine in resultListString) {
    final String trimmed = resultLine.trim();
    final List<String> splitted = trimmed.split(' • ');
    final List<String> urlSplitted = splitted[2].split(':');
    allResults[urlSplitted[0]] ??= <List<String>>[];

    // [       0             ,       1      ,          2          ,   3   ,   4    ]
    // [ 'error|warning|info', '<rule_name>', '<rule description>', '<LN>', '<LC>' ]
    allResults[urlSplitted[0]]!.add(<String>[
      splitted[0],
      splitted[3],
      splitted[1],
      urlSplitted[1],
      urlSplitted[2],
    ]);
  }

  final List<String> resultKeys = allResults.keys.toList(growable: false);

  final List<String> parsedHTML = <String>[];

  for (int index = 0; index < resultKeys.length; index++) {
    final List<List<String>> fileReportList = allResults[resultKeys[index]]!;
    int errors = 0;
    int warnings = 0;
    int infos = 0;

    final String theContents = fileReportList.map((List<String> contentTable) {
      final String reportType = contentTable[0];
      final String lineNumber = contentTable[3];
      final String lineColumn = contentTable[4];

      final String lineNumberElement = _generateLineNumberElement(
        repo: optionRepository,
        branch: optionBranch,
        provider: optionProvider,
        path: resultKeys[index],
        lineNumber: lineNumber,
        lineColumn: lineColumn,
      );

      if (reportType == 'info') {
        infos++;
      } else if (reportType == 'warning') {
        warnings++;
      } else if (reportType == 'error') {
        errors++;
      }

      return '<tr style="display:none" class="f-$index">'
          '$lineNumberElement'
          '<td class="clr-${reportType == 'error' ? '3' : reportType == 'warning' ? '2' : '1'}">$reportType</td>'
          '<td>${contentTable[2]}</td>'
          '<td><a href="$dartLinterDocsBaseURL#${contentTable[1]}" target="_blank">${contentTable[1]}</a></td>'
          '</tr>';
    }).join('\n');

    final List<String> summaries = <String>[];

    if (errors > 0) {
      summaries.add('$errors error${errors > 1 ? 's' : ''}');
    }
    if (warnings > 0) {
      summaries.add('$warnings warning${warnings > 1 ? 's' : ''}');
    }
    if (infos > 0) {
      summaries.add('$infos info${infos > 1 ? 's' : ''}');
    }
    final int total = fileReportList.length;
    final int background = total == 1
        ? 1
        : total > 50
            ? 5
            : total < 10
                ? 2
                : total > 30
                    ? 4
                    : 3;

    final String containingTable =
        '<tr class="bg-$background" data-group="f-$index">'
        '<th colspan="4">'
        '[+] ${resultKeys[index]}'
        '<span>${summaries.join(', ')}, ${fileReportList.length} total</span>'
        '</th>'
        '</tr>\n';

    parsedHTML.add(containingTable + theContents);
  }

  _outputResult(path: optionOutput, result: parsedHTML.join('\n'));
}

String _generateLineNumberElement({
  required String? repo,
  required String? branch,
  required String path,
  required String? provider,
  required String lineNumber,
  required String lineColumn,
}) {
  if (repo != null && branch != null) {
    late String link;
    final String repoNoTrailingSlash =
        repo.endsWith('/') ? repo.substring(0, repo.length - 1) : repo;
    switch (provider) {
      case 'gitlab':
        link = '$repoNoTrailingSlash/-/blob/$branch/$path#L$lineNumber';
        break;
      case 'github':
      default: // defaults to GitHub
        link = '$repoNoTrailingSlash/blob/$branch/$path#$lineNumber';
    }
    return '<td><a href="$link" target="_blank">$lineNumber:$lineColumn</a></td>';
  }

  return '<td>$lineNumber:$lineColumn</td>';
}

Future<List<String>> _inputGetter({
  required String? path,
}) async {
  late List<String> resultListString;

  if (path != null) {
    final File resultFile = File(path);

    resultListString = await resultFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .skip(3) // remove non-result and whitespace
        .toList();
  } else {
    resultListString = await stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .skip(3) // remove non-result and whitespace
        .toList();
  }

  resultListString.removeLast(); // remove whitespace
  return resultListString;
}

Future<void> _outputResult({
  required String? path,
  required String result,
}) async {
  if (path != null) {
    await File(path).writeAsString(resultHead + result + resultFoot);
  } else {
    stdout.write(resultHead + result + resultFoot);
  }
}

void _displayHelp() {
  stdout.write('\n'
      '  -i --input        path to file to be parsed\n'
      '                    otherwise, expects from stdin or pipe\n'
      '\n'
      '  -o --output       path to output file\n'
      '                    otherwise, prints to stdout\n'
      '\n'
      '  -h --help         show this help text'
      '\n'
      '\n'
      'If you pass the following options, you can click on the\n'
      'line number in resulting html, that redirects to the\n'
      'online repository with link hash to the specific line number.\n'
      '\n'
      '  -b --branch       branch name\n'
      '\n'
      '  -r --repository   url to repository\n'
      '\n'
      '  -p --provider     gitlab or github\n'
      '                    default: github\n'
      '\n\n');
}

void _handleError(Object e, StackTrace s) {
  stdout.write('-------------- Message --------------\n\n');
  if (e is FileSystemException) {
    if (e.osError != null &&
        e.osError!.message.indexOf('No such file or directory') > 0) {
      stdout.write(
          'No file detected based on path from option -i or --input\n\n');
    } else {
      stdout.write('Cannot open the file passed from option -i or --input\n\n');
    }
  } else {
    stdout.write('Unhandled error\n\n');
  }
  stderr.write(''
      '--------------- Error ---------------\n\n'
      '$e\n\n'
      '------------- StackTrace ------------\n\n'
      '$s\n'
      '-------------------------------------\n');
}
