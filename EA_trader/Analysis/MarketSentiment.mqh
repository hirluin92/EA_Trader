#include "DataStructures.mqh"
#include "Forward.mqh"
class CMarketSentiment {
private:
    CSentimentAnalyzer* sentimentAnalyzer;
    int volumeMA;
    double sentimentBands[];
    int sentimentHandle;
    int lookbackPeriod;
    double extremeThreshold;
    
public:
    CMarketSentiment(int period = 20, double threshold = 0.8) {
        sentimentAnalyzer = new CSentimentAnalyzer();
        lookbackPeriod = period;
        extremeThreshold = threshold;
        volumeMA = iMA(_Symbol, PERIOD_CURRENT, lookbackPeriod, 0, MODE_SMA, VOLUME_TICK);
        ArrayResize(sentimentBands, lookbackPeriod);
    }
    
    ~CMarketSentiment() {
        delete sentimentAnalyzer;
        if(volumeMA != INVALID_HANDLE) IndicatorRelease(volumeMA);
    }
    
    bool Initialize() {
        if(!sentimentAnalyzer.Initialize()) return false;
        return CalculateSentimentBands();
    }
    
    MarketMood GetMarketMood() {
        MarketMood mood;
        
        mood.current = sentimentAnalyzer.GetCurrentSentiment();
        mood.historicalAverage = CalculateHistoricalAverage();
        mood.sentimentBand = CalculateSentimentBand();
        mood.extremeLevel = IsSentimentExtreme();
        mood.lastUpdate = TimeCurrent();
        
        return mood;
    }
    
    double GetSentimentStrength() {
        SentimentData current = sentimentAnalyzer.GetCurrentSentiment();
        return MathAbs(current.netSentiment);
    }
    
    bool IsSentimentExtreme() {
        double strength = GetSentimentStrength();
        return strength > extremeThreshold;
    }
    
private:
    bool CalculateSentimentBands() {
        double volume[];
        ArraySetAsSeries(volume, true);
        
        if(CopyBuffer(volumeMA, 0, 0, lookbackPeriod, volume) <= 0)
            return false;
            
        double sum = 0, sumSq = 0;
        
        for(int i = 0; i < lookbackPeriod; i++) {
            double value = volume[i];
            sum += value;
            sumSq += value * value;
        }
        
        double mean = sum / lookbackPeriod;
        double stdDev = MathSqrt(sumSq/lookbackPeriod - mean*mean);
        
        for(int i = 0; i < lookbackPeriod; i++) {
            sentimentBands[i] = mean + (2 * stdDev);
        }
        
        return true;
    }
    
    double CalculateHistoricalAverage() {
        double sentiments[];
        ArrayResize(sentiments, lookbackPeriod);
        double sum = 0;
        
        for(int i = 0; i < lookbackPeriod; i++) {
            SentimentData hist = sentimentAnalyzer.GetCurrentSentiment();
            sentiments[i] = hist.netSentiment;
            sum += sentiments[i];
        }
        
        return sum / lookbackPeriod;
    }
    
    double CalculateSentimentBand() {
        if(ArraySize(sentimentBands) == 0) return 0;
        return sentimentBands[0];
    }
    
    void SetExtremeThreshold(double threshold) {
        extremeThreshold = MathMax(0.5, MathMin(1.0, threshold));
    }
    
    void SetLookbackPeriod(int period) {
        lookbackPeriod = MathMax(10, MathMin(100, period));
        ArrayResize(sentimentBands, lookbackPeriod);
    }
};