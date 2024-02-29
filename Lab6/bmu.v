`timescale 1ns / 1ps
// Refer to ECEN 489/689 Lecture 10 Page 19
module bmu(
clk,
rst,
code, // codeword (parity bits) received.
state_next, // 8 expected parity bits.
dis_out // 8 hamming distances.
    );

parameter r=2;  // Number of parity bits for each message bit.
parameter K=3;  // Convolutional window size.

input clk,rst;
input[r-1:0] code;
input[(1<<(K-1))*2*r-1:0] state_next;   // Length: 2^(2) * 2 * 2 = 16. 
output reg[(1<<(K-1))*2*r-1:0] dis_out; // Length: 16. Contains 8 hamming distances.

wire[(1<<(K-1))*2*r-1:0] dis_outw;

genvar gi;
generate
    for(gi = 0; gi < 2*(1<<(K-1)); gi = gi + 1) begin : genhdis    // gi from 0 to 2*(2^2)-1 = 7. 
       // Calculate the hamming distance between each of the possible next states and the received codeword.
       // dist_outw[1:0] = HammingDist(code, state_next[1:0])
       // dist_outw[3:2] = HammingDist(code, state_next[3:2])
       // dist_outw[5:4] = HammingDist(code, state_next[5:4])
       // ...
       // dist_outw[15:14] = HammingDist(code, state_next[15:14])
       hammingdis #(.r(r)) hd(code,state_next[(gi+1)*r-1:gi*r],dis_outw[(gi+1)*r-1:gi*r]);
    end
endgenerate

reg[7:0] i;

always@(posedge clk or negedge rst)begin
    if(~rst)begin
        dis_out<=0;
    end
    else begin
        dis_out<=dis_outw;
    end
end

endmodule
