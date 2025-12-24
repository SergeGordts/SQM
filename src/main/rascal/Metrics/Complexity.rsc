module Metrics::Complexity

import lang::java::m3::AST;
import IO;
import List;
import Metrics::Utility;

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

public map[str, int] calculateComplexityDistribution(loc cl) {
    set[Declaration] asts = createAstsFromDirectory(cl, true);

    map[str, int] complexityDistribution = ("simple": 0, "moderate": 0, "high": 0, "very high": 0);

    visit (asts) {
        case Declaration d: {
            // Check if this declaration is a method/constructor/initializer
            if (d is \method || d is \constructor || d is \initializer ) {
                int cc = approxCyclomatic(d);
                str r = riskClass(cc);
                
                complexityDistribution[r] += size(getLinesOfMethod(d.src));
            }
        }
    }

    return complexityDistribution;  
}