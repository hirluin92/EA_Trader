//+------------------------------------------------------------------+
//|                                              ExposureManager.mqh |
//|                                                         Hirluin9 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

class CExposureManager {
private:
    double maxExposure;         // Massima esposizione consentita
    double currentExposure;     // Esposizione corrente
    double exposureLimit;       // Limite percentuale account
    
public:
    CExposureManager(double limit = 0.5) {  // 50% default max exposure
        exposureLimit = limit;
        currentExposure = 0;
        maxExposure = AccountInfoDouble(ACCOUNT_EQUITY) * exposureLimit;
    }
    
    bool Initialize() {
        UpdateExposure();
        return true;
    }
    
    bool CheckExposure(string symbol, double volume) {
        double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        double newExposure = volume * pointValue;
        
        return (currentExposure + newExposure <= maxExposure);
    }
    
    void UpdateExposure() {
        currentExposure = 0;
        for(int i = 0; i < PositionsTotal(); i++) {
            if(PositionSelectByTicket(PositionGetTicket(i))) {
                double volume = PositionGetDouble(POSITION_VOLUME);
                string symbol = PositionGetString(POSITION_SYMBOL);
                double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
                currentExposure += volume * pointValue;
            }
        }
    }
    
    double GetAvailableExposure() {
        return maxExposure - currentExposure;
    }
    
    // Getters e Setters
    void SetMaxExposure(double exposure) { maxExposure = exposure; }
    double GetMaxExposure() const { return maxExposure; }
    double GetCurrentExposure() const { return currentExposure; }
};