//+------------------------------------------------------------------+
//|                                          CorrelationAnalyzer.mqh |
//|                                                         Hirluin9 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hirluin9"
#property link      "https://www.mql5.com"

class CCorrelationAnalyzer {
private:
    int lookbackPeriod;
    double correlationMatrix[];
    string symbols[];
    int matrixSize;

public:
    CCorrelationAnalyzer(int period = 20) {
        lookbackPeriod = period;
        matrixSize = 0;
    }

    bool CalculateCorrelations(string &symbolList[]) {
        int symbolCount = ArraySize(symbolList);
        if(symbolCount == 0) return false;
        
        // Ridimensiona arrays
        ArrayResize(symbols, symbolCount);
        ArrayCopy(symbols, symbolList);
        
        // Ridimensiona matrice correlazione
        matrixSize = symbolCount;
        ArrayResize(correlationMatrix, symbolCount * symbolCount);
        
        return UpdateCorrelationMatrix();
    }

    double GetCorrelation(string symbol1, string symbol2) {
        int index1 = ArraySearch(symbols, symbol1);
        int index2 = ArraySearch(symbols, symbol2);
        
        if(index1 == -1 || index2 == -1) return 0;
        
        return correlationMatrix[index1 * matrixSize + index2];
    }

    bool UpdateCorrelationMatrix() {
        double prices1[], prices2[];
        ArraySetAsSeries(prices1, true);
        ArraySetAsSeries(prices2, true);
        
        for(int i = 0; i < matrixSize; i++) {
            for(int j = 0; j < matrixSize; j++) {
                if(i == j) {
                    correlationMatrix[i * matrixSize + j] = 1.0;
                    continue;
                }
                
                // Ottieni prezzi di chiusura
                if(!CopyClose(symbols[i], PERIOD_CURRENT, 0, lookbackPeriod, prices1) ||
                   !CopyClose(symbols[j], PERIOD_CURRENT, 0, lookbackPeriod, prices2)) {
                    return false;
                }
                
                correlationMatrix[i * matrixSize + j] = CalculatePearsonCorrelation(prices1, prices2);
            }
        }
        return true;
    }

private:
    int ArraySearch(string &array[], string value) {
        for(int i = 0; i < ArraySize(array); i++) {
            if(array[i] == value) return i;
        }
        return -1;
    }
    
    double CalculatePearsonCorrelation(double &x[], double &y[]) {
        int n = MathMin(ArraySize(x), ArraySize(y));
        if(n < 2) return 0;
        
        double sumX = 0, sumY = 0, sumXY = 0;
        double sumX2 = 0, sumY2 = 0;
        
        for(int i = 0; i < n; i++) {
            sumX += x[i];
            sumY += y[i];
            sumXY += x[i] * y[i];
            sumX2 += x[i] * x[i];
            sumY2 += y[i] * y[i];
        }
        
        double numerator = n * sumXY - sumX * sumY;
        double denominator = MathSqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
        
        return denominator == 0 ? 0 : numerator / denominator;
    }
};