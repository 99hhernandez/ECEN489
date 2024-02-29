`timescale 1ns / 1ps

module hammingdis(
in1,
in2,
out
    );

parameter r=2;

input[r-1:0] in1;
input[r-1:0] in2;
output reg[r-1:0] out;

reg[7:0] i;

reg[r-1:0] inxor;

always@(in1,in2)begin
    inxor = in1 ^ in2;
    out = 0;
    for(i = 0; i < r; i = i + 1)begin
        out = out + inxor[i];
    end
end

endmodule
