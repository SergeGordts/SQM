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

// --------------------------------------------------------------------------
// volume: Lines of code

public void linesOfCode() {
   loc project = |file:///smallsql/|;
   M3 model = createM3FromDirectory(project);
   set[loc] javaFiles = files(model);
   int totalLines = 0;
   for (loc f <- javaFiles) {
        totalLines += size(readFileLines(f));
        }
    println("SmallSQL");
    println("---------");
    println("lines of code: <totalLines>");
}

// size of each unit (a unit in java is a method)

//manier a
public void numberOfUnits() {
    loc project = |file:///smallsql/|;
    M3 model = createM3FromDirectory(project);

    // relation: class -> method/constructor
    rel[loc, loc] methoden =
    { <x, y> | <x, y> <- model.containment,
               x.scheme == "java+class",
               (y.scheme == "java+method" ||
                y.scheme == "java+constructor")
    };

    // total number of units = total number of methods
    int totalUnits = size(range(methoden));

    println("SmallSQL");
    println("---------");
    println("Number of units (methods): <totalUnits>");
}

//manier B
// Print number of methods (units) in a project
public void numberOfUnits(loc project) {
    M3 model = createM3FromDirectory(project);

    // collect all methods and constructors
    list[loc] allMethods = [l | l <- methods(model)];

    int totalUnits = size(allMethods);

    println("SmallSQL");
    println("---------");
    println("Number of units (methods): <totalUnits>");
}

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