module IB(clk,rst,ctl,in,out,next);
parameter width=8;  // Width of a data.
parameter vector=3; // Size of the buffer.

input clk,rst;
input[1:0] ctl; // Control signal: 2 bits.
input[width-1:0] in; // Buffer input: 1 data, width = param "width"..
output reg[width-1:0] out; // Buffer output: 1 data, width = param "width". Connects to the PE.
output reg[width-1:0] next; // Buffer next output: 1 data, width = param "width". Connects to the next buffer.

reg[width-1:0] buffer[vector-1:0];

reg[7:0] i;

reg[7:0] addr;

always@(posedge clk or negedge rst)begin
	if(~rst)begin
		for(i=0;i<vector;i=i+1)begin
			buffer[i]<=0;
		end
		out<=0;
		next<=0;
		addr<=0;
	end
	else begin
		if(ctl==0)begin   // Idle.
			addr<=0;
			next<=0;
			out<=0;
		end
		else if(ctl==1)begin  // Send data to the next buffer.
			addr<=0;
			next<=in;
			out<=0;
		end
		else if(ctl==2)begin //  Send data to the next buffer./ Store the inputs to this buffer.
			next<=in;
			if(addr<vector)begin
				buffer[addr]<=in;
				addr<=addr+1;
			end			
			out<=0;
		end
		else if(ctl==3)begin // Output the data in the buffer to the connected PE.
			if(addr<vector)begin
				out<=buffer[addr];
				addr<=addr+1;
			end
			else begin
				out<=0;
			end
		end
	end
end

endmodule
