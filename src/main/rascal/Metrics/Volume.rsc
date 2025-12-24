module Metrics::Volume

import IO;
import List;
import lang::java::m3::Core;

// 1 --> volume: Lines of code, skip blank lines and comments
public int calculateVolume(M3 model) {
    set[loc] javaFiles = files(model);
    int totalLines = 0;
    
    for (loc f <- javaFiles) {
        list[str] lines = readFileLines(f);
        
        int codeLines = size([ l | str l <- lines, 
                           !(/^\s*$/ := l), //not blank
                           !(/^\s*\/\// := l), //not single line comment //
                           !(/^\s*\/\*/ := l), //not start of block /*
                           !(/^\s*\*/ := l),   //not middle of block 
                           !(/^\s*\*\/$/ := l) //not end of block
                     ]);

        totalLines += codeLines;
    }
    return totalLines;
}