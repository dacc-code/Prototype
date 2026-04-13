import tensorflow as tf
import numpy as np

interpreter = tf.lite.Interpreter(model_path="assets/best_float32.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input:", input_details[0]['shape'], input_details[0]['dtype'])
print("Output:", output_details[0]['shape'], output_details[0]['dtype'])

# Run dummy inference
input_shape = input_details[0]['shape']
dummy_input = np.zeros(input_shape, dtype=np.float32)

interpreter.set_tensor(input_details[0]['index'], dummy_input)
interpreter.invoke()

output_data = interpreter.get_tensor(output_details[0]['index'])
print("Output data shape:", output_data.shape)
print("First 5 detections (raw):")
for i in range(min(5, output_data.shape[1])):
    print(output_data[0][i])
