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
  output   reg        rsp_valid,
  input               rsp_ready,
  output   reg  [31:0]   rsp_payload_outputs_0,
  input               reset,
  input               clk
);


  //----- declare internal signals -----
  reg rst_n;
  reg in_valid;
  reg [31:0] input0_reg;
  reg [31:0] input1_reg;
  reg [31:0] K, M, N;
  wire [6:0] op;
 
  wire A_wr_en;
  wire B_wr_en;
  wire [ADDR_BITS-1:0] A_index;
  wire [ADDR_BITS-1:0] B_index;
  wire [31:0] A_data_in;
  wire [31:0] B_data_in;
  reg A_wr_en_init;
  reg B_wr_en_init;
  reg [ADDR_BITS-1:0] A_index_init;
  reg [ADDR_BITS-1:0] B_index_init;
  reg [31:0] A_data_in_init;
  reg [31:0] B_data_in_init;

  assign op = cmd_payload_function_id[9:3]; // 用來判斷是哪一個operation，更新 K、M、N，寫入 buf A、B，開始 TPU 計算，寫到 buf C
  assign A_wr_en =  A_wr_en_init;
  assign B_wr_en =  B_wr_en_init;
  assign A_index =  A_index_init;
  assign B_index =  B_index_init;
  assign A_data_in =  A_data_in_init;
  assign B_data_in =  B_data_in_init;
  assign cmd_ready = ~rsp_valid;

  // Control signals


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
  

  //  global_buffer_bram #(
  //     .ADDR_BITS(ADDR_BITS), // ADDR_BITS 12 -> generates 10^12 entries
  //     .DATA_BITS(C_BITS)  
  //   )
  //   gbuff_C(
  //     .clk(clk),
  //     .rst_n(reset),
  //     .ram_en(1'b1),
  //     .wr_en(C_wr_en),
  //     .index(C_index),
  //     .data_in(C_data_in),
  //     .data_out(C_data_out)
  //   );



  always @(posedge clk) begin
    if (reset) begin
      rsp_valid <= 1'b0;
      in_valid <= 1'b0;
      rsp_payload_outputs_0 <= 32'b0;
    end else if (rsp_valid) begin
      // Waiting to hand off response to CPU.
      rsp_valid <= ~rsp_ready;
    end else if (cmd_valid) begin
      rsp_valid <= 1'b1;
      // Accumulate step:
      case (op)
        7'd1: begin // Reset
            rst_n <= 1'b0;
            in_valid <= 1'b0;
            K = 'bx;
            M = 'bx;
            N = 'bx;
          end
        7'd2: begin // Set parameter K
            rst_n <= 1'b1;
            K <= cmd_payload_inputs_0;
	        end
        7'd3: begin // Read parameter K <測試用>
            rst_n <= 1'b1;
            rsp_payload_outputs_0 <= K;
	        end
        7'd4: begin // Set parameter M
            rst_n <= 1'b1;
            M <= cmd_payload_inputs_0;
	        end
        7'd5: begin // Read parameter M <測試用>
            rst_n <= 1'b1;
            rsp_payload_outputs_0<= M;
	        end
        7'd6: begin // Set parameter N
            rst_n <= 1'b1;
            N <= cmd_payload_inputs_0;
	        end
        7'd7: begin // Read parameter N <測試用>
            rst_n <= 1'b1;
            rsp_payload_outputs_0 <= N;
	        end
        7'd8: begin // Set global bufer A
            rst_n <= 1'b1;
            A_index_init <= cmd_payload_inputs_0[ADDR_BITS-1:0];
            A_data_in_init <= cmd_payload_inputs_1;
            A_wr_en_init <= 1'b1;
            rsp_payload_outputs_0 <= cmd_payload_inputs_0[ADDR_BITS-1:0]; //check index
	        end
        7'd9: begin // Read global bufer A
            rst_n <= 1'b1;
            A_wr_en_init <= 1'b0;
            A_index_init <= cmd_payload_inputs_0[9:0];
            rsp_payload_outputs_0 <= A_data_out;
	        end
        7'd10: begin // Set global bufer B
            rst_n <= 1'b1;
            B_index_init <= cmd_payload_inputs_0;
            B_data_in_init <= cmd_payload_inputs_1;
            B_wr_en_init <= 1'b1;
	        end
        7'd11: begin // Read global bufer A
            rst_n <= 1'b1;
            B_wr_en_init <= 1'b0;
            B_index_init <= cmd_payload_inputs_0;
            rsp_payload_outputs_0 <= B_data_out;
	        end
        default begin
            rst_n <= 1'b1;
            A_wr_en_init <= 1'b0;
            B_wr_en_init <= 1'b0;
          end
	      endcase
    end
  end

endmodule