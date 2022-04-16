module SignalParsed(
	dataReg,
	ps2_out,
	lleft,
	rright,
	rotate
);

input [7:0] dataReg;	// represent the value of register of A,D,W
input [7:0] ps2_out;	// ps2_out, indicate the operation 97,100,119 

output reg [7:0] lleft;
output reg [7:0] rright;
output reg [7:0] rotate;


/// wire ///
wire signed [31:0] Rdata;
reg[7:0] left_reg;
reg[7:0] right_reg;
reg[7:0] rotate_reg;

assign Rdata = dataReg;

/// initial ///
initial begin
	left_reg <= 0;
	right_reg <= 0;
	rotate_reg <= 0;
	lleft <= 0;
	rright <= 0;
	rotate <= 0;
end



/// judge ///

always @(dataReg or ps2_out)
	begin
		if(ps2_out == 97)begin
			if(Rdata > left_reg)begin
				left_reg = Rdata;
				lleft = Rdata;
			end
		end
		
		else if(ps2_out == 100)begin
			if(Rdata > right_reg)begin
				right_reg = Rdata;
				rright = Rdata;
			end
		end
		else if(ps2_out == 119)begin
			if(Rdata > rotate_reg)begin
				rotate_reg = Rdata;
				rotate = Rdata;
			end
		end
	end
	
endmodule
