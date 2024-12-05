#property copyright "Hirluin9";
#property link      "https://www.mql5.com";

#include "DataStructures.mqh"
#include "Forward.mqh"

class CPatternDetector {
private:
   int lookbackPeriod;
   double patternThreshold;
   int ma20Handle;
   int ma50Handle;
   int rsiHandle;
   int bandsHandle;
   int atrHandle;
   
   bool IsTrendContinuation() {
       double ma20Buffer[], ma50Buffer[], closeBuffer[];
       ArraySetAsSeries(ma20Buffer, true);
       ArraySetAsSeries(ma50Buffer, true);
       ArraySetAsSeries(closeBuffer, true);
       
       if(CopyBuffer(ma20Handle, 0, 0, 1, ma20Buffer) <= 0 ||
          CopyBuffer(ma50Handle, 0, 0, 1, ma50Buffer) <= 0 ||
          CopyClose(_Symbol, PERIOD_CURRENT, 0, 1, closeBuffer) <= 0)
           return false;
       
       return (closeBuffer[0] > ma20Buffer[0] && ma20Buffer[0] > ma50Buffer[0]) || 
              (closeBuffer[0] < ma20Buffer[0] && ma20Buffer[0] < ma50Buffer[0]);
   }
   
   bool IsTrendReversal() {
       double rsiBuffer[];
       ArraySetAsSeries(rsiBuffer, true);
       
       if(CopyBuffer(rsiHandle, 0, 0, 1, rsiBuffer) <= 0)
           return false;
       
       return (rsiBuffer[0] > 70.0 || rsiBuffer[0] < 30.0);
   }
   
   bool IsBreakout() {
       double upperBuffer[], lowerBuffer[], closeBuffer[];
       ArraySetAsSeries(upperBuffer, true);
       ArraySetAsSeries(lowerBuffer, true);
       ArraySetAsSeries(closeBuffer, true);
       
       if(CopyBuffer(bandsHandle, 1, 0, 1, upperBuffer) <= 0 ||  
          CopyBuffer(bandsHandle, 2, 0, 1, lowerBuffer) <= 0 ||
          CopyClose(_Symbol, PERIOD_CURRENT, 0, 1, closeBuffer) <= 0)
           return false;
       
       return (closeBuffer[0] > upperBuffer[0] || closeBuffer[0] < lowerBuffer[0]);
   }
   
   bool IsRange() {
       double atrBuffer[], avgAtr = 0;
       ArraySetAsSeries(atrBuffer, true);
       
       if(CopyBuffer(atrHandle, 0, 0, lookbackPeriod, atrBuffer) <= 0)
           return false;
       
       for(int i = 1; i < lookbackPeriod; i++) {
           avgAtr += atrBuffer[i];
       }
       avgAtr /= (lookbackPeriod - 1);
       
       return (atrBuffer[0] < avgAtr * patternThreshold);
   }
   
public:
   enum PATTERN_TYPE {
       PATTERN_NONE = 0,
       PATTERN_TREND_CONTINUATION,
       PATTERN_TREND_REVERSAL,
       PATTERN_BREAKOUT,
       PATTERN_RANGE
   };
   
   CPatternDetector(int period = 20, double threshold = 0.7) {
       lookbackPeriod = period;
       patternThreshold = threshold;
       ma20Handle = INVALID_HANDLE;
       ma50Handle = INVALID_HANDLE;
       rsiHandle = INVALID_HANDLE;
       bandsHandle = INVALID_HANDLE;
       atrHandle = INVALID_HANDLE;
   }
   
   bool Initialize() {
       ma20Handle = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
       ma50Handle = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE);
       rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
       bandsHandle = iBands(_Symbol, PERIOD_CURRENT, 20, 2.0, 0.0, PRICE_CLOSE);
       atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
       
       return ma20Handle != INVALID_HANDLE && 
              ma50Handle != INVALID_HANDLE && 
              rsiHandle != INVALID_HANDLE && 
              bandsHandle != INVALID_HANDLE && 
              atrHandle != INVALID_HANDLE;
   }
   
   void Deinit() {
       if(ma20Handle != INVALID_HANDLE) IndicatorRelease(ma20Handle);
       if(ma50Handle != INVALID_HANDLE) IndicatorRelease(ma50Handle);
       if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
       if(bandsHandle != INVALID_HANDLE) IndicatorRelease(bandsHandle);
       if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
       
       ma20Handle = INVALID_HANDLE;
       ma50Handle = INVALID_HANDLE;
       rsiHandle = INVALID_HANDLE;
       bandsHandle = INVALID_HANDLE;
       atrHandle = INVALID_HANDLE;
   }
   
   PATTERN_TYPE DetectPattern() {
       if(IsTrendContinuation()) return PATTERN_TREND_CONTINUATION;
       if(IsTrendReversal()) return PATTERN_TREND_REVERSAL;
       if(IsBreakout()) return PATTERN_BREAKOUT;
       if(IsRange()) return PATTERN_RANGE;
       return PATTERN_NONE;
   }
   
   void SetPatternThreshold(double threshold) {
       patternThreshold = MathMax(0.1, MathMin(1.0, threshold));
   }
   
   void SetLookbackPeriod(int period) {
       lookbackPeriod = MathMax(10, MathMin(100, period));
   }
   
   double GetPatternThreshold() const { return patternThreshold; }
   int GetLookbackPeriod() const { return lookbackPeriod; }
   
   ~CPatternDetector() {
       Deinit();
   }
};