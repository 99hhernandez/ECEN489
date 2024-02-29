`timescale 1ns / 1ps

module top_sysarr(

    );

parameter width=16;
parameter decimal=8;
parameter memaddrbits=16;
parameter rows=8;
parameter cols=8;
parameter vector=16;

wire clk;

wire clk2;

clkdivider cd0(clk,clk2);

wire[15:0] memaddraxi;
wire[7:0] memdinaxi;
wire memwenaxi;
wire[7:0] memdoutaxi;

reg trigger;

reg[15:0] memaddrb;
reg[7:0] memdinb;
reg memwenb;
wire[7:0] memdoutb;

wire[15:0] memaddr1;
wire[width-1:0] memdin1;
wire memwen1;
wire[width-1:0] memdout1;

reg[15:0] memaddrfpga;
reg[width-1:0] memdinfpga;
reg memwenfpga;

wire[15:0] memaddrarr;
wire[width-1:0] memdinarr;
wire memwenarr;

reg memctl2;

assign memaddr1=memctl2?memaddrarr:memaddrfpga;
assign memdin1=memctl2?memdinarr:memdinfpga;
assign memwen1=memctl2?memwenarr:memwenfpga;

datatrans_sys_wrapper mw0
       (.axiclk(clk),
        .memaddr(memaddraxi),
        .memctl(memctl),
        .memdin(memdinaxi),
        .memdout(memdoutaxi),
        .memwen(memwenaxi),
        .triggerin(trigger));

blk_mem_gen_0 b0
  (
      clk,
      memwenaxi,
      memaddraxi,
      memdinaxi,
      memdoutaxi,
      clk2,
      memwenb,
      memaddrb,
      memdinb,
      memdoutb
  );
  
blk_mem_gen_1 b1
    (
        clk2,
        memwen1,
        memaddr1,
        memdin1,
        memdout1
    );

wire rst;

reg[7:0] step;
reg relu;
reg[7:0] shift;
reg[7:0] do,di,dr,dc,dkr,dkc;

reg[memaddrbits-1:0] waddr;
reg[memaddrbits-1:0] inaddr;
reg[memaddrbits-1:0] outaddr;

reg[7:0] ctl;//bit0: to w, 1: to in, 2: no output
wire[7:0] signal;

reg rstsys;

wire[cols*2*width-1:0] probe;

wire[7:0] probe_io,probe_ii,probe_ir,probe_ic,probe_ikr,probe_ikc,probe_ro,probe_rc,probe_state;

matrix_cal #(.width(width),.decimal(decimal),.rows(rows),.cols(cols),.vector(vector),.memaddrbits(memaddrbits)) mc0(clk2,rstsys,memaddrarr,memdinarr,memwenarr,memdout1,waddr,inaddr,outaddr,step,relu,do,di,dr,dc,dkr,dkc,out,probe,probe_io,probe_ii,probe_ir,probe_ic,probe_ikr,probe_ikc,probe_ro,probe_rc,probe_state,ctl,signal);

reg[7:0] i,j;

reg[7:0] state;

reg[7:0] shift;

reg[15:0] addroffset;

reg[15:0] count;

always@(posedge clk2)begin
	if(memctl)begin
	    memctl2<=0;
	    state<=0;
	    shift<=0;
	    addroffset<=0;
	    count<=0;
	    ctl<=1;
	    relu<=0;
        step<=0;
        shift<=0;
		do<=0;
		di<=0;
		dr<=0;
		dc<=0;
		dkr<=0;
		dkc<=0;
		waddr<=0;
		inaddr<=0;
		outaddr<=0;
		state<=0;
		rstsys<=0;
		trigger<=0;
	end 
	else begin
		case(state)
		0:begin
		    memctl2<=0;
		    memwenfpga<=0;
            memaddrfpga<=0;
            memdinfpga<=0;
            memwenb<=0;
            memaddrb<=0;
            memdinb<=0;
            count<=0;
            state<=state+1;
		end
		1:begin
		    if(count>=2)begin
		        if(memdoutb)begin//this is not the first time
		            addroffset<='h1f54;
		        end
		        else begin
		            addroffset<=0;
		        end
		        state<=state+1;
		        count<=0;
		    end
		    else
		    count<=count+1;
		end
		2:begin
		    memwenfpga<=1;
            memaddrfpga<=addroffset;
            memdinfpga<=0;
            memwenb<=0;
            memaddrb<=1+addroffset*width/8;
            memdinb<=0;
            count<=0;
            shift<=0;
            state<=state+1;
		end
		3:begin
		  if(count>=2)begin
              if(shift==width)begin
                if(memaddrfpga>='h2264-1)begin
                    state<=state+1;
                end
                else begin
                    memdinfpga<=memdoutb;
                    memaddrfpga<=memaddrfpga+1;
                    shift<=8;
                end
              end
              else begin
                  memdinfpga<=memdinfpga|(memdoutb<<shift);
                  shift<=shift+8;
              end
          end
          memaddrb<=memaddrb+1;
          count<=count+1;
		end
		4:begin
		    memctl2<=1;
		    memwenfpga<=0;
            memaddrfpga<=0;
            memdinfpga<=0;
            memwenb<=0;
            memaddrb<=0;
            memdinb<=0;
            count<=0;
            state<=state+1;
		end
		5:begin
		    rstsys<=0;
		    relu<=1;
            step<=1;
            shift<=2;
            do<=4;
            di<=1;
            dr<=28;
            dc<=28;
            dkr<=5;
            dkc<=5;
            waddr<=2;
            inaddr<=16'h1f54;
            outaddr<=16'h1f54+28*28*1;
            state<=state+1;
		end
		6:begin
			rstsys<=1;
			ctl<=1;
			state<=state+1;
		end
		7:begin
			ctl<=0;
			if(signal==4)begin
				state<=state+1;
			end
		end
		8:begin
			do<=4;
			di<=4;
			dr<=12;
			dc<=12;
			dkr<=5;
			dkc<=5;
			waddr<=106;
			inaddr<=16'h2264;
			outaddr<=16'h2264+12*12*4;
			rstsys<=0;
			state<=state+1;
		end
		9:begin
			rstsys<=1;
			ctl<=1;
			state<=state+1;
		end
		10:begin
			ctl<=0;
			if(signal==4)begin
				state<=state+1;
			end
		end
		11:begin
			relu<=1;
			step<=0;
			do<=100;
			di<=64;
			dr<=1;
			dc<=1;
			dkr<=1;
			dkc<=1;
			waddr<=510;
			inaddr<=16'h24a4;
			outaddr<=16'h24a4+4*4*4;
			rstsys<=0;
			state<=state+1;
		end
		12:begin
			rstsys<=1;
			ctl<=1;
			state<=state+1;
		end
		13:begin
			ctl<=0;
			if(signal==4)begin
				state<=state+1;
			end
		end
		14:begin
			relu<=0;
			step<=0;
			do<=10;
			di<=100;
			dr<=1;
			dc<=1;
			dkr<=1;
			dkc<=1;
			waddr<=7010;
			inaddr<=16'h24e4;
			outaddr<=16'h24e4+100;
			rstsys<=0;
			state<=state+1;
		end
		15:begin
			rstsys<=1;
			ctl<=1;
			state<=state+1;
		end
		16:begin
			ctl<=0;
			if(signal==4)begin
				state<=state+1;
			end
		end
		17:begin
		  memctl2<=0;
          rstsys<=0;
          memwenfpga<=0;
          memaddrfpga<='h24e4+100;
          memdinfpga<=0;
          memwenb<=1;
          memaddrb<=20000-1;
          memdinb<=0;
          count<=0;
          shift<=0;
          state<=state+1;
        end
		18:begin
		   if(count>=2)begin
              if(shift==width)begin
                if(memaddrfpga>='h24e4+100+10-1)begin
                    state<=state+1;
                end
                else begin
                    count<=0;
                    memaddrfpga<=memaddrfpga+1;
                    shift<=0;
                end
              end
              else begin
                  memdinb<=((memdout1>>shift)&'hff);
                  memaddrb<=memaddrb+1;
                  shift<=shift+8;
              end
          end
          else begin
             count<=count+1;
          end
		end
		19:begin
          memctl2<=0;
          rstsys<=0;
          memwenfpga<=0;
          memaddrfpga<='h0;
          memdinfpga<=0;
          memwenb<=1;
          memaddrb<=30000-1;
          memdinb<=0;
          count<=0;
          shift<=0;
          state<=state+1;
        end
        20:begin
           if(count>=2)begin
              if(shift==width)begin
                if(memaddrfpga>='h24e4+100+10-1)begin
                    state<=state+1;
                end
                else begin
                    count<=0;
                    memaddrfpga<=memaddrfpga+1;
                    shift<=0;
                end
              end
              else begin
                  memdinb<=((memdout1>>shift)&'hff);
                  memaddrb<=memaddrb+1;
                  shift<=shift+8;
              end
          end
          else begin
             count<=count+1;
          end
        end
		21:begin
		  memwenfpga<=0;
          memaddrfpga<=0;
          memdinfpga<=0;
          memwenb<=0;
          memaddrb<=0;
          memdinb<=0;
          count<=0;
          shift<=0;
		  trigger<=1;
		end
		endcase
	end
end

endmodule


module clkdivider(
clk,
clkout
);
input clk;
output reg clkout;

reg[3:0] count;

always@(posedge clk)begin
    clkout<=~clkout;
end

endmodule

