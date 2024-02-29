`timescale 1ns / 1ps

module IIR_fold_tb(
y
    );

reg clk,rst;
reg[7:0] a,b,c,d;
reg[7:0] x;
output reg[7:0] y;
wire[7:0] yo;

IIR_fold f0(
clk,
rst,
a,b,c,d,
x,
yo
);

reg[7:0] count;

initial begin
clk=0;
rst=0;
a=8;//0.5
b=-24;//-1.5
c=32;//2.0
d=-16;//-1.0
x=-80;
count=0;
#4 rst=1;

end

always #1 begin
    clk<=~clk;
end
integer i = -5;
always@(posedge clk)begin
    if(rst)begin
        if((count==0))begin
            if(i<6)begin
                x<=256+i*16;
                   i<=i+1;
            end
        end
        if((count==0))begin
            y<=yo;
        end
        if(count==3)
            count<=0;
        else
            count<=count+1;
    end
end

endmodule
