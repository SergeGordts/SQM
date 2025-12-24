module Metrics::Utility

import IO;
import List;

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