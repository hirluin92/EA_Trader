#import "stdlib.mqh"
#import "Indicators.mqh"class CFeatureEngineering {
private:
    int featureWindow;
    double featureMatrix[];
    int indicatorHandles[];

public:
    CFeatureEngineering(int window = 20) {
        featureWindow = window;
        ArrayResize(indicatorHandles, 0);
    }

    ~CFeatureEngineering() {
        ReleaseIndicators();
    }

    bool PrepareFeatures() {
        if (!InitializeIndicators()) return false;

        ArrayResize(featureMatrix, featureWindow * 6);

        double rsi[], macd[], bb[], ma[], atr[], volume[];
        if (!CopyBuffers(rsi, macd, bb, ma, atr, volume)) return false;

        for (int i = 0; i < featureWindow; i++) {
            featureMatrix[i * 6] = rsi[i];
            featureMatrix[i * 6 + 1] = macd[i];
            featureMatrix[i * 6 + 2] = bb[i];
            featureMatrix[i * 6 + 3] = ma[i];
            featureMatrix[i * 6 + 4] = atr[i];
            featureMatrix[i * 6 + 5] = volume[i];
        }
        return NormalizeFeatures();
    }

    double[] GetFeatureMatrix() {
        return featureMatrix;
    }

private:
    bool InitializeIndicators() {
        ArrayResize(indicatorHandles, 5);
        indicatorHandles[0] = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
        indicatorHandles[1] = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
        indicatorHandles[2] = iBands(_Symbol, PERIOD_CURRENT, 20, 2, 0, PRICE_CLOSE);
        indicatorHandles[3] = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
        indicatorHandles[4] = iATR(_Symbol, PERIOD_CURRENT, 14);

        for (int i = 0; i < ArraySize(indicatorHandles); i++) {
            if (indicatorHandles[i] == INVALID_HANDLE) {
                CLogger::Error("Failed to initialize an indicator in CFeatureEngineering");
                return false;
            }
        }
        return true;
    }

    void ReleaseIndicators() {
        for (int i = 0; i < ArraySize(indicatorHandles); i++) {
            if (indicatorHandles[i] != INVALID_HANDLE) IndicatorRelease(indicatorHandles[i]);
        }
    }

    bool CopyBuffers(double &rsi[], double &macd[], double &bb[], double &ma[], double &atr[], double &volume[]) {
        if (!CopyBuffer(indicatorHandles[0], 0, 0, featureWindow, rsi) ||
            !CopyBuffer(indicatorHandles[1], 0, 0, featureWindow, macd) ||
            !CopyBuffer(indicatorHandles[2], 0, 0, featureWindow, bb) ||
            !CopyBuffer(indicatorHandles[3], 0, 0, featureWindow, ma) ||
            !CopyBuffer(indicatorHandles[4], 0, 0, featureWindow, atr) ||
            !CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, featureWindow, volume)) {
            CLogger::Error("Failed to copy buffers in CFeatureEngineering");
            return false;
        }
        return true;
    }

    bool NormalizeFeatures() {
        int features = 6;
        for (int f = 0; f < features; f++) {
            double min = DBL_MAX, max = DBL_MIN;
            for (int i = 0; i < featureWindow; i++) {
                double value = featureMatrix[i * features + f];
                if (value < min) min = value;
                if (value > max) max = value;
            }
            double range = max - min;
            if (range > 0) {
                for (int i = 0; i < featureWindow; i++) {
                    featureMatrix[i * features + f] = (featureMatrix[i * features + f] - min) / range;
                }
            }
        }
        return true;
    }
};
