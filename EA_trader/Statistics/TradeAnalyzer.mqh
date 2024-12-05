class CTradeAnalyzer {
private:
    int tradeSeries[];
    double profitSeries[];
    int maxSeriesLength;
    
public:
    CTradeAnalyzer(int maxLength = 1000) {
        maxSeriesLength = maxLength;
        ArrayResize(tradeSeries, 0);
        ArrayResize(profitSeries, 0);
    }
    
    void AnalyzeTradeSequence() {
        ulong ticket = HistoryDealGetTicket(HistoryDealsTotal() - 1);
        if(ticket > 0) {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            AddTrade(profit > 0 ? 1 : 0, profit);
        }
    }
    
    int GetConsecutiveWins() {
        int consecutive = 0;
        int maxConsecutive = 0;
        
        for(int i = 0; i < ArraySize(tradeSeries); i++) {
            if(tradeSeries[i] == 1) {
                consecutive++;
                if(consecutive > maxConsecutive) maxConsecutive = consecutive;
            } else {
                consecutive = 0;
            }
        }
        
        return maxConsecutive;
    }
    
    int GetConsecutiveLosses() {
        int consecutive = 0;
        int maxConsecutive = 0;
        
        for(int i = 0; i < ArraySize(tradeSeries); i++) {
            if(tradeSeries[i] == 0) {
                consecutive++;
                if(consecutive > maxConsecutive) maxConsecutive = consecutive;
            } else {
                consecutive = 0;
            }
        }
        
        return maxConsecutive;
    }
    
    double GetWinRate() {
        int wins = 0;
        int total = ArraySize(tradeSeries);
        
        if(total == 0) return 0;
        
        for(int i = 0; i < total; i++) {
            if(tradeSeries[i] == 1) wins++;
        }
        
        return (double)wins/total;
    }
    
private:
    void AddTrade(int isWin, double profit) {
        if(ArraySize(tradeSeries) >= maxSeriesLength) {
            ArrayRemove(tradeSeries, 0, 1);
            ArrayRemove(profitSeries, 0, 1);
        }
        
        ArrayResize(tradeSeries, ArraySize(tradeSeries) + 1);
        ArrayResize(profitSeries, ArraySize(profitSeries) + 1);
        
        tradeSeries[ArraySize(tradeSeries) - 1] = isWin;
        profitSeries[ArraySize(profitSeries) - 1] = profit;
    }
};