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
    // Taylor expansion，計算 e^x = 1 + x + x^2/2! + x^3/3!
    wire [31:0] x_2,x_3,exp,reciprocal_init,reciprocal_approx;
    assign x_2 =  (x*x) >> 16;
    assign x_3 =  (x_2*x) >> 16;
    assign exp =  (1<<16) + x + (x_2>>1) + (x_3/6);

    assign reciprocal_init = (1<<16);
    assign reciprocal_approx = reciprocal_init*((2<<16) - ((reciprocal_init * exp) >> 16))>>16;

    assign y = reciprocal_approx;

endmodule

module exp (
    input [31:0] x,
    output [31:0] y
);
    // Taylor expansion，計算 e^x = 1 + x + x^2/2! + x^3/3!
    wire [31:0] x_2,x_3,exp;
    assign x_2 =  (x*x) >> 18;
    assign x_3 =  (x_2*x) >> 18;
    assign exp =  (1<<18) + x + (x_2>>1) + (x_3/6);

    assign y = exp;
endmodule
