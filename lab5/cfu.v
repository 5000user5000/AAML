`include "TPU.v"
`include "global_buffer_bram.v" 

module Cfu
#(  parameter ADDR_BITS=12,

    parameter DATA_BITS=32,
    parameter C_BITS=128
)(
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

    global_buffer_bram #(
      .ADDR_BITS(ADDR_BITS), // ADDR_BITS 12 -> generates 10^12 entries
      .DATA_BITS(DATA_BITS)  // DATA_BITS 32 -> 32 bits for each entries
    )
    gbuff_A(
      .clk(clk),
      .rst_n(reset),
      .ram_en(1'b1),
      .wr_en(A_wr_en),
      .index(A_index),
      .data_in(A_data_in),
      .data_out(A_data_out)
    );

    global_buffer_bram #(
      .ADDR_BITS(ADDR_BITS), // ADDR_BITS 12 -> generates 10^12 entries
      .DATA_BITS(DATA_BITS)  // DATA_BITS 32 -> 32 bits for each entries
    )
    gbuff_B(
      .clk(clk),
      .rst_n(reset),
      .ram_en(1'b1),
      .wr_en(B_wr_en),
      .index(B_index),
      .data_in(B_data_in),
      .data_out(B_data_out)
    );
  

   global_buffer_bram #(
      .ADDR_BITS(ADDR_BITS), // ADDR_BITS 12 -> generates 10^12 entries
      .DATA_BITS(C_BITS)  
    )
    gbuff_C(
      .clk(clk),
      .rst_n(reset),
      .ram_en(1'b1),
      .wr_en(C_wr_en),
      .index(C_index),
      .data_in(C_data_in),
      .data_out(C_data_out)
    );


  // Trivial handshaking for a combinational CFU
  assign rsp_valid = cmd_valid;
  assign cmd_ready = rsp_ready;

  //
  // select output -- note that we're not fully decoding the 3 function_id bits
  //
  assign rsp_payload_outputs_0 = cmd_payload_function_id[0] ? 
                                           cmd_payload_inputs_1 :
                                           cmd_payload_inputs_0 ;


endmodule
