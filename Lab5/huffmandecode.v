`timescale 1ns / 1ps

module huffmandecode(
clk,
rst,
code,
hufftable,
huffsymbol,
data,
length,
finish
    );
input clk,rst;
input[15:0] code;
input[8*16-1:0] hufftable;
input[8*256-1:0] huffsymbol;
output reg[7:0] data;
output reg[7:0] length;
output reg finish;

reg n = 0;
reg upperBound = 0;
reg symbolCount = 0;
reg code_to_compare;
integer index;


always@(posedge clk or negedge rst)begin
    if(~rst)begin
    // Start of your code ====================================
        n <= 0;
        upperBound <= 0;
        symbolCount <= 0;
        code_to_compare <= 0;
        data <= 'hff;
        finish <= 0;
    // End of your code ======================================

    end
    else if(finish==0)begin
	if(n < 16)begin
    	// Start of your code ====================================
        code_to_compare <= (code >> (15-n)) & 'hff;
        upperBound <= (upperBound << 1) + ((hufftable >> (8*n)) & 'hff);
        symbolCount <= symbolCount + ((hufftable >> (8*n)) & 'hff);
        
        if(code_to_compare < upperBound) begin
            index <= symbolCount - (upperBound - code_to_compare);
            data <= (huffsymbol >> (8*index)) & 'hff;
        end
    	// End of your code ======================================    
	n = n + 1;
	end
        else begin
            n <= 0;
            length<=0;
            finish<=1;
            data<='hff;
        end   
    end
end

endmodule
