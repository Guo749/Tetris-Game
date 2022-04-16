module random(
  input             clk,   
     
  output reg [15:0] rand_num   
);

initial begin
 rand_num    <=16'b0;
end


always@(posedge clk)
begin
	rand_num[0] <= rand_num[15];
	rand_num[1] <= rand_num[0];
	rand_num[2] <= rand_num[1];
	rand_num[3] <= rand_num[2];
	rand_num[4] <= rand_num[3] ^~rand_num[15];
	rand_num[5] <= rand_num[4] ^~rand_num[15];
	rand_num[6] <= rand_num[5] ^~rand_num[15];
	rand_num[7] <= rand_num[6];
	rand_num[8] <= rand_num[7];
   rand_num[9] <= rand_num[8];
   rand_num[10]<= rand_num[9];
   rand_num[11]<= rand_num[10];
   rand_num[12]<= rand_num[11]^~rand_num[15];
   rand_num[13]<= rand_num[12]^~rand_num[15];
   rand_num[14]<= rand_num[13]^~rand_num[15];
   rand_num[15]<= rand_num[14];
   
end
endmodule