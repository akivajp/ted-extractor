#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="build multi-lingual parallel corpus from 2 parallel corpus")
    parser.add_argument('joined_corpus1', help="lang1-lang2 paralell corpus (joined with ' ||| ', must be sorted)")
    parser.add_argument('joined_corpus2', help="lang1-lang3 paralell corpus (joined with ' ||| ', must be sorted)")
    parser.add_argument('output1', help='lang1 aligned corpus')
    parser.add_argument('output2', help='lang2 aligned corpus')
    parser.add_argument('output3', help='lang3 aligned corpus')
    args = parser.parse_args()

    fileIn1 = open(args.joined_corpus1, 'r')
    fileIn2 = open(args.joined_corpus2, 'r')
    fileOut1 = open(args.output1, 'w')
    fileOut2 = open(args.output2, 'w')
    fileOut3 = open(args.output3, 'w')
    alignedLines = dict()
    while True:
        line1 = fileIn1.readline()
        line2 = fileIn2.readline()
        if not all( [line1, line2] ):
            break
        fields1 = line1.strip().split(' ||| ')
        fields2 = line2.strip().split(' ||| ')
        if fields1[0] == fields2[0]:
            try:
                lineNumber = int(fields1[2])
                lines = (fields1[0].strip(), fields1[1].strip(), fields2[1].strip())
                alignedLines[lineNumber] = lines
            except Exception as e:
                print(e)
        else:
            if line1 < line2:
                line1 = fileIn1.readline()
            else:
                line2 = fileIn2.readline()
    for _, lines in sorted(alignedLines.items()):
        try:
            fileOut1.write(lines[0] + "\n")
            fileOut2.write(lines[1] + "\n")
            fileOut3.write(lines[2] + "\n")
        except Exception as e:
            print(e)

if __name__ == '__main__':
    main()

