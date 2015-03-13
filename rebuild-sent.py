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

def readLines(inputFiles):
    lines = []
    for inputFile in inputFiles:
        lines.append( inputFile.readline() )
    return lines

def writeLines(outputFiles, lines, newLine = False):
    for i, outputFile in enumerate(outputFiles):
        outputFile.write( lines[i] )
        if newLine:
            outputFile.write("\n")
        else:
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
    while True:
        lines = readLines(inputFiles)
        if not any(lines):
            break
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

