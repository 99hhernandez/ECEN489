`timescale 1ns / 1ps

module top_viterbi(

    );

parameter r=2;
parameter K=3;
parameter lenin=10;
parameter lenout=5;

wire clk;
wire memctl;

wire[15:0] memaddraxi;
wire[7:0] memdinaxi;
wire memwenaxi;

reg trigger;

//1st port, controlled by arm or fpga
wire[15:0] memaddra;
wire[7:0] memdina;
wire memwena;
wire[7:0] memdouta;

//2nd port, controlled by fpga
reg[15:0] memaddrb;
reg[7:0] memdinb;
reg memwenb;
wire[7:0] memdoutb;

//fpga controlled memory ports
reg[15:0] memaddrfpga;
reg[7:0] memdinfpga;
reg memwenfpga;

assign memaddra=memctl?memaddraxi:memaddrfpga;
assign memdina=memctl?memdinaxi:memdinfpga;
assign memwena=memctl?memwenaxi:memwenfpga;

datatrans_sys_wrapper mw0
       (.axiclk(clk),
        .memaddr(memaddraxi),
        .memctl(memctl),
        .memdin(memdinaxi),
        .memdout(memdouta),
        .memwen(memwenaxi),
        .triggerin(trigger));

blk_mem_gen_0 b0
  (
      clk,
      memwena,
      memaddra,
      memdina,
      memdouta,
      clk,
      memwenb,
      memaddrb,
      memdinb,
      memdoutb
  );

reg vrst;
reg[lenin-1:0] codein;
reg[(1<<(K-1))*2*r-1:0] state_out;
wire[lenout-1:0] codeout;
wire finish;

viterbi #(.r(r),.K(K),.lenin(lenin),.lenout(lenout)) v0(
clk,
vrst,
codein,
state_out,
codeout,
finish
    );

reg[7:0] state;

reg[15:0] count;

reg[31:0] cycle;

always@(posedge clk)begin
    if(memctl)begin
        state<=0;
        trigger<=0;
        count<=0;
        
        memwenfpga<=0;
        memaddrfpga<=0;
        memdinfpga<=0;
        
        memwenb<=0;
        memaddrb<=0;
        memdinb<=0;
        
        cycle<=0;
        
        codein<=0;
        state_out<=0;
        vrst<=0;
    end
    else begin
        case(state)
        0:begin
            if(count>=2&&count<4)begin
                codein<=codein|(memdoutb<<(8*(count-2)));
            end
            else if(count>=4&&count<6)begin
                state_out<=state_out|(memdoutb<<(8*(count-4)));
            end
            else if(count==6)begin
                state<=1;
            end
            memaddrb<=memaddrb+1;
            count<=count+1;
        end
        1:begin
            vrst<=1;
            count<=0;
            state<=2;
        end
        2:begin
            if(finish)begin
               state<=3;
            end
            cycle<=cycle+1;
        end
        3:begin
           memdinb<=codeout;
           memaddrb<=100;
           memwenb<=1;
           state<=4;
        end
        4:begin
            if(count<=3)begin
                memwenb<=1;
                memaddrb<=200+count;
                memdinb<=(cycle>>(count*8))&'hff;
                count<=count+1;
            end
            else begin
                memwenb<=0;
                trigger<=1;
            end
        end
        endcase
    end
end


endmodule