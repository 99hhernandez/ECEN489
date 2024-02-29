`timescale 1ns / 1ps

module tb(
    );

reg clk;


reg[15:0] data;



reg[15:0] code;
reg[8*16-1:0] hufftable;
reg[8*256-1:0] huffsymbol;
wire[7:0] huffdata;
wire[7:0] hufflength;
wire hufffinish;
reg huffrst;
huffmandecode h0(
clk,
huffrst,
code,
hufftable,
huffsymbol,
huffdata,
hufflength,
hufffinish
    );

reg[7:0] count;

initial begin

code = 'h6000; // code to be decoded: 0110 0000 0000 0000
huffrst = 0;
data<=0;
// huffcodes should be  01 100 00 00 00 00 00
// indices should be    1, 2, 0, 0, 0, 0, 0
// symbols should be    2, 3, 1, 1, 1, 1, 1
// concatenated symbol: 02030101010101

hufftable[7:0]=0;
hufftable[15:8]=2;
hufftable[23:16]=1;
hufftable[31:24]=3;
hufftable[39:32]=3;
hufftable[47:40]=2;
hufftable[55:48]=4;
hufftable[63:56]=3;
hufftable[71:64]=5;
hufftable[79:72]=5;
hufftable[87:80]=4;
hufftable[95:88]=4;
hufftable[103:96]=0;
hufftable[111:104]=0;
hufftable[119:112]=1;
hufftable[127:120]=125;

huffsymbol[7:0]=1;
huffsymbol[15:8]=2;
huffsymbol[23:16]=3;
huffsymbol[31:24]=0;
huffsymbol[39:32]=4;
huffsymbol[47:40]=17;
huffsymbol[55:48]=5;
huffsymbol[63:56]=18;
huffsymbol[71:64]=33;
huffsymbol[79:72]=49;
huffsymbol[87:80]=65;
huffsymbol[95:88]=6;
huffsymbol[103:96]=19;
huffsymbol[111:104]=81;
huffsymbol[119:112]=97;
huffsymbol[127:120]=7;
huffsymbol[135:128]=34;
huffsymbol[143:136]=113;
huffsymbol[151:144]=20;
huffsymbol[159:152]=50;
huffsymbol[167:160]=129;
huffsymbol[175:168]=145;
huffsymbol[183:176]=161;
huffsymbol[191:184]=8;
huffsymbol[199:192]=35;
huffsymbol[207:200]=66;
huffsymbol[215:208]=177;
huffsymbol[223:216]=193;
huffsymbol[231:224]=21;
huffsymbol[239:232]=82;
huffsymbol[247:240]=209;
huffsymbol[255:248]=240;
huffsymbol[263:256]=36;
huffsymbol[271:264]=51;
huffsymbol[279:272]=98;
huffsymbol[287:280]=114;
huffsymbol[295:288]=130;
huffsymbol[303:296]=9;
huffsymbol[311:304]=10;
huffsymbol[319:312]=22;
huffsymbol[327:320]=23;
huffsymbol[335:328]=24;
huffsymbol[343:336]=25;
huffsymbol[351:344]=26;
huffsymbol[359:352]=37;
huffsymbol[367:360]=38;
huffsymbol[375:368]=39;
huffsymbol[383:376]=40;
huffsymbol[391:384]=41;
huffsymbol[399:392]=42;
huffsymbol[407:400]=52;
huffsymbol[415:408]=53;
huffsymbol[423:416]=54;
huffsymbol[431:424]=55;
huffsymbol[439:432]=56;
huffsymbol[447:440]=57;
huffsymbol[455:448]=58;
huffsymbol[463:456]=67;
huffsymbol[471:464]=68;
huffsymbol[479:472]=69;
huffsymbol[487:480]=70;
huffsymbol[495:488]=71;
huffsymbol[503:496]=72;
huffsymbol[511:504]=73;
huffsymbol[519:512]=74;
huffsymbol[527:520]=83;
huffsymbol[535:528]=84;
huffsymbol[543:536]=85;
huffsymbol[551:544]=86;
huffsymbol[559:552]=87;
huffsymbol[567:560]=88;
huffsymbol[575:568]=89;
huffsymbol[583:576]=90;
huffsymbol[591:584]=99;
huffsymbol[599:592]=100;
huffsymbol[607:600]=101;
huffsymbol[615:608]=102;
huffsymbol[623:616]=103;
huffsymbol[631:624]=104;
huffsymbol[639:632]=105;
huffsymbol[647:640]=106;
huffsymbol[655:648]=115;
huffsymbol[663:656]=116;
huffsymbol[671:664]=117;
huffsymbol[679:672]=118;
huffsymbol[687:680]=119;
huffsymbol[695:688]=120;
huffsymbol[703:696]=121;
huffsymbol[711:704]=122;
huffsymbol[719:712]=131;
huffsymbol[727:720]=132;
huffsymbol[735:728]=133;
huffsymbol[743:736]=134;
huffsymbol[751:744]=135;
huffsymbol[759:752]=136;
huffsymbol[767:760]=137;
huffsymbol[775:768]=138;
huffsymbol[783:776]=146;
huffsymbol[791:784]=147;
huffsymbol[799:792]=148;
huffsymbol[807:800]=149;
huffsymbol[815:808]=150;
huffsymbol[823:816]=151;
huffsymbol[831:824]=152;
huffsymbol[839:832]=153;
huffsymbol[847:840]=154;
huffsymbol[855:848]=162;
huffsymbol[863:856]=163;
huffsymbol[871:864]=164;
huffsymbol[879:872]=165;
huffsymbol[887:880]=166;
huffsymbol[895:888]=167;
huffsymbol[903:896]=168;
huffsymbol[911:904]=169;
huffsymbol[919:912]=170;
huffsymbol[927:920]=178;
huffsymbol[935:928]=179;
huffsymbol[943:936]=180;
huffsymbol[951:944]=181;
huffsymbol[959:952]=182;
huffsymbol[967:960]=183;
huffsymbol[975:968]=184;
huffsymbol[983:976]=185;
huffsymbol[991:984]=186;
huffsymbol[999:992]=194;
huffsymbol[1007:1000]=195;
huffsymbol[1015:1008]=196;
huffsymbol[1023:1016]=197;
huffsymbol[1031:1024]=198;
huffsymbol[1039:1032]=199;
huffsymbol[1047:1040]=200;
huffsymbol[1055:1048]=201;
huffsymbol[1063:1056]=202;
huffsymbol[1071:1064]=210;
huffsymbol[1079:1072]=211;
huffsymbol[1087:1080]=212;
huffsymbol[1095:1088]=213;
huffsymbol[1103:1096]=214;
huffsymbol[1111:1104]=215;
huffsymbol[1119:1112]=216;
huffsymbol[1127:1120]=217;
huffsymbol[1135:1128]=218;
huffsymbol[1143:1136]=225;
huffsymbol[1151:1144]=226;
huffsymbol[1159:1152]=227;
huffsymbol[1167:1160]=228;
huffsymbol[1175:1168]=229;
huffsymbol[1183:1176]=230;
huffsymbol[1191:1184]=231;
huffsymbol[1199:1192]=232;
huffsymbol[1207:1200]=233;
huffsymbol[1215:1208]=234;
huffsymbol[1223:1216]=241;
huffsymbol[1231:1224]=242;
huffsymbol[1239:1232]=243;
huffsymbol[1247:1240]=244;
huffsymbol[1255:1248]=245;
huffsymbol[1263:1256]=246;
huffsymbol[1271:1264]=247;
huffsymbol[1279:1272]=248;
huffsymbol[1287:1280]=249;
huffsymbol[1295:1288]=250;


    clk=0;
//    idct_rst=0;
//    #4 idct_rst=1;
    #4 huffrst = 1;
end

always #1 begin
    clk<=~clk;
end

always@(posedge clk)begin

    if(hufffinish == 1)begin
        data<=data<<8;
        data[7:0] <= huffdata;
        code<=code<<(hufflength);
        huffrst<=0;
        #1 huffrst<=1;
    end
end

endmodule
