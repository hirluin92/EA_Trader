class CForwardPassHandler {
public:
    static double[] ForwardLayer(const double &input[], const double &weights[], const double &bias[], int nodes) {
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

    static double Activation(double x) {
        // Passaggio a una funzione di attivazione moderna (Leaky ReLU)
        return x > 0.0 ? x : 0.01 * x;
    }
};