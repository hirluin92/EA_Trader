//+------------------------------------------------------------------+
//|                                                MarketScanner.mqh |
//|                                                         Hirluin9 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

class CMarketScanner {
private:
    double minVolatility;
    double maxSpread;
    int minVolume;
    int atrHandle;
    int atrPeriod;
    
public:
    CMarketScanner() {
        minVolatility = 0.1;
        maxSpread = 3.0;
        minVolume = 100;
        atrPeriod = 14;
        atrHandle = INVALID_HANDLE;
    }
    
    bool Initialize() {
        atrHandle = iATR(_Symbol, PERIOD_CURRENT, atrPeriod);
        return (atrHandle != INVALID_HANDLE);
    }
    
    void Deinit() {
        if(atrHandle != INVALID_HANDLE) {
            IndicatorRelease(atrHandle);
            atrHandle = INVALID_HANDLE;
        }
    }
    
    bool IsMarketConditionValid() {
        if(!CheckSpread()) return false;
        if(!CheckVolume()) return false;
        if(!CheckVolatility()) return false;
        return true;
    }
    
    bool CheckSpread() {
        double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * 
                             SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        return currentSpread <= maxSpread;
    }
    
    bool CheckVolume() {
        long currentVolume;
        if(!SymbolInfoInteger(_Symbol, SYMBOL_VOLUME, currentVolume)) return false;
        return currentVolume >= minVolume;
    }
    
    bool CheckVolatility() {
        if(atrHandle == INVALID_HANDLE) return false;
        
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        
        if(CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) <= 0) return false;
        
        double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double volValue = atrBuffer[0] / price * 100;
        
        return volValue >= minVolatility;
    }
    
    // Getters e Setters
    double GetMinVolatility() const { return minVolatility; }
    void SetMinVolatility(double value) { minVolatility = value; }
    
    double GetMaxSpread() const { return maxSpread; }
    void SetMaxSpread(double value) { maxSpread = value; }
    
    int GetMinVolume() const { return minVolume; }
    void SetMinVolume(int value) { minVolume = value; }
    
    ~CMarketScanner() {
        Deinit();
    }
};