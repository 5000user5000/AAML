module Cfu (
  input               cmd_valid,
  output              cmd_ready,
  input      [9:0]    cmd_payload_function_id,
  input      [31:0]   cmd_payload_inputs_0,
  input      [31:0]   cmd_payload_inputs_1,
  output    reg          rsp_valid,
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
    assign rsp_payload_outputs_0 = reciprocal_result;

    // Handshake logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rsp_valid <= 0;
            // cmd_ready <= 1;
            cycle_counter <= 0;
            calculation_in_progress <= 0;
        end else begin
        if (cmd_valid && cmd_payload_function_id == 10'b0000000001) begin
            input_x <= cmd_payload_inputs_0;
            rsp_valid <= 0;
            // cmd_ready <= 0;
            calculation_in_progress <= 1;
            cycle_counter <= 0;
        end 
        else if (calculation_in_progress) begin
            if (cycle_counter < 8) begin
                cycle_counter <= cycle_counter + 1;
            end 
            else begin
                rsp_valid <= 1;
                // rsp_payload_outputs_0 <= reciprocal_result;
                //cmd_ready <= 1;
                calculation_in_progress <= 0;
            end
        end 
        else begin
            rsp_valid <= 0;
            // cmd_ready <= 1;
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

    localparam [31:0] constant0 = 32'h10000000; // 1.0
    localparam [31:0] constant1 = 32'h08000000; // 0.5
    localparam [31:0] constant2 = 32'h02aaaaaa; // 1/6
    localparam [31:0] constant3 = 32'h00aaaaaa; // 1/24
    localparam [31:0] constant4 = 32'h00222222; // 1/120
    // e^x ~= 1 + x + x^2/2! + x^3/3! + x^4/4! + x^5/5!
    wire [31:0] x2, x3, x4, x5;

    wire [31:0] sum0;
    wire [31:0] sum1;
    wire [31:0] sum2;
    wire [31:0] sum3;
    wire [31:0] sum4;

    wire [31:0] term0;
    wire [31:0] term1;
    wire [31:0] term2;
    wire [31:0] term3;


        // Calculate powers of x
        q4_28_multiplication mul_inst1 (.a(x), .b(x), .result(x2));
        q4_28_multiplication mul_inst2 (.a(x2), .b(x), .result(x3));
        q4_28_multiplication mul_inst3 (.a(x3), .b(x), .result(x4));
        q4_28_multiplication mul_inst4 (.a(x4), .b(x), .result(x5));

        // Calculate each term in the Taylor expansion
        q4_28_addition add_inst1 (.a(constant0), .b(x), .result(sum0)); // 1 + x

        q4_28_multiplication mul_inst5 (.a(x2), .b(constant1), .result(term0));
        q4_28_addition add_inst2 (.a(sum0), .b(term0), .result(sum1)); // sum + x^2 / 2!

        q4_28_multiplication mul_inst6 (.a(x3), .b(constant2), .result(term1));
        q4_28_addition add_inst3 (.a(sum1), .b(term1), .result(sum2)); // sum + x^3 / 3!

        q4_28_multiplication mul_inst7 (.a(x4), .b(constant3), .result(term2));
        q4_28_addition add_inst4 (.a(sum2), .b(term2), .result(sum3)); // sum + x^4 / 4!

        q4_28_multiplication mul_inst8 (.a(x5), .b(constant4), .result(term3));
        q4_28_addition add_inst5 (.a(sum3), .b(term3), .result(sum4)); // sum + x^5 / 5!

        // Assign the result
        assign eofx = sum4;


endmodule

// fixed-point division, Q4,28 using Newton-Raphson method
module reciporical(x,reciprocal);
  input [31:0] x;
  output [31:0] reciprocal;

  localparam [31:0] constants1 = 32'h2d2d2d2d; // 48/17
  localparam [31:0] constants2 = 32'h9e1e1e1e; // -32/17

//   reg [31:0] y [0:4]; // Initial approximation
  wire [31:0] y0, y1, y2, y3, y4;
  wire [159:0] term1, term2;
  wire [31:0] mul_result;
//   reg [31:0] neg_term1;


    // Initial approximation y0 = 48/17 - (32/17) * x
    q4_28_multiplication mul_inst1 (.a(constants2), .b(x), .result(term1[31:0]));
    q4_28_addition add_inst1 (.a(constants1), .b(term1[31:0]), .result(y0));

    // Newton-Raphson iteration: y = y * (2 - x * y), repeated four times
    // 第一次迭代
    q4_28_multiplication mul_inst2_0 (.a(x), .b(y0), .result(term1[63:32]));
    // assign neg_term1 = term1 ^ 32'h80000000; // 取反符号位
    q4_28_addition add_inst2_0 (.a(32'h20000000), .b( term1[63:32]^32'h80000000 ), .result(term2[31:0]));
    q4_28_multiplication mul_inst3_0 (.a(y0), .b(term2[31:0]), .result(y1));

    // 第二次迭代
    q4_28_multiplication mul_inst2_1 (.a(x), .b(y1), .result(term1[95:64]));
    // assign neg_term1 = term1 ^ 32'h80000000;
    q4_28_addition add_inst2_1 (.a(32'h20000000), .b( term1[95:64]^32'h80000000 ), .result(term2[63:32]));
    q4_28_multiplication mul_inst3_1 (.a(y1), .b(term2[63:32]), .result(y2));

    // 第三次迭代
    q4_28_multiplication mul_inst2_2 (.a(x), .b(y2), .result(term1[127:96]));
    // assign neg_term1 = term1 ^ 32'h80000000;
    q4_28_addition add_inst2_2 (.a(32'h20000000), .b( term1[127:96]^32'h80000000 ), .result(term2[95:64]));
    q4_28_multiplication mul_inst3_2 (.a(y2), .b(term2[95:64]), .result(y3));

    // 第四次迭代
    q4_28_multiplication mul_inst2_3 (.a(x), .b(y3), .result(term1[159:128]));
    // assign neg_term1 = term1 ^ 32'h80000000;
    q4_28_addition add_inst2_3 (.a(32'h20000000), .b( term1[159:128]^32'h80000000 ), .result(term2[127:96]));
    q4_28_multiplication mul_inst3_3 (.a(y3), .b(term2[127:96]), .result(y4));


    // Assign the result after 4 iterations
    assign reciprocal = y4;
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

    reg signed [32:0] extended_sum;

    always @(*) begin
        // Intermediate variable for addition with extended bits to detect overflow
        
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

    reg signed [63:0] extended_product;
    reg signed [63:0] adjusted_product;
    reg signed [31:0] truncated_result;

    always @(*) begin
        // Intermediate variable for multiplication with extended bits to prevent overflow
        
        extended_product = a * b;

        // Adjust the product back to Q4.28 by shifting right 28 bits
        
        adjusted_product = extended_product >>> 28; // >>> arithmetic shift right

        // Truncate and extend to 32-bit signed value to preserve the sign
        
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
