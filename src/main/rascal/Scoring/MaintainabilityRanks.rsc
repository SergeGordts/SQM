module Scoring::MaintainabilityRanks

import util::Math;
import List;

str analysabilityScore;
str changeabilityScore;
str testabilityScore;

public str calculateAnalysabilityRank(list[str] ranks){
    analysabilityScore = calculateAverageRank(ranks);
    return analysabilityScore;
}

public str calculateChangeabilityRank(list[str] ranks){
    changeabilityScore = calculateAverageRank(ranks);
    return changeabilityScore;
}

public str calculateTestabilityRank(list[str] ranks){
    testabilityScore = calculateAverageRank(ranks);
    return testabilityScore;
}

public str calculateMaintainabilityRank(){
    return calculateAverageRank([analysabilityScore, changeabilityScore, testabilityScore]);
}

public str calculateAverageRank(list[str] ranks){
    list[int] rankValues = [];
	for (rank <- ranks) {
		switch(rank) {
			case "++": 	rankValues += 5;
			case "+": 	rankValues += 4;
			case "o": 	rankValues += 3;
			case "-": 	rankValues += 2;
			case "--":  rankValues += 1;
		}
	}

    int averageRank = round(sum(rankValues) / size(rankValues));
	
	switch(averageRank) {
		case 5: 	return "++";
		case 4: 	return "+";
		case 3: 	return "o";
		case 2:		return "-";
		case 1:		return "--";
	}

    return "";
}
