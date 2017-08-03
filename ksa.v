module ksa(CLOCK_50, KEY, SW, LEDR, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;
output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

wire [1:0] foundStatus1, foundStatus2, foundStatus3, foundStatus4;
wire [23:0] secretKey1, secretKey2, secretKey3, secretKey4;
wire stop;

wire [7:0] address1, data1, q1, address_e1, q_e1;
wire [23:0] startKey1;
wire wren1;

wire [7:0] address2, data2, q2, address_e2, q_e2;
wire [23:0] startKey2;
wire wren2;

wire [7:0] address3, data3, q3, address_e3, q_e3;
wire [23:0] startKey3;
wire wren3;

wire [7:0] address4, data4, q4, address_e4, q_e4;
wire [23:0] startKey4;
wire wren4;

wire start_result;
wire [23:0] secretKey;
reg [9:0] LEDR;


//Memories
s_memory1 (address1, CLOCK_50, data1, wren1, q1);
e_memory1 (address_e1, CLOCK_50, q_e1);

s_memory2 (address2, CLOCK_50, data2, wren2, q2);
e_memory2 (address_e2, CLOCK_50, q_e2);

s_memory3 (address3, CLOCK_50, data3, wren3, q3);
e_memory3 (address_e3, CLOCK_50, q_e3);

s_memory4 (address4, CLOCK_50, data4, wren4, q4);
e_memory4 (address_e4, CLOCK_50, q_e4);


//Search Cores
search_core s_core1(CLOCK_50, reset, stop, startKey1, secretKey1, foundStatus1, address1, data1, wren1, q1, address_e1, q_e1);
search_core s_core2(CLOCK_50, reset, stop, startKey2, secretKey2, foundStatus2, address2, data2, wren2, q2, address_e2, q_e2);
search_core s_core3(CLOCK_50, reset, stop, startKey3, secretKey3, foundStatus3, address3, data3, wren3, q3, address_e3, q_e3);
search_core s_core4(CLOCK_50, reset, stop, startKey4, secretKey4, foundStatus4, address4, data4, wren4, q4, address_e4, q_e4);

//Result Core
result_core(CLOCK_50, reset, start_result, secretKey, LEDR[1:0]);

//Seven Segment Displays Key
SevenSegmentDisplayDecoder h0(HEX0, inHEX0);
SevenSegmentDisplayDecoder h1(HEX1, inHEX1);
SevenSegmentDisplayDecoder h2(HEX2, inHEX2);
SevenSegmentDisplayDecoder h3(HEX3, inHEX3);
SevenSegmentDisplayDecoder h4(HEX4, inHEX4);
SevenSegmentDisplayDecoder h5(HEX5, inHEX5);

//Hex Displays
reg [3:0]inHEX0;
reg [3:0]inHEX1;
reg [3:0]inHEX2;
reg [3:0]inHEX3;
reg [3:0]inHEX4;
reg [3:0]inHEX5;

//Reset button
assign reset = ~KEY[3];

//SecretKeys from all 4 search cores
assign startKey1 = 24'b0;
assign startKey2 = 24'b01;
assign startKey3 = 24'b10;
assign startKey4 = 24'b11;

always @(*) begin
	if (reset) begin	
		secretKey <= 24'b0;
		start_result <= 1'b0;
		stop <= 1'b0;
		
		//Initialize HEX Displays
		inHEX0 = 4'b0;
		inHEX1 = 4'b0;
		inHEX2 = 4'b0;
		inHEX3 = 4'b0;
		inHEX4 = 4'b0;
		inHEX5 = 4'b0;
	end
	else begin	
		if (foundStatus1== 2'b01 || foundStatus2 == 2'b01 || foundStatus3 == 2'b01 || foundStatus4 == 2'b01) begin		
			stop = 1'b1;				
			start_result = 1'b1;
			
			if(foundStatus1 == 2'b01) begin			
				secretKey = secretKey1;
			end
			else if(foundStatus2 == 2'b01) begin
				secretKey = secretKey2;
			end
			else if(foundStatus3 == 2'b01) begin
				secretKey = secretKey3;
			end
			else if(foundStatus4 == 2'b01) begin
				secretKey = secretKey4;
			end	

			//Displays secret key 
			inHEX0 = secretKey[3:0];
			inHEX1 = secretKey[7:4];
			inHEX2 = secretKey[11:8];
			inHEX3 = secretKey[15:12];
			inHEX4 = secretKey[19:16];
			inHEX5 = secretKey[23:20];
				
		end
		else if(foundStatus1== 2'b10 && foundStatus2 == 2'b10 && foundStatus3 == 2'b10 && foundStatus4 == 2'b10) begin 	
			LEDR[9] = 1'b1;  //If all cores cannot find secret key then light up LEDR[9]
		end
				
		else begin		
			secretKey = 24'b0;
			LEDR[9] = 1'b0; 		
			start_result = 1'b0;
			stop = 1'b0;
		end
			
	end
end


endmodule