/*
 * 
 * Based on the result of `eslint --format html
 *     link: https://eslint.org/docs/user-guide/formatters/#html
 *
 */

const String styleWithCSS = '<style>'
    'body {font-family:Arial, "Helvetica Neue", Helvetica, sans-serif;font-size:16px;font-weight:normal;margin:0;padding:0;color:#333}'
    '#overview {padding:20px 30px}'
    'td, th {padding:5px 10px}'
    'h1 {margin:0}'
    'table {margin:30px;width:calc(100% - 60px);max-width:1000px;border-radius:5px;border:1px solid #ddd;border-spacing:0px;}'
    'th {font-weight:400;font-size:medium;text-align:left;cursor:pointer}'
    'td.clr-1, td.clr-2, td.clr-3 {font-weight:700}'
    'th span {float:right;margin-left:20px}'
    'th span:after {content:"";clear:both;display:block}'
    'tr:last-child td {border-bottom:none}'
    'tr td:first-child, tr td:last-child {color:#9da0a4}'
    '#overview.bg-1, tr.bg-1 th {color:#000;background:#efefef;border-bottom:1px solid #efefef}'
    '#overview.bg-2, tr.bg-2 th {color:#000;background:#ffec18;border-bottom:1px solid #ffec18}'
    '#overview.bg-3, tr.bg-3 th {color:#000;background:#ff9800;border-bottom:1px solid #ff9800}'
    '#overview.bg-4, tr.bg-4 th {color:#fff;background:#fe560a;border-bottom:1px solid #fe560a}'
    '#overview.bg-5, tr.bg-5 th {color:#fff;background:#cc1905;border-bottom:1px solid #cc1905}'
    'td {border-bottom:1px solid #ddd}'
    'td.clr-1 {color:#1b73e8}'
    'td.clr-2 {color:#f0ad4e}'
    'td.clr-3 {color:#b94a48}'
    'td a {color:#3a33d1;}'
    'td a:hover {color:#272296;}'
    '</style>';

const String javascriptWithJS = '<script type="text/javascript">'
    '\nvar groups = document.querySelectorAll("tr[data-group]");'
    '\nfor (i = 0; i < groups.length; i++) {'
    '\n  groups[i].addEventListener("click", function() {'
    '\n    var inGroup = document.getElementsByClassName(this.getAttribute("data-group"));'
    '\n    this.innerHTML = (this.innerHTML.indexOf("+") > -1) ? this.innerHTML.replace("+", "-") : this.innerHTML.replace("-", "+");'
    '\n    for (var j = 0; j < inGroup.length; j++) {'
    '\n      inGroup[j].style.display = (inGroup[j].style.display !== "none") ? "none" : "table-row";'
    '\n    }'
    '\n  });'
    '\n}'
    '\n</script>';

const String header =
    '<head><meta charset="UTF-8"><title>Flutter Analyzer Report</title>$styleWithCSS</head>';

const String resultHead =
    '<!DOCTYPE html>\n<html>\n$header\n<body>\n<table>\n<tbody>\n';

const String resultFoot =
    '\n</tbody>\n</table>\n$javascriptWithJS\n</body>\n</html>';

