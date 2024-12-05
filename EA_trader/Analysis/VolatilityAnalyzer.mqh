// VolatilityAnalyzer.mqh 
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

#include "Forward.mqh"
#include "DataStructures.mqh"

class CVolatilityAnalyzer {
private:
    int atrPeriod;
    double volThreshold;
    int atrHandle;
    
    double CalculateCurrentVolatility() {
        if(atrHandle == INVALID_HANDLE) return 0;
        
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        
        if(CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) <= 0) return 0;
        
        return atrBuffer[0];
    }
    
    double CalculateAverageVolatility() {
        if(atrHandle == INVALID_HANDLE) return 0;
        
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        
        if(CopyBuffer(atrHandle, 0, 1, atrPeriod, atrBuffer) <= 0) return 0;
        
        double avgVol = 0;
        for(int i = 0; i < atrPeriod; i++) {
            avgVol += atrBuffer[i];
        }
        return avgVol / atrPeriod;
    }
    
    bool IsVolatilityIncreasing() {
        if(atrHandle == INVALID_HANDLE) return false;
        
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        
        if(CopyBuffer(atrHandle, 0, 0, 2, atrBuffer) <= 0) return false;
        
        return atrBuffer[0] > atrBuffer[1];
    }
    
    bool ValidateVolatility(VolatilityState& state) {
        return state.currentVol >= state.averageVol * volThreshold;
    }

public:    
    CVolatilityAnalyzer() {
        atrPeriod = 14;
        volThreshold = 0.8;
        atrHandle = INVALID_HANDLE;
    }
    
    bool Initialize() {
        Deinit();
        atrHandle = iATR(_Symbol, PERIOD_CURRENT, atrPeriod);
        return (atrHandle != INVALID_HANDLE);
    }
    
    void Deinit() {
        if(atrHandle != INVALID_HANDLE) {
            IndicatorRelease(atrHandle);
            atrHandle = INVALID_HANDLE;
        }
    }
    
    VolatilityState AnalyzeVolatility() {
        VolatilityState state;
        
        state.currentVol = CalculateCurrentVolatility();
        state.averageVol = CalculateAverageVolatility();
        state.isIncreasing = IsVolatilityIncreasing();
        state.isValid = ValidateVolatility(state);
        
        return state;
    }
    
    void SetATRPeriod(int period) {
        if(period != atrPeriod) {
            atrPeriod = period;
            if(atrHandle != INVALID_HANDLE) {
                IndicatorRelease(atrHandle);
                atrHandle = iATR(_Symbol, PERIOD_CURRENT, atrPeriod);
            }
        }
    }
    
    void SetVolThreshold(double threshold) {
        volThreshold = MathMax(0.1, MathMin(2.0, threshold));
    }
    
    double GetCurrentVolatility() const {
        return CalculateCurrentVolatility();
    }
    
    double GetAverageVolatility() const {
        return CalculateAverageVolatility();
    }
    
    double GetVolThreshold() const { return volThreshold; }
    int GetATRPeriod() const { return atrPeriod; }
    
    ~CVolatilityAnalyzer() {
        Deinit();
    }
};