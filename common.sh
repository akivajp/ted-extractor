#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
stamp=$(date +"%Y/%m/%d %H:%M:%S")
source ${dir}/config.sh

show_exec()
{
#  echo "[exec ${stamp} on ${HOST}] $*" | tee -a ${LOG}
  echo "[exec ${stamp} on ${HOST}] $@" | tee -a ${LOG}
#  eval $*
  eval "$@"

  if [ $? -gt 0 ]
  then
    local red=31
#    local msg="[error ${stamp} on ${HOST}]: $*"
    local msg="[error ${stamp} on ${HOST}]: $@"
    echo -e "\033[${red}m${msg}\033[m" | tee -a ${LOG}
    exit 1
  fi
}

abspath()
{
  echo $(cd $(dirname $1) && pwd)/$(basename $1)
}

check_exclude()
{
  local file=$1
  local lang=$2
  if [ -f ${dir}/files/exclude_id.${lang} ]; then
    show_exec mv ${file} ${file}.orig
    show_exec grep -xv -f ${dir}/files/exclude_id.${lang} ${file}.orig \> ${file}
    show_exec rm ${file}.orig
  fi
}

get_num_lines()
{
  local file=$1
  wc -l $file | cut -f1 -d' '
}

if [ -d "${TOOLS}" ]; then
  echo "[OK] tools directory \"${TOOLS}\" is found."
  echo ""
elif [ -d "${dir}/${TOOLS}" ]; then
  TOOLS=$(abspath ${dir}/${TOOLS})
  echo "[OK] tools directory \"${TOOLS}\" is found."
  echo ""
else
  echo "[NG] tools directory \"${TOOLS}\" is not found."
  echo "please download WIT3 tools from: "
  echo "  https://wit3.fbk.eu/"
  echo "and set TOOLS variable in \"config.sh\""
  echo "  as a path of expanded archive"
  echo ""
  exit 1
fi

get_tuple()
{
  echo $@ | sed -e 's/ /-/g'
}

