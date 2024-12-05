struct AdvancedStats {
    double sharpeRatio;
    double sortinoRatio;
    double maxDrawdown;
    double profitFactor;
    double recoveryFactor;
    double expectancy;
    int consecutiveWins;
    int consecutiveLosses;
    datetime lastUpdateTime;
};

class CAdvancedStatistics : public CStatistics {
private:
    AdvancedStats stats;
    double trades[];
    double returns[];
    CPerformanceMetrics* perfMetrics;
    CTradeAnalyzer* tradeAnalyzer;
    
public:
    CAdvancedStatistics() {
        perfMetrics = new CPerformanceMetrics();
        tradeAnalyzer = new CTradeAnalyzer();
    }
    
    ~CAdvancedStatistics() {
        delete perfMetrics;
        delete tradeAnalyzer;
    }
    
    bool Initialize() {
        if(!CStatistics::Initialize()) return false;
        stats.lastUpdateTime = TimeCurrent();
        return true;
    }
    
    void UpdateAdvancedStats() {
        UpdateBasicStats();
        CalculateAdvancedMetrics();
        perfMetrics.UpdateMetrics();
        tradeAnalyzer.AnalyzeTradeSequence();
        stats.lastUpdateTime = TimeCurrent();
    }
    
    AdvancedStats GetStats() {
        return stats;
    }
    
private:
    void CalculateAdvancedMetrics() {
        stats.sharpeRatio = CalculateSharpeRatio();
        stats.sortinoRatio = CalculateSortinoRatio();
        stats.maxDrawdown = perfMetrics.CalculateMaxDrawdown();
        stats.recoveryFactor = perfMetrics.CalculateRecoveryFactor();
        stats.expectancy = perfMetrics.CalculateExpectancy();
        UpdateConsecutiveWinLoss();
    }
    
    double CalculateSortinoRatio() {
        double negativeReturns[];
        int negCount = 0;
        
        for(int i = 0; i < ArraySize(returns); i++) {
            if(returns[i] < 0) {
                ArrayResize(negativeReturns, negCount + 1);
                negativeReturns[negCount++] = returns[i];
            }
        }
        
        double avgNeg = 0;
        for(int i = 0; i < negCount; i++)
            avgNeg += negativeReturns[i];
        avgNeg /= negCount;
        
        double sumSquares = 0;
        for(int i = 0; i < negCount; i++)
            sumSquares += MathPow(negativeReturns[i] - avgNeg, 2);
            
        double downside_dev = MathSqrt(sumSquares / negCount);
        
        return downside_dev == 0 ? 0 : GetAverageReturn() / downside_dev;
    }
    
    void UpdateConsecutiveWinLoss() {
        stats.consecutiveWins = tradeAnalyzer.GetConsecutiveWins();
        stats.consecutiveLosses = tradeAnalyzer.GetConsecutiveLosses();
    }
    
    double GetAverageReturn() {
        if(ArraySize(returns) == 0) return 0;
        double sum = 0;
        for(int i = 0; i < ArraySize(returns); i++)
            sum += returns[i];
        return sum / ArraySize(returns);
    }
};
