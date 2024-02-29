module matrix_cal(clk,
                  rst,
                  memaddr,  // Output
                  memdata,  // Output
                  memwren,  // Output
                  memq,     // Input
                  waddr,    // Input
                  inaddr,   // Input
                  outaddr,  // Input
                  step,     // Input
                  relu,     // Input
                  do,       // Input
                  di,       // Input
                  dr,       // Input
                  dc,       // Input
                  dkr,      // Input
                  dkc,      // Input
                  out,      // Output
                  probe,probe_io,probe_ii,probe_ir,probe_ic,probe_ikr,probe_ikc,probe_ro,probe_rc,probe_state,  // Outputs: Probes.
                  ctl,  //  Input 
                  signal);
parameter width=8;          // Parameter for data width.
parameter decimal=4;        // Parameter for fractional width.
parameter memaddrbits=8;    // Parameter for number of memory address bits.
parameter rows=3;           // Parameter for number of rows of the systolic array.
parameter cols=4;           // Parameter for number of columns of the systolic array.
parameter vector=2;         // Parameter for the sequential input size for each PE. i, kr, kc

input clk,rst;

input[7:0] step;//ir and ic moves 2^step each time
input relu;
input[7:0] do,di,dr,dc,dkr,dkc;

output reg[memaddrbits-1:0] memaddr;
output reg[width-1:0] memdata;
output reg memwren;
input[width-1:0] memq;
input[memaddrbits-1:0] waddr;
input[memaddrbits-1:0] inaddr;
input[memaddrbits-1:0] outaddr;

wire[rows*cols-1:0] ctlpe;      // Wires for the control signal of all PEs.
wire[rows*2-1:0] ctlbw;         // Wires for the control signal of the wight buffer. 
wire[cols*2-1:0] ctlbin,ctlbout;// Wires for the control signal of the input/output buffers.
reg[width-1:0] w,in;            // Registers for the weight and data_in.
output[width-1:0] out;          // Register for the data_out.

input[7:0] ctl; //bit0: to w, 1: to in, 2: no output
output reg[7:0] signal;

output[cols*2*width-1:0] probe;

reg rst_sysarr;

// Instantiate of the systolic array.
systolic_array #(.width(width),.decimal(decimal),.rows(rows),.cols(cols),.vector(vector)) s0(clk,rst_sysarr,ctlpe,ctlbw,ctlbin,ctlbout,w,in,out,probe);

wire [width-1:0] wbin[rows-1:0];
wire [width-1:0] wbnext[rows-1:0];
wire [width-1:0] inbin[cols-1:0];
wire [width-1:0] inbnext[cols-1:0];
wire [width-1:0] outbprev[cols-1:0];
wire [width-1:0] outbout[cols-1:0];

reg ctlper[rows*cols-1:0];      // Register: Control siganls for all PEs.
reg[1:0] ctlbwr[rows-1:0];      // Register: Control signals for the weight buffer.
reg[1:0] ctlbinr[cols-1:0];     // Register: Control signals for the input buffer.
reg[1:0] ctlboutr[cols-1:0];    // Register: Control signals for the output buffer.

genvar gi;
generate
	for (gi=0; gi<rows; gi=gi+1) begin : genr
		assign ctlbw[2*(gi+1)-1:2*gi]=ctlbwr[gi]; // Connect the wires with the registers for control_buffer_weight.
	end
	for (gi=0; gi<cols; gi=gi+1) begin : genc
		assign ctlbin[2*(gi+1)-1:2*gi]=ctlbinr[gi]; // Connect the wires with the registers for control_buffer_in.
		assign ctlbout[2*(gi+1)-1:2*gi]=ctlboutr[gi]; // Connect the wires with the registers for control_buffer_out.
	end
	for (gi=0; gi<rows*cols; gi=gi+1) begin : genpe
		assign ctlpe[gi]=ctlper[gi]; // Connect the wires with the registers for control_pe.
	end
endgenerate

parameter aux_width=16; // Auxiliary data width.

reg[aux_width-1:0] i,j; // Auxiliary register.

reg[7:0] state;

reg[aux_width-1:0] count,countr,countc,countv; // Count, count_row, count_column, count_vector.

reg[aux_width-1:0] pi,pkr,pkc,pb;//vector
reg[aux_width-1:0] po,pc;//row/col
reg[aux_width-1:0] pr;//loop

reg[aux_width-1:0] ii,ikr,ikc,ib;//vector
reg[aux_width-1:0] io,ic;//row/col
reg[aux_width-1:0] ir;//loop

reg[aux_width-1:0] ro,rc;//row/col
reg[aux_width-1:0] rr;//loop

reg[aux_width-1:0] next_dr,next_dc;

reg[7:0] next_ite;

output[7:0] probe_io,probe_ii,probe_ir,probe_ic,probe_ikr,probe_ikc,probe_ro,probe_rc,probe_state;

assign probe_io=io;
assign probe_ii=ii;
assign probe_ir=ir;
assign probe_ic=ic;
assign probe_ikr=ikr;
assign probe_ikc=ikc;
assign probe_rc=rc;
assign probe_ro=ro;
assign probe_state=state;

parameter IDLE=0;
parameter LOADW=1;
parameter LOADIN=2;
parameter CAL=3;
parameter OUT=4;
parameter LOOP=5;
parameter TEST=6;
parameter RST=7;

always @(posedge clk or negedge rst) begin
	if(~rst)begin
		rst_sysarr<=0;    // Reset the systolic array.
		for(i=0;i<rows*cols;i=i+1)begin
			ctlper[i]<=0;    // Reset the control signal of all PEs.
		end
		for(i=0;i<rows;i=i+1)begin
			ctlbwr[i]<=0;
		end
		for(i=0;i<cols;i=i+1)begin
			ctlbinr[i]<=0;
			ctlboutr[i]<=0;
		end
		w<=0;
		in<=0;
		state<=0;
		count<=0;
		memaddr<=0;
		memdata<=0;
		memwren<=0;
		
		next_dr<=0;
		next_dc<=0;
		
		ii<=0;
		ikr<=0;
		ikc<=0;
		io<=0;
		ic<=0;
		ir<=0;
		ib<=0;
		
		pi<=0;
		pkr<=0;
		pkc<=0;
		po<=0;
		pc<=0;
		pr<=0;
		pb<=0;
		
		ro<=0;
		rc<=0;
		rr<=0;
		
		countr<=0;
		countc<=0;
		countv<=0;
		
		next_ite<=0;
	end
	else begin
		case(state)
		IDLE:begin//init
			rst_sysarr<=1;
			for(i=0;i<rows*cols;i=i+1)begin
				ctlper[i]<=0;
			end
			for(i=0;i<rows;i=i+1)begin
				ctlbwr[i]<=0;
			end
			for(i=0;i<cols;i=i+1)begin
				ctlbinr[i]<=0;
				ctlboutr[i]<=0;
			end
			memdata<=0;
			memwren<=0;
			w<=0;
			in<=0;
			count<=0;
			countr<=0;
			countc<=0;
			countv<=0;
			if(ctl[0])begin  // Go to Load Weight
				memaddr<=waddr;
				state<=LOADW;
			end
			else if(ctl[1])begin // Go to Load IN
				memaddr<=inaddr;
				state<=LOADIN;
			end
			else begin
				memaddr<=0;
				state<=IDLE;
			end
			next_ite<=0;
			signal<=0;
		end
		LOADW:begin//row
			for(i=0;i<rows;i=i+1)begin
				if(count>=3+i+vector*(rows-i-1)&&count<3+i+vector*(rows-i-1)+vector)
				ctlbwr[i]<=2;   //  Send data to the next buffer./ Store the inputs to this buffer.
				else
				ctlbwr[i]<=1;   // Send data to the next buffer.
			end
			
			if(ii>di)begin
				memaddr<=0;
			end
			else begin
			    memaddr<=waddr+io*di*dkr*dkc+ii*dkr*dkc+ikr*dkc+ikc+io;//+io is for adding the bias; when ii<di, weight is get ;when ii==di, bias is get
			end
			
			w<=memq;
			
			if(countv<vector-1)begin
				if(ii<di)begin
					if(ikc==dkc-1)begin
						ikc<=0;
						if(ikr==dkr-1)begin
							ikr<=0;
							ii<=ii+1;
						end
						else begin
							ikr<=ikr+1;
						end
					end
					else begin
						ikc<=ikc+1;
					end
				end
				else if(ii==di)begin
					ii<=ii+1;
				end
				countv<=countv+1;
			end
			else begin
				if(countr==rows-1)begin
					/*pi<=ii;
					pkr<=ikr;
					pkc<=ikc;*/
				end
				else begin
					ii<=pi;
					ikr<=pkr;
					ikc<=pkc;
					if(io==do-1)begin
						//io<=0;
					end
					else begin
						io<=io+1;
					end
					countv<=0;
					countr<=countr+1;
				end
			end
			
			if(count>3+vector*(rows-1)+vector)begin
				for(i=0;i<rows;i=i+1)begin
					ctlbwr[i]<=1;
				end
				count<=0;
				countv<=0;
				countr<=0;
				countc<=0;
				ii<=pi;
				ikr<=pkr;
				ikc<=pkc;
				memaddr<=inaddr;
				state<=LOADIN;
			end
			else begin
				//memaddr<=memaddr+1;
				count<=count+1;
			end
		end
		LOADIN:begin//col
			for(i=0;i<cols;i=i+1)begin
				if(count>=3+i+vector*(cols-i-1)&&count<3+i+vector*(cols-i-1)+vector)
				ctlbinr[i]<=2;
				else
				ctlbinr[i]<=1;
			end
			if(ii>di||ir+ikr>=dr||ic+ikc>=dc)begin
				memaddr<=0;
			end
			else if(ii==di)begin
				memaddr<=1;
			end
			else begin
				memaddr<=inaddr+ii*dr*dc+(ir+ikr)*dc+ic+ikc;
			end
			in<=memq;
			
			if(countv<vector-1)begin
				if(ii<di)begin
					if(ikc==dkc-1)begin
						ikc<=0;
						if(ikr==dkr-1)begin
							ikr<=0;
							ii<=ii+1;
						end
						else begin
							ikr<=ikr+1;
						end
					end
					else begin
						ikc<=ikc+1;
					end
				end
				else if(ii==di)begin
					ii<=ii+1;
				end
				countv<=countv+1;
			end
			else begin
				if(countc==cols-1)begin
					/*pi<=ii;
					pkr<=ikr;
					pkc<=ikc;*/
				end
				else begin
					ii<=pi;
					ikr<=pkr;
					ikc<=pkc;
					if(ic+(1<<step)+dkc>=dc)begin
						//io<=0;
					end
					else begin
						ic<=ic+(1<<step);
					end
					countv<=0;
					countc<=countc+1;
				end
			end
			
			if(count>3+vector*(cols-1)+vector)begin
				for(i=0;i<cols;i=i+1)begin
					ctlbinr[i]<=1;
				end
				count<=0;
				countv<=0;
				countr<=0;
				countc<=0;
				//determine how will the next iteration go
				ro<=po;//these are used when outputing the calculated data
				rc<=pc;
				rr<=pr;
				if(ii>=di)begin
					ii<=0;
					ikr<=0;
					ikc<=0;
					pi<=0;
					pkr<=0;
					pkc<=0;
					if(ic+(1<<step)+dkc>=dc)begin
						ic<=0;
						pc<=0;
						if(io>=do-1)begin
							io<=0;
							po<=0;
							if(ir+(1<<step)+dkr>=dr)begin
								next_ite<=3;//out end
							end
							else begin
								pr<=pr+(1<<step);
								ir<=pr+(1<<step);
								next_ite<=2;//out continue
							end
						end
						else begin
							ir<=pr;
							po<=po+rows;
							io<=po+rows;
							next_ite<=2;//out continue
						end
					end
					else begin
						ir<=pr;
						io<=po;
						pc<=pc+(cols<<step);
						ic<=pc+(cols<<step);
						next_ite<=2;//out continue
					end
				end
				else begin
					if(ikc==dkc-1)begin
						pkc<=0;
						ikc<=0;
						if(ikr==dkr-1)begin
							pkr<=0;
							ikr<=0;
							pi<=ii+1;
							ii<=ii+1;
						end
						else begin
							pi<=ii;
							pkr<=ikr+1;
							ikr<=ikr+1;
						end
					end
					else begin
						pi<=ii;
						pkr<=ikr;
						pkc<=ikc+1;
						ikc<=ikc+1;
					end
					ic<=pc;
					io<=po;
					ir<=pr;
					next_ite<=1;//continue
				end
				
				state<=CAL;
			end
			else begin
				count<=count+1;
			end
		end
		TEST:begin
			for(i=0;i<cols;i=i+1)
			ctlbinr[i]<=3;
		end
		CAL:begin//calculate
			if(count<rows||count<cols)begin
				if(count<rows)
				ctlbwr[count]<=3;
				if(count<cols)
				ctlbinr[count]<=3;
			end
			for(i=0;i<rows;i=i+1)begin
				for(j=0;j<cols;j=j+1)begin
					if(count==1+vector+rows+j)begin
						ctlper[i*cols+j]<=1;
					end
					else begin
						ctlper[i*cols+j]<=0;
					end
				end
			end
			for(i=0;i<cols;i=i+1)begin
				if(count>=2+vector+rows+i&&count<2+vector+rows+rows+i)
				ctlboutr[i]<=2;
				else
				ctlboutr[i]<=1;
			end
			
			if(count>=1+rows+cols+vector&&next_ite==1)begin
				signal<=1;
				for(i=0;i<cols;i=i+1)begin
					ctlboutr[i]<=1;
				end
				count<=0;
				countv<=0;
				countr<=0;
				countc<=0;
				next_ite<=0;
				state<=LOADW;
			end
			else if(count>2+vector+rows+rows+cols&&(next_ite==2||next_ite==3))begin
				for(i=0;i<cols;i=i+1)begin
					ctlboutr[i]<=1;
				end
				count<=0;
				countv<=0;
				countr<=0;
				countc<=0;
				state<=OUT;
			end
			else begin
				count<=count+1;
			end
		end
		OUT:begin
			for(i=0;i<cols;i=i+1)begin
				if(count>=(rows-1)*i&&count<(rows-1)*i+rows)
				ctlboutr[i]<=3;
				else
				ctlboutr[i]<=1;
			end
			//calculate how many rows and cols in the picture of the next layer
			next_dr<=((dr-dkr)>>step)+1;
			next_dc<=((dc-dkc)>>step)+1;
			if(count>=2&&count<rows*cols+2)begin
				if(ro+rows-1-countr<do&&(rc+((cols-1-countc)<<step)+dkc)<=dc)begin
					memaddr<=outaddr+(ro+rows-1-countr)*next_dr*next_dc+(rr>>step)*next_dc+((rc>>step)+cols-1-countc);
					memwren<=1;
					if(relu)begin//activation
						if(out[width-1])begin
							memdata<=0;
						end
						else begin
							memdata<=out;
						end
					end
					else begin
						memdata<=out;
					end
				end
				else begin
					memwren<=0;
				end
				signal<=2;
				if(countr==rows-1)begin
					countr<=0;
					countc<=countc+1;
				end
				else begin
					countr<=countr+1;
				end
				count<=count+1;
			end
			else if(count>=rows*cols+2)begin
				memwren<=0;
				signal<=3;
				count<=0;
				countv<=0;
				countr<=0;
				countc<=0;
				rst_sysarr<=0;
				state<=RST;
			end
			else begin
				count<=count+1;
			end
		end
		RST:begin
			memwren<=0;
			rst_sysarr<=1;
			if(next_ite==2)
			state<=LOADW;
			else begin
			    if(count<4)begin
			        count<=count+1;
			        memwren<=0;
                    memaddr<=0;
			    end
			    else begin
			        count<=0;
			        memwren<=0;
                    memaddr<=outaddr;
			        state<=LOOP;
			    end
				//signal<=4;
				//memwren<=0;
				//memaddr<=outaddr;
				//state<=IDLE;
				//state<=LOOP;
			end
		end
		LOOP:begin
			memaddr<=memaddr+1;
			if(memaddr-outaddr>=600)begin
				signal<=4;
				state<=IDLE;
			end
		end
		endcase
	end
end

endmodule
