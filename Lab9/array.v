module array(clk,
             rst,
             ctls,  // Input:   Control signals for each PE.
             ins,   // Input:   Data inputs from the input buffer.
             ws,    // Input:   Weight inputs from the weight buffer.
             outs); // Output:  Outputs to the output buffer.
parameter width=8;  // Width of the fix-point numbers.
parameter decimal=4;// Width of the fractional part.
parameter rows=3;   // Number of rows in the array.
parameter cols=4;   // Number of columns in the array.

input clk,rst;

input[rows*cols-1:0] ctls;
input[cols*width-1:0] ins;
input[rows*width-1:0] ws;
output[cols*width-1:0] outs;

wire [width-1:0] wire_i_in[rows-1:0][cols-1:0];     // Wires for the i_in of each PE.
wire [width-1:0] wire_o_in[rows-1:0][cols-1:0];     // Wires for the o_in of each PE.
wire [width-1:0] wire_i_w[rows-1:0][cols-1:0];      // Wires for the i_w of each PE. 
wire [width-1:0] wire_o_w[rows-1:0][cols-1:0];      // Wires for the o_w of each PE.
wire [width-1:0] wire_i_out[rows-1:0][cols-1:0];    // Wires for the i_out of each PE.
wire [width-1:0] wire_o_out[rows-1:0][cols-1:0];    // Wires for the o_out of each PE.

genvar gr,gc; // Loop variables for row and column.
generate
	for (gr=0; gr<rows; gr=gr+1) begin : genper
		for(gc=0;gc<cols;gc=gc+1)begin : genpec
			PE #(.width(width),.decimal(decimal)) PE_gi(clk,rst,ctls[(gr*cols)+gc],
			wire_i_in[gr][gc],
			wire_i_w[gr][gc],
			wire_i_out[gr][gc],
			wire_o_in[gr][gc],
			wire_o_w[gr][gc],
			wire_o_out[gr][gc]
			);
		end
	end
endgenerate

generate
	for (gr=0; gr<rows; gr=gr+1) begin : gencontr
		for(gc=0;gc<cols;gc=gc+1)begin : gencontc
			// start of your code====================================
			// Example:
			// 	if(gr==0)begin
			// 		assign wire_i_in[gr][gc]=ins[(gc+1)*width-1:(gc)*width];
			// 	end
			// 	else begin
			// 		assign wire_i_in[gr][gc]=wire_o_in[gr-1][gc];
			// 	end
			
			//First row
			if(gr == 0) begin
                assign wire_i_in[gr][gc] = ins[(gc+1)*width-1:(gc)*width];      //data inputs
                assign outs[(cols-gc)*width-1:(cols-(gc+1))*width] = wire_o_out[gr][gc];  //data outputs
                //assign outs[(gc+1)*width-1:(gc)*width] = wire_o_out[gr][gc];
                assign wire_i_out[gr][gc] = wire_o_out[gr+1][gc];
			end
			
			//Last row
			if(gr == rows-1) begin
                assign wire_i_out[gr][gc] = 0;
                assign wire_i_in[gr][gc] = wire_o_in[gr-1][gc];
			end
			
			//Other rows
			else begin
                assign wire_i_in[gr][gc] = wire_o_in[gr-1][gc];     //connect i_in with o_in
                assign wire_i_out[gr][gc] = wire_o_out[gr+1][gc];   //connect i_out with o_out  
			end
			
			//First column
			if(gc == 0) begin
                assign wire_i_w[gr][gc] = ws[(gr+1)*width-1:(gr)*width];    //weight inputs
			end
			
			//Other columns
			else begin
                assign wire_i_w[gr][gc] = wire_o_w[gr][gc-1];       //connect i_w with o_w
			end


			// end of your code======================================
		end
	end
endgenerate
	
endmodule
