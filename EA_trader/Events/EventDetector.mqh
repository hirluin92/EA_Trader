class CEventDetector {
private:
    int volatilityPeriod;
    double spikeThreshold;
    double trendThreshold;
    int atrHandle;
    int maHandle;
    double volSpikes[];
    double trendPoints[];
    
public:
    CEventDetector(int volPeriod = 14, double spikeTh = 2.0, double trendTh = 1.5) {
        volatilityPeriod = volPeriod;
        spikeThreshold = spikeTh;
        trendThreshold = trendTh;
        atrHandle = INVALID_HANDLE;
        maHandle = INVALID_HANDLE;
    }
    
    bool Initialize() {
        ArrayResize(volSpikes, volatilityPeriod);
        ArrayResize(trendPoints, volatilityPeriod);
        ArrayInitialize(volSpikes, 0);
        ArrayInitialize(trendPoints, 0);
        
        atrHandle = iATR(_Symbol, PERIOD_CURRENT, volatilityPeriod);
        maHandle = iMA(_Symbol, PERIOD_CURRENT, volatilityPeriod, 0, MODE_SMA, PRICE_CLOSE);
        
        if(atrHandle == INVALID_HANDLE || maHandle == INVALID_HANDLE) {
            Print("Failed to initialize indicators");
            return false;
        }
        
        return UpdateHistoricalData();
    }
    
    bool DetectVolatilitySpike() {
        double atr[];
        ArraySetAsSeries(atr, true);
        
        if(CopyBuffer(atrHandle, 0, 0, 2, atr) <= 0) {
            Print("Failed to copy ATR data");
            return false;
        }
        
        double avgSpike = CalculateAverageSpike();
        double currentSpike = (atr[0] - atr[1]) / atr[1];
        
        UpdateVolatilityHistory(currentSpike);
        
        return (currentSpike > avgSpike * spikeThreshold);
    }
    
    bool DetectTrendChange() {
        double ma[], close[];
        ArraySetAsSeries(ma, true);
        ArraySetAsSeries(close, true);
        
        if(CopyBuffer(maHandle, 0, 0, 3, ma) <= 0 || 
           CopyClose(_Symbol, PERIOD_CURRENT, 0, 3, close) <= 0) {
            Print("Failed to copy price data");
            return false;
        }
        
        bool previousTrend = close[2] > ma[2];
        bool currentTrend = close[0] > ma[0];
        double trendStrength = MathAbs(close[0] - ma[0]) / ma[0];
        
        UpdateTrendHistory(trendStrength);
        
        return (previousTrend != currentTrend && trendStrength > trendThreshold);
    }
    
    bool DetectLiquidityEvent() {
        long volume[], avgVolume = 0;
        ArraySetAsSeries(volume, true);
        
        if(!CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, volatilityPeriod, volume)) {
            Print("Failed to copy volume data");
            return false;
        }
        
        double currentVolume = (double)volume[0];
        double averageVolume = 0;
        
        for(int i = 1; i < volatilityPeriod; i++) {
            averageVolume += (double)volume[i];
        }
        averageVolume /= (volatilityPeriod - 1);
        
        return (currentVolume < averageVolume * 0.5);
    }
    
    int GetEventSeverity() {
        int severity = 0;
        double volWeight = 2.0;
        double trendWeight = 1.5;
        double liqWeight = 1.0;
        
        if(DetectVolatilitySpike()) severity += (int)(volWeight * GetVolatilityMagnitude());
        if(DetectTrendChange()) severity += (int)(trendWeight * GetTrendMagnitude());
        if(DetectLiquidityEvent()) severity += (int)liqWeight;
        
        return severity;
    }
    
    double GetVolatilityMagnitude() {
        double atr[];
        ArraySetAsSeries(atr, true);
        CopyBuffer(atrHandle, 0, 0, 2, atr);
        return (atr[0] / atr[1]) - 1;
    }
    
    double GetTrendMagnitude() {
        double ma[], close[];
        ArraySetAsSeries(ma, true);
        ArraySetAsSeries(close, true);
        
        CopyBuffer(maHandle, 0, 0, 1, ma);
        CopyClose(_Symbol, PERIOD_CURRENT, 0, 1, close);
        
        return MathAbs(close[0] - ma[0]) / ma[0];
    }
    
private:
    bool UpdateHistoricalData() {
        double atr[], ma[], close[];
        ArraySetAsSeries(atr, true);
        ArraySetAsSeries(ma, true);
        ArraySetAsSeries(close, true);
        
        if(CopyBuffer(atrHandle, 0, 0, volatilityPeriod, atr) <= 0 ||
           CopyBuffer(maHandle, 0, 0, volatilityPeriod, ma) <= 0 ||
           CopyClose(_Symbol, PERIOD_CURRENT, 0, volatilityPeriod, close) <= 0) {
            return false;
        }
        
        for(int i = 1; i < volatilityPeriod; i++) {
            volSpikes[i-1] = (atr[i-1] - atr[i]) / atr[i];
            trendPoints[i-1] = MathAbs(close[i-1] - ma[i-1]) / ma[i-1];
        }
        
        return true;
    }
    
    void UpdateVolatilityHistory(double spike) {
        for(int i = volatilityPeriod-2; i >= 0; i--) {
            volSpikes[i+1] = volSpikes[i];
        }
        volSpikes[0] = spike;
    }
    
    void UpdateTrendHistory(double trend) {
        for(int i = volatilityPeriod-2; i >= 0; i--) {
            trendPoints[i+1] = trendPoints[i];
        }
        trendPoints[0] = trend;
    }
    
    double CalculateAverageSpike() {
        double sum = 0;
        for(int i = 0; i < volatilityPeriod-1; i++) {
            sum += volSpikes[i];
        }
        return sum / (volatilityPeriod-1);
    }
    
    void Deinit() {
        if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
        if(maHandle != INVALID_HANDLE) IndicatorRelease(maHandle);
    }
    
    ~CEventDetector() {
        Deinit();
    }
};