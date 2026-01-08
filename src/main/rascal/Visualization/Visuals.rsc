module Visualization::Visuals

import IO;
import List;
import Map;
import String;
import Set;
import lang::java::m3::Core;
import lang::java::m3::AST;
import vis::Charts;
import vis::Graphs;
import Content;
import lang::json::IO;
import util::Math;

import Metrics::Complexity;
import Metrics::UnitSize;
import Metrics::Utility;
import Metrics::Duplication;

// Fine grained view of methods
str riskClassCC(int cc) {
    if (cc <= 10) return "simple";
    if (cc <= 20) return "moderate";
    if (cc <= 50) return "high";
    return "veryHigh";
}

//helper functions
// Mapping Risk to Hex Colors
str riskColor(str risk) {
    switch (risk) {
        case "simple":   return "#4CAF50";   // green
        case "moderate": return "#FFC107";   // yellow
        case "high":     return "#FF9800";   // orange
        case "veryHigh": return "#F44336";   // red
        default:         return "#9E9E9E";   // grey
    }
}

int countLOC(loc f) {
    list[str] lines = readFileLines(f);
    
    return size([ l | str l <- lines, 
        !(/^\s*$/ := l),             // not blank
        !(/^\s*\/\// := l),         // not single line comment //
        !(/^\s*\/\*/ := l),         // not start of block /*
        !(/^\s*\* / := l),          // not middle of block
        !(/^\s*\*\/$/ := l)         // not end of block
    ]);
}

// creating treemap-Data for all methods
public list[map[str, value]] getMethodData(loc cl) {
    M3 model = createM3FromDirectory(cl);
    set[Declaration] asts = createAstsFromDirectory(cl, true);
    
    list[map[str, value]] results = [];

    visit (asts) {
        case Declaration d: {
            if (d is \method || d is \constructor || d is \initializer) {
                // Calculate CC and LOC using existing logic
                int cc = approxCyclomatic(d); 
                str risk = riskClassCC(cc);
                int locSize = countLOC(d.src);

                // Create the data point for the treemap
                results += (
                    "label": d.src.path ,
                    "value": locSize,                  
                    "cc": cc,                          
                    "backgroundColor": riskColor(risk) 
                );
            }
        }
    }
    return results;
}

void exportMethodData(loc cl) {
    str projectName = cl.file;
    loc jsonFile = cl + "<methods.json>";
    list[map[str,value]] inputMethodGraphic = getMethodData(cl);
    str jsonData = asJSON(inputMethodGraphic);
    writeFile(jsonFile, jsonData);
}

//erna lokale server opstarten vanop de plaats waar de json staat met  "python -m http.server"
//html copiëren op de plaats van het systeem openen met http://localhost:8000/

// Helper function
private bool isCode(str line) {
    return !(/^\s*$/ := line)      // Not empty
        && !(/^\s*\/\// := line)   // Not single line comment
        && !(/^\s*\/\*/ := line)   // Not start of block comment
        && !(/^\s*\*/ := line)     // Not middle of block comment
        && !(/^\s*\*\/$/ := line); // Not end of block comment
}

// Coarse grained view of LOC per file
public map[loc, int] regelsPerBestand(M3 model) {
    set[loc] javaFiles = files(model);
    map[loc, int] counts = ( l : size([line | line <- readFileLines(l), isCode(line)]) | l <- javaFiles );
    
    // validity check: Calculate the total by summing all values in the map
    int totalLines = (0 | it + counts[l] | l <- counts);
    println("Total lines of code: <totalLines>");
    return counts;
}

public bool aflopend(tuple[&a, num] x, tuple[&a, num] y) {
return x[1] > y[1];
}

public Content visualizeVolume(loc cl) {
    M3 model = createM3FromDirectory(cl);
    
    rel[str, int] regels = { <l.file, a> | <l, a> <- toRel(regelsPerBestand(model)) };
    
    return barChart(sort(regels, bool(tuple[str, int] a, tuple[str, int] b) { 
        return a[1] > b[1]; 
    }), title="Regels per Javabestand");
}

str duplicationClassOfFile(int dup) {
    if (dup < 15)  return "lowVolume";
    if (dup < 80) return "mediumVolume";
    return "highVolume";
}

public Content visualizeDuplication(loc cl) {
    M3 model = createM3FromDirectory(cl);
    rel[str, int, str] edges =
        calculateIntraFileDuplication(model);

    map[str,int] totalDupPerFile = ();
    set[str] files = { from | <from,_,_> <- edges } + { to | <_,_,to> <- edges };

    for (str f <- files) {
        int total = sum([ dup | <from, dup, to> <- edges, from == f || to == f ]);
        totalDupPerFile[f] = total;
    }

    list[str] fileClassifier(str f) {
        int total = sum([dup | <from, dup, to> <- edges, from == f || to == f]);
        return [duplicationClassOfFile(total)];
    }

    list[CytoStyleOf] nodeStyles = [
    cytoStyleOf(
        selector = \node(className("lowVolume")),
        style    = defaultNodeStyle()
        [width = "30"]
        [\background-color = "#9E9E9E"]
    ),
    cytoStyleOf(
        selector = \node(className("mediumVolume")),
        style    = defaultNodeStyle()
        [width = "60"]
        [\background-color = "#FF9800"]
    ),
    cytoStyleOf(
        selector = \node(className("highVolume")),
        style    = defaultNodeStyle()
        [width = "90"]
        [\background-color = "#F44336"]
    )];

     list[CytoStyleOf] edgeStyles = [
    cytoStyleOf(
        selector = edge(less("label", 15)),
        style    = defaultEdgeStyle()
        [color = "#FFFFFF"]
        [\line-color = "#9E9E9E"]
    ),
    cytoStyleOf(
        selector = edge(and([greater("label", 15), less("label", 50)])),
        style    = defaultEdgeStyle()
        [color = "#FFFFFF"]
        [\line-color = "#FF9800"]
    ),
    cytoStyleOf(
        selector = edge(greater("label", 50)),
        style    = defaultEdgeStyle()
        [color = "#FFFFFF"]
        [\line-color = "#F44336"]
    )];
    
    list[CytoStyleOf] styles = nodeStyles + edgeStyles;

    return graph(
        edges,
        cfg = cytoGraphConfig(
            title          = "Code duplication between files",
            nodeClassifier = fileClassifier,
            styles  = styles,
            \layout        = defaultCoseLayout()
        )
    );
}