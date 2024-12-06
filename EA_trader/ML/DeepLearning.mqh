// DeepLearning.mqh
#import "stdlib.mqh"
#import "Indicators.mqh"
class CDeepLearning {
private:
    int inputNodes;
    int hiddenNodes;
    int outputNodes;
    double learningRate;
    int maHandle;
    int rsiHandle;
    double weights1[];
    double weights2[];
    double bias1[];
    double bias2[];

public:
    CDeepLearning() {
        inputNodes = 10;
        hiddenNodes = 20;
        outputNodes = 2;
        learningRate = 0.01;
        maHandle = INVALID_HANDLE;
        rsiHandle = INVALID_HANDLE;
    }

    ~CDeepLearning() {
        if (maHandle != INVALID_HANDLE) IndicatorRelease(maHandle);
        if (rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
    }

    bool Initialize() {
        maHandle = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
        rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);

        if (maHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE) {
            CLogger::Error("Failed to initialize indicators in CDeepLearning");
            return false;
        }

        InitializeWeights();
        CLogger::Log("CDeepLearning initialized successfully");
        return true;
    }

    MLSignal GetTradingSignal() {
        double inputs[];
        if (!PrepareInputs(inputs)) {
            CLogger::Error("Failed to prepare inputs for trading signal");
            return (MLSignal){0, 0, false};
        }
        return ProcessInputs(inputs);
    }

private:
    void InitializeWeights() {
        ArrayResize(weights1, inputNodes * hiddenNodes);
        ArrayResize(weights2, hiddenNodes * outputNodes);
        ArrayResize(bias1, hiddenNodes);
        ArrayResize(bias2, outputNodes);

        for (int i = 0; i < ArraySize(weights1); i++)
            weights1[i] = (MathRand() / 32768.0) * 2 - 1;

        for (int i = 0; i < ArraySize(weights2); i++)
            weights2[i] = (MathRand() / 32768.0) * 2 - 1;

        ArrayInitialize(bias1, 0);
        ArrayInitialize(bias2, 0);
    }

    bool PrepareInputs(double &inputs[]) {
        ArrayResize(inputs, inputNodes);
        double closeArray[], maArray[], rsiArray[];
        ArraySetAsSeries(closeArray, true);
        ArraySetAsSeries(maArray, true);
        ArraySetAsSeries(rsiArray, true);

        if (CopyClose(_Symbol, PERIOD_CURRENT, 0, inputNodes, closeArray) <= 0 ||
            CopyBuffer(maHandle, 0, 0, inputNodes, maArray) <= 0 ||
            CopyBuffer(rsiHandle, 0, 0, inputNodes, rsiArray) <= 0) {
            CLogger::Error("Failed to copy indicator data");
            return false;
        }

        for (int i = 0; i < inputNodes; i++) {
            inputs[i] = NormalizePrice(closeArray[i], maArray[i], rsiArray[i]);
        }
        return true;
    }

    MLSignal ProcessInputs(const double &inputs[]) {
        double hidden[] = ForwardLayer(inputs, weights1, bias1, hiddenNodes);
        double output[] = ForwardLayer(hidden, weights2, bias2, outputNodes);

        MLSignal signal;
        signal.probability = output[0];
        signal.direction = output[0] > 0.5 ? 1 : -1;
        signal.isValid = ValidateOutput(output);

        return signal;
    }

    double[] ForwardLayer(const double &input[], const double &weights[], const double &bias[], int nodes) {
        double output[];
        ArrayResize(output, nodes);

        for (int i = 0; i < nodes; i++) {
            output[i] = 0;
            for (int j = 0; j < ArraySize(input); j++) {
                output[i] += input[j] * weights[j * nodes + i];
            }
            output[i] += bias[i];
            output[i] = Activation(output[i]);
        }
        return output;
    }

    double Activation(double x) {
        return x > 0.0 ? x : 0.01 * x; // Leaky ReLU
    }

    bool ValidateOutput(const double &output[]) {
        double confidence = MathAbs(output[0] - 0.5);
        return confidence > 0.2;
    }

    double NormalizePrice(double close, double ma, double rsi) {
        return (close - ma) / ma;
    }
};
