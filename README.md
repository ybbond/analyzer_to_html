# Flutter and Dart Analyzer Export to HTML [WIP]

Export Flutter or Dart Analyzer reports to be HTML.

## Usage

```
  -i --input        path to file to be parsed
                    otherwise, expects from stdin or pipe

  -o --output       path to output file
                    otherwise, prints to stdout

  -h --help         show this help text

If you pass the following options, you can click on the
line number in resulting html, that redirects to the
online repository with link hash to the specific line number.

  -b --branch       branch name

  -r --repository   url to repository

  -p --provider     gitlab or github
                    default: github

```
