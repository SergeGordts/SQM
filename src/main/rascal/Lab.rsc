// Uitwerking van de Rascal oefeningen met VSCode (inwerkopdracht) 
// Open Universiteit, november 2023

module Lab

import IO;
import List;
import Map;
import Set;
import String;
import analysis::graphs::Graph;
import lang::java::m3::Core;
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
import Metrics::Complexity;
import Metrics::Duplication;

//generation of text file

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
    map[str, real] unitSizePercentages = calculateUnitSizePercentages(methodSizes);
    reportContent += "unit sizes:\n";
    for (str r <- ["simple","moderate","high","veryHigh"]) {
        reportContent += "* <r>: <unitSizePercentages[r]>%\n";
    }

    map[str, int] complexityDist = calculateComplexityDistribution(cl);
    reportContent += "unit complexities:\n";
    for (str r <- ["simple","moderate","high","veryHigh"]) {
        real percentage = (complexityDist[r] * 100.0) / sum(methodSizes);
        reportContent += "* <r>: <percentage>%\n";
    }

    int amountOfDuplicatedLines = countDuplicatedLines(model);
    real duplicationFactor = (totalLines == 0) ? 0.0 : (amountOfDuplicatedLines * 100.0) / totalLines;
    reportContent += "duplication: <duplicationFactor>% (<amountOfDuplicatedLines> duplicated lines out of <totalLines>)\n";

    str volumeRank = calculateVolumeRank(totalLines);
    reportContent += "volume score: <volumeRank>\n";

    map[str, int] unitSizeDist = calculateUnitSizeDistribution(methodSizes);
    str unitSizeRank = calculateUnitsizeRank(unitSizeDist);
    reportContent += "unit size score: <unitSizeRank>\n";

    str complexityRank = calculateComplexityRank(complexityDist);
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
    println(calculateUnitSizeDistribution(methodSizes));
    println(calculateUnitSizePercentages(methodSizes));
}

public void runUnitCCMetrics(loc cl){
    println(calculateComplexityDistribution(cl));
}

public void runDuplicationCounter(loc cl){
    M3 model = createM3FromDirectory(cl);
    println(countDuplicatedLines(model));
}

//Todo: check met rubric

