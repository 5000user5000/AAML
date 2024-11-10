/* Copyright 2019 The TensorFlow Authors. All Rights Reserved.

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

// The Logistic kernel assumes an output in the range [0, 1.0], leading to these
// quantization parameters.
const float quantized_output_scale_int8 = 1.0 / 255.0;
const int quantized_output_zero_point_int8 = -128;

const int flat_size_around_zero = 11;
int shape_around_zero[] = {2, 1, 11};
const float input_data_around_zero[] = {
    0, 0.005, 0.01, 0.02, 0.05, 0.1, -0.005, -0.01, -0.02, -0.05, -0.1
};
const float golden_around_zero[] = {
    0.50000000, 0.50125000, 0.50249998, 0.50499983, 0.51249740, 0.52497919, 0.49875000, 0.49750002, 0.49500017, 0.48750260, 0.47502081
};

const int flat_size_narrow_range = 10;
int shape_narrow_range[] = {2, 2, 5};
const float input_data_narrow_range[] = {
    0.15, 0.2, 0.3, 0.4, 0.5, -0.15, -0.2, -0.3, -0.4, -0.5
};
const float golden_narrow_range[] = {
    0.53742985, 0.54983400, 0.57444252, 0.59868766, 0.62245933, 0.46257015, 0.45016600, 0.42555748, 0.40131234, 0.37754067
};

const int flat_size_basic = 10;
int shape_basic[] = {2, 2, 5};
const float input_data_basic[] = {
    0.25, 0.45, 0.65, 0.85, 1, -0.25, -0.45, -0.65, -0.85, -1
};
const float golden_basic[] = {
    0.56217650, 0.61063923, 0.65701046, 0.70056714, 0.73105858, 0.43782350, 0.38936077, 0.34298954, 0.29943286, 0.26894142
};

const int flat_size_wide_range = 10;
int shape_wide_range[] = {2, 2, 5};
const float input_data_wide_range[]{
    0.32, 0.52, 0.92, 1.02, 1.22, -0.32, -0.52, -0.92, -1.05, -1.22
};
const float golden_wide_range[] = {
    0.57932425, 0.62714777, 0.71504211, 0.73497260, 0.77206355, 0.42067575, 0.37285223, 0.28495789, 0.25922510, 0.22793645
};

template <typename T>
void ValidateLogisticGoldens(TfLiteTensor* tensors, const int tensor_count,
                             T* output_data, const T* golden,
                             int output_dims_count, float tolerance) {
  int inputs_array_data[] = {1, 0};
  TfLiteIntArray* inputs_array = IntArrayFromInts(inputs_array_data);
  int outputs_array_data[] = {1, 1};
  TfLiteIntArray* outputs_array = IntArrayFromInts(outputs_array_data);

  const TfLiteRegistration registration = tflite::Register_LOGISTIC();
  micro::KernelRunner runner(registration, tensors, tensor_count, inputs_array,
                             outputs_array, nullptr);

  TF_LITE_MICRO_EXPECT_EQ(kTfLiteOk, runner.InitAndPrepare());
  TF_LITE_MICRO_EXPECT_EQ(kTfLiteOk, runner.Invoke());

  for (int i = 0; i < output_dims_count; ++i) {
    TF_LITE_MICRO_EXPECT_NEAR_INT8(golden[i], output_data[i], tolerance);
  }
}

template <typename T>
void TestLogisticQuantized(int* input_dims_data, const float* input_data,
                           T* input_quantized, const float input_scale,
                           const int input_zero_point, const float* golden,
                           T* golden_quantized, int* output_dims_data,
                           const float output_scale,
                           const int output_zero_point, T* output_data,
                           float tolerance) {
  TfLiteIntArray* input_dims = IntArrayFromInts(input_dims_data);
  TfLiteIntArray* output_dims = IntArrayFromInts(output_dims_data);
  const int output_elements_count = ElementCount(*output_dims);

  constexpr int inputs_size = 1;
  constexpr int outputs_size = 1;
  constexpr int tensors_size = inputs_size + outputs_size;
  TfLiteTensor tensors[tensors_size] = {
      CreateQuantizedTensor(input_data, input_quantized, input_dims,
                            input_scale, input_zero_point),
      CreateQuantizedTensor(output_data, output_dims, output_scale,
                            output_zero_point),
  };

  tflite::Quantize(golden, golden_quantized, output_elements_count,
                   output_scale, output_zero_point);
  ValidateLogisticGoldens(tensors, tensors_size, output_data, golden_quantized,
                          output_elements_count, tolerance);
}

}  // namespace
}  // namespace testing
}  // namespace tflite

TF_LITE_MICRO_TESTS_BEGIN

TF_LITE_MICRO_TEST(LogisticQuantizedInt8AroundZeroShouldMatchGolden) {
  const float input_scale = 0.005;
  const int input_zero_point = 0;
  int8_t input_quantized[tflite::testing::flat_size_around_zero];
  int8_t golden_quantized[tflite::testing::flat_size_around_zero];
  int8_t output_data[tflite::testing::flat_size_around_zero];

  tflite::testing::TestLogisticQuantized<int8_t>(
      tflite::testing::shape_around_zero, tflite::testing::input_data_around_zero,
      input_quantized, input_scale, input_zero_point,
      tflite::testing::golden_around_zero, golden_quantized,
      tflite::testing::shape_around_zero,
      tflite::testing::quantized_output_scale_int8,
      tflite::testing::quantized_output_zero_point_int8, output_data, 1);
}

TF_LITE_MICRO_TEST(LogisticQuantizedInt8NarrowRangeShouldMatchGolden) {
  const float input_scale = 0.01;
  const int input_zero_point = 0;
  int8_t input_quantized[tflite::testing::flat_size_narrow_range];
  int8_t golden_quantized[tflite::testing::flat_size_narrow_range];
  int8_t output_data[tflite::testing::flat_size_narrow_range];

  tflite::testing::TestLogisticQuantized<int8_t>(
      tflite::testing::shape_narrow_range, tflite::testing::input_data_narrow_range,
      input_quantized, input_scale, input_zero_point,
      tflite::testing::golden_narrow_range, golden_quantized,
      tflite::testing::shape_narrow_range,
      tflite::testing::quantized_output_scale_int8,
      tflite::testing::quantized_output_zero_point_int8, output_data, 1);
}

TF_LITE_MICRO_TEST(LogisticQuantizedInt8BasicShouldMatchGolden) {
  const float input_scale = 0.01;
  const int input_zero_point = 0;
  int8_t input_quantized[tflite::testing::flat_size_basic];
  int8_t golden_quantized[tflite::testing::flat_size_basic];
  int8_t output_data[tflite::testing::flat_size_basic];

  tflite::testing::TestLogisticQuantized<int8_t>(
      tflite::testing::shape_basic, tflite::testing::input_data_basic,
      input_quantized, input_scale, input_zero_point,
      tflite::testing::golden_basic, golden_quantized,
      tflite::testing::shape_basic,
      tflite::testing::quantized_output_scale_int8,
      tflite::testing::quantized_output_zero_point_int8, output_data, 1);
}

TF_LITE_MICRO_TEST(LogisticQuantizedInt8WideRangeShouldMatchGolden) {
  const float input_scale = 0.02;
  const int input_zero_point = 0;
  int8_t input_quantized[tflite::testing::flat_size_wide_range];
  int8_t golden_quantized[tflite::testing::flat_size_wide_range];
  int8_t output_data[tflite::testing::flat_size_wide_range];

  tflite::testing::TestLogisticQuantized<int8_t>(
      tflite::testing::shape_wide_range, tflite::testing::input_data_wide_range,
      input_quantized, input_scale, input_zero_point,
      tflite::testing::golden_wide_range, golden_quantized,
      tflite::testing::shape_wide_range,
      tflite::testing::quantized_output_scale_int8,
      tflite::testing::quantized_output_zero_point_int8, output_data, 1);
}

TF_LITE_MICRO_TESTS_END
