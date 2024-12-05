#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

#include <Trade/Trade.mqh>

class CStopManager {
private:
    CTrade trade;
    double minRiskReward;
    double atrMultiplier;
    int atrHandle;
    
    void UpdateTrailingStop() {
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        CopyBuffer(atrHandle, 0, 0, 1, atrBuffer);
        double trailDistance = atrBuffer[0] * 2;
        
        for(int i = 0; i < PositionsTotal(); i++) {
            if(PositionSelectByTicket(PositionGetTicket(i))) {
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                    double newSL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) - trailDistance, _Digits);
                    if(newSL > PositionGetDouble(POSITION_SL)) {
                        trade.PositionModify(PositionGetTicket(i), newSL, PositionGetDouble(POSITION_TP));
                    }
                }
                else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                    double newSL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK) + trailDistance, _Digits);
                    if(newSL < PositionGetDouble(POSITION_SL) || PositionGetDouble(POSITION_SL) == 0) {
                        trade.PositionModify(PositionGetTicket(i), newSL, PositionGetDouble(POSITION_TP));
                    }
                }
            }
        }
    }
    
    void UpdateBreakEven() {
        double be_level = 1.5;
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        CopyBuffer(atrHandle, 0, 0, 1, atrBuffer);
        double atr = atrBuffer[0];
        
        for(int i = 0; i < PositionsTotal(); i++) {
            if(PositionSelectByTicket(PositionGetTicket(i))) {
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                    if(SymbolInfoDouble(_Symbol, SYMBOL_BID) - PositionGetDouble(POSITION_PRICE_OPEN) > atr * be_level) {
                        if(PositionGetDouble(POSITION_SL) < PositionGetDouble(POSITION_PRICE_OPEN)) {
                            trade.PositionModify(PositionGetTicket(i), PositionGetDouble(POSITION_PRICE_OPEN), 
                                               PositionGetDouble(POSITION_TP));
                        }
                    }
                }
                else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                    if(PositionGetDouble(POSITION_PRICE_OPEN) - SymbolInfoDouble(_Symbol, SYMBOL_ASK) > atr * be_level) {
                        if(PositionGetDouble(POSITION_SL) > PositionGetDouble(POSITION_PRICE_OPEN)) {
                            trade.PositionModify(PositionGetTicket(i), PositionGetDouble(POSITION_PRICE_OPEN), 
                                               PositionGetDouble(POSITION_TP));
                        }
                    }
                }
            }
        }
    }

public:
    CStopManager(double minRR = 1.5) {
        minRiskReward = minRR;
        atrMultiplier = 2.0;
        atrHandle = INVALID_HANDLE;
    }
    
    bool Initialize() {
        atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
        return (atrHandle != INVALID_HANDLE);
    }
    
    void Deinit() {
        if(atrHandle != INVALID_HANDLE) {
            IndicatorRelease(atrHandle);
            atrHandle = INVALID_HANDLE;
        }
    }
    
    void UpdateStopLevels() {
        if(atrHandle != INVALID_HANDLE) {
            UpdateTrailingStop();
            UpdateBreakEven();
        }
    }
    
    double CalculateStopLoss(double entryPrice, ENUM_ORDER_TYPE orderType) {
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        CopyBuffer(atrHandle, 0, 0, 1, atrBuffer);
        double stopDistance = atrBuffer[0] * atrMultiplier;
        
        return (orderType == ORDER_TYPE_BUY) ? 
                entryPrice - stopDistance : 
                entryPrice + stopDistance;
    }
    
    ~CStopManager() {
        Deinit();
    }
};