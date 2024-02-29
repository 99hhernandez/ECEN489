`timescale 1ns / 1ps

module izigzag(
clk,
rst,
zigzag,
outdata,
finish
    );
    
input clk,rst;
input[32*64-1:0] zigzag;//[64th data (32bits)]..[2nd data][1st data]
output reg[32*64-1:0] outdata;
output reg finish;

always@(posedge clk or negedge rst)begin
    if(~rst)begin
        outdata<=0;
        finish<=0;
    end
    else begin
    // Example:
    // outdata[31:0]<=zigzag[31:0];
    // outdata[63:32]<=zigzag[63:32];
    // outdata[287:256]<=zigzag[95:64];
    // Start of your code ====================================
        outdata[(32*1)-1:32*0] <= zigzag[(32*1)-1:32*0];
        outdata[(32*2)-1:32*1] <= zigzag[(32*2)-1:32*1];
        outdata[(32*6)-1:32*5] <= zigzag[(32*3)-1:32*2];
        outdata[(32*7)-1:32*6] <= zigzag[(32*4)-1:32*3];
        outdata[(32*15)-1:32*14] <= zigzag[(32*5)-1:32*4];
        outdata[(32*16)-1:32*15] <= zigzag[(32*6)-1:32*5];
        outdata[(32*28)-1:32*27] <= zigzag[(32*7)-1:32*6];
        outdata[(32*29)-1:32*28] <= zigzag[(32*8)-1:32*7];
        outdata[(32*3)-1:32*2] <= zigzag[(32*9)-1:32*8];
        outdata[(32*5)-1:32*4] <= zigzag[(32*10)-1:32*9];
        outdata[(32*8)-1:32*7] <= zigzag[(32*11)-1:32*10];
        outdata[(32*14)-1:32*13] <= zigzag[(32*12)-1:32*11];
        outdata[(32*17)-1:32*16] <= zigzag[(32*13)-1:32*12];
        outdata[(32*27)-1:32*26] <= zigzag[(32*14)-1:32*13];
        outdata[(32*30)-1:32*29] <= zigzag[(32*15)-1:32*14];
        outdata[(32*43)-1:32*42] <= zigzag[(32*16)-1:32*15];
        outdata[(32*4)-1:32*3] <= zigzag[(32*17)-1:32*16];
        outdata[(32*9)-1:32*8] <= zigzag[(32*18)-1:32*17];
        outdata[(32*13)-1:32*12] <= zigzag[(32*19)-1:32*18];
        outdata[(32*18)-1:32*17] <= zigzag[(32*20)-1:32*19];
        outdata[(32*26)-1:32*25] <= zigzag[(32*21)-1:32*20];
        outdata[(32*31)-1:32*30] <= zigzag[(32*22)-1:32*21];
        outdata[(32*42)-1:32*41] <= zigzag[(32*23)-1:32*22];
        outdata[(32*44)-1:32*43] <= zigzag[(32*24)-1:32*23];
        outdata[(32*10)-1:32*9] <= zigzag[(32*25)-1:32*24];
        outdata[(32*12)-1:32*11] <= zigzag[(32*26)-1:32*25];
        outdata[(32*19)-1:32*18] <= zigzag[(32*27)-1:32*26];
        outdata[(32*25)-1:32*24] <= zigzag[(32*28)-1:32*27];
        outdata[(32*32)-1:32*31] <= zigzag[(32*29)-1:32*28];
        outdata[(32*41)-1:32*40] <= zigzag[(32*30)-1:32*29];
        outdata[(32*45)-1:32*44] <= zigzag[(32*31)-1:32*30];
        outdata[(32*54)-1:32*53] <= zigzag[(32*32)-1:32*31];
        outdata[(32*11)-1:32*10] <= zigzag[(32*33)-1:32*32];
        outdata[(32*20)-1:32*19] <= zigzag[(32*34)-1:32*33];
        outdata[(32*24)-1:32*23] <= zigzag[(32*35)-1:32*34];
        outdata[(32*33)-1:32*32] <= zigzag[(32*36)-1:32*35];
        outdata[(32*40)-1:32*39] <= zigzag[(32*37)-1:32*36];
        outdata[(32*46)-1:32*45] <= zigzag[(32*38)-1:32*37];
        outdata[(32*53)-1:32*52] <= zigzag[(32*38)-1:32*37];
        outdata[(32*55)-1:32*54] <= zigzag[(32*39)-1:32*38];
        outdata[(32*21)-1:32*20] <= zigzag[(32*40)-1:32*39];
        outdata[(32*23)-1:32*22] <= zigzag[(32*41)-1:32*40];
        outdata[(32*34)-1:32*33] <= zigzag[(32*42)-1:32*41];
        outdata[(32*39)-1:32*38] <= zigzag[(32*43)-1:32*42];
        outdata[(32*47)-1:32*46] <= zigzag[(32*44)-1:32*43];
        outdata[(32*52)-1:32*51] <= zigzag[(32*45)-1:32*44];
        outdata[(32*56)-1:32*55] <= zigzag[(32*46)-1:32*45];
        outdata[(32*61)-1:32*60] <= zigzag[(32*47)-1:32*46];
        outdata[(32*22)-1:32*21] <= zigzag[(32*48)-1:32*47];
        outdata[(32*35)-1:32*34] <= zigzag[(32*49)-1:32*48];
        outdata[(32*38)-1:32*37] <= zigzag[(32*50)-1:32*49];
        outdata[(32*48)-1:32*47] <= zigzag[(32*51)-1:32*50];
        outdata[(32*51)-1:32*50] <= zigzag[(32*52)-1:32*51];
        outdata[(32*57)-1:32*56] <= zigzag[(32*53)-1:32*52];
        outdata[(32*60)-1:32*59] <= zigzag[(32*54)-1:32*53];
        outdata[(32*62)-1:32*61] <= zigzag[(32*55)-1:32*54];
        outdata[(32*36)-1:32*35] <= zigzag[(32*56)-1:32*55];
        outdata[(32*37)-1:32*36] <= zigzag[(32*57)-1:32*56];
        outdata[(32*49)-1:32*48] <= zigzag[(32*58)-1:32*57];
        outdata[(32*50)-1:32*49] <= zigzag[(32*59)-1:32*58];
        outdata[(32*58)-1:32*57] <= zigzag[(32*60)-1:32*59];
        outdata[(32*59)-1:32*58] <= zigzag[(32*61)-1:32*60];
        outdata[(32*63)-1:32*62] <= zigzag[(32*62)-1:32*61];
        outdata[(32*64)-1:32*63] <= zigzag[(32*63)-1:32*62];
    // End of your code ======================================
    finish<=1;
    end
end

endmodule
