class CPerformanceMetrics {
private:
    double returns[];
    double drawdowns[];
    int lookbackPeriod;
    
public:
    CPerformanceMetrics(int period = 100) {
        lookbackPeriod = period;
        ArrayResize(returns, 0);
        ArrayResize(drawdowns, 0);
    }
    
    double CalculateMaxDrawdown() {
        double maxEquity = 0;
        double maxDrawdown = 0;
        double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        
        for(int i = 0; i < ArraySize(drawdowns); i++) {
            if(drawdowns[i] > maxEquity) maxEquity = drawdowns[i];
            double drawdown = (maxEquity - drawdowns[i]) / maxEquity * 100;
            if(drawdown > maxDrawdown) maxDrawdown = drawdown;
        }
        
        return maxDrawdown;
    }
    
    double CalculateRecoveryFactor() {
        double netProfit = AccountInfoDouble(ACCOUNT_PROFIT);
        double maxDrawdown = CalculateMaxDrawdown();
        return maxDrawdown > 0 ? MathAbs(netProfit) / maxDrawdown : 0;
    }
    
    double CalculateExpectancy() {
        double winSum = 0, lossSum = 0;
        int wins = 0, losses = 0;
        
        for(int i = 0; i < ArraySize(returns); i++) {
            if(returns[i] > 0) {
                winSum += returns[i];
                wins++;
            } else {
                lossSum += MathAbs(returns[i]);
                losses++;
            }
        }
        
        double avgWin = wins > 0 ? winSum/wins : 0;
        double avgLoss = losses > 0 ? lossSum/losses : 0;
        double winRate = (double)wins/(wins + losses);
        
        return (winRate * avgWin) - ((1 - winRate) * avgLoss);
    }
    
    void UpdateMetrics() {
        UpdateReturns();
        UpdateDrawdowns();
    }
    
private:
    void UpdateReturns() {
        ulong ticket = HistoryDealGetTicket(HistoryDealsTotal() - 1);
        if(ticket > 0) {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            AddReturn(profit);
        }
    }
    
    void UpdateDrawdowns() {
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        AddDrawdown(equity);
    }
    
    void AddReturn(double value) {
        int size = ArraySize(returns);
        if(size >= lookbackPeriod) ArrayRemove(returns, 0, 1);
        ArrayResize(returns, ArraySize(returns) + 1);
        returns[ArraySize(returns) - 1] = value;
    }
    
    void AddDrawdown(double value) {
        int size = ArraySize(drawdowns);
        if(size >= lookbackPeriod) ArrayRemove(drawdowns, 0, 1);
        ArrayResize(drawdowns, ArraySize(drawdowns) + 1);
        drawdowns[ArraySize(drawdowns) - 1] = value;
    }
};