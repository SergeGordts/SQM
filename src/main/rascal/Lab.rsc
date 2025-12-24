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
import Scoring::Duplication;
import Scoring::MaintainabilityRanks;
import Metrics::Volume;
import Metrics::UnitSize;

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

public tuple[map[str, int], int] unitCCMetrics(loc cl, M3 model) {
    set[Declaration] asts = createAstsFromDirectory(cl, true);

    map[str, int] complexitySum = ("simple": 0, "moderate": 0, "high": 0, "very high": 0);
    int totalComplexity = 0;

    visit (asts) {
        case Declaration d: {
            // Check if this declaration is a method/constructor/initializer
            if (d is \method || d is \constructor || d is \initializer ) {
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

//5 --> Duplication: the percentage of all comment-free, normalized and leading spaces-free code that occurs more than once in equal code blocks of at least 6 lines
public str duplicationCounter(loc cl, M3 model) {
    int totalLines = 0;
    int duplicatedLinesCount = 0;
    map[str, list[tuple[loc, int]]] blocks = ();
    set[loc] javaFiles = files(model);

    // Map from block (6 lines) to a list of its physical locations <file, start_index> in the trimmed version
    for (loc f <- javaFiles) {
        list[str] lines = trimmedLines(f);
        int n = size(lines);
        totalLines += n;

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
    real percentage = (totalLines == 0) ? 0.0 : (duplicatedLinesCount * 100.0) / totalLines;
    return "duplication: <percentage>% (<duplicatedLinesCount> duplicated lines out of <totalLines>)\n";
}

//6 --> generation of text file

public void generateQualityReport(loc cl, M3 model) {
    str projectName = cl.file;
    
    loc reportFile = cl + "report_<projectName>.txt";
    
    str reportContent = "Software Quality Report for: <projectName>\n";
    reportContent += "==========================================\n\n";
    
    int totalLines = calculateVolume(model);
    reportContent += "lines of code: <totalLines>\n";

    int numberOfUnits = calculateNumberOfUnits(model);
    reportContent += "number of units: <numberOfUnits>\n";

    list[int] methodSizes = calculateMethodSizes(model);
    map[str, real] unitSizePercentages = unitSizePercentages(methodSizes);
    reportContent += "unit sizes:\n";
    for (str r <- ["simple","moderate","high","very high"]) {
        output += "* <r>: <unitSizePercentages[r]>%\n";
    }

    reportContent += unitCCMetrics(cl, model) + "\n";
    reportContent += duplicationCounter(cl, model) + "\n";

    str volumeRank = calculateVolumeRank(totalLines);
    reportContent += "volume score: <volumeRank>\n";

    map[str, int] unitSizeDist = unitSizeDistribution(methodSizes);
    str unitSizeRank = calculateUnitsizeRank(unitSizeDist);
    reportContent += "unit size score: <unitSizeRank>\n";

    str complexityRank = calculateComplexityRank(<complexity.distribution["moderate"], complexity.distribution["high"], complexity.distribution["very high"]>);
    reportContent += "unit complexity score: <complexityRank>\n";
    str duplicationRank = calculateDuplicationRank(duplicationFactor);
    reportContent += "duplication score: <duplicationRank>\n";

    str analysabilityRank = calculateAnalysabilityRank([volumeRank, unitSizeRank, duplicationRank]);
    reportContent += "analysability score: <analysabilityRank>\n";
    str changeabilityRank = calculateChangeabilityRank([complexityRank, duplicationRank]);
    reportContent += "changeability score: <changeabilityRank>\n";
    str testabilityRank = calculateTestabilityRank([complexityRank, unitSizeRank]);
    reportContent += "testability score: <testabilityRank>\n";
    reportContent += "mainainability score: <calculateMaintainabilityRank()>\n";
    writeFile(reportFile, reportContent);
    
    println("Report generated successfully at: <reportFile>");
}

//shortcut om smallsql te runnen 
public void runProjectSmallSql(){
    loc project = |file:///SmallSql/|;
    M3 model = createM3FromDirectory(project);
    generateQualityReport(project, model);
}

public void runProjectHyperSql(){
    loc project = |file:///Hsqldb/|;
    M3 model = createM3FromDirectory(project);
    generateQualityReport(project, model);
}
public void runlinesOfCode(loc cl){
    M3 model = createM3FromDirectory(cl);
    println(calculateVolume(model));
}

public void runNumberOfUnits(loc cl){
    M3 model = createM3FromDirectory(cl);
    list[int] methodSizes = calculateMethodSizes(model);
    println(calculateNumberOfUnits(model));
    println(unitSizeDistribution(methodSizes));
    println(unitSizePercentages(methodSizes));
}

public void runUnitCCMetrics(loc cl){
    M3 model = createM3FromDirectory(cl);
    println(unitCCMetrics(project, model));
}

public void runDuplicationCounter(loc cl){
    M3 model = createM3FromDirectory(cl);
    println(duplicationCounter(project, model));
}

//Todo: check met rubric

