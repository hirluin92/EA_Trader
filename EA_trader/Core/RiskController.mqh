//+------------------------------------------------------------------+
//|                                               RiskController.mqh |
//|                                                         Hirluin9 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"
class CRiskController {
private:
    double riskPerTrade;
    double maxDailyRisk;
    double currentDayRisk;
    
public:
    CRiskController(double riskPercent = 2.0) {  // Rinominato da risk a riskPercent
        riskPerTrade = riskPercent;
        maxDailyRisk = riskPercent * 3;
        currentDayRisk = 0;
    }
    
    bool Initialize() {
        ResetDailyRisk();
        return true;
    }
    
    bool ValidateRisk() {
        if(currentDayRisk >= maxDailyRisk) return false;
        return true;
    }
    
    double CalculatePositionSize(double stopLoss) {
        double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        double riskAmount = accountEquity * (riskPerTrade / 100);
        double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        
        return NormalizeDouble(riskAmount / (stopLoss * pointValue), 2);
    }
    
    void UpdateRisk(double riskValue) {  // Rinominato da risk a riskValue
        currentDayRisk += riskValue;
    }
    
    void ResetDailyRisk() {
        currentDayRisk = 0;
    }
};
