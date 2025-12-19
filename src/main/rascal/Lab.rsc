// Uitwerking van de Rascal oefeningen met VSCode (inwerkopdracht) 
// Open Universiteit, november 2023

module Lab

import IO;
import List;
import Map;
import Relation;
import Set;
import analysis::graphs::Graph;
import lang::java::m3::Core;
import lang::java::m3::AST;
import vis::Charts;
import vis::Graphs;
import Content;

// volume: Lines of code

public void linesOfCode(loc cl, M3 model) {
   set[loc] javaFiles = files(model);
   int totalLines = 0;
   for (loc f <- javaFiles) {
        totalLines += size(readFileLines(f));
        }
    println("SmallSQL");
    println("---------");
    println("lines of code: <totalLines>");
}

// number of units (a unit in java is a method)
public void numberOfUnits(loc cl, M3 model) {
   list[loc] allMethods = [l | l <- methods(model)];
   int totalUnits = size(allMethods);

   println("SmallSQL");
   println("---------");
   println("Number of units (methods): <totalUnits>");
}

// unit size: from "Deriving Metric Thresholds from Benchmark Data" by Visser et al
// This article discusses a method that determines metric thresholds empirically from measurement data.
// Table IV in this article shows the empirically derived Thresholds for Unit Size (Java and other OO systems)
// The thresholds are based on benchmarked quantiles of the distribution of unit size (LOC per method). The authors use the 70th, 80th, and 90th percentiles as thresholds that capture meaningful variation while weighting by code volume across many systems.
// | Metric                       | 70%    | 80%    | 90%    |
// Unit size (LOC per unit)       | 30     | 44     | 74     |
// so Simple is ≤ 30, Moderate > 30 and ≤ 44, High > 44 and ≤ 74 and Very high > 74                                 

//they pool measurement data across many systems (100 projects), aggregates relative size weighting (LOC) so larger units contribute proportionally,
//chooses quantiles (70%, 80%, 90%) that emphasize meaningful code volume splits, and rounds values to practical integer thresholds. 

public void unitSizeDistribution(loc cl, M3 model) {
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
        println("unit size:");
        println("* simple: <100.0 * simple / totalLOC>%");
        println("* moderate: <100.0 * moderate / totalLOC>%");
        println("* high: <100.0 * high / totalLOC>%");
        println("* very high: <100.0 * veryHigh / totalLOC>%");
    } else {
        println("No methods found to analyze.");
    }
}




//aanroepen in terminal met
//    loc project = |file:///smallsql/|;
//    M3 model = createM3FromDirectory(project);
//    linesOfCode(project, model); 
//    numberOfUnits(project, model);

// cyclomatic complexity of each unit: 1-10 is simple, 11-20 more complex, moderate risk, 
// 21-50 complex, high risk, > 50 untestable, very high risk

str riskClass(int cc) {
    if (cc <= 10) return "simple";
    if (cc <= 20) return "moderate";
    if (cc <= 50) return "high";
    return "very high";
}

// Approximate McCabe CC by counting decision points in method source
int approxCyclomatic(M3 model, loc method) {
    // get the source file of the method
    loc file = model.resource[method];

    set[Declaration] decls = createAstsFromFile(file); // parse the file AST

    int cc = 1; // minimum cyclomatic complexity

    // visit the AST declarations
    visit (decls) {
        // match the method declaration by name
        case \method(_, name, _, body): if (name == lastSegment(method)) {
            visit(body) {
                case \if(_, _, _): cc = cc + 1;
                case \for(_, _, _): cc = cc + 1;
                case \for(_, _, _, _): cc = cc + 1;
                case \foreach(_, _, _): cc = cc + 1;
                case \while(_, _): cc = cc + 1;
                case \doWhile(_, _): cc = cc + 1;
                case \catch(_, _): cc = cc + 1;
                case \case(_, _): cc = cc + 1;
                case \conditional(_, _, _): cc = cc + 1; // ternary operator
                case \binary(_, "&&", _, _): cc = cc + 1;
                case \binary(_, "||", _, _): cc = cc + 1;
            }
        }
    }

    return cc;
} 


public void printUnitMetrics() {
    loc project = |file:///smallsql/|;
    M3 model = createM3FromDirectory(project);

    // all units (methods + constructors)
    set[loc] units =
    {
        y | <x,y> <- model.containment,
             x.scheme == "java+class",
             (y.scheme == "java+method" || y.scheme == "java+constructor")
    };

    map[str,int] unitCount = ();       // number of units per risk
    map[str,int] complexitySum = ();   // sum of CC per risk

    for (loc u <- units) {
        int cc = approxCyclomatic(u);
        str r = riskClass(cc);

        unitCount[r] = (unitCount[r] ? 0) + 1;
        complexitySum[r] = (complexitySum[r] ? 0) + cc;
    }

    int totalUnits = size(units);
    int totalComplexity = sum({ complexitySum[r] | r <- complexitySum });

    println("unit size:");
    for (str r <- ["simple","moderate","high","very high"]) {
        int p = totalUnits == 0 ? 0 : ((unitCount[r] ? 0) * 100 / totalUnits);
        println("* <r>: <p>%");
    }

    println("unit complexity:");
    for (str r <- ["simple","moderate","high","very high"]) {
        int p = totalComplexity == 0 ? 0 : ((complexitySum[r] ? 0) * 100 / totalComplexity);
        println("* <r>: <p>%");
    }
}



// --------------------------------------------------------------------------
// visualisatie

public Content exercise10a() {
   loc project = |file:///SQM/JabberPoint/|;
   M3 model = createM3FromDirectory(project);
   rel[str, num] regels = { <l.file, a> | <l,a> <- toRel(regelsPerBestand(model)) };
   return barChart(sort(regels, aflopend), title="Regels per Javabestand");
}

public Content exercise10b() {
   return graph(gebruikt,title="Componenten", \layout=defaultGridLayout(rows=2,cols=3));
}