// Copyright 2021 The CFU-Playground Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.



module Cfu (
  input               cmd_valid,
  output              cmd_ready,
  input      [9:0]    cmd_payload_function_id,
  input      [31:0]   cmd_payload_inputs_0,
  input      [31:0]   cmd_payload_inputs_1,
  output              rsp_valid,
  input               rsp_ready,
  output     [31:0]   rsp_payload_outputs_0,
  input               reset,
  input               clk
);

    // Internal signals
    reg  [31:0]  input_x;
    wire [31:0] exp_result;
    wire [31:0] one_plus_exp;
    wire [31:0] reciprocal_result;
    reg [3:0] cycle_counter;
    reg calculation_in_progress;

    // Instantiate exp and reciporical modules
    exp exp_inst (
        .x(input_x),
        .eofx(exp_result)
    );

    q4_28_addition add_inst (
        .a(32'h10000000), // 1.0 in Q4.28 format
        .b(exp_result),
        .result(one_plus_exp)
    );

    reciporical recip_inst (
        .x(one_plus_exp),
        .reciprocal(reciprocal_result)
    );

    assign cmd_ready = ~rsp_valid;

    // Handshake logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rsp_valid <= 0;
            cmd_ready <= 1;
            cycle_counter <= 0;
            calculation_in_progress <= 0;
        end else begin
        if (cmd_valid && cmd_payload_function_id == 10'b0000000001) begin
            input_x <= cmd_payload_inputs_0;
            rsp_valid <= 0;
            cmd_ready <= 0;
            calculation_in_progress <= 1;
            cycle_counter <= 0;
        end 
        else if (calculation_in_progress) begin
            if (cycle_counter < 8) begin
                cycle_counter <= cycle_counter + 1;
            end 
            else begin
                rsp_valid <= 1;
                rsp_payload_outputs_0 <= reciprocal_result;
                //cmd_ready <= 1;
                calculation_in_progress <= 0;
            end
        end 
        else begin
            rsp_valid <= 0;
            cmd_ready <= 1;
        end
        end
        // else begin
        //     rsp_payload_outputs_0 <= cmd_payload_function_id[0] ? cmd_payload_inputs_1 : cmd_payload_inputs_0;
        // end
    end
endmodule

// fixed-point exponentiation using lut and taylor expansion
module exp(x,eofx);
  input [31:0] x;
  output [31:0] eofx;

  localparam [31:0] constants[4:0] = {
                                      32'10000000, // 1.0
                                      32'h08000000, // 0.5
                                      32'h02aaaaaa, // 1/6
                                      32'h00aaaaaa, // 1/24
                                      32'h00222222  // 1/120
                                      };
  // e^x ~= 1 + x + x^2/2! + x^3/3! + x^4/4! + x^5/5!
    reg [31:0] sum [4:0];
    reg [31:0] x2, x3, x4, x5;
    wire [31:0] term [3:0];

    always @(*) begin
        // Calculate powers of x
        q4_28_multiplication mul_inst1 (.a(x), .b(x), .result(x2));
        q4_28_multiplication mul_inst2 (.a(x2), .b(x), .result(x3));
        q4_28_multiplication mul_inst3 (.a(x3), .b(x), .result(x4));
        q4_28_multiplication mul_inst4 (.a(x4), .b(x), .result(x5));

        // Calculate each term in the Taylor expansion
        q4_28_addition add_inst1 (.a(constants[0]), .b(x), .result(sum[0])); // 1 + x

        q4_28_multiplication mul_inst5 (.a(x2), .b(constants[1]), .result(term[0]));
        q4_28_addition add_inst2 (.a(sum[0]), .b(term[0]), .result(sum[1])); // sum + x^2 / 2!

        q4_28_multiplication mul_inst6 (.a(x3), .b(constants[2]), .result(term[1]));
        q4_28_addition add_inst3 (.a(sum[1]), .b(term[1]), .result(sum[2])); // sum + x^3 / 3!

        q4_28_multiplication mul_inst7 (.a(x4), .b(constants[3]), .result(term[2]));
        q4_28_addition add_inst4 (.a(sum[2]), .b(term[2]), .result(sum[3])); // sum + x^4 / 4!

        q4_28_multiplication mul_inst8 (.a(x5), .b(constants[4]), .result(term[3]));
        q4_28_addition add_inst5 (.a(sum[3]), .b(term[3]), .result(sum[4])); // sum + x^5 / 5!

        // Assign the result
        eofx = sum[4];
    end

endmodule

// fixed-point division, Q4,28 using Newton-Raphson method
module reciporical(x,reciprocal);
  input [31:0] x;
  output [31:0] reciprocal;

  localparam [31:0] constants1 = 32'h2d2d2d2d; // 48/17
  localparam [31:0] constants2 = 32'h9e1e1e1e; // -32/17

   reg [31:0] y [4:0]; // Initial approximation
  reg [31:0] term1, term2;
  wire [31:0] mul_result;

  always @(*) begin
    // Initial approximation y0 = 48/17 - (32/17) * x
    q4_28_multiplication mul_inst1 (.a(constants2), .b(x), .result(term1));
    q4_28_addition add_inst1 (.a(constants1), .b(term1), .result(y[0]));

    // Newton-Raphson iteration: y = y * (2 - x * y), repeated four times
    integer i;
    for (i = 0; i < 4; i = i + 1) begin
      q4_28_multiplication mul_inst2 (.a(x), .b(y[i]), .result(term1));
      reg [31:0] neg_term1;
      neg_term1 = term1 ^ 32'h80000000; // Flip the sign bit
      q4_28_addition add_inst2 (.a(32'h20000000), .b(neg_term1), .result(term2)); // 2 - x * y 
      q4_28_multiplication mul_inst3 (.a(y[i]), .b(term2), .result(y[i+1])); // y * (2 - x * y)
    end

    // Assign the result after 4 iterations
    reciprocal = y[4];
  end
endmodule




// fixed-point addition, Q4,28
module q4_28_addition(
    input signed [31:0] a,
    input signed [31:0] b,
    output reg signed [31:0] result
);
    // Parameters for maximum and minimum values of Q4.28 format
    parameter signed [31:0] MAX_VAL = 32'h7fffffff;  // Maximum positive value
    parameter signed [31:0] MIN_VAL = 32'h80000000;  // Minimum negative value

    always @(*) begin
        // Intermediate variable for addition with extended bits to detect overflow
        reg signed [32:0] extended_sum;
        extended_sum = a + b;

        // Check for overflow and assign result accordingly
        if (extended_sum > MAX_VAL) begin
            result = MAX_VAL;
        end else if (extended_sum < MIN_VAL) begin
            result = MIN_VAL;
        end else begin
            result = extended_sum[31:0];
        end
    end
endmodule


// fixed-point multiplication, Q4,28
module q4_28_multiplication(
    input signed [31:0] a,
    input signed [31:0] b,
    output reg signed [31:0] result
);
    // Parameters for maximum and minimum values of Q4.28 format
    parameter signed [31:0] MAX_VAL = 32'h7fffffff;  // Maximum positive value
    parameter signed [31:0] MIN_VAL = 32'h80000000;  // Minimum negative value

    always @(*) begin
        // Intermediate variable for multiplication with extended bits to prevent overflow
        reg signed [63:0] extended_product;
        extended_product = a * b;

        // Adjust the product back to Q4.28 by shifting right 28 bits
        reg signed [63:0] adjusted_product;
        adjusted_product = extended_product >>> 28; // >>> arithmetic shift right

        // Truncate and extend to 32-bit signed value to preserve the sign
        reg signed [31:0] truncated_result;
        truncated_result = adjusted_product[31:0];

        // Check for overflow and assign result accordingly
        if (adjusted_product > MAX_VAL) begin
            result = MAX_VAL;
        end else if (adjusted_product < MIN_VAL) begin
            result = MIN_VAL;
        end else begin
            result = truncated_result;
        end
    end
endmodule
