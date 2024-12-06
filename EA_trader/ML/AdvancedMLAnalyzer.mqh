#import "stdlib.mqh"
#import "Indicators.mqh"
class CAdvancedMLAnalyzer : public CDeepLearning {
private:
    double featureMatrix[];
    double predictionConfidence;
    int modelState;
    int lstmLayers;
    int denseNodes;
    double dropoutRate;
    CFeatureEngineering *featureEng;
    CModelValidator *validator;

public:
    CAdvancedMLAnalyzer() : CDeepLearning() {
        lstmLayers = 2;
        denseNodes = 64;
        dropoutRate = 0.2;
        predictionConfidence = 0;
        modelState = 0;
        featureEng = new CFeatureEngineering();
        validator = new CModelValidator();
    }

    ~CAdvancedMLAnalyzer() {
        delete featureEng;
        delete validator;
    }

    bool Initialize() {
        if (!CDeepLearning::Initialize()) return false;
        if (!featureEng->PrepareFeatures()) {
            CLogger::Error("Feature Engineering initialization failed");
            return false;
        }

        featureMatrix = featureEng->GetFeatureMatrix();
        return ArraySize(featureMatrix) > 0;
    }

    MLSignal GetEnhancedSignal() {
        MLSignal baseSignal = GetTradingSignal();

        if (!validator->ValidateSignal(baseSignal)) {
            CLogger::Log("Signal not validated");
            return baseSignal;
        }

        return EnhanceSignal(baseSignal);
    }

private:
    MLSignal EnhanceSignal(MLSignal &baseSignal) {
        baseSignal.probability = CalculateEnhancedProbability(baseSignal);
        validator->AddPrediction(baseSignal.probability);
        return baseSignal;
    }

    double CalculateEnhancedProbability(const MLSignal &signal) {
        double enhancedProb = signal.probability;
        enhancedProb *= (0.5 + predictionConfidence * 0.5);

        if (modelState > 0) {
            enhancedProb *= 1.1;
        } else if (modelState < 0) {
            enhancedProb *= 0.9;
        }

        return MathMin(enhancedProb, 1.0);
    }

    void UpdateModelState() {
        predictionConfidence = validator->GetModelAccuracy();
        modelState = predictionConfidence > 0.7 ? 1 :
                    predictionConfidence < 0.5 ? -1 : 0;
    }
};
