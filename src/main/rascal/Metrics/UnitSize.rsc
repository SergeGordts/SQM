module Metrics::UnitSize

import IO;
import List;
import lang::java::m3::Core;
import Metrics::Utility;

// 2 ---> number of units (a unit in java is a method). methods() is a core library function and includes constructors and initializers.
public int calculateNumberOfUnits(M3 model) {
   list[loc] allMethods = [l | l <- methods(model)];
   int totalUnits = size(allMethods);
   return totalUnits;
}

// 3 --> unit size: The article "Deriving Metric Thresholds from Benchmark Data" by Visser et al
// discusses a method that determines metric thresholds empirically from measurement data.
// Table IV in this article shows the empirically derived Thresholds for Unit Size for Java and other OO systems.
// The thresholds are based on benchmarked quantiles of the distribution of unit size (LOC per method, exlcuding comments and balnk lines via a regex). 
// The authors use the 70th, 80th, and 90th percentiles as thresholds that capture meaningful variation while weighting by code volume across many systems.
// | Metric                       | 70%    | 80%    | 90%    |
// Unit size (LOC per unit)       | 30     | 44     | 74     |
// so Simple is ≤ 30, Moderate > 30 and ≤ 44, High > 44 and ≤ 74 and Very high > 74                                 

//they pool measurement data across many systems (100 projects), aggregates relative size weighting (LOC) so larger units contribute proportionally,
//chooses quantiles (70%, 80%, 90%) that emphasize meaningful code volume splits, and rounds values to practical integer thresholds. 

//during the online sessions in the course it was said that one could also choose the CC tresholhds, or the SIG/tüvit evaluation criteria
//but since the author of the aforementioned article also is one of the creators of the SIG we opt for this one.

public list[int] calculateMethodSizes(M3 model){
    list[loc] allMethods = [l | l <- methods(model)];
    list[int] methodSizes = [
        //list allows non-unique lines
        size(getLinesOfMethod(m)) 
        | m <- allMethods
    ];

    return methodSizes;
}

str riskClass(int size) {
    if (size <= 10) return "simple";
    if (size <= 20) return "moderate";
    if (size <= 50) return "high";
    return "very high";
}

public map[str, int] calculateUnitSizeDistribution(list[int] methodSizes) {
    int simple = 0;
    int moderate = 0;
    int high = 0;
    int veryHigh = 0;

    for (int size <- methodSizes) {
        if (size <= 30) { simple += 1; }
        else if (size <= 44) { moderate += 1; }
        else if (size <= 74) { high += 1; }
        else { veryHigh += 1; }
    }

    return ("simple": simple,
            "moderate": moderate,
            "high": high,
            "veryHigh": veryHigh);
}

public map[str, real] calculateUnitSizePercentages(list[int] methodSizes) {
    int simple = 0;
    int moderate = 0;
    int high = 0;
    int veryHigh = 0;

    int totalMethods = size(methodSizes);

    for (int size <- methodSizes) {
        if (size <= 30) { simple += 1; }
        else if (size <= 44) { moderate += 1; }
        else if (size <= 74) { high += 1; }
        else { veryHigh += 1; }
    }

    return ("simple": (simple * 100.0) / totalMethods,
            "moderate": (moderate * 100.0) / totalMethods,
            "high": (high * 100.0) / totalMethods,
            "veryHigh": (veryHigh * 100.0) / totalMethods);
}