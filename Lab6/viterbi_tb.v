`timescale 1ns / 1ps

module viterbi_tb(

    );

parameter r=2;
parameter K=3;
parameter lenin=10;
parameter lenout=5;

reg clk,rst;

reg[lenin-1:0] vcodein;
reg[(1<<(K-1))*2*r-1:0] vstate_out;
wire[lenout-1:0] vcodeout;
wire vfinish;

viterbi #(.r(r),.K(K),.lenin(lenin),.lenout(lenout)) v0(
clk,
rst,
vcodein,
vstate_out,
vcodeout,
vfinish
    );


initial begin
clk=0;
rst=0;

//vcodein='b1110111101;
vcodein='b1111010001; // 11 11 01 00 01
//vstate_out='b1001011000111100; // 'b10 01 01 10 00 11 11 00
vstate_out='b1001001101101100; // 'b10 01 00 11 01 10 11 00

#4 rst=1;
end

always #1 begin
    clk<=~clk;
end

endmodule
