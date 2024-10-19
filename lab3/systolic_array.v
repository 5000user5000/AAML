`include "PE.v" 

module systolic_array(
    clk, rst, done,
    in_west0, in_west4, in_west8, in_west12,
    in_north0, in_north1, in_north2, in_north3
);
    input clk, rst;
    input [7:0] in_west0, in_west4, in_west8, in_west12;
    input [7:0] in_north0, in_north1, in_north2, in_north3;
   
    output reg done;
    
    reg [3:0] count;
    
    // PE輸出的訊號定義
    wire [7:0] out_south [0:3][0:3];
    wire [7:0] out_east [0:3][0:3];
    wire [31:0] result [0:3][0:3];
    
    // 生成4x4 PE矩陣
    genvar row, col;
    generate
        for (row = 0; row < 4; row = row + 1) begin: rows
            for (col = 0; col < 4; col = col + 1) begin: cols
                if (row == 0 && col == 0) begin
                    // 第一行第一列: 從北和西輸入
                    PE pe_inst (
                        .clk(clk),
                        .rst(rst),
                        .in_north(in_north0),
                        .in_west(in_west0),
                        .out_south(out_south[row][col]),
                        .out_east(out_east[row][col]),
                        .result(result[row][col])
                    );
                end
                else if (row == 0) begin
                    // 第一行其他單元: 從北輸入
                    PE pe_inst (
                        .clk(clk),
                        .rst(rst),
                        .in_north((col == 1) ? in_north1 : (col == 2) ? in_north2 : in_north3),
                        .in_west(out_east[row][col-1]),
                        .out_south(out_south[row][col]),
                        .out_east(out_east[row][col]),
                        .result(result[row][col])
                    );
                end
                else if (col == 0) begin
                    // 第一列其他單元: 從西輸入
                    PE pe_inst (
                        .clk(clk),
                        .rst(rst),
                        .in_north(out_south[row-1][col]),
                        .in_west((row == 1) ? in_west4 : (row == 2) ? in_west8 : in_west12),
                        .out_south(out_south[row][col]),
                        .out_east(out_east[row][col]),
                        .result(result[row][col])
                    );
                end
                else begin
                    // 其他單元: 從北和西輸入
                    PE pe_inst (
                        .clk(clk),
                        .rst(rst),
                        .in_north(out_south[row-1][col]),
                        .in_west(out_east[row][col-1]),
                        .out_south(out_south[row][col]),
                        .out_east(out_east[row][col]),
                        .result(result[row][col])
                    );
                end
            end
        end
    endgenerate

    // 計數和完成信號的控制邏輯
    always @(posedge clk or negedge rst_n) begin
        if (rst) begin
            done <= 0;
            count <= 0;
        end
        else begin
            if (count == 9) begin
                done <= 1;
                count <= 0;
            end
            else begin
                done <= 0;
                count <= count + 1;
            end
        end    
    end 
endmodule
