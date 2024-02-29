`timescale 1ns / 1ps

module IIR_unfold(
clk,
rst,
a,b,c,d,
x2k,x2k1,
y2k,y2k1
);

input clk,rst;
input[7:0] a,b,c,d;
input[7:0] x2k,x2k1;
output[7:0] y2k,y2k1;

reg[7:0] x_1[1:0];
reg[7:0] y_1[1:0],y_2[1:0];


/*************** Your code here ***************/
wire[7:0] r0,r1,r2,r3,s0,s1,s2,s3;

multiply m0(a,x2k,r0);
multiply m1(a,x2k1,s0);
multiply m2(b,x_1[0],r1);
multiply m3(b,x2k,s1);
multiply m4(c,y_1[0],r2);
multiply m5(c,y2k,s2);
multiply m6(d,y_2[0],r3);
multiply m7(d,y_1[0],s3);

assign y2k=r0+r1+r2+r3;
assign y2k1=s0+s1+s2+s3;

always@(posedge clk or negedge rst) begin
    if(~rst) begin
        x_1[0] <= 0;
        y_1[0] <= 0;
        y_2[0] <= 0;
    end
    else begin
        x_1[0] <= x2k1;
        y_1[0] <= y2k1;
        y_2[0] <= y2k;
    end
end
/********************* Done *********************/

endmodule
