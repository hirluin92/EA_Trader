#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

#include <Math/Stat/Stat.mqh>

class CStatistics {
private:
    int totalTrades;
    double winRate;
    double profitFactor;
    double sharpeRatio;
    
    double CalculateWinRate() {
        int wins = 0;
        ulong ticket;
        
        for(int i = 0; i < HistoryDealsTotal(); i++) {
            ticket = HistoryDealGetTicket(i);
            if(ticket > 0) {
                double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                if(profit > 0) wins++;
            }
        }
        return totalTrades > 0 ? (double)wins/totalTrades : 0;
    }
    
    double CalculateProfitFactor() {
        double grossProfit = 0, grossLoss = 0;
        ulong ticket;
        
        for(int i = 0; i < HistoryDealsTotal(); i++) {
            ticket = HistoryDealGetTicket(i);
            if(ticket > 0) {
                double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                if(profit > 0) 
                    grossProfit += profit;
                else 
                    grossLoss += MathAbs(profit);
            }
        }
        return grossLoss > 0 ? grossProfit/grossLoss : 0;
    }
    
    double CalculateSharpeRatio() {
        if(totalTrades == 0) return 0;
        
        double returns[];
        ArrayResize(returns, totalTrades);
        ulong ticket;
        int validTrades = 0;
        double avgReturn = 0;
        
        for(int i = 0; i < HistoryDealsTotal() && validTrades < totalTrades; i++) {
            ticket = HistoryDealGetTicket(i);
            if(ticket > 0) {
                returns[validTrades] = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                avgReturn += returns[validTrades];
                validTrades++;
            }
        }
        
        if(validTrades > 0) {
            avgReturn /= validTrades;
            double sum = 0;
            for(int i = 0; i < validTrades; i++) {
                sum += MathPow(returns[i] - avgReturn, 2);
            }
            double stdDev = MathSqrt(sum / validTrades);
            
            return stdDev > 0 ? avgReturn/stdDev : 0;
        }
        return 0;
    }
    
public:
    virtual double GetAverageReturn() {
        if(totalTrades == 0) return 0;
        double total = 0;
        ulong ticket;
        
        for(int i = 0; i < HistoryDealsTotal() && i < totalTrades; i++) {
            ticket = HistoryDealGetTicket(i);
            if(ticket > 0) {
                total += HistoryDealGetDouble(ticket, DEAL_PROFIT);
            }
        }
        return totalTrades > 0 ? total/totalTrades : 0;
    }
    
    CStatistics() {
        Reset();
    }
    
    bool Initialize() {
        Reset();
        return true;
    }
    
    void UpdateStats() {
        totalTrades++;
        CalculateMetrics();
    }
    
    void Reset() {
        totalTrades = 0;
        winRate = 0;
        profitFactor = 0;
        sharpeRatio = 0;
    }
    
    void CalculateMetrics() {
        winRate = CalculateWinRate();
        profitFactor = CalculateProfitFactor();
        sharpeRatio = CalculateSharpeRatio();
    }
    
    double GetWinRate() const { return winRate; }
    double GetProfitFactor() const { return profitFactor; }
    double GetSharpeRatio() const { return sharpeRatio; }
    int GetTotalTrades() const { return totalTrades; }
};