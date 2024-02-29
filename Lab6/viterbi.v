`timescale 1ns / 1ps

module viterbi(
clk,
rst,
codein, // input: the code word sequence; length = param(lenin) = 10.
states, // input: state; length: 2^(k-1)*2*r = 16. 8 expected parity bits
codeout, // output: decoded message; length: lenout = 5.
finish // output: 1 bit flag signal.
    );

parameter r=2; // Number of parity bits in each cycle.
parameter K=3; // Max convolutional window size.
parameter lenin=10; // Length of the input code word.
parameter lenout=5; // Length of the output decoded message.

parameter maskcode=(1<<r)-1; // 11.
parameter maskstate=(1<<(K-1))-1; // 11.
parameter maskpath=(1<<K)-1; // 111. take lower 3 bits.

input clk,rst;
input[lenin-1:0] codein;
input[(1<<(K-1))*2*r-1:0] states; // input: state; length: 2^(k-1)*2*r = 16.
output reg[lenout-1:0] codeout;
output reg finish;


// Some registers/wiers you may use.
// You can uncomment them or create your own.
 reg[7:0] state;
 reg[7:0] code_count;
 reg[7:0] count;
 reg[7:0] i;
 reg[7:0] mindis;
 reg[7:0] mins;
 reg[r-1:0] code; // code word we exam each time.
 wire[(1<<(K-1))*2*r-1:0] dis_path_out; // length: 16.
 reg[lenout*K-1:0] paths[(1<<(K-1))-1:0]; //each K: [input dir 0/1: 1bit][last state: (K-1)bits]
 reg[(1<<(K-1))*8-1:0] dis[1:0]; // 4*8 // path metrics
 wire[(1<<(K-1))*K-1:0] pmu_path_out;
 wire[(1<<(K-1))*8-1:0] pmu_dis_out;


// Example of the instantiation of the bmu module
// You can uncomment it or create your own.
// Branch Metric Unit
 bmu #(.r(r),.K(K)) b0(
 clk,
 rst,
 code,
 states,
 dis_path_out
     );


// Example of the instantiation of the pmu module
// You can uncomment it or create your own.
// Path Metric Unit
 pmu #(.r(r),.K(K)) p0(
 clk,
 rst,
 dis[1],
 dis_path_out,
 pmu_path_out,
 pmu_dis_out
     );




always@(posedge clk or negedge rst)begin
    if(~rst)begin
        // Start of your code
        state <= 0;
        codeout <= 0;
        code <= 0;
        i <= 0;
        count <= 0;
        code_count <= 0;
        finish <= 0;
        
        dis[0] <= (~(0)) & ((~(0)) << 8);
        dis[1] <= ~(0);
        for (i=0; i < 1<<(K-1); i=i+1) begin
            paths[i] <= 0;
        end
        // End of your code
    end
    else begin
        // Start of your code
        case(state)
        0:begin
            //2bits of codein to input bmu
            code <= (codein >> (16 - (8+2*i))) & maskcode;
            code_count <= code_count + 2;
            //input of pmu
            dis[1] <= dis[0];
            i <= i + 1;
            state <= 1;
        end
        1:begin
            if(count == 2) begin
                state <= 2;
                count <= 0;
            end
            else begin
                count = count + 1;
                state <= 1;
            end    
        end
        2:begin
        paths[i] <= pmu_path_out;
        dis[0] <= pmu_dis_out;
        // if 10 bits processed
        if(code_count == 10) begin state <= 3; end
        // else state 0
        else begin state <= 0; end     
        end
//        3:begin
        
        

//            state <= 4;
        
//        end
//        4:begin
        
        
            
        
//        end
        endcase
        finish <= 1;
//        // End of your code


    end
end

endmodule
