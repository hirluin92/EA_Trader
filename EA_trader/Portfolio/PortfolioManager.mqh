#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

#include <Trading/PositionManager.mqh>
#include <Core/RiskController.mqh>
#include <Portfolio/CorrelationAnalyzer.mqh>
#include <Portfolio/ExposureManager.mqh>

class CPortfolioManager {
private:
    double maxPortfolioRisk;
    double currentPortfolioRisk;
    double correlationThreshold;
    bool allowMultiplePositions;
    string tradedSymbols[];
    
    CCorrelationAnalyzer* correlationAnalyzer;
    CExposureManager* exposureManager;
    
    struct SymbolCorrelation {
        string symbol1;
        string symbol2;
        double correlation;
        datetime lastUpdate;
    };
    SymbolCorrelation correlations[];
    
public:
    CPortfolioManager(double maxRisk = 20.0, double corrThreshold = 0.7) {
        maxPortfolioRisk = maxRisk;
        correlationThreshold = corrThreshold;
        allowMultiplePositions = false;
        currentPortfolioRisk = 0;
        
        correlationAnalyzer = new CCorrelationAnalyzer(20);
        exposureManager = new CExposureManager(0.5);
    }
    
    ~CPortfolioManager() {
        delete correlationAnalyzer;
        delete exposureManager;
    }
    
    bool Initialize() {
        if(!correlationAnalyzer.Initialize() || !exposureManager.Initialize())
            return false;
            
        currentPortfolioRisk = CalculateCurrentRisk();
        return UpdateCorrelations();
    }
    
    bool CanOpenPosition(string symbol, double riskAmount) {
        if(currentPortfolioRisk + riskAmount > maxPortfolioRisk)
            return false;
            
        if(!CheckCorrelations(symbol))
            return false;
            
        if(!allowMultiplePositions && HasOpenPosition(symbol))
            return false;
            
        return exposureManager.CheckExposure(symbol, CalculatePositionSize(symbol, riskAmount));
    }
    
private:
    double CalculateCurrentRisk() {
        double totalRisk = 0;
        for(int i = 0; i < ArraySize(tradedSymbols); i++) {
            if(PositionSelect(tradedSymbols[i])) {
                totalRisk += CalculatePositionRisk(tradedSymbols[i]);
            }
        }
        return totalRisk;
    }
    
    double CalculatePositionRisk(string symbol) {
        if(!PositionSelect(symbol)) return 0;
        
        double positionSize = PositionGetDouble(POSITION_VOLUME);
        double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double stopLoss = PositionGetDouble(POSITION_SL);
        
        if(stopLoss == 0) return 0;
        
        double riskPerPoint = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        double points = MathAbs(entryPrice - stopLoss) / SymbolInfoDouble(symbol, SYMBOL_POINT);
        
        return (points * riskPerPoint * positionSize);
    }
    
    bool CheckCorrelations(string symbol) {
        for(int i = 0; i < ArraySize(tradedSymbols); i++) {
            if(PositionSelect(tradedSymbols[i])) {
                double correlation = correlationAnalyzer.GetCorrelation(symbol, tradedSymbols[i]);
                if(MathAbs(correlation) > correlationThreshold)
                    return false;
            }
        }
        return true;
    }
    
    bool HasOpenPosition(string symbol) {
        return PositionSelect(symbol);
    }
    
    bool UpdateCorrelations() {
        return correlationAnalyzer.CalculateCorrelations(tradedSymbols);
    }
    
    double CalculatePositionSize(string symbol, double riskAmount) {
        double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        double sl = GetDynamicStopLoss(symbol, ask);
        
        if(sl == 0) return 0;
        
        double points = MathAbs(ask - sl) / SymbolInfoDouble(symbol, SYMBOL_POINT);
        return NormalizeDouble(riskAmount / (points * tickValue), 2);
    }
    
    double GetDynamicStopLoss(string symbol, double price) {
        // Implementa la tua logica per il calcolo dello stop loss dinamico
        return price * 0.99; // Esempio: SL all'1%
    }
};