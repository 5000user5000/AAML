`timescale 1ns/1ps
`include "cfu.v"
module cfu_tb;
    // Inputs
    reg cmd_valid;
    reg [9:0] cmd_payload_function_id;
    reg [31:0] cmd_payload_inputs_0;
    reg rsp_ready;
    reg reset;
    reg clk;

    initial begin
        $dumpfile("cfu_tb.vcd");
        $dumpvars(0, cfu_tb);
        #10000;                           // 等待 10000 個時鐘週期
        $finish;                         // 停止模擬並結束
    end


    // Outputs
    wire cmd_ready;
    wire rsp_valid;
    wire [31:0] rsp_payload_outputs_0;

    // Instantiate the Cfu module
    Cfu uut (
        .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready),
        .cmd_payload_function_id(cmd_payload_function_id),
        .cmd_payload_inputs_0(cmd_payload_inputs_0),
        .rsp_valid(rsp_valid),
        .rsp_ready(rsp_ready),
        .rsp_payload_outputs_0(rsp_payload_outputs_0),
        .reset(reset),
        .clk(clk)
    );

    // Clock generation
    always #5 clk = ~clk;

    // input x > 0

    // Test procedure
    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 0;
        cmd_valid = 0;
        cmd_payload_function_id = 0;
        cmd_payload_inputs_0 = 0;
        rsp_ready = 1;

        #5;
        reset = 1;

        #5;
        reset = 0;


        // Test 2: Test with x = 0 (expected output is 0.5)
        #5;
        if(cmd_ready) begin
            cmd_valid = 1;
            cmd_payload_function_id = 10'b0000000001;
            cmd_payload_inputs_0 = 32'h00cccccd;  // Input x = 0
        end


        #5;
        cmd_valid = 0;
        cmd_payload_inputs_0 = 32'h00000000;  // Input x = 0

        wait(rsp_valid);
        

        // Check output (expected ~0.5 in Q4.28, 32'h08000000)
        $display("Input: 0, Expected Output: 0.5 (Q4.28 ~ 32'h08000000), Actual Output: %h", rsp_payload_outputs_0);

        #5;
        // reset = 1;
        cmd_valid = 1;
        cmd_payload_function_id = 0;

        #5;
        cmd_valid = 0;

        // Test 2: Test with x = 1 (e.g., in Q4.28, 1 can be represented by 32'h10000000)
        #10;
        // reset = 0;
        cmd_valid = 1;
        cmd_payload_function_id = 10'b0000000001;  // Assume this ID triggers the function
        cmd_payload_inputs_0 = 32'h000a3d71;  // Input x = 1 in Q4.28 format

        #5;
        cmd_valid = 0;
        // Wait for response
        wait(rsp_valid);
        
        

        // Check output (expected  in Q4.28, roughly 32'h0bbad960)
        $display("Input: 1, Expected Output: ~0.7310586 (Q4.28 ~ 32'h0bbad960), Actual Output: %h", rsp_payload_outputs_0);

        // #5;
        // reset = 1;

        // // // Test 3: Test with x = 1 (e.g., in Q4.28, 1 can be represented by 32'h10000000)
        // #5;
        // reset = 0;
        // cmd_valid = 1;
        // cmd_payload_function_id = 10'b0000000001;
        // cmd_payload_inputs_0 = 32'h20000000;  // Input x = 1

        // #5;
        // cmd_valid = 0;

        // wait(rsp_valid);

        // // Check output (expected ~0.731058579 in Q4.28, roughly 32'h0BAE147B)
        // $display("Input: 1, Expected Output: ~0.731058579 (Q4.28 ~ 32'h0BAE147B), Actual Output: %h", rsp_payload_outputs_0);

        // Finish simulation
        #10;
        $finish;
    end
endmodule
