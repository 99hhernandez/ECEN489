`timescale 1ns / 1ps

module kalman(
clk,
rst,
n,      // Input: Index of the inputs.
u,      // Input: Scalar: Acceleration.
z,      // Input: 1x2 Z Vector; Measurement of x.
x0,     // Initial state of x.
P0,     // Initial state of P.
F,      // Input: 2x2 F Matrix.
B,      // Input: 2x1 B Vector.
Q,      // Input: 2x2 Q Matrix.
H,      // Input: 2x2 H Matrix.
R,      // Input: 2x2 R Matrix.
no,     // Output: n_out.
xo,     // Output: x_out.
outen   // Output: output enable: a flag signal. 
    );

parameter len=2;		// # of input size.
parameter dsize=16;		// Width of each data.
parameter decimal=10;	// Width of fraction.

input clk,rst;
input[dsize-1:0] n;
input[dsize-1:0] u;
input[dsize*len-1:0] z;
input[dsize*len-1:0] x0;
input[dsize*len*len-1:0] P0;
input[dsize*len*len-1:0] F,H,Q,R;
input[dsize*len-1:0] B;
output reg[dsize-1:0] no;
output reg[dsize*len-1:0] xo;
output reg outen;

parameter S0 = 3'b0,
          S1 = 3'b001,
          S2 = 3'b010,
          S3 = 3'b011,
          S4 = 3'b100,
          S5 = 3'b101,
          S6 = 3'b110,
          S7 = 3'b111;

reg[dsize-1:0] mi[1:0][3:0];
wire[dsize-1:0] mo[3:0];

wire[dsize*2*2-1:0] mmin1;
wire[dsize*2*2-1:0] mmin2;
wire[dsize*2*2-1:0] mmout;

assign mmin1[dsize-1:0]=mi[0][0];            
assign mmin1[2*dsize-1:dsize]=mi[0][1];
assign mmin1[3*dsize-1:2*dsize]=mi[0][2];
assign mmin1[4*dsize-1:3*dsize]=mi[0][3];

assign mmin2[dsize-1:0]=mi[1][0];
assign mmin2[2*dsize-1:dsize]=mi[1][1];
assign mmin2[3*dsize-1:2*dsize]=mi[1][2];
assign mmin2[4*dsize-1:3*dsize]=mi[1][3];

assign mo[0]=mmout[dsize-1:0];
assign mo[1]=mmout[2*dsize-1:dsize];
assign mo[2]=mmout[3*dsize-1:2*dsize];
assign mo[3]=mmout[4*dsize-1:3*dsize];


/////////////////////////////////////////////////////////////////////
//  | mo[0] mo[1] |     | mi[0][0] mi[0][1] |   | mi[1][0] mi[1][1] |
//  | mo[2] mo[3] | =   | mi[0][2] mi[0][3] | x | mi[1][2] mi[1][3] |
/////////////////////////////////////////////////////////////////////
matmul22 #(.size(dsize),.decimal(decimal)) mm0(mmin1,mmin2,mmout);

reg[dsize-1:0] divin;
wire[dsize-1:0] divout;

///////////////////////
// divout = 1 / divin.
///////////////////////
divider #(.size(dsize),.decimal(decimal)) d0(divin,divout);

reg[3:0] state;
reg[dsize-1:0] nk;
reg zenk;
reg[dsize*len-1:0] uk,zk,xkm,xkp,yk;    // Vector; Width = 16x2 = 32.
reg[dsize*len*len-1:0] Pkm,Kk,Pkp;      // Matrix; Width = 16x2x2 = 64.
reg[dsize*len*len-1:0] temp_mul1, temp_mul2, temp_mul3, temp_mul4;
reg count;


always@(posedge clk or negedge rst)begin
    if(~rst)begin
        state <= S0;
        nk <= 16'b0;
        zenk <= 0;
        uk <= 32'b0;
        zk <= 32'b0;
        xkm <= 32'b0;
        xkp <= 32'b0;
        yk <= 32'b0;
        Pkm <= 64'b0;
        Kk <= 64'b0;
        Pkp <= 64'b0;
        count <= 0;
        no <= 16'b0;
        xo <= 16'b0;
        outen <= 16'b0;
    end
    else begin
        case(state)
            S0: begin
                nk <= n;
                zk <= z;
                uk <= u;
                state <= S1;
                outen <= 0;
            end
            S1: begin
                if(count != 1) begin
                    mi[0][0] = F[dsize*1-1:dsize*0];
                    mi[0][1] = F[dsize*2-1:dsize*1];
                    mi[0][2] = F[dsize*3-1:dsize*2];
                    mi[0][3] = F[dsize*4-1:dsize*3];
                    
                    mi[1][0] = 16'b0;
                    mi[1][1] = xkp[dsize*1-1:dsize*0];
                    mi[1][2] = 16'b0;
                    mi[1][3] = xkp[dsize*2-1:dsize*1];
                    
                    temp_mul2[1*dsize-1:0*dsize] = mo[1];
                    temp_mul2[2*dsize-1:1*dsize] = mo[3];
                    count = count + 1;
                end
                else begin
                    mi[0][0] = 16'b0;
                    mi[0][1] = B[dsize*1-1:dsize*0];
                    mi[0][2] = 16'b0;
                    mi[0][3] = B[dsize*2-1:dsize*1];
                    
                    mi[1][0] = 16'b0;
                    mi[1][1] = uk[dsize*1-1:dsize*0];
                    mi[1][2] = 16'b0;
                    mi[1][3] = uk[dsize*2-1:dsize*1];
                    
                    temp_mul2[dsize*1-1:dsize*0] = mo[1];
                    temp_mul2[dsize*2-1:dsize*1] = mo[3];
                    
                    xkm[1*dsize-1:0*dsize] = temp_mul1[1*dsize-1:0*dsize] + temp_mul2[1*dsize-1:0*dsize];
                    xkm[2*dsize-1:1*dsize] = temp_mul1[2*dsize-1:1*dsize] + temp_mul2[2*dsize-1:1*dsize];
                    
                    count = 0;
                    state <= S2;
                end
            end
            S2: begin
                if(count != 1) begin
                    mi[0][0] = F[dsize*1-1:dsize*0];
                    mi[0][1] = F[dsize*2-1:dsize*1];
                    mi[0][2] = F[dsize*3-1:dsize*2];
                    mi[0][3] = F[dsize*4-1:dsize*3];
                    
                    mi[1][0] = Pkp[dsize*1-1:dsize*0];
                    mi[1][1] = Pkp[dsize*2-1:dsize*1];
                    mi[1][2] = Pkp[dsize*3-1:dsize*2];
                    mi[1][3] = Pkp[dsize*4-1:dsize*3];
                    
                    temp_mul1[dsize*1-1:dsize*0] = mo[0];
                    temp_mul1[dsize*2-1:dsize*1] = mo[1];
                    temp_mul1[dsize*3-1:dsize*2] = mo[2];
                    temp_mul1[dsize*4-1:dsize*3] = mo[3];
                    count = count + 1;
                end
                else begin
                    mi[0][0] = temp_mul1[dsize*1-1:dsize*0];
                    mi[0][1] = temp_mul1[dsize*2-1:dsize*1];
                    mi[0][2] = temp_mul1[dsize*3-1:dsize*2];
                    mi[0][3] = temp_mul1[dsize*4-1:dsize*3];
                    
                    mi[1][0] = F[dsize*1-1:dsize*0];
                    mi[1][1] = F[dsize*2-1:dsize*1];
                    mi[1][2] = F[dsize*3-1:dsize*2];
                    mi[1][3] = F[dsize*4-1:dsize*3];
                    
                    temp_mul1[dsize*1-1:dsize*0] = mo[0];
                    temp_mul1[dsize*2-1:dsize*1] = mo[1];
                    temp_mul1[dsize*3-1:dsize*2] = mo[2];
                    temp_mul1[dsize*4-1:dsize*3] = mo[3];
                    
                    Pkm[dsize*1-1:dsize*0] = temp_mul2[dsize*1-1:dsize*0] + Q[dsize*1-1:dsize*0];
                    Pkm[dsize*2-1:dsize*1] = temp_mul2[dsize*2-1:dsize*1] + Q[dsize*2-1:dsize*1];
                    Pkm[dsize*3-1:dsize*2] = temp_mul2[dsize*3-1:dsize*2] + Q[dsize*3-1:dsize*2];
                    Pkm[dsize*4-1:dsize*3] = temp_mul2[dsize*4-1:dsize*3] + Q[dsize*4-1:dsize*3];
                    
                    count = count + 1;
                    state <= S3;
                end
            end
            S3: begin
                mi[0][0] = H[dsize*1-1:dsize*0];
                mi[0][1] = H[dsize*2-1:dsize*1];
                mi[0][2] = H[dsize*3-1:dsize*2];
                mi[0][3] = H[dsize*4-1:dsize*3];
                
                mi[1][0] = 16'b0;
                mi[1][1] = xkm[dsize*1-1:dsize*0];
                mi[1][2] = 16'b0;
                mi[1][3] = xkm[dsize*2-1:dsize*1];
                
                count = 0;
                state <= S4;
            end
            S4: begin
                if(count == 0) begin
                    mi[0][0] = H[dsize*1-1:dsize*0];
                    mi[0][1] = H[dsize*2-1:dsize*1];
                    mi[0][2] = H[dsize*3-1:dsize*2];
                    mi[0][3] = H[dsize*4-1:dsize*3];
                    
                    mi[1][0] = Pkm[dsize*1-1:dsize*0];
                    mi[1][1] = Pkm[dsize*2-1:dsize*1];
                    mi[1][2] = Pkm[dsize*3-1:dsize*2];
                    mi[1][3] = Pkm[dsize*4-1:dsize*3];
                    
                    temp_mul1[dsize*1-1:dsize*0] = mo[0];
                    temp_mul1[dsize*2-1:dsize*1] = mo[1];
                    temp_mul1[dsize*3-1:dsize*2] = mo[2];
                    temp_mul1[dsize*4-1:dsize*3] = mo[3];
                    
                    count = count + 1;
                end
                else if(count == 1) begin
                    mi[0][0] = temp_mul1[dsize*1-1:dsize*0];
                    mi[0][1] = temp_mul1[dsize*2-1:dsize*1];
                    mi[0][2] = temp_mul1[dsize*3-1:dsize*2];
                    mi[0][3] = temp_mul1[dsize*4-1:dsize*3];
                    
                    mi[1][0] = H[dsize*1-1:dsize*0];
                    mi[1][1] = H[dsize*3-1:dsize*2];
                    mi[1][2] = H[dsize*2-1:dsize*1];
                    mi[1][3] = H[dsize*4-1:dsize*3];
                    
                    temp_mul1[dsize*1-1:dsize*0] = mo[0] + R[dsize*1-1:dsize*0];
                    temp_mul1[dsize*2-1:dsize*1] = mo[1] + R[dsize*2-1:dsize*1];
                    temp_mul1[dsize*3-1:dsize*2] = mo[2] + R[dsize*3-1:dsize*2];
                    temp_mul1[dsize*4-1:dsize*3] = mo[3] + R[dsize*4-1:dsize*3];
                    
                    count = count + 1;
                end
                else if(count == 2) begin
                    divin = temp_mul1[dsize*1-1:dsize*0] + temp_mul1[dsize*3-1:dsize*2] - temp_mul1[dsize*2-1:dsize*1] * temp_mul1[dsize*4-1:dsize*3];
                    temp_mul2[dsize*1-1:dsize*0] = divout * temp_mul1[dsize*4-1:dsize*3];
                    temp_mul2[dsize*2-1:dsize*1] = divout * -1 * temp_mul1[dsize*2-1:dsize*1];
                    temp_mul2[dsize*3-1:dsize*2] = divout * -1 * temp_mul1[dsize*3-1:dsize*2];
                    temp_mul2[dsize*4-1:dsize*3] = divout * temp_mul1[dsize*1-1:dsize*0];
                    count = count + 1;
                end
                else if(count == 3) begin
                    mi[0][0] = Pkm[dsize*1-1:dsize*0];
                    mi[0][1] = Pkm[dsize*2-1:dsize*1];
                    mi[0][2] = Pkm[dsize*3-1:dsize*2];
                    mi[0][3] = Pkm[dsize*4-1:dsize*3];
                    
                    mi[1][0] = H[dsize*1-1:dsize*0];
                    mi[1][1] = H[dsize*3-1:dsize*2];
                    mi[1][2] = H[dsize*2-1:dsize*1];
                    mi[1][3] = H[dsize*4-1:dsize*3];
                    
                    temp_mul2[dsize*1-1:dsize*0] = mo[0] + R[dsize*1-1:dsize*0];
                    temp_mul2[dsize*2-1:dsize*1] = mo[1] + R[dsize*2-1:dsize*1];
                    temp_mul2[dsize*2-1:dsize*2] = mo[2] + R[dsize*3-1:dsize*2];
                    temp_mul2[dsize*4-1:dsize*3] = mo[3] + R[dsize*4-1:dsize*3];
                    
                    count = count + 1;
                end
                else if(count == 4) begin
                    mi[0][0] = temp_mul2[dsize*1-1:dsize*0];
                    mi[0][1] = temp_mul2[dsize*2-1:dsize*1];
                    mi[0][2] = temp_mul2[dsize*3-1:dsize*2];
                    mi[0][3] = temp_mul2[dsize*4-1:dsize*3]; 
                    
                    mi[1][0] = temp_mul1[dsize*1-1:dsize*0];
                    mi[1][1] = temp_mul1[dsize*2-1:dsize*1];
                    mi[1][2] = temp_mul1[dsize*3-1:dsize*2];
                    mi[1][3] = temp_mul1[dsize*4-1:dsize*3];
                    
                    Kk[dsize*1-1:dsize*0] = mo[0];
                    Kk[dsize*2-1:dsize*1] = mo[1];
                    Kk[dsize*3-1:dsize*2] = mo[2];
                    Kk[dsize*4-1:dsize*3] = mo[3];
                    
                    state <= S5;
                    count = 0;
                end
            end
            S5: begin
                mi[0][0] = Kk[dsize*1-1:dsize*0];
                mi[0][1] = Kk[dsize*2-1:dsize*1];
                mi[0][2] = Kk[dsize*3-1:dsize*2];
                mi[0][3] = Kk[dsize*4-1:dsize*3];
                
                mi[1][0] = 16'b0;
                mi[1][1] = yk[dsize*1-1:dsize*0];
                mi[1][2] = 16'b0;
                mi[1][3] = yk[dsize*2-1:dsize*1];
                
                xkp[dsize*1-1:dsize*0] = xkm[dsize*1-1:dsize*0] + mo[1];
                xkp[dsize*2-1:dsize*1] = xkm[dsize*2-1:dsize*1] + mo[3];
                state <= S6;
            end
            S6: begin
                if(count == 0) begin
                    mi[0][0] = Kk[dsize*1-1:dsize*0];
                    mi[0][1] = Kk[dsize*2-1:dsize*1];
                    mi[0][2] = Kk[dsize*3-1:dsize*2];
                    mi[0][3] = Kk[dsize*4-1:dsize*3];
                    
                    mi[1][0] = H[dsize*1-1:dsize*0];
                    mi[1][1] = H[dsize*2-1:dsize*1];
                    mi[1][2] = H[dsize*3-1:dsize*2];
                    mi[1][3] = H[dsize*4-1:dsize*3];
                    
                    temp_mul1[dsize*1-1:dsize*0] = 16'b10000000000 - mo[0];
                    temp_mul1[dsize*2-1:dsize*1] = 16'b0 - mo[1];
                    temp_mul1[dsize*3-1:dsize*2] = 16'b0 - mo[2];
                    temp_mul1[dsize*4-1:dsize*3] = 16'b10000000000 - mo[3];
                    count = count + 1;
                end
                else if(count == 1) begin
                    mi[0][0] = temp_mul1[dsize*1-1:dsize*0];
                    mi[0][1] = temp_mul1[dsize*2-1:dsize*1];
                    mi[0][2] = temp_mul1[dsize*3-1:dsize*2];
                    mi[0][3] = temp_mul1[dsize*4-1:dsize*3];
                    
                    mi[1][0] = Pkm[dsize*1-1:dsize*0];
                    mi[1][1] = Pkm[dsize*2-1:dsize*1];
                    mi[1][2] = Pkm[dsize*3-1:dsize*2];
                    mi[1][3] = Pkm[dsize*4-1:dsize*3];
                    
                    Pkm[dsize*1-1:dsize*0] = mo[0];
                    Pkm[dsize*1-1:dsize*0] = mo[0];
                    Pkm[dsize*1-1:dsize*0] = mo[0];
                    Pkm[dsize*1-1:dsize*0] = mo[0];
                    count = 0;
                end
            end
            S7: begin
                no = nk;
                xo[dsize*1-1:dsize*0] = xkp[dsize*1-1:dsize*0];
                xo[dsize*2-1:dsize*1] = xkp[dsize*2-1:dsize*1];
                outen = 1;
            end
        endcase
    end
end

endmodule
