#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

#include <Events/MarketEventManager.mqh>

class CEventProcessor {
private:
    double eventImpactMatrix[];
    int eventHistory[];
    int maxHistorySize;
    double impactDecayFactor;
    double minImpactThreshold;
    
public:
    CEventProcessor(int historySize = 100) {
        maxHistorySize = historySize;
        impactDecayFactor = 0.95;  // 5% decay per interval
        minImpactThreshold = 0.1;
        ArrayResize(eventHistory, 0);
        InitializeImpactMatrix();
    }
    
    void ProcessEvent(MarketEvent& event) {
        // Aggiunge evento alla storia
        AddToHistory(event);
        
        // Calcola impatto totale
        double totalImpact = CalculateTotalImpact(event);
        
        // Aggiorna matrice impatti
        UpdateImpactMatrix(event.type, totalImpact);
        
        // Marca evento come processato
        event.processed = true;
    }
    
    bool ShouldModifyPositions() {
        return GetCurrentTotalImpact() > minImpactThreshold;
    }
    
    double GetEventImpact(ENUM_MARKET_EVENT_TYPE eventType) {
        return eventImpactMatrix[eventType];
    }

private:
    void InitializeImpactMatrix() {
        ArrayResize(eventImpactMatrix, 4); // Per i 4 tipi di evento
        ArrayInitialize(eventImpactMatrix, 0);
    }
    
    void AddToHistory(const MarketEvent& event) {
        if(ArraySize(eventHistory) >= maxHistorySize) {
            RemoveOldestEvent();
        }
        
        int size = ArraySize(eventHistory);
        ArrayResize(eventHistory, size + 1);
        eventHistory[size] = (int)event.type;
    }
    
    void RemoveOldestEvent() {
        int size = ArraySize(eventHistory);
        for(int i = 0; i < size - 1; i++) {
            eventHistory[i] = eventHistory[i + 1];
        }
        ArrayResize(eventHistory, size - 1);
    }
    
    double CalculateTotalImpact(const MarketEvent& event) {
        double baseImpact = event.impact;
        double frequencyMultiplier = CalculateFrequencyMultiplier(event.type);
        double severityMultiplier = CalculateSeverityMultiplier(event.impact);
        
        return baseImpact * frequencyMultiplier * severityMultiplier;
    }
    
    double CalculateFrequencyMultiplier(ENUM_MARKET_EVENT_TYPE eventType) {
        int count = 0;
        for(int i = 0; i < ArraySize(eventHistory); i++) {
            if(eventHistory[i] == (int)eventType) count++;
        }
        
        return 1.0 + (count * 0.1); // Aumenta 10% per ogni occorrenza
    }
    
    double CalculateSeverityMultiplier(double impact) {
        return impact > 2.0 ? 1.5 : 1.0; // 50% extra per eventi ad alto impatto
    }
    
    void UpdateImpactMatrix(ENUM_MARKET_EVENT_TYPE eventType, double impact) {
        // Applica decay a tutti gli impatti
        for(int i = 0; i < ArraySize(eventImpactMatrix); i++) {
            eventImpactMatrix[i] *= impactDecayFactor;
            if(eventImpactMatrix[i] < minImpactThreshold) {
                eventImpactMatrix[i] = 0;
            }
        }
        
        // Aggiunge nuovo impatto
        eventImpactMatrix[eventType] += impact;
    }
    
    double GetCurrentTotalImpact() {
        double total = 0;
        for(int i = 0; i < ArraySize(eventImpactMatrix); i++) {
            total += eventImpactMatrix[i];
        }
        return total;
    }
    
    void Reset() {
        ArrayResize(eventHistory, 0);
        ArrayInitialize(eventImpactMatrix, 0);
    }
};