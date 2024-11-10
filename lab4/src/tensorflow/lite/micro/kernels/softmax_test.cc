/* Copyright 2017 The TensorFlow Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

/* Modifications:
   - "Improve readability for failure message and tolerance"
   - "Add more tests for values near zero"
   - "Delete tests with large values"
   - Modified by Charles Tsai in 2024 Fall for AAML lab4.
*/

#define TF_LITE_MICRO_EXPECT_NEAR_INT8(x, y, epsilon)                         \
  do {                                                                        \
    int8_t vx = (x);                                                          \
    int8_t vy = (y);                                                          \
    int8_t delta = ((vx) > (vy)) ? ((vx) - (vy)) : ((vy) - (vx));             \
    if (vx != vy && delta > epsilon) {                                        \
      MicroPrintf(#x " (%d) near " #y " (%d) failed at %s:%d",                \
                  vx, vy, __FILE__, __LINE__);                                \
      micro_test::did_test_fail = true;                                       \
    }                                                                         \
  } while (false)

#include "tensorflow/lite/c/builtin_op_data.h"
#include "tensorflow/lite/c/common.h"
#include "tensorflow/lite/micro/kernels/kernel_runner.h"
#include "tensorflow/lite/micro/test_helpers.h"
#include "tensorflow/lite/micro/testing/micro_test.h"

namespace tflite {
namespace testing {
namespace {

// The Softmax kernel assumes an output in the range [0, 1.0], leading to these
// quantization parameters.
const float output_scale_int8 = 1.0f / 256.0f;
const int output_zero_point_int8 = -128;

// 1-dimensional test data.
const int flat_size_1d = 5;
int shape_1d[] = {1, 5};
const float input_data_1d[] = {0.1, 0.2, 0.3, 0.4, 0.5};
const float golden_1d[] = {0.162120357, 0.179170698, 0.198014244, 0.218839586, 
                           0.241855130};

const int flat_size_1d_wide = 5;
int shape_1d_wide[] = {1, 5};
const float input_data_1d_wide[] = {0.05, 0.25, 0.45, 0.65, 0.85};
const float golden_1d_wide[] = {0.128851250, 0.157379270, 0.192223474, 0.234782279, 
                                0.286763728};

// 2-dimensional test data.
const int flat_size_2d = 10;
int shape_2d[] = {2, 2, 5};
const float input_data_2d[] = {0.1, 0.2, 0.3, 0.4, 0.5,
                               -0.1, -0.2, -0.3, -0.4, -0.5};
const float golden_2d[] = {0.162120357, 0.179170698, 0.198014244, 0.218839586, 
                           0.241855130, 0.241855145, 0.218839586, 0.198014230, 
                           0.179170683, 0.162120342};

const int flat_size_2d_wide = 10;
int shape_2d_wide[] = {2, 2, 5};
const float input_data_2d_wide[] = {0.05, 0.25, 0.45, 0.65, 0.85,
                                    -0.05, -0.25, -0.45, -0.65, -0.85};
const float golden_2d_wide[] = {0.128851250, 0.157379270, 0.192223474, 0.234782279, 
                                0.286763728, 0.286763698, 0.234782279, 0.192223474, 
                                0.157379270, 0.128851250};

template <typename T>
void ValidateSoftmaxGoldens(TfLiteTensor* tensors, const int tensor_count,
                            T* output_data, const T* expected_output,
                            int output_dims_count, float tolerance) {
  TfLiteSoftmaxParams builtin_data = {1.0f};

  int inputs_array_data[] = {1, 0};
  TfLiteIntArray* inputs_array = IntArrayFromInts(inputs_array_data);
  int outputs_array_data[] = {1, 1};
  TfLiteIntArray* outputs_array = IntArrayFromInts(outputs_array_data);

  const TfLiteRegistration registration = Register_SOFTMAX();
  micro::KernelRunner runner(registration, tensors, tensor_count, inputs_array,
                             outputs_array, &builtin_data);

  TF_LITE_MICRO_EXPECT_EQ(kTfLiteOk, runner.InitAndPrepare());
  TF_LITE_MICRO_EXPECT_EQ(kTfLiteOk, runner.Invoke());

  for (int i = 0; i < output_dims_count; ++i) {
    TF_LITE_MICRO_EXPECT_NEAR_INT8(expected_output[i], output_data[i], tolerance);
  }
}

template <typename inputT, typename outputT>
void TestSoftmaxQuantized(int* input_dims_data, const float* input_data,
                          inputT* input_quantized, float input_scale,
                          int input_zero_point, int* output_dims_data,
                          const float* golden, outputT* golden_quantized,
                          float output_scale, int output_zero_point,
                          outputT* output_data, float tolerance = 1.0) {
  TfLiteIntArray* input_dims = IntArrayFromInts(input_dims_data);
  TfLiteIntArray* output_dims = IntArrayFromInts(output_dims_data);
  const int output_dims_count = ElementCount(*output_dims);

  constexpr int inputs_size = 1;
  constexpr int outputs_size = 1;
  constexpr int tensors_size = inputs_size + outputs_size;
  TfLiteTensor tensors[tensors_size] = {
      CreateQuantizedTensor(input_data, input_quantized, input_dims,
                            input_scale, input_zero_point),
      CreateQuantizedTensor(output_data, output_dims, output_scale,
                            output_zero_point),
  };

  Quantize(golden, golden_quantized, output_dims_count, output_scale,
           output_zero_point);

  ValidateSoftmaxGoldens(tensors, tensors_size, output_data, golden_quantized,
                         output_dims_count, tolerance);
}

}  // namespace
}  // namespace testing
}  // namespace tflite

TF_LITE_MICRO_TESTS_BEGIN

TF_LITE_MICRO_TEST(Softmax1DQuantizedInt8ShouldMatchGolden) {
  const float input_scale = 0.01f;
  const int input_zero_point = 0;

  int8_t input_quantized[tflite::testing::flat_size_1d];
  int8_t golden_quantized[tflite::testing::flat_size_1d];
  int8_t output_data[tflite::testing::flat_size_1d];
  tflite::testing::TestSoftmaxQuantized(
      tflite::testing::shape_1d, tflite::testing::input_data_1d,
      input_quantized, input_scale, input_zero_point, tflite::testing::shape_1d,
      tflite::testing::golden_1d, golden_quantized,
      tflite::testing::output_scale_int8,
      tflite::testing::output_zero_point_int8, output_data);
}

TF_LITE_MICRO_TEST(Softmax1DWideQuantizedInt8ShouldMatchGolden) {
  const float input_scale = 0.01f;
  const int input_zero_point = 0;

  int8_t input_quantized[tflite::testing::flat_size_1d_wide];
  int8_t golden_quantized[tflite::testing::flat_size_1d_wide];
  int8_t output_data[tflite::testing::flat_size_1d_wide];
  tflite::testing::TestSoftmaxQuantized(
      tflite::testing::shape_1d_wide, tflite::testing::input_data_1d_wide,
      input_quantized, input_scale, input_zero_point, tflite::testing::shape_1d_wide,
      tflite::testing::golden_1d_wide, golden_quantized,
      tflite::testing::output_scale_int8,
      tflite::testing::output_zero_point_int8, output_data);
}

TF_LITE_MICRO_TEST(Softmax2DQuantizedInt8ShouldMatchGolden) {
  const float input_scale = 0.01f;
  const int input_zero_point = 0;

  int8_t input_quantized[tflite::testing::flat_size_2d];
  int8_t golden_quantized[tflite::testing::flat_size_2d];
  int8_t output_data[tflite::testing::flat_size_2d];
  tflite::testing::TestSoftmaxQuantized(
      tflite::testing::shape_2d, tflite::testing::input_data_2d,
      input_quantized, input_scale, input_zero_point, tflite::testing::shape_2d,
      tflite::testing::golden_2d, golden_quantized,
      tflite::testing::output_scale_int8,
      tflite::testing::output_zero_point_int8, output_data);
}

TF_LITE_MICRO_TEST(Softmax2DWideQuantizedInt8ShouldMatchGolden) {
  const float input_scale = 0.01f;
  const int input_zero_point = 0;

  int8_t input_quantized[tflite::testing::flat_size_2d_wide];
  int8_t golden_quantized[tflite::testing::flat_size_2d_wide];
  int8_t output_data[tflite::testing::flat_size_2d_wide];
  tflite::testing::TestSoftmaxQuantized(
      tflite::testing::shape_2d_wide, tflite::testing::input_data_2d_wide,
      input_quantized, input_scale, input_zero_point, tflite::testing::shape_2d_wide,
      tflite::testing::golden_2d_wide, golden_quantized,
      tflite::testing::output_scale_int8,
      tflite::testing::output_zero_point_int8, output_data);
}

TF_LITE_MICRO_TESTS_END
