#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import re

replaceList = []
replaceList.append(['（', '('])
replaceList.append(['）', ')'])
replaceList.append(['　', ' '])
replaceList.append(['\([^\)]*\)', ''])
replaceList.append(['<[^>]*>', ''])

suffixList = []
suffixList.append('ありがとう')
suffixList.append('いね')
suffixList.append('ください')
suffixList.append('しまった')
suffixList.append('しょう')
suffixList.append('しょうか')
suffixList.append('ですね')
suffixList.append('でした')
suffixList.append('です')
suffixList.append('ました')
suffixList.append('ましたね')
suffixList.append('ましたよ')
suffixList.append('ます')
suffixList.append('ますよ')
suffixList.append('ません')
suffixList.append('よね')

for line in sys.stdin:
    line = line.strip()
    for match, replace in replaceList:
        line = re.sub(match, replace, line)
    line = line.strip()
    for suffix in suffixList:
        if line.endswith(suffix):
            print(line+"。")
            break
    else:
            print(line)

