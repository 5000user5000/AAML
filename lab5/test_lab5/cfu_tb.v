`timescale 1ns/1ps
`include "cfu.v"
// `include "global_buffer_bram.v"
// `include "TPU.v"

module cfu_tb;
    // Clock and Reset
    reg clk;
    reg reset;

    // CFU Inputs
    reg cmd_valid;
    reg [9:0] cmd_payload_function_id;
    reg [31:0] cmd_payload_inputs_0;
    reg [31:0] cmd_payload_inputs_1;
    reg rsp_ready;

    // CFU Outputs
    wire cmd_ready;
    wire rsp_valid;
    wire [31:0] rsp_payload_outputs_0;

    initial begin
        $dumpfile("cfu_tb.vcd"); // 指定波形文件名
        $dumpvars(0, cfu_tb); // 將 cfu_tb 的所有信號記錄到波形文件
    end

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock

    // Memory declarations for A and B
    reg [31:0] A_data [0:63]; // Memory for Matrix A
    reg [31:0] B_data [0:63]; // Memory for Matrix B

    integer i;

    // CFU instantiation
    Cfu cfu_inst (
        .clk(clk),
        .reset(reset),
        .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready),
        .cmd_payload_function_id(cmd_payload_function_id),
        .cmd_payload_inputs_0(cmd_payload_inputs_0),
        .cmd_payload_inputs_1(cmd_payload_inputs_1),
        .rsp_valid(rsp_valid),
        .rsp_ready(rsp_ready),
        .rsp_payload_outputs_0(rsp_payload_outputs_0)
    );

    

    // Initialize matrices from files
    initial begin
        $readmemh("A_data.txt", A_data); // Read hexadecimal data for A
        $readmemh("B_data.txt", B_data); // Read hexadecimal data for B

        // Optional: Print loaded data for debugging
        // for (i = 0; i < 64; i = i + 1) begin
        //     $display("A_data[%0d] = %h", i, A_data[i]);
        //     $display("B_data[%0d] = %h", i, B_data[i]);
        // end
    end

    reg [31:0] data_0, data_1, data_2, data_3;
    // Testbench process
    initial begin
        // Initialize
        reset = 1;
        cmd_valid = 0;
        rsp_ready = 0;
        #20;
        reset = 0;

        // Reset CFU
        send_command((10'd1)<<3, 32'd0, 32'd0);
        wait_for_response();

        // Set K, M, N
        send_command((10'd2)<<3, 32'd16, 32'd0); // Set K = 16
        wait_for_response();
        send_command((10'd4)<<3, 32'd16, 32'd0); // Set M = 16
        wait_for_response();
        send_command((10'd6)<<3, 32'd16, 32'd0); // Set N = 16
        wait_for_response();

        // Read K, M, N
        send_command((10'd3)<<3, 32'd0, 32'd0); // Read K
        wait_for_response();
        $display("K: %d", rsp_payload_outputs_0);
        send_command((10'd5)<<3, 32'd0, 32'd0); // Read M
        wait_for_response();
        $display("M: %d", rsp_payload_outputs_0);
        send_command((10'd7)<<3, 32'd0, 32'd0); // Read N
        wait_for_response();
        $display("N: %d", rsp_payload_outputs_0);

        // Write Buffer A
        for (i = 0; i < 64; i = i + 1) begin
            send_command((10'd8)<<3, i, A_data[i]);
            wait_for_response();
        end

        // Read Buffer A
        for (i = 0; i < 16; i = i + 1) begin
            send_command((10'd9)<<3, i, 32'd0);
            wait_for_response();
            data_0 = rsp_payload_outputs_0;
            // $display("A[%0d]: %h", i,rsp_payload_outputs_0);
            send_command((10'd9)<<3, i+1, 32'd0);
            wait_for_response();
            data_1 = rsp_payload_outputs_0;
            // $display("A[%0d]: %h", i+1,rsp_payload_outputs_0);
            send_command((10'd9)<<3, i+2, 32'd0);
            wait_for_response();
            data_2 = rsp_payload_outputs_0;
            // $display("A[%0d]: %h", i+2,rsp_payload_outputs_0);
            send_command((10'd9)<<3, i+3, 32'd0);
            wait_for_response();
            data_3 = rsp_payload_outputs_0;
            // $display("A[%0d]: %h", i+3,rsp_payload_outputs_0);
            $display("A[%0d]: %h %h %h %h", i, data_0, data_1, data_2, data_3);
        end
        $display("A data over\n");


        // Write Buffer B
        for (i = 0; i < 64; i = i + 1) begin
            send_command((10'd10)<<3, i, B_data[i]);
            wait_for_response();
        end

        // Read Buffer B
        for (i = 0; i < 16; i = i + 1) begin
            send_command((10'd11)<<3, i, 32'd0);
            wait_for_response();
            data_0 = rsp_payload_outputs_0;
            // $display("B[%0d]: %h", i,rsp_payload_outputs_0);
            send_command((10'd11)<<3, i+1, 32'd0);
            wait_for_response();
            data_1 = rsp_payload_outputs_0;
            // $display("B[%0d]: %h", i+1,rsp_payload_outputs_0);
            send_command((10'd11)<<3, i+2, 32'd0);
            wait_for_response();
            data_2 = rsp_payload_outputs_0;
            // $display("B[%0d]: %h", i+2,rsp_payload_outputs_0);
            send_command((10'd11)<<3, i+3, 32'd0);
            wait_for_response();
            data_3 = rsp_payload_outputs_0;
            // $display("B[%0d]: %h", i+3,rsp_payload_outputs_0);
            $display("B[%0d]: %h %h %h %h", i, data_0, data_1, data_2, data_3);
        end
        $display("B data over\n");

        // Start computation
        send_command((10'd12)<<3, 32'd0, 32'd0);
        wait_for_response();

        // Read Buffer C
        for (i = 0; i < 64 ; i = i + 1) begin
            send_command((10'd17)<<3, i, 32'd0);
            wait_for_response();
            data_0 = rsp_payload_outputs_0;
            // $display("C[%0d]: %h", i,rsp_payload_outputs_0);
            send_command((10'd16)<<3, i, 32'd0);
            wait_for_response();
            data_1 = rsp_payload_outputs_0;
            // $display("C[%0d]: %h", i,rsp_payload_outputs_0);
            send_command((10'd15)<<3, i, 32'd0);
            wait_for_response();
            data_2 = rsp_payload_outputs_0;
            // $display("C[%0d]: %h", i,rsp_payload_outputs_0);
            send_command((10'd14)<<3, i, 32'd0);
            wait_for_response();
            data_3 = rsp_payload_outputs_0;
            // $display("C[%0d]: %h", i,rsp_payload_outputs_0);
            $display("C[%0d]: %h %h %h %h", i, data_0, data_1, data_2, data_3);
        end

        $display("Done\n");

        $finish;
    end

    // Task: Send command to CFU
    task send_command(input [9:0] function_id, input [31:0] input_0, input [31:0] input_1);
    begin
        @(posedge clk);
        cmd_valid = 1;
        cmd_payload_function_id = function_id;
        cmd_payload_inputs_0 = input_0;
        cmd_payload_inputs_1 = input_1;
        @(posedge clk);
        cmd_valid = 0;
    end
    endtask

    // Task: Wait for response
    task wait_for_response();
    begin
        rsp_ready = 1;
        while (!rsp_valid) @(posedge clk);
        rsp_ready = 0;
    end
    endtask

endmodule