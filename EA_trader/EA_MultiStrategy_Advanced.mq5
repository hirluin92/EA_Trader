//+------------------------------------------------------------------+
//|                                    EA_MultiStrategy_Advanced.mq5    |
//+------------------------------------------------------------------+
#property copyright "Advanced Trading Systems"
#property link      "https://www.yoursite.com"
#property version   "2.00"
#property strict

// Input Parameters
input group "Trading Hours"
input string TRADING_START = "08:00";     // Trading Session Start
input string TRADING_END = "20:00";       // Trading Session End
input bool TRADE_MONDAY = true;           // Trade on Monday
input bool TRADE_FRIDAY = true;           // Trade on Friday

input group "Risk Management"
input double RISK_PERCENT = 2.0;          // Risk per trade (%)
input double MAX_DAILY_RISK = 6.0;        // Maximum daily risk (%)
input int MAX_DAILY_TRADES = 5;           // Maximum trades per day
input double MIN_RISK_REWARD = 1.5;       // Minimum risk/reward ratio

input group "Market Conditions"
input double MIN_VOLATILITY = 0.1;        // Minimum volatility threshold
input double MAX_SPREAD = 3.0;            // Maximum spread (points)
input int MIN_VOLUME = 100;               // Minimum volume threshold
input double PATTERN_THRESHOLD = 0.7;     // Pattern detection threshold

input group "Technical Parameters"
input int ATR_PERIOD = 14;                // ATR Period
input int RSI_PERIOD = 14;                // RSI Period
input double BB_DEVIATION = 2.0;          // Bollinger Bands deviation
input int MA_FAST_PERIOD = 20;            // Fast MA period
input int MA_SLOW_PERIOD = 50;            // Slow MA period

input group "Machine Learning"
input bool USE_ML = true;                 // Use Machine Learning
input double ML_THRESHOLD = 0.75;         // ML Signal Threshold
input int ML_LOOKBACK = 10;               // ML Lookback Period

input group "News Trading Settings"        // Nuovo gruppo per le news
input int NEWS_BUFFER = 30;               // Minutes before/after news
input bool TRADE_HIGH_IMPACT = false;     // Trade during high impact news
input bool TRADE_MED_IMPACT = true;       // Trade during medium impact news
input bool TRADE_LOW_IMPACT = true;       // Trade during low impact news

// Portfolio Parameters
input double MAX_PORTFOLIO_RISK = 20.0;     // Massimo rischio portfolio (%)
input double CORRELATION_THRESHOLD = 0.7;    // Soglia correlazione
input bool ALLOW_MULTIPLE_POSITIONS = false; // Permetti posizioni multiple

// Event Detection Parameters
input double VOLATILITY_SPIKE_THRESHOLD = 2.0; // Soglia spike volatilità
input double TREND_CHANGE_THRESHOLD = 1.5;     // Soglia cambio trend

// ML Parameters
input int LSTM_LAYERS = 2;                   // Numero layer LSTM
input int DENSE_NODES = 64;                  // Nodi layer denso
input double DROPOUT_RATE = 0.2;             // Rate dropout

// Performance Monitoring
input int PERFORMANCE_WINDOW = 100;          // Finestra analisi performance
input double MIN_SHARPE_RATIO = 1.0;         // Minimo Sharpe ratio
input double MIN_SORTINO_RATIO = 1.5;        // Minimo Sortino ratio

// Backup & Recovery
input int BACKUP_INTERVAL = 3600;            // Intervallo backup (secondi)
input bool AUTO_RESTORE = true;              // Ripristino automatico

// Include necessary files
#include <Analysis/SentimentAnalyzer.mqh>
#include <Analysis/VolatilityAnalyzer.mqh>
#include <Analysis/PatternDetector.mqh>
#include <ML/DeepLearning.mqh>
#include <Trading/OrderManager.mqh>
#include <Trading/PositionManager.mqh>
#include <Trading/StopManager.mqh>
#include <Core/IntradayManager.mqh>
#include <Core/RiskController.mqh>
#include <Core/MarketScanner.mqh>
#include <Statistics/Statistics.mqh>
#include <Core/NewsManager.mqh>
#include <Portfolio/PortfolioManager.mqh>
#include <Portfolio/CorrelationAnalyzer.mqh>
#include <Events/MarketEventManager.mqh>
#include <Events/EventDetector.mqh>
#include <ML/AdvancedMLAnalyzer.mqh>
#include <ML/FeatureEngineering.mqh>
#include <Statistics/AdvancedStatistics.mqh>
#include <Statistics/PerformanceMetrics.mqh>
#include <Portfolio/CorrelationAnalyzer.mqh>
#include <Portfolio/ExposureManager.mqh>
#include <Events/EventDetector.mqh>
#include <Events/EventProcessor.mqh>
#include <ML/FeatureEngineering.mqh>
#include <ML/ModelValidator.mqh>
#include <Statistics/PerformanceMetrics.mqh>
#include <Statistics/TradeAnalyzer.mqh>
#include <Analysis/MarketRegimeAnalyzer.mqh>
#include <Core/StrategyOptimizer.mqh>
#include <Utils/BackupManager.mqh>

// Global variables
CIntradayManager*    intraday = NULL;
CRiskController*     risk = NULL;
CMarketScanner*      scanner = NULL;
CPatternDetector*    pattern = NULL;
CVolatilityAnalyzer* volatility = NULL;
CSentimentAnalyzer*  sentiment = NULL;
CPositionManager*    position = NULL;
COrderManager*       order = NULL;
CStopManager*        stop = NULL;
CDeepLearning*       ml = NULL;
CStatistics*         stats = NULL;
CNewsManager*        news = NULL;
CPortfolioManager*     portfolio = NULL;
CMarketEventManager*   events = NULL;
CAdvancedMLAnalyzer*   mlAdvanced = NULL;
CAdvancedStatistics*   statsAdvanced = NULL;
CCorrelationAnalyzer*    correlation = NULL;
CExposureManager*        exposure = NULL;
CEventDetector*          eventDetector = NULL;
CEventProcessor*         eventProcessor = NULL;
CFeatureEngineering*     featureEng = NULL;
CModelValidator*         modelValidator = NULL;
CPerformanceMetrics*     perfMetrics = NULL;
CTradeAnalyzer*         tradeAnalyzer = NULL;
CMarketRegimeAnalyzer*   regimeAnalyzer = NULL;
CStrategyOptimizer*      optimizer = NULL;
CBackupManager*          backup = NULL;

// Global variables for logging
string g_LogFileName;
int g_LogHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Custom enums and structs                                          |
//+------------------------------------------------------------------+
enum TRADING_STATE {
    STATE_ALLOWED,
    STATE_MAX_TRADES_REACHED,
    STATE_MAX_RISK_REACHED,
    STATE_INVALID_TIME,
    STATE_HIGH_SPREAD,
    STATE_LOW_VOLUME,
    STATE_NEWS_TIME
};

struct TradeSignal {
    bool valid;
    ENUM_ORDER_TYPE direction;
    double probability;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    string reason;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialize logging
    g_LogFileName = "EA_Log_" + IntegerToString(TimeCurrent()) + ".txt";
    g_LogHandle = FileOpen(g_LogFileName, FILE_WRITE|FILE_TXT);
    if(g_LogHandle == INVALID_HANDLE) {
        Print("Error: Cannot create log file!");
        return INIT_FAILED;
    }
    
    // Create class instances
    intraday = new CIntradayManager();
    risk = new CRiskController(RISK_PERCENT);
    scanner = new CMarketScanner();
    pattern = new CPatternDetector();
    volatility = new CVolatilityAnalyzer();
    sentiment = new CSentimentAnalyzer();
    position = new CPositionManager(MAX_DAILY_TRADES);
    order = new COrderManager();
    stop = new CStopManager(MIN_RISK_REWARD);
    if(USE_ML) ml = new CDeepLearning();
    stats = new CStatistics();
    
    // Configure objects with input parameters
    scanner.SetMinVolatility(MIN_VOLATILITY);
    scanner.SetMaxSpread(MAX_SPREAD);
    scanner.SetMinVolume(MIN_VOLUME);
    // All'interno di OnInit()
      news = new CNewsManager();
      if(!news.Initialize()) {
          Print("Failed to initialize NewsManager");
          return INIT_FAILED;
      }
      news.SetNewsBuffer(NEWS_BUFFER);
      news.SetImpactFilters(TRADE_HIGH_IMPACT, TRADE_MED_IMPACT, TRADE_LOW_IMPACT);
          portfolio = new CPortfolioManager();
    events = new CMarketEventManager();
    advStats = new CAdvancedStatistics();
    
    if(!portfolio.Initialize() || 
       !events.Initialize() || 
       !advStats.Initialize()) {
        return INIT_FAILED;
    }
    // Initialize all components
    if(!InitializeAll()) {
        LogError("Initialization failed");
        return INIT_FAILED;
    }
    
    // Log successful initialization
    LogMessage("EA initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Clean up objects
    SafeDelete(intraday);
    SafeDelete(risk);
    SafeDelete(scanner);
    SafeDelete(pattern);
    SafeDelete(volatility);
    SafeDelete(sentiment);
    SafeDelete(position);
    SafeDelete(order);
    SafeDelete(stop);
    SafeDelete(ml);
    SafeDelete(stats);
    SafeDelete(news);
    SafeDelete(portfolio);
    SafeDelete(events);
    SafeDelete(advStats);
    // Close log file
    if(g_LogHandle != INVALID_HANDLE) {
        FileClose(g_LogHandle);
        g_LogHandle = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    // Check if we can trade
    TRADING_STATE state = GetTradingState();
    if(state != STATE_ALLOWED) {
        HandleTradingState(state);
        return;
    }
    
    // Update stop levels for existing positions
    stop.UpdateStopLevels();
    
    // Get current market conditions
    TradeSignal signal = AnalyzeMarket();
    
    // Execute trade if signal is valid
    if(signal.valid && position.CanOpenNewPosition()) {
        if(ExecuteTrade(signal)) {
            stats.UpdateStats();
            LogTrade(signal, true);
        } else {
            LogTrade(signal, false);
        }
    }
}

//+------------------------------------------------------------------+
//| Market analysis function                                          |
//+------------------------------------------------------------------+
TradeSignal AnalyzeMarket() {
    TradeSignal signal = {0};
    
    // Get all analysis components
    CPatternDetector::PATTERN_TYPE currentPattern = pattern.DetectPattern();
    VolatilityState volState = volatility.AnalyzeVolatility();
    SentimentData sentimentData = sentiment.GetCurrentSentiment();
    
    // Get ML signal if enabled
    MLSignal mlSignal = {0};
    if(USE_ML) mlSignal = ml.GetTradingSignal();
    
    // Validate all components
    if(!volState.isValid || !sentimentData.isValid) {
        signal.valid = false;
        signal.reason = "Invalid market conditions";
        return signal;
    }
    
    if(USE_ML && !mlSignal.isValid) {
        signal.valid = false;
        signal.reason = "Invalid ML signal";
        return signal;
    }
    
    // Determine trade direction
    signal.direction = DetermineTradeDirection(currentPattern, sentimentData, mlSignal);
    if(signal.direction == -1) {
        signal.valid = false;
        signal.reason = "No clear direction";
        return signal;
    }
    
    // Calculate entry and exit points
    CalculateEntryAndExits(signal);
    
    signal.valid = true;
    signal.probability = CalculateSignalProbability(currentPattern, sentimentData, mlSignal);
    
    return signal;
}

//+------------------------------------------------------------------+
//| Helper functions                                                  |
//+------------------------------------------------------------------+
template<typename T>
void SafeDelete(T*& ptr) {
    if(ptr != NULL) {
        delete ptr;
        ptr = NULL;
    }
}

void LogMessage(string message) {
    if(g_LogHandle != INVALID_HANDLE) {
        string logLine = TimeToString(TimeCurrent()) + ": " + message + "\n";
        FileWriteString(g_LogHandle, logLine);
    }
    Print(message);
}

void LogError(string error) {
    LogMessage("ERROR: " + error);
}

void LogTrade(const TradeSignal &signal, bool success) {
    string direction = (signal.direction == ORDER_TYPE_BUY) ? "BUY" : "SELL";
    string logMessage = StringFormat(
        "Trade %s: %s at %.5f, SL=%.5f, TP=%.5f, Prob=%.2f, Reason=%s",
        success ? "EXECUTED" : "FAILED",
        direction,
        signal.entryPrice,
        signal.stopLoss,
        signal.takeProfit,
        signal.probability,
        signal.reason
    );
    LogMessage(logMessage);
}

TRADING_STATE GetTradingState() {
    if(!intraday.IsValidTradingTime()) return STATE_INVALID_TIME;
    if(!scanner.CheckSpread()) return STATE_HIGH_SPREAD;
    if(!scanner.CheckVolume()) return STATE_LOW_VOLUME;
    if(IsNewsTime()) return STATE_NEWS_TIME;
    if(!position.CanOpenNewPosition()) return STATE_MAX_TRADES_REACHED;
    if(!risk.ValidateRisk()) return STATE_MAX_RISK_REACHED;
    return STATE_ALLOWED;
}

void HandleTradingState(TRADING_STATE state) {
    switch(state) {
        case STATE_MAX_TRADES_REACHED:
            LogMessage("Maximum daily trades reached");
            break;
        case STATE_MAX_RISK_REACHED:
            LogMessage("Maximum daily risk reached");
            break;
        case STATE_INVALID_TIME:
            LogMessage("Outside trading hours");
            break;
        case STATE_HIGH_SPREAD:
            LogMessage("Spread too high");
            break;
        case STATE_LOW_VOLUME:
            LogMessage("Volume too low");
            break;
        case STATE_NEWS_TIME:
            LogMessage("News time - trading paused");
            break;
    }
}

bool IsNewsTime() {
    return news.IsNewsTime();
}

ENUM_ORDER_TYPE DetermineTradeDirection(CPatternDetector::PATTERN_TYPE patternType,
                                      const SentimentData& sentimentState,
                                      const MLSignal& mlState) 
{
    if(patternType == CPatternDetector::PATTERN_TREND_CONTINUATION && 
       sentimentState.netSentiment > 0 && 
       mlState.direction > 0) {
        return ORDER_TYPE_BUY;
    }
    
    if(patternType == CPatternDetector::PATTERN_TREND_CONTINUATION && 
       sentimentState.netSentiment < 0 && 
       mlState.direction < 0) {
        return ORDER_TYPE_SELL;
    }
    
    return ORDER_TYPE_BUY; // Default o gestione altri casi
}

double CalculateSignalProbability(CPatternDetector::PATTERN_TYPE currentPattern,
                                const SentimentData &currentSentiment,
                                const MLSignal &mlSignal) 
{
    double patternWeight = 0.4;
    double sentimentWeight = 0.3;
    double mlWeight = 0.3;
    
    double patternProb = (currentPattern != CPatternDetector::PATTERN_NONE) ? 1.0 : 0.0;
    double sentimentProb = MathAbs(currentSentiment.netSentiment);
    double mlProb = mlSignal.probability;
    
    return patternProb * patternWeight +
           sentimentProb * sentimentWeight +
           mlProb * mlWeight;
}

void CalculateEntryAndExits(TradeSignal &signal) {
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, true);
    
    int atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATR_PERIOD);
    if(CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) > 0) {
        double atr = atrBuffer[0];
        
        if(signal.direction == ORDER_TYPE_BUY) {
            signal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            signal.stopLoss = signal.entryPrice - (atr * 2);
            signal.takeProfit = signal.entryPrice + (atr * 2 * MIN_RISK_REWARD);
        } else {
            signal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            signal.stopLoss = signal.entryPrice + (atr * 2);
            signal.takeProfit = signal.entryPrice - (atr * 2 * MIN_RISK_REWARD);
        }
    }
    IndicatorRelease(atrHandle);
}

bool ExecuteTrade(const TradeSignal &signal) {
    STradeParameters params;
    params.volume = risk.CalculatePositionSize(MathAbs(signal.entryPrice - signal.stopLoss));
    params.orderType = signal.direction;
    params.entryPrice = signal.entryPrice;
    params.stopLoss = signal.stopLoss;
    params.takeProfit = signal.takeProfit;
    params.isValid = true;
    
    int retries = 3;
    bool success = false;
    
    while(retries > 0 && !success) {
        success = order.ExecuteTrade(params);
        if(!success) {
            LogError(StringFormat("Trade execution failed, retry %d, error %d",
                     4-retries, GetLastError()));
            Sleep(1000);
            retries--;
        }
    }
    
    return success;
}

bool InitializeAll() {
    if(!intraday.Initialize()) return false;
    if(!risk.Initialize()) return false;
    if(!scanner.Initialize()) return false;
    if(!pattern.Initialize()) return false;
    if(!volatility.Initialize()) return false;
    if(!sentiment.Initialize()) return false;
    if(!position.Initialize()) return false;
    if(!order.Initialize()) return false;
    if(!stop.Initialize()) return false;
    if(USE_ML && !ml.Initialize()) return false;
    if(!stats.Initialize()) return false;
    return true;
}