`timescale 1ns / 1ps

module top_decoder(

    );

parameter width=8;
parameter decimal=4;
parameter fftn=8;
parameter signal=3;

wire clk;
wire clk2;
//wire clk2, clk4, clk8, clk16;
clkdivider cd0(clk,clk2);
//clkdivider cd1(clk2,clk4);
//clkdivider cd2(clk4,clk8);
//clkdivider cd3(clk8,clk16);
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
      clk2, 
      memwenb,
      memaddrb,
      memdinb,
      memdoutb
  );

reg idct_rst;
reg[32*64-1:0] dctin;
wire[32*64-1:0] idctout;
wire idct_finish;

//idct i0(
//clk2,
//idct_rst,
//dctin,
//idctout,
//idct_finish
//    );

reg izz_rst;
reg[32*64-1:0] zigzag;//[64th data (32bits)]..[2nd data][1st data]
wire[32*64-1:0] izz_outdata;
wire izz_finish;

izigzag(
clk2,
izz_rst,
zigzag,
izz_outdata,
izz_finish
    );

reg huff_rst;
reg[15:0] huffcode;
reg[8*16-1:0] hufftable;
reg[8*256-1:0] huffsymbol;
wire[7:0] huffdata;
wire[7:0] hufflength;
wire huff_finish;

huffmandecode h0(
clk2,
huff_rst,
huffcode,
hufftable,
huffsymbol,
huffdata,
hufflength,
huff_finish
    );

parameter IDLE=0;
parameter IDCT0=1;
parameter IDCT1=2;
parameter IDCT2=3;
parameter IDCT3=4;
parameter IDCT4=5;
parameter CYCLE=6;
parameter ZZ0=7;
parameter ZZ1=8;
parameter ZZ2=9;
parameter ZZ3=10;
parameter ZZ4=11;
parameter HUFF0=12;
parameter HUFF1=13;
parameter HUFF2=14;
parameter HUFF3=15;
parameter HUFF4=16;

reg[7:0] state;

reg[15:0] count;

reg[31:0] cycle;

always@(posedge clk2)begin
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
        
        idct_rst<=0;
        izz_rst<=0;
        huff_rst<=0;
    end
    else begin
        case(state)
        IDLE:begin
            if(count>=2)begin
                if(memdoutb==1)begin//idct
                    state<=IDCT0;
                    count<=0;
                end
                else if(memdoutb==2)begin//zigzag
                    state<=ZZ0;
                    count<=0;
                end
                else if(memdoutb==3)begin//huffman
                    state<=HUFF0;
                    count<=0;
                end
            end
            else
            count<=count+1;
        end
        IDCT0:begin
            dctin<=0;
            idct_rst<=0;
            state<=IDCT1;
        end
        IDCT1:begin
            idct_rst<=0;
            if(count>=3)begin
                dctin<=dctin|(memdoutb<<((count-3)*8));
                if(count>=64*4+3-1)begin
                    state<=IDCT2;
                end
            end
            count<=count+1;
            memwenb<=0;
            memaddrb<=memaddrb+1;
        end
        IDCT2:begin
            idct_rst<=1;
            state<=IDCT3;
        end
        IDCT3:begin
            if(idct_finish)begin
                state<=IDCT4;
                count<=0;
                memaddrb<=1000-1;
            end
            cycle<=cycle+1;
        end
        IDCT4:begin
            memdinb<=(idctout>>(count*8))&'hff;
            if(count>=64*4+2)begin
                memwenb<=0;
                count<=0;
                trigger<=0;
                state<=CYCLE;
            end
            else
            begin
                count<=count+1;
                memwenb<=1;
                memaddrb<=memaddrb+1;
            end
        end
        ZZ0:begin
            zigzag<=0;
            izz_rst<=0;
            state<=ZZ1;
        end
        ZZ1:begin
            izz_rst<=0;
            if(count>=3)begin
                zigzag<=zigzag|(memdoutb<<((count-3)*8));
                if(count>=64*4+3-1)begin
                    state<=ZZ2;
                end
            end
            count<=count+1;
            memwenb<=0;
            memaddrb<=memaddrb+1;
        end
        ZZ2:begin
            izz_rst<=1;
            state<=ZZ3;
        end
        ZZ3:begin
            if(izz_finish)begin
                state<=ZZ4;
                count<=0;
                memaddrb<=1000-1;
            end
            cycle<=cycle+1;
        end
        ZZ4:begin
            memdinb<=(izz_outdata>>(count*8))&'hff;
            if(count>=64*4+2)begin
                memwenb<=0;
                count<=0;
                trigger<=0;
                state<=CYCLE;
            end
            else
            begin
                count<=count+1;
                memwenb<=1;
                memaddrb<=memaddrb+1;
            end
        end
        HUFF0:begin
            huffcode<=0;
            hufftable<=0;
            huffsymbol<=0;
            huff_rst<=0;
            count<=0;
            memwenb<=0;
            memaddrb<=0;
            state<=HUFF1;
        end
        HUFF1:begin
            huff_rst<=0;
            if(count>=3&&count<5)begin
                huffcode<=huffcode|(memdoutb<<((count-3)*8));
            end
            else if(count>=5&&count<5+16)begin
                hufftable<=hufftable|(memdoutb<<((count-5)*8));
            end
            else if(count>=21&&count<21+256)begin
                huffsymbol<=huffsymbol|(memdoutb<<((count-21)*8));
            end
            else if(count>=21+256)begin
                state<=HUFF2;
            end
            count<=count+1;
            memwenb<=0;
            memaddrb<=memaddrb+1;
        end
        HUFF2:begin
            huff_rst<=1;
            state<=HUFF3;
        end
        HUFF3:begin
            if(huff_finish)begin
                state<=HUFF4;
                count<=0;
                memaddrb<=1000-1;
            end
            cycle<=cycle+1;
        end
        HUFF4:begin
            if(count==0)
            memdinb<=huffdata;
            else if(count==1)
            memdinb<=hufflength;
            if(count>=4+2)begin
                memwenb<=0;
                count<=0;
                trigger<=0;
                state<=CYCLE;
            end
            else
            begin
                count<=count+1;
                memwenb<=1;
                memaddrb<=memaddrb+1;
            end
        end

        CYCLE:begin
            if(count<=3)begin
                memwenb<=1;
                memaddrb<=2000+count;
                memdinb<=(cycle>>(count*8))&'hff;
                count<=count+1;
            end
            else begin
                trigger<=1;
            end
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
