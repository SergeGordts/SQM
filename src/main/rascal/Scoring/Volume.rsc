module Scoring::Volume

//Volume thresholds defined by HeitlagerPracticalModel
tuple[int min, int max] PlusPlus = <0, 66000>;
tuple[int min, int max] Plus = <66000, 246000>;
tuple[int min, int max] Neutral = <246000, 665000>;
tuple[int min, int max] Minus = <665000, 1310000>;

public str calculateVolumeRank(int volume){
    
    if(volume < PlusPlus.min){
        return "";
    }
    else if(volume >= PlusPlus.min && volume < PlusPlus.max){
        return "++";
    }
    else if(volume >= Plus.min && volume < Plus.max){
        return "+";
    }
    else if(volume >= Neutral.min && volume < Neutral.max){
        return "o";
    }
    else if(volume >= Minus.min && volume < Minus.max){
        return "-";
    }
    else{
        return "--";
    }
}