module Scoring::Duplication

tuple[real min, real max] PlusPlus = <0.0, 3.0>;
tuple[real min, real max] Plus = <3.0, 5.0>;
tuple[real min, real max] Neutral = <5.0, 10.0>;
tuple[real min, real max] Minus = <10.0, 20.0>;

public str calculateDuplicationRank(real duplicationFactor){
    
    if(duplicationFactor < PlusPlus.min){
        return "";
    }
    else if(duplicationFactor >= PlusPlus.min && duplicationFactor < PlusPlus.max){
        return "++";
    }
    else if(duplicationFactor >= Plus.min && duplicationFactor < Plus.max){
        return "+";
    }
    else if(duplicationFactor >= Neutral.min && duplicationFactor < Neutral.max){
        return "o";
    }
    else if(duplicationFactor >= Minus.min && duplicationFactor < Minus.max){
        return "-";
    }
    else{
        return "--";
    }
}