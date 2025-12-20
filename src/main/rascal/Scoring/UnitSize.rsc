module Scoring::UnitSize

//same thresholds as CC defined by HeitlagerPracticalModel
tuple[int moderate, int high, int veryHigh] PlusPlus = <25, 0, 0>;
tuple[int moderate, int high, int veryHigh] Plus = <30, 5, 0>;
tuple[int moderate, int high, int veryHigh] Neutral = <40, 10, 0>;
tuple[int moderate, int high, int veryHigh] Minus = <50, 15, 5>;

public str calculateUnitsizeRank(tuple[int moderate, int high, int veryHigh] unitSizeDistribution){
    
    if (unitSizeDistribution.moderate >= Minus.moderate || unitSizeDistribution.high >= Minus.high || unitSizeDistribution.veryHigh >= Minus.veryHigh) {
		return "--";
	} else if (unitSizeDistribution.moderate >= Neutral.moderate || unitSizeDistribution.high >= Neutral.high || unitSizeDistribution.veryHigh >= Neutral.veryHigh) {
		return "-";
	} else if (unitSizeDistribution.moderate >= Plus.moderate || unitSizeDistribution.high >= Plus.high || unitSizeDistribution.veryHigh >= Plus.veryHigh) {
		return "o";
	} else if (unitSizeDistribution.moderate >= PlusPlus.moderate || unitSizeDistribution.high >= PlusPlus.high || unitSizeDistribution.veryHigh >= PlusPlus.veryHigh) {
		return "+";
	} else {
		return "++";
	}
}