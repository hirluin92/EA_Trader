#include <Analysis/VolatilityAnalyzer.mqh>
#include <Analysis/PatternDetector.mqh>
#include <Events/EventDetector.mqh>
#include <Events/EventProcessor.mqh>

class CMarketEventManager {
private:
    struct MarketEvent {
        datetime time;
        ENUM_MARKET_EVENT_TYPE type;
        double impact;
        bool processed;
        string description;
    };
    
    MarketEvent events[];
    CEventDetector* eventDetector;
    CEventProcessor* eventProcessor;
    double eventThreshold;
    int maxEvents;
    datetime lastUpdate;
    double impactMultiplier;
    
public:
    enum ENUM_MARKET_EVENT_TYPE {
        EVENT_VOLATILITY_SPIKE,
        EVENT_TREND_CHANGE,
        EVENT_LIQUIDITY_DROP,
        EVENT_CORRELATION_BREAK
    };
    
    CMarketEventManager(double threshold = 2.0, double multiplier = 1.0) {
        eventThreshold = threshold;
        maxEvents = 100;
        impactMultiplier = multiplier;
        lastUpdate = 0;
        
        eventDetector = new CEventDetector();
        eventProcessor = new CEventProcessor();
        ArrayResize(events, 0);
    }
    
    ~CMarketEventManager() {
        delete eventDetector;
        delete eventProcessor;
    }
    
    bool Initialize() {
        if(!eventDetector.Initialize()) {
            Print("Failed to initialize EventDetector");
            return false;
        }
        
        lastUpdate = TimeCurrent();
        return true;
    }
    
    void DetectEvents() {
        if(!ShouldUpdateEvents()) return;
        
        if(eventDetector.DetectVolatilitySpike()) {
            double magnitude = eventDetector.GetVolatilityMagnitude();
            AddEvent(EVENT_VOLATILITY_SPIKE, 2.0 * magnitude * impactMultiplier,
                    "Volatility spike detected: " + DoubleToString(magnitude, 2));
        }
        
        if(eventDetector.DetectTrendChange()) {
            double strength = eventDetector.GetTrendMagnitude();
            AddEvent(EVENT_TREND_CHANGE, 1.5 * strength * impactMultiplier,
                    "Trend change detected: " + DoubleToString(strength, 2));
        }
        
        if(eventDetector.DetectLiquidityEvent()) {
            AddEvent(EVENT_LIQUIDITY_DROP, 1.0 * impactMultiplier,
                    "Liquidity drop detected");
        }
        
        CheckCorrelationBreaks();
        lastUpdate = TimeCurrent();
    }
    
    bool ShouldAdjustStrategy() {
        ProcessPendingEvents();
        return eventProcessor.ShouldModifyPositions();
    }
    
    MarketEvent GetLastEvent() {
        int size = ArraySize(events);
        if(size > 0) return events[size-1];
        
        MarketEvent emptyEvent = {0};
        return emptyEvent;
    }
    
    double GetCurrentImpact(ENUM_MARKET_EVENT_TYPE type) {
        return eventProcessor.GetEventImpact(type);
    }
    
private:
    void AddEvent(ENUM_MARKET_EVENT_TYPE type, double impact, string description) {
        int size = ArraySize(events);
        if(size >= maxEvents) RemoveOldEvents();
        
        size = ArraySize(events);
        ArrayResize(events, size + 1);
        
        events[size].time = TimeCurrent();
        events[size].type = type;
        events[size].impact = impact;
        events[size].processed = false;
        events[size].description = description;
        
        Print("New market event: ", description);
    }
    
    void RemoveOldEvents() {
        datetime currentTime = TimeCurrent();
        int validEvents = 0;
        
        for(int i = 0; i < ArraySize(events); i++) {
            if(currentTime - events[i].time < 24*3600) {
                if(validEvents != i) events[validEvents] = events[i];
                validEvents++;
            }
        }
        
        ArrayResize(events, validEvents);
    }
    
    void ProcessPendingEvents() {
        for(int i = 0; i < ArraySize(events); i++) {
            if(!events[i].processed) {
                eventProcessor.ProcessEvent(events[i]);
            }
        }
    }
    
private:
    void CheckCorrelationBreaks() {
        const int CORRELATION_PERIOD = 20;
        const double CORRELATION_THRESHOLD = 0.7;
        const double BREAK_THRESHOLD = 0.3;
        
        // Array per prezzi di chiusura
        double prices1[], prices2[];
        ArraySetAsSeries(prices1, true);
        ArraySetAsSeries(prices2, true);
        
        // Ottiene i simboli correlati dal portfolio manager
        string symbols[] = {"EURUSD", "GBPUSD", "USDJPY", "USDCHF"}; // Esempio, dovresti ottenere questi dal PortfolioManager
        
        // Controlla le correlazioni tra coppie di simboli
        for(int i = 0; i < ArraySize(symbols); i++) {
            for(int j = i + 1; j < ArraySize(symbols); j++) {
                // Copia i prezzi per entrambi i simboli
                if(!CopyClose(symbols[i], PERIOD_CURRENT, 0, CORRELATION_PERIOD, prices1) ||
                   !CopyClose(symbols[j], PERIOD_CURRENT, 0, CORRELATION_PERIOD, prices2)) {
                    continue;
                }
                
                // Calcola correlazione attuale e precedente
                double currentCorr = CalculateCorrelation(prices1, prices2, 10);  // Ultimi 10 periodi
                double historicalCorr = CalculateCorrelation(prices1, prices2, CORRELATION_PERIOD);  // Intero periodo
                
                // Verifica break di correlazione
                if(MathAbs(historicalCorr) > CORRELATION_THRESHOLD && 
                   MathAbs(currentCorr - historicalCorr) > BREAK_THRESHOLD) {
                    string desc = StringFormat("Correlation break between %s and %s: %.2f -> %.2f",
                                            symbols[i], symbols[j], historicalCorr, currentCorr);
                    AddEvent(EVENT_CORRELATION_BREAK, 1.5, desc);
                }
            }
        }
    }
    
    double CalculateCorrelation(const double &x[], const double &y[], const int period) {
        if(ArraySize(x) < period || ArraySize(y) < period) return 0;
        
        double sumX = 0, sumY = 0, sumXY = 0;
        double sumX2 = 0, sumY2 = 0;
        
        for(int i = 0; i < period; i++) {
            sumX += x[i];
            sumY += y[i];
            sumXY += x[i] * y[i];
            sumX2 += x[i] * x[i];
            sumY2 += y[i] * y[i];
        }
        
        double n = (double)period;
        double numerator = (n * sumXY) - (sumX * sumY);
        double denominator = MathSqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
        
        return denominator == 0 ? 0 : numerator / denominator;
    }
    
    bool ShouldUpdateEvents() {
        datetime currentTime = TimeCurrent();
        return (currentTime - lastUpdate >= 60); // Aggiorna ogni minuto
    }
};