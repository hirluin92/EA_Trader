// Analysis/Analysis.mqh
#property copyright "Hirluin9";
#property link      "https://www.mql5.com";

#include "DataStructures.mqh"
#include "Forward.mqh"
#include "MarketSentiment.mqh"
#include "SentimentAnalyzer.mqh"
#include "VolatilityAnalyzer.mqh"
#include "PatternDetector.mqh"
#include "MarketRegimeAnalyzer.mqh"

class CAnalysis {
private:
    CMarketSentiment* marketSentiment;
    CSentimentAnalyzer* sentimentAnalyzer;
    CVolatilityAnalyzer* volatilityAnalyzer;
    CPatternDetector* patternDetector;
    CMarketRegimeAnalyzer* regimeAnalyzer;
    
public:
    CAnalysis() {
        marketSentiment = new CMarketSentiment();
        sentimentAnalyzer = new CSentimentAnalyzer(marketSentiment);
        volatilityAnalyzer = new CVolatilityAnalyzer();
        patternDetector = new CPatternDetector();
        regimeAnalyzer = new CMarketRegimeAnalyzer(marketSentiment);
    }
    
    ~CAnalysis() {
        delete marketSentiment;
        delete sentimentAnalyzer;
        delete volatilityAnalyzer;
        delete patternDetector;
        delete regimeAnalyzer;
    }
    
    bool Initialize() {
        return marketSentiment.Initialize() &&
               sentimentAnalyzer.Initialize() &&
               volatilityAnalyzer.Initialize() &&
               patternDetector.Initialize() &&
               regimeAnalyzer.Initialize();
    }
    
    MarketMood GetMarketMood() { return marketSentiment.GetMarketMood(); }
    VolatilityState GetVolatilityState() { return volatilityAnalyzer.AnalyzeVolatility(); }
    ENUM_MARKET_REGIME GetMarketRegime() { return regimeAnalyzer.DetectRegime(); }
    CPatternDetector::PATTERN_TYPE GetCurrentPattern() { return patternDetector.DetectPattern(); }
};