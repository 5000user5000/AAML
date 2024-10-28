module TPU(
    clk,
    rst_n,

    in_valid,
    K,
    M,
    N,
    busy,

    A_wr_en,
    A_index,
    A_data_in,
    A_data_out,

    B_wr_en,
    B_index,
    B_data_in,
    B_data_out,

    C_wr_en,
    C_index,
    C_data_in,
    C_data_out
);


input clk;
input rst_n;
input            in_valid;
input [7:0]      K;
input [7:0]      M;
input [7:0]      N;
output  reg      busy;

output           A_wr_en;
output [15:0]    A_index;
output [31:0]    A_data_in;
input  [31:0]    A_data_out;

output           B_wr_en;
output [15:0]    B_index;
output [31:0]    B_data_in;
input  [31:0]    B_data_out;

output           C_wr_en;
output [15:0]    C_index;
output [127:0]   C_data_in;
input  [127:0]   C_data_out;



//* Implement your design here

// 先把 K, M, N 放到 reg，不然 K, M, N 的值只會存在一個 cycle
reg [7:0] K_tmp, M_tmp, N_tmp;


wire [1:0] state, n_state;
wire [31:0] counter;
wire [31:0] datain_h, datain_v;
wire [127:0] psum_1, psum_2, psum_3, psum_4;




parameter IDLE = 2'd0;
parameter READ = 2'd1;
parameter OUTPUT = 2'd2;
parameter FINISH = 2'd3;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        busy <= 0;
    end
    if(in_valid)
        busy <= 1;
    else if(n_state == FINISH)
        busy <= 0;
end



always @(posedge clk) begin
    if(K > 0) begin
        K_tmp <= K;
        M_tmp <= M;
        N_tmp <= N;
    end
end


// 1. 用 data_loader 將資料載入 PE
data_loader A_loader(
    .clk(clk),
    .rst_n(rst_n),
    .state(state),
    .in_data(A_data_out),
    .K_tmp(K_tmp), 
    .counter(counter),
    .out_wire(datain_h)
);

data_loader B_loader(
    .clk(clk),
    .rst_n(rst_n),
    .state(state),
    .in_data(B_data_out),
    .K_tmp(K_tmp),
    .counter(counter),
    .out_wire(datain_v)
);
// 2. 用 systolic_array 進行計算
systolic_array systolic(
    .clk(clk),
    .rst_n(rst_n),
    .state(state),
    .datain_h(datain_h),
    .datain_v(datain_v),
    .psum_1(psum_1),
    .psum_2(psum_2),
    .psum_3(psum_3),
    .psum_4(psum_4)
);
// 3. 用 controller 控制 PE 和 data_loader 的狀態以及寫入資料到 Buffer C
controller ctrl(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .busy(busy),
    .K_tmp(K_tmp),
    .M_tmp(M_tmp),
    .N_tmp(N_tmp),
    .psum_1(psum_1),
    .psum_2(psum_2),
    .psum_3(psum_3),
    .psum_4(psum_4),
    .state_wire(state),
    .n_state_wire(n_state),
    .A_wr_en(A_wr_en),
    .B_wr_en(B_wr_en),
    .C_wr_en(C_wr_en),
    .A_data_in(A_data_in),
    .B_data_in(B_data_in),
    .C_data_in(C_data_in),
    .A_index(A_index),
    .B_index(B_index),
    .C_index(C_index),
    .counter_wire(counter)
);



endmodule



// 將資料載入PE，部分延遲載入
module data_loader(
    clk,
    rst_n,
    state,
    in_data,
    K_tmp, 
    counter, 
    out_wire
);
    input clk;
    input rst_n;
    input [1:0] state;
    input [31:0] in_data;
    input [7:0] K_tmp;
    input [31:0] counter;

    output wire [31:0] out_wire;

    localparam IDLE = 2'b0;
    localparam READ = 2'b1;

    reg [31:0] out;
    reg [7:0] temp_out1;
    reg [15:0] temp_out2;
    reg [23:0] temp_out3;
    reg [31:0] temp_out4;

    assign out_wire = out;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            temp_out1 <= 0;
            temp_out2 <= 0;
            temp_out3 <= 0;
            temp_out4 <= 0;
            out <= 0;
        end else if(state == IDLE) begin
            temp_out1 <= 0;
            temp_out2 <= 0;
            temp_out3 <= 0;
            temp_out4 <= 0;
            out <= 0;
        end 
        // else if(state == READ) begin  
        //     out <= {temp_out1[7:0], temp_out2[15:8], temp_out3[23:16], temp_out4[31:24]}; // 各自取開頭 8 bits，並組合
        //     end
        end
    
    always @(posedge clk) begin
        if(state == READ) begin
            if(counter < K_tmp) begin
                temp_out1 <= in_data[31:24];
                temp_out2 <= {temp_out2[7:0] , in_data[23:16]}; // 向前 shift 8 bits，並將新資料放入
                temp_out3 <= {temp_out3[15:0] , in_data[15:8]};
                temp_out4 <= {temp_out4[23:0] , in_data[7:0]};
                out <= {in_data[31:24], temp_out2[7:0], temp_out3[15:8], temp_out4[23:16]}; // 各自取開頭 8 bits，並組合
            end
            else begin
                temp_out1 <= temp_out1 << 8;
                temp_out2 <= temp_out2 << 8;
                temp_out3 <= temp_out3 << 8;
                temp_out4 <= temp_out4 << 8;
                out <= {8'b0, temp_out2[7:0], temp_out3[15:8], temp_out4[23:16]}; 
            end
        end
    end

endmodule

// process element
module PE(
    clk,
    rst_n,
    state,
    in_west, // input from west
    in_north, // input from north

    out_east, // output to east
    out_south,
    psum // result
);  
    input clk , rst_n;
    input [1:0] state;
    input [7:0]  in_west , in_north;

    output reg [7:0] out_east , out_south;
    output wire [31:0] psum;

    reg [31:0] maccout;
    reg [31:0] west_c , north_c; // temporary storage for west and north

    wire [31:0] product;

    localparam IDLE = 2'd0;
    localparam READ = 2'd1;

    assign psum = maccout;
    assign product = in_west * in_north;

    always @(negedge rst_n) begin
        maccout <= 0;
        west_c <= 0;
        north_c <= 0;
    end

    always @(negedge clk) begin
        if(state == READ) begin
            maccout <= maccout + product;
            west_c <= in_west;
            north_c <= in_north;
        end
    end

    always @(posedge clk)begin
        if(state == IDLE) begin
            maccout <= 0;
        end
        out_east <= west_c;
        out_south <= north_c;
    end
endmodule

module systolic_array(
    clk,
    rst_n,
    state,
    datain_h,
    datain_v,
    psum_1,
    psum_2,
    psum_3,
    psum_4
);

    input clk;
    input rst_n;
    input [1:0] state;
    input [31:0] datain_h;
    input [31:0] datain_v;

    output wire [127:0] psum_1;
    output wire [127:0] psum_2;
    output wire [127:0] psum_3;
    output wire [127:0] psum_4;


    wire [31:0] psum [0:15]; // partial sum
    wire [95:0] dataout_h;
    wire [95:0] dataout_v;

    assign psum_1 = {psum[0], psum[1], psum[2], psum[3]};
    assign psum_2 = {psum[4], psum[5], psum[6], psum[7]};
    assign psum_3 = {psum[8], psum[9], psum[10], psum[11]};
    assign psum_4 = {psum[12], psum[13], psum[14], psum[15]};



    // genvat 和 generate 反而比較麻煩
    // 這邊直接用 16 個 PE 來實作
    // 順序  1 2 3 4，下一個 row 5 6 7 8

    PE pe1(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (datain_h[31:24]),
        .in_north (datain_v[31:24]),
        .out_east (dataout_h[7:0]),
        .out_south (dataout_v[7:0]),
        .psum (psum[0])
    );
    PE pe2(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[7:0]),
        .in_north (datain_v[23:16]),
        .out_east (dataout_h[15:8]),
        .out_south (dataout_v[15:8]),
        .psum (psum[1])
    );
    PE pe3(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[15:8]),
        .in_north (datain_v[15:8]),
        .out_east (dataout_h[23:16]),
        .out_south (dataout_v[23:16]),
        .psum (psum[2])
    );
    PE pe4(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[23:16]),
        .in_north (datain_v[7:0]),
        .out_east (), // 這個是最後一個，所以不需要 output
        .out_south (dataout_v[31:24]),
        .psum (psum[3])
    );

    // 下一個 ROW
    PE pe5(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (datain_h[23:16]),
        .in_north (dataout_v[7:0]),
        .out_east (dataout_h[31:24]),
        .out_south (dataout_v[39:32]),
        .psum (psum[4])
    );
    PE pe6(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[31:24]),
        .in_north (dataout_v[15:8]),
        .out_east (dataout_h[39:32]),
        .out_south (dataout_v[47:40]),
        .psum (psum[5])
    );
    PE pe7(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[39:32]),
        .in_north (dataout_v[23:16]),
        .out_east (dataout_h[47:40]),
        .out_south (dataout_v[55:48]),
        .psum (psum[6])
    );
    PE pe8(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[47:40]),
        .in_north (dataout_v[31:24]),
        .out_east (),
        .out_south (dataout_v[63:56]),
        .psum (psum[7])
    );

    // 下一個 ROW
    PE pe9(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (datain_h[15:8]),
        .in_north (dataout_v[39:32]),
        .out_east (dataout_h[55:48]),
        .out_south (dataout_v[71:64]),
        .psum (psum[8])
    );
    PE pe10(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[55:48]),
        .in_north (dataout_v[47:40]),
        .out_east (dataout_h[63:56]),
        .out_south (dataout_v[79:72]),
        .psum (psum[9])
    );
    PE pe11(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[63:56]),
        .in_north (dataout_v[55:48]),
        .out_east (dataout_h[71:64]),
        .out_south (dataout_v[87:80]),
        .psum (psum[10])
    );
    PE pe12(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[71:64]),
        .in_north (dataout_v[63:56]),
        .out_east (),
        .out_south (dataout_v[95:88]),
        .psum (psum[11])
    );

    // 下一個 ROW
    PE pe13(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (datain_h[7:0]),
        .in_north (dataout_v[71:64]),
        .out_east (dataout_h[79:72]),
        .out_south (),
        .psum (psum[12])
    );
    PE pe14(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[79:72]),
        .in_north (dataout_v[79:72]),
        .out_east (dataout_h[87:80]),
        .out_south (),
        .psum (psum[13])
    );
    PE pe15(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[87:80]),
        .in_north (dataout_v[87:80]),
        .out_east (dataout_h[95:88]),
        .out_south (),
        .psum (psum[14])
    );
    PE pe16(
        .clk (clk),
        .rst_n (rst_n),
        .state (state),
        .in_west (dataout_h[95:88]),
        .in_north (dataout_v[95:88]),
        .out_east (),
        .out_south (),
        .psum (psum[15])
    );


endmodule

module controller(
    clk,
    rst_n,
    in_valid,
    busy,
    // busy_wire,
    K_tmp,
    M_tmp,
    N_tmp,
    psum_1,
    psum_2,
    psum_3,
    psum_4,
    state_wire,
    n_state_wire,
    A_wr_en,
    B_wr_en,
    C_wr_en,
    A_data_in,
    B_data_in,
    C_data_in,
    A_index,
    B_index,
    C_index,
    counter_wire
);
    input clk;
    input rst_n;
    input in_valid;
    input [7:0] K_tmp;
    input [7:0] M_tmp;
    input [7:0] N_tmp;
    input [127:0] psum_1;
    input [127:0] psum_2;
    input [127:0] psum_3;
    input [127:0] psum_4;
    input busy;

    output wire [1:0] state_wire;
    output wire [1:0] n_state_wire;
    output A_wr_en;
    output B_wr_en;
    output C_wr_en;
    output [31:0] A_data_in;
    output [31:0] B_data_in;
    output [127:0] C_data_in;
    output [15:0] A_index;
    output [15:0] B_index;
    output [15:0] C_index;
    output wire [31:0] counter_wire;
    // output wire busy_wire;

    reg [1:0] state;
    reg [1:0] n_state;
    
 
    reg [2:0] out_cycle; // 輸出 cycle 數，通常是 4，在最後一個 block 的則可能是 1~4
    reg [7:0] a_offset;
    reg [7:0] b_offset;

    reg [31:0] counter_out; // 注意要 32 bits, 只用 2 bit 會出問題
    reg [7:0] counter_a;
    reg [7:0] counter_b;
    reg [31:0] counter;

    reg [15:0] idx_a;
    reg [15:0] idx_b;
    reg [15:0] idx_c;

    


    parameter IDLE = 2'd0;
    parameter READ = 2'd1;
    parameter OUTPUT = 2'd2;
    parameter FINISH = 2'd3;

    assign state_wire = state;
    assign n_state_wire = n_state;
    assign counter_wire = counter;
    assign A_index = idx_a;
    assign B_index = idx_b;
    assign C_index = idx_c;
    // assign busy_wire = busy; 

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            state <= IDLE;
        else 
            state <= n_state;
    end

    // state transition
    always @(*) begin
        case (state)
            IDLE: 
                n_state = (in_valid || busy) ? READ : IDLE;
            READ: 
                n_state = (counter <= (K_tmp + 6)) ? READ : OUTPUT; 
            OUTPUT: 
                n_state = (counter_out < out_cycle) ? OUTPUT : (counter_b == b_offset) ? FINISH : IDLE;
            FINISH: 
                n_state = IDLE;
            default: 
                n_state = IDLE;
        endcase
    end

    // block offset
    always @(*) begin
        a_offset = ((M_tmp+3)/4); // ceil(M/4)，相當於 a 的 block 數量
        b_offset = ((N_tmp+3)/4); // ceil(N/4)，相當於 b 的 block 數量
    end


    /* 
    ***********************************************************
    *   Control Signals                                       *
    *  - wr_en                                                *
    *  - out_cycle                                            *
    *  - counter , counter_a , counter_b , counter_out        *
    ***********************************************************
    */



    // wr_en
    assign A_wr_en = 0;
    assign B_wr_en = 0;
    assign C_wr_en = (n_state == OUTPUT) ? 1 : 0;

    // out_cycle
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) out_cycle <= 0;
        else if(state == busy)
            out_cycle <= (counter_a == (a_offset - 1) && M_tmp[1:0] != 2'b00 ) ? M_tmp[1:0] : 4; // 輸出 cycle 數，通常是 4，在最後一個 block 的則可能是 1~4
        else
            out_cycle <= out_cycle;
    end

    // counter
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) counter <= 0;
        else begin
            if(state == READ)
                counter <= counter + 1;
            else
                counter <= 0;
        end
    end

    // counter_a
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) counter_a <= 0;
        else begin
            if(counter_out == out_cycle-1 && state == OUTPUT) begin
                if(counter_a < a_offset)
                    counter_a <= counter_a + 1;
                else
                    counter_a <= 1;
            end
        else if(state == FINISH)
            counter_a <= 0;
        end
    end

    // counter_b
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) counter_b <= 0;
        else begin
            if(n_state == IDLE && counter_a == a_offset && busy)
                counter_b <= counter_b + 1;
            else if(state == FINISH)
                counter_b <= 0;
        end
    end

    // counter_out
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) counter_out <= 0;
        else if(state == OUTPUT)
            counter_out <= counter_out + 1;
        else
            counter_out <= 0;
    end

    /* 
    ***********************************************************
    *   Buffer Index                                          *
    *  - The buffer location where data store or write        *
    *       - idx_a , idx_b , idx_c                           *
    *  - Wrte data                                            *
    *       - A_data_in , B_data_in , C_data_in               *
    ***********************************************************
    */

    // idx_a
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) idx_a <= 15'd0;
        else begin
        if(state == OUTPUT) begin
            if(K_tmp == 1)
                idx_a <= 1;
            else if(n_state==IDLE) begin
                idx_a <= idx_a + 15'd1;
            end
            else
              idx_a <= idx_a;
        end
        else if(state == IDLE && counter_a == a_offset)begin
            idx_a <= 0;
        end
        else if(state == FINISH)begin
            idx_a <= 15'd0;
        end
        else if(state == READ) begin
            if(counter < K_tmp - 1) // 如果單純用 < k 的話，第一波運算會多讀下一波的第一筆資料，造成錯誤
            idx_a <= idx_a + 15'd1;
        end
        else begin
            idx_a <= idx_a;
        end
        end
    end
  
    // idx_b
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) idx_b <= 0;
        else begin
            if(state == IDLE && busy) begin
                idx_b <= K_tmp * counter_b;
            end
            else if(state == FINISH)begin
                idx_b <= 15'd0;
            end
            else if(state == READ) begin
                if(counter < K_tmp ) // not K-1
                    idx_b <= idx_b + 1;
            end
        end
    end

    // idx_c
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) idx_c <= 0;
        else begin
            if(state == FINISH)
                idx_c <= 0;
            else if(state == OUTPUT && n_state == OUTPUT)
                idx_c <= idx_c + 1;
            else
                idx_c <= idx_c;
        end
    end

    assign A_data_in = 0;
    assign B_data_in = 0;

    assign C_data_in = (!rst_n) ? 0 :
                   (counter_out == 2'd0) ? psum_1 :
                   (counter_out == 2'd1) ? psum_2 :
                   (counter_out == 2'd2) ? psum_3 :
                   (counter_out == 2'd3) ? psum_4 : 0;


endmodule
