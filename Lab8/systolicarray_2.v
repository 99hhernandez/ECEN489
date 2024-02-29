`timescale 1ns / 1ps

module systolicarray_2(
clk,
rst,
mi0,
mi1,
mo
    );

parameter size=8;
parameter decimal=4;

input clk,rst;

input[4*size-1:0] mi0;
input[4*size-1:0] mi1;
output reg[4*size-1:0] mo;


integer i;
reg[4:0] count;
wire[size-1:0] umi1[3:0];
wire[size-1:0] umi2[3:0];
reg[size-1:0] umi1Dummy[3:0];
reg[size-1:0] umi2Dummy[3:0];
wire[size-1:0] uai[7:0];
wire[size-1:0] uoutmi1[3:0];
wire[size-1:0] uoutmi2[3:0];
wire[size-1:0] uout[3:0];
/*
A11 = mi0[4*size-1:3],
A12 = mi0[3*size-1:2],
A21 = mi0[2*size-1:1],
A22 = mi0[1*size-1:0];
B11 = mi1[4*size-1:3],
B12 = mi1[3*size-1:2],
B21 = mi1[2*size-1:1],
B22 = mi1[1*size-1:0];
*/
genvar gi;
generate
    for(gi=0;gi<4;gi=gi+1)begin : genu
        systolicarray_2_unit #(.size(size),.decimal(decimal)) ui(clk,rst,umi1[gi],umi2[gi],uai[gi],uoutmi1[gi],uoutmi2[gi],uout[gi]);
    end
endgenerate

assign umi1[0] = umi1Dummy[0];
assign umi2[0] = umi2Dummy[0];
assign umi1[1] = umi1Dummy[1];
assign umi2[2] = umi2Dummy[2];
assign umi2[1] = uoutmi2[0];
assign umi1[2] = uoutmi1[0];
assign umi1[3] = uoutmi1[1];
assign umi2[3] = uoutmi2[2];

always@(posedge clk or negedge rst)begin
    if(~rst)begin
    // Start of your code.
        count = 0;
        for(i=0;i<8;i=i+1) begin
            umi1Dummy[i] = 0;
            umi2Dummy[i] = 0;
        end

    // End of your code.
    end
    else begin
    // Start of your code.
        
        if(count == 0) begin
            umi1Dummy[0] = mi0[4*size-1:3*size];
            umi1Dummy[1] = 0;
            umi2Dummy[0] = mi1[4*size-1:3*size];
            umi2Dummy[2] = 0;
            count = count + 1;
        end
        else if(count == 1) begin
            umi1Dummy[0] = mi0[3*size-1:2*size];
            umi1Dummy[1] = mi0[2*size-1:1*size];
            umi2Dummy[0] = mi1[2*size-1:1*size];
            umi2Dummy[2] = mi1[3*size-1:2*size];
            count = count + 1;
        end
        else if(count == 2) begin
            umi1Dummy[0] = 0;
            umi1Dummy[1] = mi0[1*size-1:0];
            umi2Dummy[0] = 0;
            umi2Dummy[2] = mi1[1*size-1:0];
            count = count + 1;
        end
        else if(count == 3) begin
            umi1Dummy[0] = 0;
            umi1Dummy[1] = 0;
            umi2Dummy[0] = 0;
            umi2Dummy[1] = 0;
            count = count + 1;
        end
        else begin
            umi1Dummy[0] = 0;
            umi1Dummy[1] = 0;
            umi2Dummy[0] = 0;
            umi2Dummy[2] = 0;
            
            mo[4*size-1:3*size] = uout[0];
            mo[2*size-1:1*size] = uout[1];
            mo[3*size-1:2*size] = uout[2];
            mo[1*size-1:0*size] = uout[3];
        end

    // End of your code.
    end
end

endmodule
