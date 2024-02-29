module OB(clk,rst,ctl,in,prev,out);
parameter width=8;
parameter rows=3;

input clk,rst;
input[1:0] ctl;
input[width-1:0] in;    // Data_in from the connected PE.
input[width-1:0] prev;  // data from the previous output buffer.
output reg[width-1:0] out;  // Data_out of this buffer.

reg[width-1:0] buffer[rows-1:0];

reg[7:0] i;

reg[7:0] addr;

always@(posedge clk or negedge rst)begin
	if(~rst)begin
		for(i=0;i<rows;i=i+1)begin
			buffer[i]<=0;
		end
		out<=0;
		addr<=0;
	end
	else begin
		if(ctl==0)begin   // Idle.
			addr<=0;
			out<=0;
		end
		else if(ctl==1)begin  // Pass the data from Prev to Out.
			addr<=0;
			out<=prev;
		end
		else if(ctl==2)begin  // Store the data_in to the buffer.
			if(addr<rows)begin
				buffer[addr]<=in;
				addr<=addr+1;
			end
			out<=0;
		end
		else if(ctl==3)begin  // Output the data from the buffer.
			if(addr<rows)begin
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
