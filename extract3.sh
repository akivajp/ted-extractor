#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source ${dir}/common.sh

if [ $# -lt 3 ]; then
  echo "usage: $0 xml1 xml2 xml3"
  exit 1
fi

xml1=$1
xml2=$2
xml3=$3
echo "xml1: $xml1"
echo "xml2: $xml2"
echo "xml2: $xml3"

lang1=$(expr $xml1 : '.*ted_\(.*\)-')
lang2=$(expr $xml2 : '.*ted_\(.*\)-')
lang3=$(expr $xml3 : '.*ted_\(.*\)-')
echo "lang1: $lang1"
echo "lang2: $lang2"
echo "lang3: $lang3"

workdir=working_dir
outdir=output

show_exec mkdir -p ${workdir}
show_exec mkdir -p ${outdir}

echo "# Find the set of common talks between two languages:"
show_exec perl ${TOOLS}/find-common-talks.pl \
  --xml-file-l1 ${xml1} \
  --xml-file-l2 ${xml2} \> ${workdir}/talkid_${lang1}-${lang2}.all
show_exec perl ${TOOLS}/find-common-talks.pl \
  --xml-file-l1 ${xml1} \
  --xml-file-l2 ${xml3} \> ${workdir}/talkid_${lang1}-${lang3}.all
show_exec grep -x -f ${workdir}/talkid_${lang1}-{$lang2,$lang3}.all \
  \> ${workdir}/talkid_${lang1}-${lang2}-${lang3}.all
check_exclude ${workdir}/talkid_${lang1}-${lang2}-${lang3}.all ${lang1}
check_exclude ${workdir}/talkid_${lang1}-${lang2}-${lang3}.all ${lang2}
check_exclude ${workdir}/talkid_${lang1}-${lang2}-${lang3}.all ${lang3}

echo "# Select specific set of talks from the whole collection:"
show_exec perl ${TOOLS}/filter-talks.pl \
  --talkids ${workdir}/talkid_${lang1}-${lang2}-${lang3}.all \
  --xml-file ${xml1} \> ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang1}.xml
show_exec perl ${TOOLS}/filter-talks.pl \
  --talkids ${workdir}/talkid_${lang1}-${lang2}-${lang3}.all \
  --xml-file ${xml2} \> ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang2}.xml
show_exec perl ${TOOLS}/filter-talks.pl \
  --talkids ${workdir}/talkid_${lang1}-${lang2}-${lang3}.all \
  --xml-file ${xml3} \> ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang3}.xml

#echo "# Extract parallel sentences:"
show_exec perl ${TOOLS}/ted-extract-par.pl \
        --xmlsource ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang1}.xml \
        --xmltarget ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang2}.xml \
        --outsource ${workdir}/ted_${lang1}-${lang2}.${lang1} \
        --outtarget ${workdir}/ted_${lang1}-${lang2}.${lang2} \
        --outdiscarded ${workdir}/ted_${lang1}-${lang2}.discarded \
        --filter 1.96
show_exec perl ${TOOLS}/ted-extract-par.pl \
        --xmlsource ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang1}.xml \
        --xmltarget ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang3}.xml \
        --outsource ${workdir}/ted_${lang1}-${lang3}.${lang1} \
        --outtarget ${workdir}/ted_${lang1}-${lang3}.${lang3} \
        --outdiscarded ${workdir}/ted_${lang1}-${lang3}.discarded \
        --filter 1.96

show_exec cat ${workdir}/ted_${lang1}-${lang2}.${lang1} \| ${dir}/fix.py \> ${workdir}/ted_${lang1}-${lang2}.${lang1}.fix
show_exec cat ${workdir}/ted_${lang1}-${lang2}.${lang2} \| ${dir}/fix.py \> ${workdir}/ted_${lang1}-${lang2}.${lang2}.fix
show_exec cat ${workdir}/ted_${lang1}-${lang3}.${lang1} \| ${dir}/fix.py \> ${workdir}/ted_${lang1}-${lang3}.${lang1}.fix
show_exec cat ${workdir}/ted_${lang1}-${lang3}.${lang3} \| ${dir}/fix.py \> ${workdir}/ted_${lang1}-${lang3}.${lang3}.fix

show_exec ${dir}/rebuild-sent.py \
  ${workdir}/ted_${lang1}-${lang2}.${lang2}.fix \
  ${workdir}/ted_${lang1}-${lang2}.${lang1}.fix .sent
show_exec ${dir}/rebuild-sent.py \
  ${workdir}/ted_${lang1}-${lang3}.${lang3}.fix \
  ${workdir}/ted_${lang1}-${lang3}.${lang1}.fix .sent

seq 1 $(get_num_lines ${workdir}/ted_${lang1}-${lang2}.${lang1}.fix.sent) > ${workdir}/ted_${lang1}-${lang2}.numbers
seq 1 $(get_num_lines ${workdir}/ted_${lang1}-${lang3}.${lang1}.fix.sent) > ${workdir}/ted_${lang1}-${lang3}.numbers
LC_ALL=C show_exec paste ${workdir}/ted_${lang1}-${lang2}.${lang1}.fix.sent \
  ${workdir}/ted_${lang1}-${lang2}.${lang2}.fix.sent \
  ${workdir}/ted_${lang1}-${lang2}.numbers \
  \| sed -e '"s/\t/ ||| /g"' \| sort \> ${workdir}/ted_${lang1}-${lang2}.joined.sorted
LC_ALL=C show_exec paste ${workdir}/ted_${lang1}-${lang3}.${lang1}.fix.sent \
  ${workdir}/ted_${lang1}-${lang3}.${lang3}.fix.sent \
  ${workdir}/ted_${lang1}-${lang3}.numbers \
  \| sed -e '"s/\t/ ||| /g"' \| sort \> ${workdir}/ted_${lang1}-${lang3}.joined.sorted

show_exec ${dir}/extract-multi.py \
  ${workdir}/ted_${lang1}-${lang2}.joined.sorted \
  ${workdir}/ted_${lang1}-${lang3}.joined.sorted \
  ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang1}.sent \
  ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang2}.sent \
  ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang3}.sent

show_exec mv ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang1}.sent ${outdir}
show_exec mv ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang2}.sent ${outdir}
show_exec mv ${workdir}/ted_${lang1}-${lang2}-${lang3}.${lang3}.sent ${outdir}

show_exec rm -rf ${workdir}

