#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source ${dir}/common.sh

if [ $# -lt 1 ]; then
  echo "usage: $0 xmlfile"
  exit 1
fi

xml=$1
echo "xml: $xml"

lang=$(expr $xml : '.*ted_\(.*\)-')
echo "lang: $lang"

workdir=working_dir
outdir=output

show_exec mkdir -p ${workdir}
show_exec mkdir -p ${outdir}

echo "# Find the id set of talks"
show_exec perl ${TOOLS}/find-talks.pl \
  --xml-file ${xml} \> ${workdir}/talkid_${lang}.all
check_exclude ${workdir}/talkid_${lang}.all ${lang}

show_exec perl ${TOOLS}/filter-talks.pl \
  --talkids ${workdir}/talkid_${lang}.all \
  --xml-file ${xml} \> ${workdir}/ted_${lang}.xml

echo "# Extract monolingual text:"
show_exec perl ${TOOLS}/ted-extract-mono.pl \
        --xml ${workdir}/ted_${lang}.xml \
        --out ${workdir}/ted_${lang}

show_exec cat ${workdir}/ted_${lang} \| ${dir}/fix.py \> ${workdir}/ted_${lang}.fix
show_exec ${dir}/rebuild-sent.py ${workdir}/ted_${lang}.fix .sent

show_exec mv ${workdir}/ted_${lang}.fix.sent ${outdir}/ted_${lang}.sent

show_exec rm -rf ${workdir}

