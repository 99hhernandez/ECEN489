`timescale 1ns / 1ps

module comp(
dis0, // PM on the previous level.
path0, // BM (edge weight).
dis1,
path1,
path_out,
dis_out
    );

parameter r=2;

input[7:0] dis0,dis1;
input[r-1:0] path0,path1;
output reg path_out;
output reg[7:0] dis_out;

reg[7:0] dis_out0,dis_out1;

// Compare the two paths and select the one with smaller PM.
// dis_out = min(dis0 + path0, dis1 + path1)
// path_out = 0 if path 0 selected.
// path_out = 1 if path 1 selected.

always@(dis0,dis1,path0,path1) begin
    if (dis0=='hff) begin
        dis_out0 = 'hff; // We use 'hff to denote infinity. 
    end
    else begin
        dis_out0 = dis0 + path0;
    end
    if (dis1 == 'hff) begin
        dis_out1 = 'hff; // infinity;
    end
    else begin
        dis_out1 = dis1 + path1;
    end
    
    if (dis_out0 <= dis_out1) begin
        dis_out = dis_out0;
        path_out = 0; // first input.
    end
    else begin
        dis_out = dis_out1;
        path_out = 1; // second input.
    end
end


endmodule
