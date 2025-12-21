module Scoring::Complexity

//same thresholds as CC defined by HeitlagerPracticalModel
tuple[int moderate, int high, int veryHigh] PlusPlus = <25, 0, 0>;
tuple[int moderate, int high, int veryHigh] Plus = <30, 5, 0>;
tuple[int moderate, int high, int veryHigh] Neutral = <40, 10, 0>;
tuple[int moderate, int high, int veryHigh] Minus = <50, 15, 5>;

public str calculateComplexityRank(tuple[int moderate, int high, int veryHigh] complexityDistribution){
    
    if (complexityDistribution.moderate >= Minus.moderate || complexityDistribution.high >= Minus.high || complexityDistribution.veryHigh >= Minus.veryHigh) {
		return "--";
	} 
    else if (complexityDistribution.moderate >= Neutral.moderate || complexityDistribution.high >= Neutral.high || complexityDistribution.veryHigh >= Neutral.veryHigh) {
		return "-";
	} 
    else if (complexityDistribution.moderate >= Plus.moderate || complexityDistribution.high >= Plus.high || complexityDistribution.veryHigh >= Plus.veryHigh) {
		return "o";
	} 
    else if (complexityDistribution.moderate >= PlusPlus.moderate || complexityDistribution.high >= PlusPlus.high || complexityDistribution.veryHigh >= PlusPlus.veryHigh) {
		return "+";
	} 
    else {
		return "++";
	}
}