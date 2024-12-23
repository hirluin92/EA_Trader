//+------------------------------------------------------------------+
//|                                              PositionManager.mqh |
//|                                                         Hirluin9 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

#include <Trade/Trade.mqh>

class CPositionManager {
private:
    int maxPositions;
    int currentPositions;
    double totalExposure;
    CTrade trade;
    
    void CalculateTotalExposure() {
        totalExposure = 0;
        for(int i = 0; i < PositionsTotal(); i++) {
            if(PositionSelectByTicket(PositionGetTicket(i))) {
                totalExposure += PositionGetDouble(POSITION_VOLUME);
            }
        }
    }  

public:
    CPositionManager(int maxPos = 5) {
        maxPositions = maxPos;
        currentPositions = 0;
        totalExposure = 0;
    }
    
    bool Initialize() {
        UpdateCurrentPositions();
        return true;
    }
    
    bool CanOpenNewPosition() {
        UpdateCurrentPositions();
        return currentPositions < maxPositions;
    }
    
    void UpdateCurrentPositions() {
        currentPositions = PositionsTotal();
        CalculateTotalExposure();
    }
    
    // Getter per l'esposizione totale
    double GetTotalExposure() const {
        return totalExposure;
    }
    
    // Getter per il numero di posizioni correnti
    int GetCurrentPositions() const {
        return currentPositions;
    }
    
    // Verifica se una posizione specifica è aperta
    bool IsPositionOpen(ulong ticket) {
        return PositionSelectByTicket(ticket);
    }
    
    // Chiude tutte le posizioni aperte
    bool CloseAllPositions() {
        bool result = true;
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if(ticket > 0) {
                if(!trade.PositionClose(ticket)) {
                    result = false;
                }
            }
        }
        return result;
    }
};