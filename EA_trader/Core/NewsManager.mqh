//+------------------------------------------------------------------+
//|                                                 NewsManager.mqh    |
//|                                                         Hirluin9 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

// Struttura per eventi economici
struct NewsEvent {
    datetime time;
    string currency;
    string event;
    int impact;      // 1-low, 2-medium, 3-high
    bool actual;     // true se l'evento è già accaduto
};

class CNewsManager {
private:
    NewsEvent news[];
    long newsTotal;
    int newsBuffer;
    string currencies[];
    bool useHighImpact;
    bool useMediumImpact;
    bool useLowImpact;
    
    // Nuova funzione per validare l'impatto
    int ValidateImpact(const string &impactStr) {
        long impactValue = StringToInteger(impactStr);
        
        // Validazione del range
        if(impactValue < 1 || impactValue > 3) {
            Print("Invalid impact value: ", impactStr, ", defaulting to low impact");
            return 1; // Default a basso impatto
        }
        
        return (int)impactValue;
    }
    
    bool LoadNewsFromFile() {
        int handle = FileOpen("news_calendar.csv", FILE_READ|FILE_CSV|FILE_ANSI, ',');
        if(handle == INVALID_HANDLE) return false;
        
        newsTotal = 0;
        ArrayResize(news, 1000);
        
        while(!FileIsEnding(handle)) {
            NewsEvent event;
            
            string dateStr = FileReadString(handle);
            string timeStr = FileReadString(handle);
            event.currency = FileReadString(handle);
            event.event = FileReadString(handle);
            event.impact = ValidateImpact(FileReadString(handle)); // Usando la nuova funzione
            
            event.time = StringToTime(dateStr + " " + timeStr);
            event.actual = (TimeCurrent() > event.time);
            
            if(newsTotal >= ArraySize(news)) 
                ArrayResize(news, (int)(newsTotal + 1000));
                
            news[newsTotal++] = event;
        }
        
        FileClose(handle);
        ArrayResize(news, (int)newsTotal);
        return true;
    }
    
    bool IsRelevantCurrency(string currency) {
        for(int i = 0; i < ArraySize(currencies); i++)
            if(currencies[i] == currency) return true;
        return false;
    }

public:
    CNewsManager() {
        newsBuffer = 30;  // 30 minuti default
        newsTotal = 0;
        useHighImpact = true;
        useMediumImpact = true;
        useLowImpact = false;
        
        // Imposta le valute da monitorare basandosi sul simbolo corrente
        string baseCurrency = StringSubstr(_Symbol, 0, 3);
        string quoteCurrency = StringSubstr(_Symbol, 3, 3);
        ArrayResize(currencies, 2);
        currencies[0] = baseCurrency;
        currencies[1] = quoteCurrency;
    }
    
    bool Initialize() {
        return LoadNewsFromFile();
    }
    
    bool IsNewsTime() {
        datetime currentTime = TimeCurrent();
        
        for(long i = 0; i < newsTotal; i++) {  // Cambiato da int a long
            // Salta news vecchie o non rilevanti
            if(news[i].actual) continue;
            if(!IsRelevantCurrency(news[i].currency)) continue;
            
            // Controlla l'impatto
            if(news[i].impact == 3 && !useHighImpact) continue;
            if(news[i].impact == 2 && !useMediumImpact) continue;
            if(news[i].impact == 1 && !useLowImpact) continue;
            
            // Verifica se siamo nel buffer temporale
            if(MathAbs(news[i].time - currentTime) <= newsBuffer * 60) {
                return true;
            }
        }
        return false;
    }
    
    // Getters e Setters
    void SetNewsBuffer(int minutes) { newsBuffer = minutes; }
    void SetImpactFilters(bool high, bool medium, bool low) {
        useHighImpact = high;
        useMediumImpact = medium;
        useLowImpact = low;
    }
    
    // Aggiunge una valuta da monitorare
    void AddCurrency(string currency) {
        int size = ArraySize(currencies);
        ArrayResize(currencies, size + 1);
        currencies[size] = currency;
    }
    
    // Ottieni informazioni sulle prossime news
    bool GetNextNews(NewsEvent &nextEvent) {
        datetime currentTime = TimeCurrent();
        datetime nextTime = D'2050.01.01';
        long nextIndex = -1;  // Cambiato da int a long
        
        for(long i = 0; i < newsTotal; i++) {  // Cambiato da int a long
            if(news[i].actual) continue;
            if(!IsRelevantCurrency(news[i].currency)) continue;
            
            if(news[i].time > currentTime && news[i].time < nextTime) {
                nextTime = news[i].time;
                nextIndex = i;
            }
        }
        
        if(nextIndex >= 0) {
            nextEvent = news[nextIndex];
            return true;
        }
        
        return false;
    }
    
    // Pulizia delle news vecchie
    void CleanupOldNews() {
        datetime currentTime = TimeCurrent();
        long validNews = 0;  // Cambiato da int a long
        
        for(long i = 0; i < newsTotal; i++) {  // Cambiato da int a long
            if(!news[i].actual) {
                if(validNews != i)
                    news[validNews] = news[i];
                validNews++;
            }
        }
        
        if(validNews < newsTotal) {
            newsTotal = validNews;
            ArrayResize(news, (int)newsTotal);  // Cast esplicito per ArrayResize
        }
    }
};