#!/bin/bash

workdir=working_dir
outdir=output

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source ${dir}/common.sh

if [ $# -lt 1 ]; then
  echo "usage: $0 xml1 [xml2, [xml3, [...]]]"
  echo ""
  echo "       xml1 is recommended to be English data."
  echo "       each xml file name should be like \"ted_{langcode}-*.xml\"."
  exit 1
fi

if [ $# -eq 1 ]; then
  show_exec ${dir}/extract-mono.sh "$@"
  exit 0
fi

xmls=()
langs=()
for xml in "$@"; do
  xmls+=("$xml")
  echo "xml${#xmls[@]}: ${xml}"
  lang=$(expr "$xml" : '.*ted_\(.*\)-.*.xml')
  if [ "${lang}" ]; then
    langs+=("$lang")
    echo "lang${#langs[@]}: ${lang}"
  else
    echo "file name parse error: $xml"
    echo "each xml file name should be like \"ted_{langcode}-*.xml\"."
  fi
done

tuple=$(get_tuple "${langs[@]}")
echo "tuple code: ${tuple}"

show_exec mkdir -p ${workdir}
show_exec mkdir -p ${outdir}

echo "# Find the set of common talks between two languages:"
talkids=""
for (( i = 1; i < ${#langs[@]} ; i++ )); do
  src_xml=${xmls[0]}
  src_lang=${langs[0]}
  trg_xml=${xmls[$i]}
  trg_lang=${langs[$i]}
  outfile="${workdir}/talkid_${src_lang}-${trg_lang}.all"
  show_exec perl ${TOOLS}/find-common-talks.pl \
    --xml-file-l1 ${src_xml} \
    --xml-file-l2 ${trg_xml} \> ${outfile}
  check_exclude ${outfile} ${src_lang}
  check_exclude ${outfile} ${trg_lang}
  if [ "${talkids}" ]; then
    common=${workdir}/talkid_$(get_tuple ${langs[@]:0:$i+1}).all
    show_exec grep -x -f ${talkids} ${outfile} \> ${common}
    talkids=${common}
  else
    talkids=${outfile}
  fi
done

echo "# Select specific set of talks from the whole collection:"
for (( i = 0; i < ${#langs[@]}; i++ )); do
  xml=${xmls[$i]}
  lang=${langs[$i]}
  outfile=${workdir}/ted_${tuple}.${lang}.xml
  show_exec perl ${TOOLS}/filter-talks.pl \
    --talkids ${talkids} --xml-file ${xml} \> ${outfile}
done

echo "# Extract parallel sentences:"
joined=""
for (( i = 1; i < ${#langs[@]}; i++ )); do
  src_lang=${langs[0]}
  trg_lang=${langs[$i]}
  src_xml=${workdir}/ted_${tuple}.${src_lang}.xml
  trg_xml=${workdir}/ted_${tuple}.${trg_lang}.xml
  src_out=${workdir}/ted_${src_lang}-${trg_lang}.${src_lang}
  trg_out=${workdir}/ted_${src_lang}-${trg_lang}.${trg_lang}
  discarded=${workdir}/ted_${src_lang}-${trg_lang}.discarded
  filter=1.96
  show_exec perl ${TOOLS}/ted-extract-par.pl \
          --xmlsource ${src_xml} --xmltarget ${trg_xml} \
          --outsource ${src_out} --outtarget ${trg_out} \
          --outdiscarded ${discarded} --filter ${filter}
  src_fix=${workdir}/ted_${src_lang}-${trg_lang}.${src_lang}.fix
  trg_fix=${workdir}/ted_${src_lang}-${trg_lang}.${trg_lang}.fix
  show_exec cat ${src_out} \| ${dir}/fix.py \> ${src_fix}
  show_exec cat ${trg_out} \| ${dir}/fix.py \> ${trg_fix}
  show_exec ${dir}/rebuild-sent.py ${trg_fix} ${src_fix} .sent
  pasted=${workdir}/ted_${src_lang}-${trg_lang}.joined
  LC_ALL=C show_exec paste ${src_fix}.sent ${trg_fix}.sent \| nl \| sort -t "$'\t'" -k 2 \
    \| awk -F "$'\t'" '"\$2 != last && length(\$3) > 0 { print; last = \$2; }"' \> ${pasted}

  prev_joined=${joined}
  if [ ! "${joined}" ]; then
    joined=${pasted}
  else
    let n=${i}+1
    format="$(seq -s ' ' -f '1.%g' 1 $n) 2.3"
    joined=${workdir}/ted_$(get_tuple ${langs[@]:0:$i+1}).joined
    LC_ALL=C show_exec join -t "$'\t'" -j 2 -o "'${format}'" ${prev_joined} ${pasted} \> ${joined}
  fi
done

joined_sorted=${workdir}/ted_${tuple}.joined.sorted
LC_ALL=C show_exec sort -t "$'\t'" -k 1 ${joined} \> ${joined_sorted}

for (( i = 0; i < ${#langs[@]}; i++ )); do
  lang=${langs[$i]}
  outfile=${workdir}/ted_${tuple}.${lang}.sent
  let f=${i}+2
  show_exec cut -d "$'\t'" -f ${f} ${joined_sorted} \> ${outfile}
done

for (( i = 0; i < ${#langs[@]}; i++ )); do
  lang=${langs[$i]}
  show_exec mv ${workdir}/ted_${tuple}.${lang}.sent ${outdir}
done
show_exec mv ${joined_sorted} ${outdir}

show_exec rm -rf ${workdir}

