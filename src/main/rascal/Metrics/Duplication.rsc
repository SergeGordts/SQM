module Metrics::Duplication

import String;
import IO;
import lang::java::m3::Core;
import Relation;
import List;
import Metrics::Utility;

//Duplication: the percentage of all comment-free, normalized and leading spaces-free code that occurs more than once in equal code blocks of at least 6 lines
public int countDuplicatedLines(M3 model) {
    int duplicatedLinesCount = 0;
    map[str, list[tuple[loc, int]]] blocks = ();
    set[loc] javaFiles = files(model);

    // Map from block (6 lines) to a list of its physical locations <file, start_index> in the trimmed version
    for (loc f <- javaFiles) {
        list[str] lines = trimmedLines(f);
        int n = size(lines);

        if (n >= 6) {
            for (int i <- [0 .. n - 6]) {
                list[str] blockLines = lines[i .. i + 6];
                //preserving line structure by using intercalate from module List
                str block = intercalate("\n", blockLines);
                if (blocks[block]?) {
                    blocks[block] += [<f, i>];
                } else {
                    blocks[block] = [<f, i>];
                }
            }
        }
    }

    // Count duplicates, each block except the initial one counts as 6 lines.
       for (str blockKey <- blocks, size(blocks[blockKey]) > 1) {
       duplicatedLinesCount += (size(blocks[blockKey])-1) * 6;
    }
    return duplicatedLinesCount;
}