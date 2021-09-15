#!/bin/bash
# to run:
# BLOB_ROOT="https://<repo_root_blob_url>/<branch>/" bash -c 'cat analyze_result.txt | ./analyzer_to_html.sh > analyze_result.html'
# BLOB_ROOT="https://<repo_root_blob_url>/<branch>/" bash -c 'flutter analyze | ./analyzer_to_html.sh > analyze_result.html'

G_PREV_IFS=$IFS

G_DOCS_BASE_URL='https://dart.dev/tools/linter-rules'
G_FILEPATH=''
G_SECTION_ARRAY=('')

G_INDEX=1
G_TOTAL=0

G_ERROR_COUNT=0
G_WARNING_COUNT=0
G_INFO_COUNT=0
G_HINT_COUNT=0

echo '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Flutter Analyzer Report</title>'
echo '<style>body {font-family:Arial, "Helvetica Neue", Helvetica, sans-serif;font-size:16px;font-weight:normal;margin:0;padding:0;color:#333}#overview {padding:20px 30px}td, th {padding:5px 10px}h1 {margin:0}table {margin:30px;width:calc(100% - 60px);max-width:1000px;border-radius:5px;border:1px solid #ddd;border-spacing:0px;}th {font-weight:400;font-size:medium;text-align:left;cursor:pointer}td.clr-1, td.clr-2, td.clr-3 {font-weight:700}th span {float:right;margin-left:20px}th span:after {content:"";clear:both;display:block}tr:last-child td {border-bottom:none}tr td:first-child, tr td:last-child {color:#9da0a4}#overview.bg-1, tr.bg-1 th {color:#000;background:#efefef;border-bottom:1px solid #efefef}#overview.bg-2, tr.bg-2 th {color:#000;background:#ffec18;border-bottom:1px solid #ffec18}#overview.bg-3, tr.bg-3 th {color:#000;background:#ff9800;border-bottom:1px solid #ff9800}#overview.bg-4, tr.bg-4 th {color:#fff;background:#fe560a;border-bottom:1px solid #fe560a}#overview.bg-5, tr.bg-5 th {color:#fff;background:#cc1905;border-bottom:1px solid #cc1905}td {border-bottom:1px solid #ddd}td.clr-1 {color:#1b73e8}td.clr-2 {color:#f0ad4e}td.clr-3 {color:#b94a48}td a {color:#3a33d1;}td a:hover {color:#272296;}</style>'
echo '</head><body><table><tbody>'

# insight: piping make the script run in subshell,
#          which disallows reassignment of global VARIABLE
# sed '/^[ \t]*$/d' $inputfile | sed '/^Analyzing.*$/d' | while read line
while read line
do
  # [[ "${line// }" = Analyzing* ]] && continue
  # [[ -z "${line// }" ]] && continue

  # insight: significantly better performance with case
  #          rather than with conditional clause
  case "${line// }" in
    Analyzing*) continue ;;
    '') continue ;;
  esac

  IFS='•' read -ra THE_ARRAY <<< "$line"
    TYPE="${THE_ARRAY[0]}"
    DESCRIPTION="${THE_ARRAY[1]}"
    LOCATION="${THE_ARRAY[2]}"
    RULE_NOSPACE="${THE_ARRAY[3]//[[:space:]]/}"

  IFS=':' read -ra LOC_ARRAY <<< "$LOCATION"
    LINENUMBER="${LOC_ARRAY[1]}"
    COLNUMBER="${LOC_ARRAY[2]}"
    CURRENT_FILEPATH="${LOC_ARRAY[0]//[[:space:]]/}"

  RULE_ANCHOR="<a href=\"$G_DOCS_BASE_URL#$RULE_NOSPACE\" target=\"_blank\">$RULE_NOSPACE</a>"
  PATH_ANCHOR="<a href=\"$BLOB_ROOT$CURRENT_FILEPATH#L$LINENUMBER\" target=\"_blank\">$LINENUMBER:$COLNUMBER</a>"

  # insight: `((++G_ERROR_COUNT))` arithmetic operator is significantly faster
  #          rather than `G_ERROR_COUNT=$(expr $G_ERROR_COUNT + 1)`
  case $TYPE in
    'error ')
      ((++G_ERROR_COUNT))
      TYPE_COLOR=3
    ;;
    'warning ')
      ((++G_WARNING_COUNT))
      TYPE_COLOR=2
    ;;
    'info ')
      ((++G_INFO_COUNT))
      TYPE_COLOR=1
    ;;
    'hint ')
      ((++G_HINT_COUNT))
      TYPE_COLOR=1
    ;;
  esac

  # # check whether length of array is 1
  # case "${#G_SECTION_ARRAY[@]}" in
  #   1) ;;
  #   *) ;;
  # esac

  case $CURRENT_FILEPATH in
    $G_FILEPATH)
      G_SECTION_ARRAY+=("<tr style=\"display:none\" class=\"f-$G_INDEX\"><td>$PATH_ANCHOR</td><td class=\"clr-$TYPE_COLOR\">$TYPE</td><td>$DESCRIPTION</td><td>$RULE_ANCHOR</td></tr>")
    ;;
    *)
      PREV_SECTION_HEAD="${G_SECTION_ARRAY[0]}"
      PREV_SECTION_FIRST="${G_SECTION_ARRAY[1]}"
      PREV_TOTAL=$G_TOTAL

      G_FILEPATH=$CURRENT_FILEPATH
      G_TOTAL=$(expr $G_ERROR_COUNT + $G_WARNING_COUNT + $G_INFO_COUNT + $G_HINT_COUNT)

      # handles section that only has 1 analysis result
      # if both prev total and curr total is 1, then print first
      case $G_TOTAL in
        $PREV_TOTAL)
          echo "$PREV_SECTION_HEAD$PREV_SECTION_FIRST"

          # resetting
          ((++G_INDEX))
          G_SECTION_ARRAY=('')
        ;;
      esac


      G_SECTION_ARRAY+=("<tr style=\"display:none\" class=\"f-$G_INDEX\"><td>$PATH_ANCHOR</td><td class=\"clr-$TYPE_COLOR\">$TYPE</td><td>$DESCRIPTION</td><td>$RULE_ANCHOR</td></tr>")


      ((BACKGROUND=$G_TOTAL==1 ? 1 : $G_TOTAL>50 ? 5 : $G_TOTAL<10 ? 2 : $G_TOTAL>30 ? 4 : 3))
      SUMMARY=""
        case $G_ERROR_COUNT in 0) ;; 1) SUMMARY="$SUMMARY$G_ERROR_COUNT Error " ;; *) SUMMARY="$SUMMARY$G_ERROR_COUNT Errors " ;; esac
        case $G_WARNING_COUNT in 0) ;; 1) SUMMARY="$SUMMARY$G_WARNING_COUNT Warning " ;; *) SUMMARY="$SUMMARY$G_WARNING_COUNT Warnings " ;; esac
        case $G_INFO_COUNT in 0) ;; 1) SUMMARY="$SUMMARY$G_INFO_COUNT Info " ;; *) SUMMARY="$SUMMARY$G_INFO_COUNT Infos " ;; esac
        case $G_HINT_COUNT in 0) ;; 1) SUMMARY="$SUMMARY$G_HINT_COUNT Error " ;; *) SUMMARY="$SUMMARY$G_HINT_COUNT Hints " ;; esac
        SUMMARY="$SUMMARY$G_TOTAL Total"
      G_SECTION_ARRAY[0]="<tr class=\"bg-$BACKGROUND\" data-group=\"f-$G_INDEX\"><th colspan=\"4\">[+] $CURRENT_FILEPATH<span>$SUMMARY</span></th></tr>"


      case $PREV_TOTAL in
        0) ;;
        *) 
          echo ${G_SECTION_ARRAY[*]}

          # resetting
          ((++G_INDEX))
          G_SECTION_ARRAY=('')
          G_ERROR_COUNT=0
          G_WARNING_COUNT=0
          G_INFO_COUNT=0
          G_HINT_COUNT=0
        ;;
      esac
    ;;
  esac
done

echo '</tbody></table>'

echo '<script type="text/javascript">
var groups = document.querySelectorAll("tr[data-group]");
for (i = 0; i < groups.length; i++) {
  groups[i].addEventListener("click", function() {
    var inGroup = document.getElementsByClassName(this.getAttribute("data-group"));
    this.innerHTML = (this.innerHTML.indexOf("+") > -1) ? this.innerHTML.replace("+", "-") : this.innerHTML.replace("-", "+");
    for (var j = 0; j < inGroup.length; j++) {
      inGroup[j].style.display = (inGroup[j].style.display !== "none") ? "none" : "table-row";
    }
  });
}
</script>'

echo '</body></html>'

IFS=$G_PREV_IFS

< "${1:-/dev/stdin}"
