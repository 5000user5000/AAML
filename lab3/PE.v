module PE(
    clk, 
    rst, 
    in_north, 
    in_west, 
    out_south, 
    out_east, 
    result
);
    input [7:0] in_north, in_west;
    output reg [7:0] out_south, out_east;
    input clk, rst;
    output reg [31:0] result;
    wire [15:0] product;

    assign product = in_north * in_west;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 32'b0;
            out_east <= 8'b0;
            out_south <= 8'b0;
        end
        else begin
            result <= result + product;
            out_east <= in_west;    
            out_south <= in_north;  
        end
    end
endmodule
