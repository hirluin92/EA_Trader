class CMarketRegimeAnalyzer {
private:
    ENUM_MARKET_REGIME currentRegime;
    double regimeThresholds[];
    int atrHandle;
    int adxHandle;
    double volatilityThreshold;
    double trendThreshold;
    CMarketSentiment* marketSentiment;
    
public:
    enum ENUM_MARKET_REGIME {
        REGIME_TRENDING,
        REGIME_RANGING,
        REGIME_VOLATILE,
        REGIME_UNDEFINED
    };
    
    CMarketRegimeAnalyzer(CMarketSentiment* ms) : 
        marketSentiment(ms),
        volatilityThreshold(1.5),
        trendThreshold(25.0),
        currentRegime(REGIME_UNDEFINED) {
        atrHandle = INVALID_HANDLE;
        adxHandle = INVALID_HANDLE;
        ArrayResize(regimeThresholds, 3);
    }
    
    bool Initialize() {
        atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
        adxHandle = iADX(_Symbol, PERIOD_CURRENT, 14);
        return (atrHandle != INVALID_HANDLE && adxHandle != INVALID_HANDLE);
    }
    
    ENUM_MARKET_REGIME DetectRegime() {
        double atr[], adx[];
        ArraySetAsSeries(atr, true);
        ArraySetAsSeries(adx, true);
        
        if(CopyBuffer(atrHandle, 0, 0, 2, atr) <= 0 ||
           CopyBuffer(adxHandle, 0, 0, 2, adx) <= 0) {
            return REGIME_UNDEFINED;
        }
        
        double volatilityRatio = atr[0] / atr[1];
        double trendStrength = adx[0];
        
        if(volatilityRatio > volatilityThreshold) {
            currentRegime = REGIME_VOLATILE;
        }
        else if(trendStrength > trendThreshold) {
            currentRegime = REGIME_TRENDING;
        }
        else {
            currentRegime = REGIME_RANGING;
        }
        
        return currentRegime;
    }
    
    bool ShouldChangeStrategy() {
        ENUM_MARKET_REGIME newRegime = DetectRegime();
        bool shouldChange = (newRegime != currentRegime);
        currentRegime = newRegime;
        return shouldChange;
    }
    
    void UpdateRegimeThresholds() {
        double atr[], adx[];
        ArraySetAsSeries(atr, true);
        ArraySetAsSeries(adx, true);
        
        if(CopyBuffer(atrHandle, 0, 0, 20, atr) > 0 && 
           CopyBuffer(adxHandle, 0, 0, 20, adx) > 0) {
            volatilityThreshold = CalculateOptimalVolatilityThreshold(atr);
            trendThreshold = CalculateOptimalTrendThreshold(adx);
        }
    }
    
    void Deinit() {
        if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
        if(adxHandle != INVALID_HANDLE) IndicatorRelease(adxHandle);
    }
    
    ~CMarketRegimeAnalyzer() {
        Deinit();
    }
    
private:
    double CalculateOptimalVolatilityThreshold(const double &atr[]) {
        double sum = 0, sumSquares = 0;
        int count = ArraySize(atr);
        
        for(int i = 0; i < count; i++) {
            sum += atr[i];
            sumSquares += atr[i] * atr[i];
        }
        
        double mean = sum / count;
        double stdDev = MathSqrt(sumSquares/count - mean*mean);
        
        return mean + 2*stdDev;
    }
    
    double CalculateOptimalTrendThreshold(const double &adx[]) {
        double sum = 0;
        int count = ArraySize(adx);
        
        for(int i = 0; i < count; i++) {
            sum += adx[i];
        }
        
        return (sum / count) * 1.2;
    }
};