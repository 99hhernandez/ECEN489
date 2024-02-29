module PE(clk,
          rst,
          ctl,  // Control.
          i_in, // Input: IN.
          i_w,  // Input: W.
          i_out,// Input: OUT.
          o_in, // Output: IN.
          o_w,  // Output: W.
          o_out);// Output: OUT.
          
parameter width=8;
parameter decimal=4;

input clk,rst,ctl;

input[width-1:0] i_in,i_w;
input[width-1:0] i_out;

output[width-1:0] o_in,o_w;
output[width-1:0] o_out;

reg[width-1:0] o_in,o_w;
reg[width-1:0] o_out;

reg[width-1:0] buffer; // the buffer used for accumulating the product.

wire[width-1:0] sel_out;

assign sel_out=ctl?buffer:i_out; // if ctl == 0, sel_out = i_out; if ctl == 1, sel_out = buffer.

wire[width-1:0] mul0,mul1;

assign mul0=i_in;
assign mul1=i_w;

wire[width-1:0] mul;

multiply #(.width(width),.decimal(decimal)) m0(mul0,mul1,mul);

always@(posedge clk or negedge rst)begin
	if(~rst)begin
		// start of your code=====================
		// reset all registers
        o_in <= 0;
        o_w <= 0;
        o_out <= 0;
        buffer <= 0;
		// end of your code=======================
	end
	else begin
		// start of your code=====================
        o_in = i_in;
        o_w = i_w;
        buffer <= buffer + mul;
        o_out = sel_out;

		// end of your code======================
	end
	
end

endmodule
