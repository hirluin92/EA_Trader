//+------------------------------------------------------------------+
//|                                                 OrderManager.mqh |
//|                                                         Hirluin9 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

struct STradeParameters {
    double volume;
    ENUM_ORDER_TYPE orderType;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    bool isValid;
};

class COrderManager {
private:
    double minLot;
    double maxLot;
    double stepLot;
    
    bool ValidateTradeParameters(const STradeParameters& params) {
        if(params.volume < minLot || params.volume > maxLot) return false;
        if(params.volume != NormalizeDouble(params.volume, 2)) return false;
        if(params.stopLoss <= 0 || params.takeProfit <= 0) return false;
        if(!params.isValid) return false;
        
        return true;
    }
    
public:
    COrderManager() {
        minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    }
    
    bool Initialize() {
        return true;
    }
    
    bool ExecuteTrade(STradeParameters& params) {
        if(!ValidateTradeParameters(params)) return false;
        
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = _Symbol;
        request.volume = params.volume;
        request.type = params.orderType;
        request.price = params.entryPrice;
        request.sl = params.stopLoss;
        request.tp = params.takeProfit;
        
        return OrderSend(request, result);
    }
};