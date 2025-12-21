// Uitwerking van de Rascal oefeningen met VSCode (inwerkopdracht) 
// Open Universiteit, november 2023

module Lab

import IO;
import List;
import Map;
import Relation;
import Set;
import String;
import analysis::graphs::Graph;
import lang::java::m3::Core;
import lang::java::m3::AST;
import vis::Charts;
import vis::Graphs;
import Content;
import Scoring::Volume;
import Scoring::UnitSize;
import Scoring::Complexity;

// 1 --> volume: Lines of code, skip blank lines and comments

public int linesOfCode(loc cl, M3 model) {
    set[loc] javaFiles = files(model);
    int totalLines = 0;
    
    for (loc f <- javaFiles) {
        list[str] lines = readFileLines(f);
        
        int codeLines = size({ l | str l <- lines, 
                           !(/^\s*$/ := l), //not blank
                           !(/^\s*\/\// := l), //noy single line comment //
                           !(/^\s*\/\*/ := l), //not start of block /*
                           !(/^\s*\*/ := l),   //not middle of block 
                           !(/^\s*\*\/$/ := l) //not end of block
                     });

        totalLines += codeLines;
    }
    return totalLines;
}

// 2 ---> number of units (a unit in java is a method)
public str numberOfUnits(loc cl, M3 model) {
   list[loc] allMethods = [l | l <- methods(model)];
   int totalUnits = size(allMethods);
   str output = "number of units: <totalUnits>\n";
   return output;
}

// 3 --> unit size: The article "Deriving Metric Thresholds from Benchmark Data" by Visser et al
// discusses a method that determines metric thresholds empirically from measurement data.
// Table IV in this article shows the empirically derived Thresholds for Unit Size for Java and other OO systems.
// The thresholds are based on benchmarked quantiles of the distribution of unit size (LOC per method). 
// The authors use the 70th, 80th, and 90th percentiles as thresholds that capture meaningful variation while weighting by code volume across many systems.
// | Metric                       | 70%    | 80%    | 90%    |
// Unit size (LOC per unit)       | 30     | 44     | 74     |
// so Simple is ≤ 30, Moderate > 30 and ≤ 44, High > 44 and ≤ 74 and Very high > 74                                 

//they pool measurement data across many systems (100 projects), aggregates relative size weighting (LOC) so larger units contribute proportionally,
//chooses quantiles (70%, 80%, 90%) that emphasize meaningful code volume splits, and rounds values to practical integer thresholds. 

public tuple[str, tuple[int, int, int]] unitSizeDistribution(loc cl, M3 model) {
    list[loc] allMethods = [l | l <- methods(model)];
    list[int] methodSizes = [size(readFileLines(m)) | m <- allMethods];

    int simple = 0;
    int moderate = 0;
    int high = 0;
    int veryHigh = 0;

    for (int lSize <- methodSizes) { 
        if (lSize <= 30) {
            simple += lSize;
        } else if (lSize <= 44) {
            moderate += lSize;
        } else if (lSize <= 74) {
            high += lSize;
        } else {
            veryHigh += lSize;
        }
    } 

    int totalLOC = sum(methodSizes);

    if (totalLOC > 0) {
        str output = "unit size: \n";
        output += " simple: <100.0 * simple / totalLOC>% \n";
        output += " moderate: <100.0 * moderate / totalLOC>% \n";
        output += " high: <100.0 * high / totalLOC>% \n";
        output += " very high: <100.0 * veryHigh / totalLOC>% \n";
        
        return <output, <moderate, high, veryHigh>>; 
    }
}

// 4 --> cyclomatic complexity of each unit: 1-10 is simple, 11-20 more complex, moderate risk, 
// 21-50 complex, high risk, > 50 untestable, very high risk

str riskClass(int cc) {
    if (cc <= 10) return "simple";
    if (cc <= 20) return "moderate";
    if (cc <= 50) return "high";
    return "very high";
}

// Approximate McCabe CC by counting decision points in method source
int approxCyclomatic(Declaration methodAST) {
    int cc = 1; 
    
    visit (methodAST) {
        case \if(_, _): cc += 1;
        case \if(_, _, _): cc += 1;
        case \conditional(_, _, _): cc += 1;
        case \while(_, _): cc += 1;
        case \do(_, _): cc += 1;
        case \for(_, _, _, _): cc += 1;
        case \for(_, _, _): cc += 1;
        case \foreach(_, _, _): cc += 1;
        case \case(_): cc += 1;
        case \catch(_, _): cc += 1;
        case \infix(_, "&&", _): cc += 1;
        case \infix(_, "||", _): cc += 1;
    }
    return cc;
}

public tuple[map[str, int], int] unitCCMetrics(loc cl) {
    set[Declaration] asts = createAstsFromDirectory(cl, true);

    map[str, int] complexitySum = ("simple": 0, "moderate": 0, "high": 0, "very high": 0);
    int totalComplexity = 0;

    visit (asts) {
        case Declaration d: {
            // Check if this declaration is a method or constructor
            if (d is \method || d is \constructor) {
                int cc = approxCyclomatic(d);
                str r = riskClass(cc);
                
                complexitySum[r] += cc;
                totalComplexity += cc;
            }
        }
    }

    str output = "unit complexity:\n";
    for (str r <- ["simple","moderate","high","very high"]) {
        real p = totalComplexity == 0 ? 0.0 : (complexitySum[r] * 100.0 / totalComplexity);
        output += "* <r>: <p>%\n";
    }
    return <complexitySum, totalComplexity>;  
}

//5 --> Duplication: the percentage of all code that occurs more than once in equal code blocks of at least 6 lines.
// Apart from removing leading spaces, the duplication we measure is an exact string matching duplication

list[str] trimmedLines(loc f) {
    return [ trim(l) | l <- readFileLines(f), trim(l) != "" ];
}

public str duplicationCounter(loc cl, M3 model) {
    set[loc] javaFiles = files(model);

    int totalLines = 0;
    set[str] duplicatedLines = {};
    // Map from block (6 lines joined) to all its occurrences (location and starting index)
    map[str, list[tuple[loc,int]]] blocks = ();

    // Collect blocks consisting of 6 lines
    for (loc f <- javaFiles) {
        //reads the trimmedlines and adds them to the lines list accessed by index
        list[str] lines = trimmedLines(f);
        totalLines += size(lines);

        //sliding window that reads 6 lines and turns them into a block
        for (int i <- [0 .. size(lines) - 6]) {
            list[str] blockLines = lines[i .. i + 6];

            str block = "";
            for (str l <- blockLines) {
                //"\n" preserves the lines
                block += l + "\n";
            }

            //map where the string of the block is the index to a list (not unique) of location and index tuples
            //so if the string appears twice, it will show twice in the map
            blocks[block] ?= [];
            blocks[block] += <f, i>;
        }
    }

    // Identify duplicated blocks
    for (str block <- blocks) {
        if (size(blocks[block]) > 1) {
            list[str] lines = split(block, "\n");
            //toSet keeps unique lines that appear in duplicated blocks
            duplicatedLines += toSet(lines);
        }
    }

    // Compute percentage
    int duplicatedLineCount = size(duplicatedLines);
    real percentage =
        (totalLines == 0)
        ? 0.0
        : (duplicatedLineCount * 100.0) / totalLines;

   str output = "duplication: <percentage>%\n";
   return output;
}

//6 --> generation of text file

public void generateQualityReport(loc cl, M3 model) {
    str projectName = cl.file;
    
    loc reportFile = cl + "report_<projectName>.txt";
    
    str reportContent = "Software Quality Report for: <projectName>\n";
    reportContent += "==========================================\n\n";
    
    int totalLines = linesOfCode(cl, model);
    reportContent += "lines of code: <totalLines>\n";
    reportContent += numberOfUnits(cl, model) + "\n";
    tuple[str output, tuple[int,int,int] distribution] unitSize = unitSizeDistribution(cl, model);
    reportContent += unitSize.output;
    tuple[map[str, int] distribution, int totalComplexity] complexity = unitCCMetrics(cl);
    reportContent += "unit complexity:\n";
    for (str r <- ["simple","moderate","high","very high"]) {
        real p = complexity.totalComplexity == 0 ? 0.0 : (complexity.distribution[r] * 100.0 / complexity.totalComplexity );
        reportContent += "* <r>: <p>%\n";
    }
    reportContent += duplicationCounter(cl, model) + "\n";
    reportContent += "volume score: <calculateVolumeRank(totalLines)>\n";
    reportContent += "unit size score: <calculateUnitsizeRank(unitSize.distribution)>\n";
    reportContent += "complexity score: <calculateComplexityRank(<complexity.distribution["moderate"], complexity.distribution["high"], complexity.distribution["very high"]>)>\n";
    writeFile(reportFile, reportContent);
    
    println("Report generated successfully at: <reportFile>");
}

//shortcut om smallsql te runnen 
public void runProject1(){
    loc project = |file:///SmallSql/|;
    M3 model = createM3FromDirectory(project);
    generateQualityReport(project, model);
}

public void runlinesOfCode(){
    loc project = |file:///SmallSql/|;
    M3 model = createM3FromDirectory(project);
    println(linesOfCode(project, model));
}

//aanroepen in terminal met
//    loc project = |file:///smallsql/|;
//    loc project2 = |file:///hsqldb/|;
//    M3 model = createM3FromDirectory(project);
//    linesOfCode(project, model);
//    numberOfUnits(project, model);

//Todo: check met rubric & check met uitleg gegeven tijdens de online les

// --------------------------------------------------------------------------
// visualisatie voor later

public Content visualizeA(loc cl, M3 model) {
   rel[str, num] regels = { <l.file, a> | <l,a> <- toRel(regelsPerBestand(model)) };
   return barChart(sort(regels, aflopend), title="Regels per Javabestand");
}

public Content visualizeB() {
   return graph(gebruikt,title="Componenten", \layout=defaultGridLayout(rows=2,cols=3));
}