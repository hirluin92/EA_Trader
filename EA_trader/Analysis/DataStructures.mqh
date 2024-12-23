
// DataStructures.mqh
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

struct SentimentData {
    double bullishPressure;
    double bearishPressure;
    double netSentiment;
    bool isValid;
};

struct VolatilityState {
    double currentVol;
    double averageVol;
    bool isIncreasing;
    bool isValid;
};

struct MarketMood {
    SentimentData current;
    double historicalAverage;
    double sentimentBand;
    bool extremeLevel;
    datetime lastUpdate;
};
