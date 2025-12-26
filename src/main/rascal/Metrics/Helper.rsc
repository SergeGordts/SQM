module Metrics::Helper

import IO;
import List;
import String;

// helper function
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