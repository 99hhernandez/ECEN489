`timescale 1ns / 1ps

module top_kalman(

    );

parameter len=2;//# of input data
parameter dsize=16;//the length of each data
parameter decimal=10;

wire clk;
wire memctl;

wire clk2;

clkdivider cd0(clk,clk2);

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

reg memweni;
reg[9:0] memaddri;
reg[95:0] memdini;
wire[95:0] memdouti;

blk_mem_gen_1 b1
    (
        clk2,
        memweni,
        memaddri,
        memdini,
        memdouti
    );
    
reg memweno;
reg[9:0] memaddro;
reg[31:0] memdino;
wire[31:0] memdouto;

blk_mem_gen_2 b2
    (
        clk2,
        memweno,
        memaddro,
        memdino,
        memdouto
    );

reg krst;
reg[dsize-1:0] n;//NO.n data
reg[dsize-1:0] u;
reg[dsize*len-1:0] z;
reg[dsize*len-1:0] x0;
reg[dsize*len*len-1:0] P0;
reg[dsize*len*len-1:0] F,H,Q,R;
reg[dsize*len-1:0] B;
wire[dsize-1:0] no;
wire[dsize*len-1:0] xo;
wire outen;

kalman #(.dsize(dsize),.decimal(decimal)) k0(
clk2,
krst,
n,
u,
z,
x0,
P0,
F,
B,
Q,
H,
R,
no,
xo,
outen
    );

wire[dsize-1:0] mask;

assign mask=(~(0));

reg[7:0] i,j;

reg[7:0] state;

reg[15:0] count;

reg[7:0] shift;

always@(posedge clk2)begin
    if(memctl)begin
        state<=0;
        count<=0;
        shift<=0;
        trigger<=0;
        
        memwenfpga<=0;
        memaddrfpga<=0;
        memdinfpga<=0;
        
        memwenb<=0;
        memaddrb<=0;
        memdinb<=0;
        
        krst<=0;
        
        x0<=0;
        P0<=0;
        F<=0;
        B<=0;
        Q<=0;
        H<=0;
        R<=0;
    end 
    else begin
        case(state)
        0:begin
          if((count>=2)&&(count<2+2*(dsize/8)))begin
              x0<=x0|(memdoutb<<((count-2)*8));
          end
          else if((count>=2+2*(dsize/8))&&(count<2+6*(dsize/8)))begin
              P0<=P0|(memdoutb<<((count-2-2*(dsize/8))*8));
          end
          else if((count>=2+6*(dsize/8))&&(count<2+10*(dsize/8)))begin
              F<=F|(memdoutb<<((count-2-6*(dsize/8))*8));
          end
          else if((count>=2+10*(dsize/8))&&(count<2+12*(dsize/8)))begin
              B<=B|(memdoutb<<((count-2-10*(dsize/8))*8));
          end
          else if((count>=2+12*(dsize/8))&&(count<2+16*(dsize/8)))begin
              H<=H|(memdoutb<<((count-2-12*(dsize/8))*8));
          end
          else if((count>=2+16*(dsize/8))&&(count<2+20*(dsize/8)))begin
              Q<=Q|(memdoutb<<((count-2-16*(dsize/8))*8));
          end
          else if((count>=2+20*(dsize/8))&&(count<2+24*(dsize/8)))begin
              R<=R|(memdoutb<<((count-2-20*(dsize/8))*8));
          end
          else if(count>=2+24*(dsize/8))begin
              state<=state+1;
          end
          count<=count+1;
          memwenb<=0;
          memaddrb<=memaddrb+1;
        end
        1:begin
          memwenfpga<=0;
          memaddrfpga<=0;
          memdinfpga<=0;
          memwenb<=0;
          memaddrb<=100;
          memdinb<=0;
          memweni<=1;
          memaddri<=0;
          memdini<=0;
          count<=0;
          state<=state+1;
        end
        2:begin
          if(count>=2)begin
              if(shift==3*dsize)begin
                if(memaddri>=1000-1)begin
                    state<=state+1;
                end
                else begin
                    memdini<=memdoutb;
                    memaddri<=memaddri+1;
                    shift<=8;
                end
              end
              else begin
                  memdini<=memdini|(memdoutb<<shift);
                  shift<=shift+8;
              end
          end
          if(memaddrb>=100+1000*(dsize/8)*3-1)
          memaddrb<=100;
          else
          memaddrb<=memaddrb+1;
          count<=count+1;
        end
        3:begin
          memwenfpga<=0;
          memaddrfpga<=0;
          memdinfpga<=0;
          memwenb<=0;
          memaddrb<=0;
          memdinb<=0;
          memweni<=0;
          memaddri<=0;
          memdini<=0;
          memweno<=1;
          memaddro<=0;
          memdino<=(mask>>1);
          count<=0;
          shift<=0;
          state<=state+1;
        end
        4:begin
          memweno<=1;
          if(memaddro>=999)
          state<=state+1;
          else
          memaddro<=memaddro+1;
          memdino<=(mask>>1);
        end
        5:begin
          memwenfpga<=0;
          memaddrfpga<=0;
          memdinfpga<=0;
          memwenb<=0;
          memaddrb<=0;
          memdinb<=0;
          memweni<=0;
          memaddri<=0;
          memdini<=0;
          memweno<=0;
          memaddro<=0;
          memdino<=0;
          count<=0;
          shift<=0;
          state<=state+1;
        end
        6:begin
          if(count>=2)begin
            krst<=1;
            n<=count-2;
            u<=memdouti&mask;
            z<=(memdouti>>dsize);
            if(outen)begin
                memweno<=1;
                memaddro<=no;
                memdino<=xo&mask;
            end
            else begin
                memweno<=0;
            end
          end
          if(count>=1002)begin
            state<=state+1;
            count<=0;
          end
          else
          count<=count+1;
          memaddri<=memaddri+1;
        end
        7:begin
          krst<=0;
          memwenfpga<=0;
          memaddrfpga<=0;
          memdinfpga<=0;
          memwenb<=1;
          memaddrb<=15000-1;
          memdinb<=0;
          memweno<=0;
          memaddro<=0;
          count<=0;
          shift<=0;
          state<=state+1;
        end
        8:begin
          if(count>=2)begin
              if(shift==dsize)begin
                if(memaddrb>=15000+1000*(dsize/8))begin
                    state<=state+1;
                end
                else begin
                    count<=0;
                    memaddro<=memaddro+1;
                    shift<=0;
                end
              end
              else begin
                  memdinb<=((memdouto>>shift)&'hff);
                  memaddrb<=memaddrb+1;
                  shift<=shift+8;
              end
          end
          else begin
             count<=count+1;
          end
        end
        9:begin
          memwenfpga<=0;
          memaddrfpga<=0;
          memdinfpga<=0;
          memwenb<=0;
          memaddrb<=0;
          memdinb<=0;
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