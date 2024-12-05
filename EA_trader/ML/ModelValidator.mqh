// ModelValidator.mqh
#import "stdlib.mqh"
#import "Indicators.mqh"
class CModelValidator {
private:
    int validationWindow;
    double accuracyThreshold;
    double predictionHistory[];
    double actualHistory[];
    datetime lastValidation;

public:
    CModelValidator(int window = 100, double threshold = 0.6) {
        validationWindow = window;
        accuracyThreshold = threshold;
        lastValidation = 0;
        ArrayResize(predictionHistory, 0);
        ArrayResize(actualHistory, 0);
    }

    bool ValidateSignal(MLSignal &signal) {
        if (!UpdateHistoricalAccuracy()) {
            CLogger::Error("Failed to update historical accuracy");
            return false;
        }

        double currentAccuracy = GetModelAccuracy();
        if (currentAccuracy < accuracyThreshold) {
            signal.isValid = false;
            signal.probability *= (currentAccuracy / accuracyThreshold);
            return false;
        }

        signal.isValid = true;
        return true;
    }

    double GetModelAccuracy() {
        int size = MathMin(ArraySize(predictionHistory), ArraySize(actualHistory));
        if (size == 0) return 0.0;

        double correctPredictions = 0;
        for (int i = 0; i < size; i++) {
            if (MathAbs(predictionHistory[i] - actualHistory[i]) < 0.1) {
                correctPredictions++;
            }
        }
        return correctPredictions / size;
    }

    void AddPrediction(double prediction) {
        int size = ArraySize(predictionHistory);
        ArrayResize(predictionHistory, size + 1);
        predictionHistory[size] = prediction;
    }

    void UpdateValidationMetrics(double actual) {
        int size = ArraySize(predictionHistory);
        ArrayResize(actualHistory, size);
        actualHistory[size - 1] = actual;
        lastValidation = TimeCurrent();
    }

private:
    bool UpdateHistoricalAccuracy() {
        while (ArraySize(predictionHistory) > validationWindow) {
            ArrayRemove(predictionHistory, 0, 1);
            if (ArraySize(actualHistory) > 0) {
                ArrayRemove(actualHistory, 0, 1);
            }
        }
        return true;
    }
};
