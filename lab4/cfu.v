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

    wire [31:0] neg_x;

    // Instantiate exp and reciporical modules
    // -x
    neg neg_inst (
        .x(cmd_payload_inputs_0),
        .neg_x(neg_x)
    );
    // e^(-x)
    exp exp_inst (
        .x(neg_x),
        .eofx(exp_result)
    );

    q4_28_addition add_inst (
        .a(32'h10000000), // 1.0 in Q4.28 format
        .b(exp_result),
        .c(one_plus_exp)
    );

    reciporical recip_inst (
        .x(one_plus_exp),
        .reciprocal(reciprocal_result)
    );

    assign cmd_ready = ~rsp_valid;
    assign rsp_payload_outputs_0 = reciprocal_result;

    // Handshake logic
    always @(negedge clk or posedge reset) begin
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
                if (cycle_counter < 3) begin
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
    wire [31:0] sum_int;
    wire [31:0] sum_all;

    wire [31:0] term0;
    wire [31:0] term1;
    wire [31:0] term2;
    wire [31:0] term3;

    wire [3:0] int_x;
    assign int_x = x[31:28];
    exp_lookup exp_lookup_inst (.x(int_x), .exp_val(sum_int));

    wire [31:0] frac_x;
    assign frac_x = {4'h0,x[27:0]}; // x 的小數部分

        // Calculate powers of x
        q4_28_multiplication mul_inst1 (.a(frac_x), .b(frac_x), .result(x2));
        q4_28_multiplication mul_inst2 (.a(x2), .b(frac_x), .result(x3));
        q4_28_multiplication mul_inst3 (.a(x3), .b(frac_x), .result(x4));
        q4_28_multiplication mul_inst4 (.a(x4), .b(frac_x), .result(x5));

        // Calculate each term in the Taylor expansion
        q4_28_addition add_inst1 (.a(constant0), .b(frac_x), .c(sum0)); // 1 + x

        q4_28_multiplication mul_inst5 (.a(x2), .b(constant1), .result(term0));
        q4_28_addition add_inst2 (.a(sum0), .b(term0), .c(sum1)); // sum + x^2 / 2!

        q4_28_multiplication mul_inst6 (.a(x3), .b(constant2), .result(term1));
        q4_28_addition add_inst3 (.a(sum1), .b(term1), .c(sum2)); // sum + x^3 / 3!

        q4_28_multiplication mul_inst7 (.a(x4), .b(constant3), .result(term2));
        q4_28_addition add_inst4 (.a(sum2), .b(term2), .c(sum3)); // sum + x^4 / 4!

        q4_28_multiplication mul_inst8 (.a(x5), .b(constant4), .result(term3));
        q4_28_addition add_inst5 (.a(sum3), .b(term3), .c(sum4)); // sum + x^5 / 5!

        q4_28_multiplication  mul_inst9 (.a(sum4), .b(sum_int), .result(sum_all));

        // Assign the result
        assign eofx = (frac_x == 32'h00000000) ? sum_int : sum_all;


endmodule

module exp_lookup (
    input signed [3:0] x,          // -8 到 7 的範圍
    output [31:0] exp_val // Q4.28 格式輸出
);

    reg [31:0] exp_table [15:0]; // 建立一個 ROM

    // 初始化 ROM 中的值
    initial begin
        exp_table[ 0] = 32'h00015fc1; // e^-8
        exp_table[ 1] = 32'h0003bc2d; // e^-7
        exp_table[ 2] = 32'h000a2728; // e^-6
        exp_table[ 3] = 32'h001b9941; // e^-5
        exp_table[ 4] = 32'h004b0557; // e^-4
        exp_table[ 5] = 32'h00cbed86; // e^-3 ...
        exp_table[ 6] = 32'h022a5554; // e^-2
        exp_table[ 7] = 32'h05e2d58e; // e^-1
        exp_table[ 8] = 32'h10000000; // e^0
        exp_table[ 9] = 32'h2b7e1516; // e^1
        exp_table[10] = 32'h763992e3; // e^2

        exp_table[11] = 32'h7fffffff; // e^3
        exp_table[12] = 32'h7fffffff; // e^4
        exp_table[13] = 32'h7fffffff; // e^5
        exp_table[14] = 32'h7fffffff; // e^6
        exp_table[15] = 32'h7fffffff; // e^7
    end

    // 將 x 的值用於查找表中
    assign exp_val = exp_table[x + 8]; // x 的範圍是 -8 到 7，因此偏移 8
endmodule



// fixed-point division, Q4,28 using Newton-Raphson method
module reciporical(x,reciprocal);
  input [31:0] x;
  output [31:0] reciprocal;

  localparam [31:0] constants_48_17 = 32'h2D2D2D2D; // 48/17
  localparam [31:0] constants_n32_17 = 32'hE1E1E1E2; // -32/17
  localparam [31:0] constants_2 = 32'h20000000; // 2

//   reg [31:0] y [0:4]; // Initial approximation
  wire [31:0] y0, y1, y2, y3;
  wire [127:0] term1, term2;
  wire [31:0] mul_result;
  wire [127:0] nxy; // -x*y 
  wire [31:0] half_x;
//   reg [31:0] neg_term1;

    assign half_x = x >> 1; // x/2
    // Initial approximation y0 = 48/17 - (32/17) * x
    q4_28_multiplication mul_inst1 (.a(constants_n32_17), .b(half_x), .result(term1[31:0]));
    q4_28_addition add_inst1 (.a(constants_48_17), .b(term1[31:0]), .c(y0));

    // Newton-Raphson iteration: y = y * (2 - x * y), repeated four times
    // 第一次迭代
    q4_28_multiplication mul_inst2_0 (.a(half_x), .b(y0), .result(term1[63:32]));
    // assign neg_term1 = term1 ^ 32'h80000000; // 取反符号位
    neg neg_inst1 (.x(term1[63:32]), .neg_x(nxy[31:0]));
    q4_28_addition add_inst2_0 (.a(constants_2), .b(nxy[31:0]), .c(term2[31:0]));
    q4_28_multiplication mul_inst3_0 (.a(y0), .b(term2[31:0]), .result(y1));

    // 第二次迭代
    q4_28_multiplication mul_inst2_1 (.a(half_x), .b(y1), .result(term1[95:64]));
    // assign neg_term1 = term1 ^ 32'h80000000;
    neg neg_inst2 (.x(term1[95:64]), .neg_x(nxy[63:32]));
    q4_28_addition add_inst2_1 (.a(constants_2), .b(nxy[63:32]), .c(term2[63:32]));
    q4_28_multiplication mul_inst3_1 (.a(y1), .b(term2[63:32]), .result(y2));

    // 第三次迭代
    q4_28_multiplication mul_inst2_2 (.a(half_x), .b(y2), .result(term1[127:96]));
    // assign neg_term1 = term1 ^ 32'h80000000;
    neg neg_inst3 (.x(term1[127:96]), .neg_x(nxy[95:64]));
    q4_28_addition add_inst2_2 (.a(constants_2), .b(nxy[95:64]), .c(term2[95:64]));
    q4_28_multiplication mul_inst3_2 (.a(y2), .b(term2[95:64]), .result(y3));

    // // 第四次迭代
    // q4_28_multiplication mul_inst2_3 (.a(half_x), .b(y3), .result(term1[159:128]));
    // // assign neg_term1 = term1 ^ 32'h80000000;
    // neg neg_inst4 (.x(term1[159:128]), .neg_x(nxy[127:96]));
    // q4_28_addition add_inst2_3 (.a(constants_2), .b(nxy[127:96]), .c(term2[127:96]));
    // q4_28_multiplication mul_inst3_3 (.a(y3), .b(term2[127:96]), .result(y4));


    // Assign the result after 1 iterations
    assign reciprocal = y3 >>> 1;
endmodule




// fixed-point addition, Q4,28
module q4_28_addition(
    input  [31:0] a,
    input  [31:0] b,
    output  [31:0] c
);
    // Parameters for maximum and minimum values of Q4.28 format
    parameter signed [31:0] MAX_VAL = 32'h7fffffff;  // Maximum positive value
    parameter signed [31:0] MIN_VAL = 32'h80000000;  // Minimum negative value

    reg [32:0] extended_sum;
    reg [31:0] res;  
    assign c = res; 

    
    // Intermediate variable for addition with extended bits to detect overflow
    always @(a, b) begin    
        extended_sum = a + b;
        // 溢出判斷
        if ((a[31] == b[31]) && (extended_sum[31] != a[31])) begin
            // 若溢出，設為最大值或最小值
            if (a[31] == 1)
                res = MIN_VAL; // 最小值
            else
                res = MAX_VAL; // 最大值
        end 
        else begin
            res = extended_sum[31:0]; // 無溢出時，直接使用計算結果
        end
    end

    
endmodule

// module q4_28_addition #(
//     // Parameterized values
//     parameter Q = 28,           // Number of fractional bits
//     parameter N = 32            // Total number of bits
// )(
//     input  [N-1:0] a,           // Input a
//     input  [N-1:0] b,           // Input b
//     output [N-1:0] c            // Output c
// );

//     reg [N-1:0] res;             // Temporary result register
//     assign c = res;              // Assign result to output

//     always @(a, b) begin
//         // Case 1: Both a and b have the same sign (both positive or both negative)
//         if (a[N-1] == b[N-1]) begin
//             res[N-2:0] = a[N-2:0] + b[N-2:0];  // Add magnitudes
//             res[N-1] = a[N-1];                 // Set sign bit based on input signs
//         end
//         // Case 2: a is positive and b is negative, perform a - b
//         else if (a[N-1] == 0 && b[N-1] == 1) begin
//             if (a[N-2:0] > b[N-2:0]) begin
//                 res[N-2:0] = a[N-2:0] - b[N-2:0];  // If a > b, subtract b from a
//                 res[N-1] = 0;                      // Result is positive
//             end else begin
//                 res[N-2:0] = b[N-2:0] - a[N-2:0];  // If a < b, subtract a from b
//                 res[N-1] = (res[N-2:0] == 0) ? 0 : 1; // Result sign: negative if non-zero
//             end
//         end
//         // Case 3: a is negative and b is positive, perform b - a
//         else begin
//             if (a[N-2:0] > b[N-2:0]) begin
//                 res[N-2:0] = a[N-2:0] - b[N-2:0];  // If |a| > |b|, subtract b from a
//                 res[N-1] = (res[N-2:0] == 0) ? 0 : 1; // Result sign: negative if non-zero
//             end else begin
//                 res[N-2:0] = b[N-2:0] - a[N-2:0];  // If |b| > |a|, subtract a from b
//                 res[N-1] = 0;                      // Result is positive
//             end
//         end
//     end
// endmodule


// fixed-point multiplication, Q4,28
// module q4_28_multiplication(
//     input signed [31:0] a,
//     input signed [31:0] b,
//     output reg signed [31:0] result
// );
//     // Parameters for maximum and minimum values of Q4.28 format
//     parameter signed [31:0] MAX_VAL = 32'h7fffffff;  // Maximum positive value
//     parameter signed [31:0] MIN_VAL = 32'h80000000;  // Minimum negative value

//     reg signed [64:0] extended_product;
//     reg signed [63:0] adjusted_product;
//     reg signed [31:0] truncated_result;

//     always @(*) begin
//         // Intermediate variable for multiplication with extended bits to prevent overflow
        
//         extended_product = a * b;

//         // Adjust the product back to Q4.28 by shifting right 28 bits
        
//         adjusted_product = extended_product >>> 28; // >>> arithmetic shift right

//         // Truncate and extend to 32-bit signed value to preserve the sign
        
//         truncated_result = adjusted_product[31:0];

//         // Check for overflow and assign result accordingly
//         if (adjusted_product > MAX_VAL) begin
//             result = MAX_VAL;
//         end else if (adjusted_product < MIN_VAL) begin
//             result = MIN_VAL;
//         end else begin
//             result = truncated_result;
//         end
//     end
// endmodule

module q4_28_multiplication #(
    parameter Q = 28,      // 小數部分的位元數
    parameter N = 32       // 總位元數
) (
    input [N-1:0] a,   // 被乘數
    input [N-1:0] b,     // 乘數
    output [N-1:0] result        // 結果
);

    wire [2*N-1:0] extended_a;   // 擴展被乘數
    wire [2*N-1:0] extended_b;   // 擴展乘數

    assign extended_a = { {N{a[N-1]}}, a };  // 將被乘數擴展為 2N 位元
    assign extended_b = { {N{b[N-1]}}, b };  // 將乘數擴展為 2N 位元 

    // 定義暫存器來存儲乘法結果和返回值
    reg [4*N-1:0] r_result;     // 暫存乘法結果，需要 2N 位元
    reg [N-1:0] r_RetVal;       // 暫存返回結果，回傳 N 位元
    wire sign_bit;

    // 輸出結果的指派語句，將暫存的返回值分配給 result
    assign result = r_RetVal;

    assign sign_bit = a[N-1] ^ b[N-1];  // 計算符號位

    // 當輸入改變時進行乘法計算
    always @(extended_a, extended_b) begin
        r_result <= extended_a * extended_b;
    end

    // 監視乘法結果變化並計算輸出結果
    always @(r_result) begin
        // 計算結果的符號位，為兩個輸入的符號位異或
        // sign_bit <= a[N-1] ^ b[N-1];

        // 截取乘法結果的 N 位，並保留 Q 位小數部分
        r_RetVal[N-1:0] <= r_result[N-1+Q:Q];

        // 檢查溢位，根據符號設置最大或最小值，兩個 4 BIT 整數相乘，得到 8 BIT 整數，如果上 4 BIT 大於 0，則溢位
        if ( { 4{r_result[N-1+Q]} } != r_result[N+Q+3 :N+Q]) begin
            if (sign_bit == 1'b0) begin
                // 正數溢位，設為最大正數
                r_RetVal <= {1'b0, {N-1{1'b1}}};
            end else begin
                // 負數溢位，設為最小負數
                r_RetVal <= {1'b1, {N-1{1'b0}}};
            end
        end
    end
endmodule

//define a module to calculate the negative value of a 32-bit signed number
module neg(x, neg_x);
    input [31:0] x;
    output [31:0] neg_x;

    reg [31:0] r_neg_x;
    assign neg_x = r_neg_x;

    always @(x) begin
        if (x == 32'h80000000) begin
            r_neg_x = 32'h7fffffff;
        end else begin
            r_neg_x = ~x + 1;
        end
    end
endmodule
