#import "stdlib.mqh"
#import "Indicators.mqh"
class CNeuralNetworkBuilder {
private:
    struct LSTMLayer {
        int inputSize;
        int outputSize;
        double dropoutRate;
        double weights[];
        double biases[];
        double cellState[];
        double hiddenState[];
    };

    struct DenseLayer {
        int inputSize;
        int outputSize;
        string activation;
        double dropoutRate;
        double weights[];
        double biases[];
    };

    LSTMLayer lstmLayers[];
    DenseLayer denseLayers[];
    
public:
    static bool SetupLSTMLayer(int inputSize, int outputSize, double dropoutRate = 0.0) {
        LSTMLayer layer;
        layer.inputSize = inputSize;
        layer.outputSize = outputSize;
        layer.dropoutRate = dropoutRate;
        
        // Inizializzazione pesi LSTM
        ArrayResize(layer.weights, inputSize * outputSize * 4); // 4 gate LSTM
        ArrayResize(layer.biases, outputSize * 4);
        ArrayResize(layer.cellState, outputSize);
        ArrayResize(layer.hiddenState, outputSize);
        
        // Inizializzazione Xavier/Glorot
        double scale = MathSqrt(2.0 / (inputSize + outputSize));
        for(int i = 0; i < ArraySize(layer.weights); i++) {
            layer.weights[i] = (MathRand() / 32768.0) * scale;
        }
        
        ArrayInitialize(layer.biases, 0);
        ArrayInitialize(layer.cellState, 0);
        ArrayInitialize(layer.hiddenState, 0);
        
        return true;
    }

    static bool SetupDenseLayer(int inputSize, int outputSize, string activationFunction = "ReLU", double dropoutRate = 0.0) {
        DenseLayer layer;
        layer.inputSize = inputSize;
        layer.outputSize = outputSize;
        layer.activation = activationFunction;
        layer.dropoutRate = dropoutRate;
        
        // Inizializzazione pesi Dense
        ArrayResize(layer.weights, inputSize * outputSize);
        ArrayResize(layer.biases, outputSize);
        
        // Inizializzazione He per ReLU
        double scale = MathSqrt(2.0 / inputSize);
        for(int i = 0; i < ArraySize(layer.weights); i++) {
            layer.weights[i] = (MathRand() / 32768.0) * scale;
        }
        
        ArrayInitialize(layer.biases, 0);
        
        return true;
    }
    
    static double ActivationFunction(double x, string functionType) {
        if(functionType == "ReLU")
            return x > 0 ? x : 0;
        if(functionType == "LeakyReLU")
            return x > 0 ? x : 0.01 * x;
        if(functionType == "Sigmoid")
            return 1.0 / (1.0 + MathExp(-x));
        if(functionType == "Tanh")
            return MathTanh(x);
            
        return x; // Linear di default
    }
    
    static double ApplyDropout(double value, double dropoutRate) {
        if(dropoutRate <= 0) return value;
        return (MathRand() / 32768.0) > dropoutRate ? value / (1.0 - dropoutRate) : 0;
    }
};

