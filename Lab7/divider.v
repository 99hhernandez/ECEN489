`timescale 1ns / 1ps

module divider(
in, // Input: in. A fix-point number.
out // Output: out = 1/in in fix-point number format.
    );

parameter size=8;
parameter decimal=4;

input[size-1:0] in;
output[size-1:0] out;

wire[decimal+size-1:0] one;
assign one=(1<<(2*decimal)); // One = 2^(decimal)

assign out=one/in;

endmodule