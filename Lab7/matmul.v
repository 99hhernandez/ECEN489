`timescale 1ns / 1ps

module matmul22(
in1, // Input: 2D Matrix - In1.
in2, // Input: 2D Matrix - In2.
out // Output: 2D Matrix - Out = In1 x In2.
    );

parameter size=16;
parameter decimal=10;

input[size*2*2-1:0] in1;
input[size*2*2-1:0] in2;
output [size*2*2-1:0] out;

wire[size-1:0] mi[1:0][3:0];

assign mi[0][0]=in1[size-1:0];          // mi[0][0] = In1[0][0].
assign mi[0][1]=in1[2*size-1:size];     // mi[0][1] = In1[0][1].
assign mi[0][2]=in1[3*size-1:2*size];   // mi[0][2] = In1[1][0].
assign mi[0][3]=in1[4*size-1:3*size];   // mi[0][3] = In1[1][1].

assign mi[1][0]=in2[size-1:0];          // mi[1][0] = In2[0][0].
assign mi[1][1]=in2[2*size-1:size];     // mi[1][1] = In2[0][1].
assign mi[1][2]=in2[3*size-1:2*size];   // mi[1][2] = In2[1][0].
assign mi[1][3]=in2[4*size-1:3*size];   // mi[1][3] = In2[1][1].

wire[size-1:0] mo[7:0];
wire[size-1:0] mr[3:0];

multiply #(.width(size),.decimal(decimal)) m0(mi[0][0],mi[1][0],mo[0]);     // mo[0] = In1[0][0]*In2[0][0].
multiply #(.width(size),.decimal(decimal)) m1(mi[0][1],mi[1][2],mo[1]);     // mo[1] = In1[0][1]*In2[1][0].

assign mr[0]=mo[0]+mo[1];                                                   // mr[0] = In1[0][0]*In2[0][0] + In1[0][1]*In2[1][0].

multiply #(.width(size),.decimal(decimal)) m2(mi[0][0],mi[1][1],mo[2]);     // mo[2] = In1[0][0]*In2[0][1].
multiply #(.width(size),.decimal(decimal)) m3(mi[0][1],mi[1][3],mo[3]);     // mo[3] = In1[0][1]*In2[1][1].

assign mr[1]=mo[2]+mo[3];                                                   // mr[1] = In1[0][0]*In2[0][1] + In1[0][1]*In2[1][1].

multiply #(.width(size),.decimal(decimal)) m4(mi[0][2],mi[1][0],mo[4]);     // mo[4] = In1[1][0]*In2[0][0].
multiply #(.width(size),.decimal(decimal)) m5(mi[0][3],mi[1][2],mo[5]);     // mo[5] = In1[1][1]*In2[1][0].

assign mr[2]=mo[4]+mo[5];                                                   // mr[2] = In1[1][0]*In2[0][0] + In1[1][1]*In2[1][0].

multiply #(.width(size),.decimal(decimal)) m6(mi[0][2],mi[1][1],mo[6]);     // mo[6] = In1[1][0]*In2[0][1].
multiply #(.width(size),.decimal(decimal)) m7(mi[0][3],mi[1][3],mo[7]);     // mo[7] = In1[1][1]*In2[1][1].

assign mr[3]=mo[6]+mo[7];                                                   // mr[3] = In1[1][0]*In2[0][1] + In1[1][1]*In2[1][1].

assign out[size-1:0]=mr[0];             // out[0][0] = mr[0] = In1[0][0]*In2[0][0] + In1[0][1]*In2[1][0].
assign out[2*size-1:size]=mr[1];        // out[0][1] = mr[1] = In1[0][0]*In2[0][1] + In1[0][1]*In2[1][1].
assign out[3*size-1:2*size]=mr[2];      // out[1][0] = mr[2] = In1[1][0]*In2[0][0] + In1[1][1]*In2[1][0].
assign out[4*size-1:3*size]=mr[3];      // out[1][1] = mr[3] = In1[1][0]*In2[0][1] + In1[1][1]*In2[1][1].

endmodule
