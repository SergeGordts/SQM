module Metrics::Utility

import IO;
import List;
import String;

public list[str] getLinesOfMethod(loc m){
    return [
            l
            | str l <- readFileLines(m),
              !(/^\s*$/ := l),       // not blank
              !(/^\s*\/\// := l),    // not single-line comment //
              !(/^\s*\/\*/ := l),    // not start of block /*
              !(/^\s*\*/ := l),      // not middle of block *
              !(/^\s*\*\/$/ := l)    // not end of block */
    ];
}

str normalizeWhiteSpace(str s) {
    return visit(s) {
        case /\s+/ => " "
    };
}

list[str] trimmedLines(loc f) { 
    return [ trim(normalizeWhiteSpace(l)) | l <- readFileLines(f), 
    !(/^\s*$/ := l),     
    !(/^\s*\/\// := l),  
    !(/^\s*\/\*/ := l),  
    !(/^\s*\*/ := l),    
    !(/^\s*\*\/$/ := l) 
    ]; 
}