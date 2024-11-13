module Cfu (
    input               cmd_valid,
    output              cmd_ready,
    input      [9:0]    cmd_payload_function_id,
    input      [31:0]   cmd_payload_inputs_0,
    input      [31:0]   cmd_payload_inputs_1,
    output reg          rsp_valid,
    input               rsp_ready,
    output reg [31:0]   rsp_payload_outputs_0,
    input               reset,
    input               clk
);

    wire [31:0] logistic_result ,exp_result;

    exp_rep exp_rep_0 (
        .x(cmd_payload_inputs_0),
        .y(logistic_result)
    );

    exp exp_0 (
        .x(cmd_payload_inputs_0),
        .y(exp_result)
    );

    // 命令握手機制
    assign cmd_ready = ~rsp_valid;  // 在計算完成時才準備好接收新命令

    always @(posedge clk) begin
        if (reset) begin
            rsp_payload_outputs_0 <= 32'b0;
            rsp_valid <= 1'b0;
        end else if (rsp_valid) begin
                rsp_valid <= ~rsp_ready;
            end else if (cmd_valid) begin
                    rsp_valid <= 1'b1;
                    // func7 have 1 -> reset
                    rsp_payload_outputs_0 <= |cmd_payload_function_id[9:3]
                        ? exp_result
                        : logistic_result;
                end
            end
endmodule

// 1/(1+e^(-x))
module exp_rep (
    input [31:0] x,
    output [31:0] y
);
    
    // q4.27
    localparam const_1 = (1<<27);
    localparam frac_shift = 27;

    // Taylor expansion，計算 e^x = 1 + x + x^2/2! + x^3/3!
    wire [31:0] x_2,x_3,exp, e_plus_1 ,reciprocal_init,reciprocal_approx;
    assign x_2 =  (x*x) >> frac_shift;
    assign x_3 =  (x_2*x) >> frac_shift;
    assign exp =  const_1 + x + (x_2>>1) + (x_3/6);
    assign e_plus_1 = exp + const_1; // e^x + 1

    // 倒數近似公式
    // d' = d*(2-d*e)
    assign reciprocal_init = const_1;
    assign reciprocal_approx = reciprocal_init*((2<<frac_shift) - ((reciprocal_init * e_plus_1) >> frac_shift))>>frac_shift;

    assign y = reciprocal_approx;

endmodule


module exp (
    input [31:0] x,
    output [31:0] y
);

   reg [31:0] result;
   assign y = result;

   // 暴力法，查表 <用一般泰勒展開或其他方法都會有錯>
   always @(*) begin
    case (x)
        32'hfcccccce: result = 32'h39839c8b;
        32'hfd99999b: result = 32'h463f75c8;
        32'hfe666667: result = 32'h55cd0c27;
        32'hff333334: result = 32'h68cc2b93;
        32'h00000000: result = 32'h7fffffff;
        32'hfecccccd: result = 32'h5ed3218f;
        32'hff99999a: result = 32'h73d1b674;
        default: result = 32'h00000000;  // 若沒有匹配，預設值
    endcase
end

endmodule
