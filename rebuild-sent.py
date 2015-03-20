#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse

punctList = []
punctList.append('.')
punctList.append('."')
punctList.append('!')
punctList.append('!"')
punctList.append('?')
punctList.append('?"')
punctList.append('．')
punctList.append('。')
punctList.append('！')
punctList.append('？')

def writeLines(outputFiles, lines, newLine = False):
    for i, outputFile in enumerate(outputFiles):
        line = lines[i]
        shouldWrite = bool(line) and (line not in punctList)
        if shouldWrite:
            outputFile.write( line )
        if newLine:
            outputFile.write("\n")
        else:
            if shouldWrite:
                outputFile.write(" ")

def main():
    parser = argparse.ArgumentParser(description="re-build sentences by strong punctuation")
    parser.add_argument('inputPathList', metavar='input_file', nargs='+', help='aligned corpus text')
    parser.add_argument('suffix', help='output suffix')
    args = parser.parse_args()
    inputFiles = []
    for path in args.inputPathList:
        inputFiles.append( open(path, 'r') )
    outputFiles = []
    for path in args.inputPathList:
        outputFiles.append( open(path+args.suffix, 'w') )
    for lines in zip(*inputFiles):
        lines = list(lines)
        for i, line in enumerate(lines):
            lines[i] = line.strip()
        for punct in punctList:
            if lines[-1].endswith(punct):
                writeLines(outputFiles, lines, True)
                break
        else:
            writeLines(outputFiles, lines)

if __name__ == '__main__':
    main()

