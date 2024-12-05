//+------------------------------------------------------------------+
//|                                              IntradayManager.mqh |
//|                                                         Hirluin9 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"
class CIntradayManager {
private:
    datetime sessionStart;
    datetime sessionEnd;
    int maxDailyTrades;
    double currentDayPnL;
    
public:
    CIntradayManager() {
        sessionStart = 0;
        sessionEnd = 0;
        maxDailyTrades = 5;
        currentDayPnL = 0;
    }
    
    bool Initialize() {
        sessionStart = StringToTime("08:00");
        sessionEnd = StringToTime("20:00");
        return true;
    }
    
    bool IsValidTradingTime() {
        datetime currentTime = TimeCurrent();
        return (currentTime >= sessionStart && 
                currentTime <= sessionEnd);
    }
    
    void UpdateDayPnL(double profit) {
        currentDayPnL += profit;
    }
    
    double GetCurrentDayPnL() {
        return currentDayPnL;
    }
};
