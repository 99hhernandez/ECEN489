`timescale 1ns / 1ps

module pmu(
clk,
rst,
dis,
dis_path,
path_out,
dis_out
    );

parameter r = 2;
parameter K = 3;

parameter ns = 1 << (K-1); // number of states = 4.
parameter mask = ns - 1; // mask = 3 = 'b11. The mask is used to take only lower 2 bits of a signal.

input clk,rst;

// dis:  path metric in each states on the current column
// dis contains 2^(K-1) = 4 path metrics.
// each of path metric is represented by a 8-bit number.
input[(1<<(K-1))*8-1:0] dis;//...[second state curr dis 15:8][first state curr dis 7:0]

// dis_path: hamming distances on all edges
// legnth: 2^(K-1)*r*2 = 16
input[(1<<(K-1))*2*r-1:0] dis_path; // length: 16. represents 8 hamming distances.

// path_out: Output path of each state with minimum path metric
// length: 2^(K-1) * K = 12 = 4 * 3
output reg[(1<<(K-1))*K-1:0] path_out;

// The path metric in state i.
output reg[(1<<(K-1))*8-1:0] dis_out;

wire[(1<<(K-1))*8-1:0] dis_outw;
wire[(1<<(K-1))*K-1:0] path_outw; // length = 12.

genvar gi;
wire [(1<<(K-1))-1:0] path_sele;

generate
    for(gi=0; gi < (1<<(K-1)); gi = gi+1)begin : gencomp
        // gi: 0, 1, 2, 3
        // (gi << 1) & mask: 00, 10, 00, 10 (decimal: 0, 2, 0, 2)
        // gi >> (K-2): 0, 0, 1, 1
        comp #(.r(r)) c0(
        dis[8* (((gi<<1)&mask)+1) - 1 : 8*((gi<<1)&mask) ], // dis0.
        dis_path[2 * r * (((gi<<1)&mask)) + r * (gi>>(K-2)) + r - 1 : 2 * r * ((gi<<1)&mask) + r * (gi>>(K-2))], // path0.
        dis[8 * (((gi<<1)&mask)+1+1) - 1 : 8 * (((gi<<1)&mask)+1)], // dis1.
        dis_path[2 * r * (((gi<<1)&mask)+1) + r * (gi>>(K-2)) + r - 1 : 2 * r * (((gi<<1)&mask) + 1 ) + r * (gi>>(K-2))], // path1.
        path_sele[gi], // path_out.
        dis_outw[8*(gi+1)-1:8*gi]); // dis_out.
        // comp(dis[7:0],   dis_path[1:0],   dis[15:8],  dis_path[5:4],   path_sele[0], dis_outw[7:0])
        // comp(dis[23:16], dis_path[9:8],   dis[31:24], dis_path[13:12], path_sele[1], dis_outw[15:8])
        // comp(dis[7:0],   dis_path[3:2],   dis[15:8],  dis_path[7:6],   path_sele[2], dis_outw[23:16])
        // comp(dis[23:16], dis_path[11:10], dis[31:24], dis_path[15:14], path_sele[3], dis_outw[31:24])
    
        assign path_outw[K*(gi+1)-1:K*gi] = (((gi>>(K-2))<<(K-1)) | (((gi<<1)&mask) + path_sele[gi]));//path_sele[gi]?:(((gi>>(K-1))<<K)|((gi<<1)&mask));
        // path_outw[2:0]  = 000 | (00 + path_sele[0]) = [0 0 path_sele[0]]: path selection for state 00
        // path_outw[5:3]  = 000 | (10 + path_sele[1]) = [0 1 path_sele[1]]: path selection for state 01
        // path_outw[8:6]  = 100 | (00 + path_sele[2]) = [1 0 path_sele[2]]: path selection for state 10
        // path_outw[11:9] = 100 | (10 + path_sele[3]) = [1 1 path_sele[3]]: path selection for state 11
    end
endgenerate

always@(posedge clk or negedge rst)begin
    if(~rst)begin
        dis_out<=0;
        path_out<=0;
    end
    else begin
        dis_out<=dis_outw;
        path_out<=path_outw;
    end
end

endmodule
