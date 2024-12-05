#property copyright "Hirluin9";
#property link      "https://www.mql5.com";

#include "Forward.mqh"
#include "DataStructures.mqh"

class CSentimentAnalyzer {
private:
    int lookbackPeriod;
    double volumeBuffer[];
    double closeBuffer[];
    double openBuffer[];
    CMarketSentiment* marketSentiment;
    
    bool ValidateData() {
        ArraySetAsSeries(volumeBuffer, true);
        ArraySetAsSeries(closeBuffer, true);
        ArraySetAsSeries(openBuffer, true);
        
        return CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, lookbackPeriod, volumeBuffer) == lookbackPeriod &&
               CopyClose(_Symbol, PERIOD_CURRENT, 0, lookbackPeriod, closeBuffer) == lookbackPeriod &&
               CopyOpen(_Symbol, PERIOD_CURRENT, 0, lookbackPeriod, openBuffer) == lookbackPeriod;
    }
    
    double CalculateBullishPressure() {
        if(!ValidateData()) return 0;
        
        double bullPressure = 0;
        double totalVolume = 0;
        
        for(int i = 0; i < lookbackPeriod; i++) {
            if(closeBuffer[i] > openBuffer[i]) {
                bullPressure += volumeBuffer[i];
            }
            totalVolume += volumeBuffer[i];
        }
        
        return totalVolume > 0 ? bullPressure / totalVolume : 0;
    }
    
    double CalculateBearishPressure() {
        if(!ValidateData()) return 0;
        
        double bearPressure = 0;
        double totalVolume = 0;
        
        for(int i = 0; i < lookbackPeriod; i++) {
            if(closeBuffer[i] < openBuffer[i]) {
                bearPressure += volumeBuffer[i];
            }
            totalVolume += volumeBuffer[i];
        }
        
        return totalVolume > 0 ? bearPressure / totalVolume : 0;
    }
    
public:    
    CSentimentAnalyzer(CMarketSentiment* ms) : marketSentiment(ms) {
        lookbackPeriod = 10;
    }
    
    ~CSentimentAnalyzer() {
        ArrayFree(volumeBuffer);
        ArrayFree(closeBuffer);
        ArrayFree(openBuffer);
    }
    
    bool Initialize() {
        ArrayResize(volumeBuffer, lookbackPeriod);
        ArrayResize(closeBuffer, lookbackPeriod);
        ArrayResize(openBuffer, lookbackPeriod);
        return ValidateData();
    }
    
    SentimentData GetCurrentSentiment() {
        SentimentData sentimentData;
        
        sentimentData.bullishPressure = CalculateBullishPressure();
        sentimentData.bearishPressure = CalculateBearishPressure();
        sentimentData.netSentiment = sentimentData.bullishPressure - sentimentData.bearishPressure;
        sentimentData.isValid = true;
        
        return sentimentData;
    }
    
    void SetLookbackPeriod(int period) {
        lookbackPeriod = MathMax(5, MathMin(100, period));
        Initialize();
    }
    
    int GetLookbackPeriod() const { return lookbackPeriod; }
};