module systolic_array(clk,
                      rst,
                      ctlpe,    // Control signal for PEs. 1 bit each.
                      ctlbw,    // Control signal for weight buffers. 2 bits each. 
                      ctlbin,   // Control signal for input buffers. 2 bits each.
                      ctlbout,  // Control signal for output buffers. 2 bits each.
                      w,        // Weight input.
                      in,       // Data_in input.
                      out,      // Data_out output.
                      probe);   // Probe used for debugging.
parameter width=8;      // Parameter for data width.
parameter decimal=4;    // Parameter for fractional part width.
parameter rows=3;       // Parameter for the number of rows of the array.
parameter cols=4;       // Parameter for the number of columns of the array.
parameter vector=3;     // Parameter for the size of the buffers.

input clk,rst;
input[rows*cols-1:0] ctlpe;
input[rows*2-1:0] ctlbw;
input[cols*2-1:0] ctlbin,ctlbout;
input[width-1:0] w,in;
output[width-1:0] out;
output[cols*2*width-1:0] probe;

wire[cols*width-1:0] ins_array;     // Wires from the input buffer to the PE array.
wire[rows*width-1:0] ws_array;      // Wires from the weight buffer to the PE array.
wire[cols*width-1:0] outs_array;    // Wires from the PE array to the output buffers.

array #(.width(width),.decimal(decimal),.rows(rows),.cols(cols)) a0(clk,rst,ctlpe,ins_array,ws_array,outs_array);

assign probe=ins_array;

wire [width-1:0] wb_in[rows-1:0];        // Wires for port "in" of the weight buffer.
wire [width-1:0] wb_next[rows-1:0];      // Wires for port "next" of the weight buffer.
wire [width-1:0] inb_in[cols-1:0];       // Wires for port "in" of the input buffer.
wire [width-1:0] inb_next[cols-1:0];     // Wires for port "next" of the input buffer.
wire [width-1:0] outb_prev[cols-1:0];    // Wires for port "prev" of the output buffer.
wire [width-1:0] outb_out[cols-1:0];     // WIres for port "out" of the output buffer.

genvar gi;
generate
	for (gi=0; gi<rows; gi=gi+1) begin : genbr
		IB #(.width(width),.vector(vector)) ibw_gi(clk,rst,ctlbw[2*gi+1:2*gi],wb_in[gi],ws_array[(gi+1)*width-1:gi*width],wb_next[gi]);
	end
	for (gi=0; gi<cols; gi=gi+1) begin : genbc
		IB #(.width(width),.vector(vector)) ibin_gi(clk,rst,ctlbin[2*gi+1:2*gi],inb_in[gi],ins_array[(gi+1)*width-1:gi*width],inb_next[gi]);
		OB #(.width(width),.rows(rows)) ob_gi(clk,rst,ctlbout[2*gi+1:2*gi],outs_array[(gi+1)*width-1:gi*width],outb_prev[gi],outb_out[gi]);
	end
endgenerate

generate
	// For the first row, input of the weight buffer comes from the weight input of this module.
	// For the other rows, input of the weight buffer comes from the previous weight buffer.
	for (gi=0; gi<rows; gi=gi+1) begin : genw
		if(gi==0)begin
			assign wb_in[gi]=w;  
		end
		else begin
			assign wb_in[gi]=wb_next[gi-1];  
		end
	end

	// start of your code=====================================
	for(gi=0; gi<cols; gi=gi+1) begin : genbuf
	// For the first column, the input of the input buffer comes from the Data_in of this module.
	// For the first column, the output of the output buffer goes to the Data_out of this module.
	// For the first column, the "prev" of the output buffer comes from the previous buffer.
	   if(gi == 0) begin
	       assign inb_in[gi] = in;
	       assign out = outb_out[gi];
	       assign outb_prev[gi] = outb_out[gi-1];
	   end
	// For the last column, the "prev" of the output buffer is zero.
	   else if(gi == cols-1) begin
	       assign outb_prev[gi] = 0;
	       assign inb_in[gi] = inb_next[gi-1];
	   end
	// For the other columns, the input of the input bufers comes from the previous input buffer.
	// For the other columns, the "prev" of the output buffer comes from the previous buffer.
	   else begin
	       assign inb_in[gi] = inb_next[gi-1];
	       assign outb_prev[gi] = outb_out[gi-1];
	   end
	end

	// end of your code=======================================


		

endgenerate

endmodule
