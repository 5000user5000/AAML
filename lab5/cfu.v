`include "TPU.v"
`include "global_buffer_bram.v" 

module Cfu
#(  parameter ADDR_BITS=12,

    parameter DATA_BITS=32,
    parameter C_BITS=128,
    parameter S0 = 4'b0000,
    parameter S1 = 4'b0001,
    parameter S2 = 4'b0010,
    parameter S3 = 4'b0011,
    parameter S4 = 4'b0100,
    parameter S5 = 4'b0101,
    parameter S6 = 4'b0110,
    parameter S7 = 4'b0111,
    parameter S8 = 4'b1000,
    parameter S9 = 4'b1001,
    parameter S10 = 4'b1010

)(
  input               cmd_valid,
  output       reg       cmd_ready,
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
  reg [7:0] K, M, N;
  wire [6:0] op;

  wire busy;
  wire [31:0] A_data_out, B_data_out;
  wire [C_BITS-1:0] C_data_out;
  wire A_wr_en , B_wr_en, C_wr_en;
  wire A_wr_en_mux;
  wire B_wr_en_mux;
  wire C_wr_en_mux;
  wire [ADDR_BITS-1:0] A_index;
  wire [ADDR_BITS-1:0] B_index;
  wire [ADDR_BITS-1:0] C_index;
  wire [31:0] A_data_in , B_data_in;
  wire [C_BITS-1:0] C_data_in;
  wire [31:0] A_data_in_mux;
  wire [31:0] B_data_in_mux;
  wire [C_BITS-1:0] C_data_in_mux;

  reg A_wr_en_init;
  reg B_wr_en_init;
  reg C_wr_en_init;

  wire [ADDR_BITS-1:0] A_index_mux , B_index_mux , C_index_mux;
  reg [ADDR_BITS-1:0] A_index_init, B_index_init, C_index_init;
  reg [31:0] A_data_in_init, B_data_in_init;
  reg [C_BITS-1:0] C_data_in_init;

  assign op = cmd_payload_function_id[9:3]; // 用來判斷是哪一個operation，更新 K、M、N，寫入 buf A、B，開始 TPU 計算，寫到 buf C
  // assign A_wr_en =  A_wr_en_init;
  // assign B_wr_en =  B_wr_en_init;
  // assign A_index =  A_index_init;
  // assign B_index =  B_index_init;
  // assign A_data_in =  A_data_in_init;
  // assign B_data_in =  B_data_in_init;
  // assign cmd_ready = ~rsp_valid;

  assign A_wr_en_mux = (in_valid | busy) ? A_wr_en : A_wr_en_init;
  assign B_wr_en_mux = (in_valid | busy) ? B_wr_en : B_wr_en_init;
  assign C_wr_en_mux = (busy) ? C_wr_en : C_wr_en_init;

  assign A_index_mux = (in_valid | busy) ? A_index : A_index_init;
  assign B_index_mux = (in_valid | busy) ? B_index : B_index_init;
  assign C_index_mux = (busy) ? C_index : C_index_init;

  assign A_data_in_mux = (in_valid) ? A_data_in : A_data_in_init;
  assign B_data_in_mux = (in_valid) ? B_data_in : B_data_in_init;
  assign C_data_in_mux = (busy) ? C_data_in : C_data_in_init;

  // Control signals


    global_buffer_bram #(
      .ADDR_BITS(ADDR_BITS), // ADDR_BITS 12 -> generates 10^12 entries
      .DATA_BITS(DATA_BITS)  // DATA_BITS 32 -> 32 bits for each entries
    )
    gbuff_A(
      .clk(clk),
      .rst_n(reset),
      .ram_en(1'b1),
      .wr_en(A_wr_en_mux),
      .index(A_index_mux),
      .data_in(A_data_in_mux),
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
      .wr_en(B_wr_en_mux),
      .index(B_index_mux),
      .data_in(B_data_in_mux),
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
      .wr_en(C_wr_en_mux),
      .index(C_index_mux),
      .data_in(C_data_in_mux),
      .data_out(C_data_out)
    );



  TPU tpu(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .K(K),
    .M(M),
    .N(N),
    .busy(busy),
    .A_wr_en(A_wr_en),
    .A_index(A_index),
    .A_data_in(A_data_in),
    .A_data_out(A_data_out),
    .B_wr_en(B_wr_en),
    .B_index(B_index),
    .B_data_in(B_data_in),
    .B_data_out(B_data_out),
    .C_wr_en(C_wr_en),
    .C_index(C_index),
    .C_data_in(C_data_in),
    .C_data_out(C_data_out)
  );





  reg [3:0] 	state;
  reg [3:0] 	comp_cnt;
  always@(negedge clk) begin
    if (reset) begin
      state <= S0;
      comp_cnt <= 4'b0000;
    end else begin
      case(state)
        S0: begin
          if (cmd_valid) begin
            state <= S1;
          end else begin
            state <= S0;
          end
        end
        S1: begin
          if (op == 9) begin // Read Buffer A
            state <= S2;
          end else if (op == 11) begin //Read Buffer B
            state <= S5;
          end else if (op == 14) begin //Read Buffer C0
            state <= S6;
          end else if (op == 15) begin //Read Buffer C1
            state <= S7;
          end else if (op == 16) begin //Read Buffer C2
            state <= S8;
          end else if (op == 17) begin //Read Buffer C3
            state <= S9;
          end else if (op == 12) begin // Set in_valid and TPU Computing
            state <= S10;
          end else begin
            state <= S3;
          end
        end
        S2: begin
          state <= S3;
        end
        S3: begin
          if (rsp_ready) begin
            state <= S4;
          end else begin
            state <= S3;
          end
        end
        S4: begin
          state <= S0;
        end
        S5: begin
          state <= S3;
        end
        S6: begin
          state <= S3;
        end
        S7: begin
          state <= S3;
        end
        S8: begin
          state <= S3;
        end
        S9: begin
          state <= S3;
        end
        S10: begin
          // state <= S3;
          if(busy) begin
            comp_cnt <= comp_cnt + 1;
            state <= S10;
          end else begin
            state <= S3;
          end
        end
      endcase
    end
  end
	
  // Set output value
  always @(posedge clk) begin
    case(state)
      S0: begin
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b0;
        rst_n <= 1'b1;
        in_valid <= 1'b0;
      end
      S1: begin
        cmd_ready <= 1'b1;
        case (op)
          7'd1: begin // Reset
            rst_n <= 1'b0;
            K = 'bx;
            M = 'bx;
            N = 'bx;
          end
          7'd2: begin // Set parameter K
            K <= cmd_payload_inputs_0;
          end

          7'd3: begin // Read parameter K
            rsp_payload_outputs_0 <= K;
          end

          7'd4: begin // Set parameter M
            M <= cmd_payload_inputs_0;
          end

          7'd5: begin // Read parameter M
            rsp_payload_outputs_0<= M;
          end

          7'd6: begin // Set parameter N
            N <= cmd_payload_inputs_0;
          end

          7'd7: begin // Read parameter N
            rsp_payload_outputs_0 <= N;
          end

          7'd8: begin // Set global bufer A
            A_index_init <= cmd_payload_inputs_0[ADDR_BITS-1:0];
            A_data_in_init <= cmd_payload_inputs_1;
            A_wr_en_init <= 1'b1;
          end
          7'd9: begin // Read global bufer A
            A_wr_en_init <= 1'b0;
            A_index_init <= cmd_payload_inputs_0[ADDR_BITS-1:0];
          end
          7'd10: begin // Set global bufer B
            A_wr_en_init <= 1'b0;
            B_index_init <= cmd_payload_inputs_0[ADDR_BITS-1:0];
            B_data_in_init <= cmd_payload_inputs_1;
            B_wr_en_init <= 1'b1;
          end
          7'd11: begin // Read global bufer B
            A_wr_en_init <= 1'b0;
            B_wr_en_init <= 1'b0;
            B_index_init <= cmd_payload_inputs_0[ADDR_BITS-1:0];
          end
          7'd12: begin // Set in_valid
            A_wr_en_init <= 1'b0;
            B_wr_en_init <= 1'b0;
            in_valid <= 1'b1;
            rsp_payload_outputs_0 <= busy;
          end
          7'd13: begin // Read busy
            rsp_payload_outputs_0 <= busy;
            // rsp_payload_outputs_0 <= in_valid;
          end
          7'd14: begin // Read global bufer C
            C_wr_en_init <= 1'b0;
            C_index_init <= cmd_payload_inputs_0[ADDR_BITS-1:0];
          end
          7'd15: begin // Read global bufer C
            C_wr_en_init <= 1'b0;
            C_index_init <= cmd_payload_inputs_0[ADDR_BITS-1:0];
          end
          7'd16: begin // Read global bufer C
            C_wr_en_init <= 1'b0;
            C_index_init <= cmd_payload_inputs_0[ADDR_BITS-1:0];
          end
          7'd17: begin // Read global bufer C
            C_wr_en_init <= 1'b0;
            C_index_init <= cmd_payload_inputs_0[ADDR_BITS-1:0];
          end
        endcase
      end
      S2: begin // Wait one cycle output buffer A
        rst_n <= 1'b1;
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b0;
        rsp_payload_outputs_0 <= A_data_out;
      end
      S3: begin
        rst_n <= 1'b1;
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b1;
      end
      S4: begin
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b0;
      end
      S5: begin // Wait one cycle output buffer B
        rst_n <= 1'b1;
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b0;
        rsp_payload_outputs_0 <= B_data_out;
      end
      S6: begin // Wait one cycle output buffer C
        rst_n <= 1'b1;
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b0;
        rsp_payload_outputs_0 <= C_data_out[31:0];
      end
      S7: begin // Wait one cycle output buffer C
        rst_n <= 1'b1;
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b0;
        rsp_payload_outputs_0 <= C_data_out[63:32];
      end
      S8: begin // Wait one cycle output buffer C
        rst_n <= 1'b1;
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b0;
        rsp_payload_outputs_0 <= C_data_out[95:64];
      end
      S9: begin // Wait one cycle output buffer C
        rst_n <= 1'b1;
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b0;
        rsp_payload_outputs_0 <= C_data_out[127:96];
      end
      S10: begin // TPU Computing ...
        in_valid <= 1'b0; // in_valid 只需一個 cycle 
        cmd_ready <= 1'b0;
        rsp_valid <= 1'b0; // 先設定為 1，用來確認 TPU 是否還在運算中
        // rsp_payload_outputs_0 <= busy;
        rsp_payload_outputs_0 <= comp_cnt;
      end
    endcase
  end


endmodule
