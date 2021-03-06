module ksa_task1(CLOCK_50, KEY, SW, LEDR, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;
output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

reg [7:0] address, data, q;
reg wren;
reg resetb;

logic [7:0] i;
logic [7:0] j;
logic [7:0] k;
logic [7:0] key_element;

reg[7:0] i_element;
reg[7:0] j_element;

reg [23:0] secretKey;
reg [7:0] key;

// state names here as you complete your design	
typedef enum {s_init_task1 = 1, s_increment = 2, s_init_task2a = 3, s_set_key_element = 4, s_sum_j = 5,
					s_get_key = 6, s_read_array_i = 7, s_read_array_i_wait = 8, s_read_array_j = 9, 
					s_read_array_j_wait = 10, s_read_done = 11, s_swap_i_to_j = 12, s_swap_j_to_i = 13,
					s_loop_task2a = 14, s_swap_done = 15, s_init_task2b = 16, s_sum_i = 17, 
					s_read_array_i_2b = 18, s_read_array_i_2b_wait = 19, s_sum_j_2b = 20, s_read_array_j_2b = 21, 
					s_read_array_j_2b_wait = 22, s_read_done_part2b = 23, s_swap_i_to_j_2b = 24, s_swap_j_to_i_2b = 25, 
					s_sum_for_address_f = 26, s_read_array_f = 27, s_read_array_f_wait = 28, s_read_encrypted_input = 29, 
					s_read_encrypted_input_wait = 30, s_read_encrypted_input_done = 31, s_decrypted_output = 32,
					s_write_decrypted_output = 33, s_loop_task2b = 34, s_brute_key = 35, state_done_success = 36,
					state_done_failure = 37, s_init_key = 38} state_type;
state_type state;

parameter keyLimit = 24'h3FFFFF;

reg [7:0] address_e, address_d, q_e, q_d;
reg [7:0] data_d;
reg wren_d;

reg [7:0] e_element;
reg [7:0] address_f;
reg [7:0] f;
reg [7:0] data_check;

s_memory (address, CLOCK_50, data, wren, q);
e_memory (address_e,	CLOCK_50, q_e);
d_memory (address_d, CLOCK_50, data_d, wren_d, q_d);

//Seven Segment Displays Key
SevenSegmentDisplayDecoder h0(HEX0, inHEX0);
SevenSegmentDisplayDecoder h1(HEX1, inHEX1);
SevenSegmentDisplayDecoder h2(HEX2, inHEX2);
SevenSegmentDisplayDecoder h3(HEX3, inHEX3);
SevenSegmentDisplayDecoder h4(HEX4, inHEX4);
SevenSegmentDisplayDecoder h5(HEX5, inHEX5);

reg [3:0]inHEX0;
reg [3:0]inHEX1;
reg [3:0]inHEX2;
reg [3:0]inHEX3;
reg [3:0]inHEX4;
reg [3:0]inHEX5;

assign reset = ~KEY[3];

always_ff @(posedge CLOCK_50, posedge reset) 
	if (reset) begin
		state <= s_init_key;
		i <= 8'b0;
	end 
	else begin
		case (state)
			s_init_key: begin
				secretKey[23:0] <= SW[9:0];
				LEDR[9:0] = 10'b0;
				state <= s_init_task1;
			end 
			
			s_init_task1: begin 
				i <= 8'b0;
				state <= s_increment;
				wren <= 1'b1;
			end 
			
			s_increment: begin
				LEDR[9:2] <= secretKey[7:0];
				address <= i[7:0];
				data <= i[7:0];
				wren <= 1'b1;
				i <= i + 8'd1;
				if (i == 255) begin
					state <= s_init_task2a;
				end
			end 

			s_init_task2a: begin
				i <= 8'b0;
				j <= 8'b0;
				state <= s_set_key_element;
				wren <= 1'b0;
			end 
			
			s_set_key_element: begin
			   address <= i[7:0];
				key_element <= i % 3; //keylength is 3 in our implementation
				state <= s_get_key;
			end 
			
			s_get_key: begin
				 if (key_element == 8'b0) 
					key <= secretKey[23:16]; 
				 else if (key_element == 8'b1) 
					key <= secretKey[15:8]; 
				 else 
					key <= secretKey[7:0]; 
				 
				 state <= s_sum_j;
			end 
			
			s_sum_j: begin
				j <= (j + q + key);
				state <= s_read_array_i;
			end 
			
			s_read_array_i: begin
				address <= i[7:0];
				wren <= 1'b0;
				state <= s_read_array_i_wait;
			end 
			
			s_read_array_i_wait: begin
				//Wait for 1 extra cycle for reading
				state <= s_read_array_j;
			end 
			
			s_read_array_j: begin
				i_element <= q;
				address <= j[7:0];
				state <= s_read_array_j_wait;
			end 
			
			s_read_array_j_wait: begin
				//Wait for 1 extra cycle for reading
				state <= s_read_done;
			end 

			s_read_done: begin
				j_element <= q;
				wren <= 1'b1;
				state <= s_swap_i_to_j;
			end 
			
			s_swap_i_to_j: begin
				address <= j[7:0];
				data <= i_element;
				state <= s_swap_j_to_i;
			end 
			
			s_swap_j_to_i: begin
				address <= i[7:0];
				data <= j_element;
				state <= s_swap_done;
			end 
			
			s_swap_done: begin
				wren <= 1'b0;
				state <= s_loop_task2a;
			end 
			
			s_loop_task2a: begin
				i <= i + 8'd1;
				if (i == 255) begin
					state <= s_init_task2b;
				end
				else begin
					state <= s_set_key_element;
				end 
			end 
				
			s_init_task2b: begin
				i <= 8'b0;
				j <= 8'b0;
				k <= 8'b0;	
				wren <= 1'b0;
				state <= s_sum_i;
			end 
			
			s_sum_i: begin
				i <= (i + 8'd1) % 256;
				state <= s_read_array_i_2b;
			end 
				
			s_read_array_i_2b: begin
				address <= i[7:0];
				wren <= 1'b0;
				state <= s_read_array_i_2b_wait;
			end 
				
			s_read_array_i_2b_wait: begin
				//Wait for 1 extra cycle for reading
				state <= s_sum_j_2b;
			end 
		
			s_sum_j_2b: begin
				j <= (j + q) % 256;
				i_element <= q;
				state <= s_read_array_j_2b;
			end 
				
			s_read_array_j_2b: begin
				address <= j[7:0];
				state <= s_read_array_j_2b_wait;
			end 
			
			s_read_array_j_2b_wait:	begin
				//Wait for 1 extra cycle for reading
				state <= s_read_done_part2b;
			end 
				
			s_read_done_part2b: begin
				j_element <= q;
				wren <= 1'b1;
				state <= s_swap_i_to_j_2b;
			end 
				
			s_swap_i_to_j_2b: begin
				address <= j[7:0];
				data <= i_element;
				state <= s_swap_j_to_i_2b;
			end 
			
			s_swap_j_to_i_2b: begin
				address <= i[7:0];
				data <= j_element;
				state <= s_sum_for_address_f;
			end 
			
			s_sum_for_address_f: begin
				address_f <= (i_element + j_element) % 256;
				state <= s_read_array_f;
			end 
			
			s_read_array_f: begin
				address <= address_f;
				wren <= 1'b0;
				state <= s_read_array_f_wait;
			end 
			
			s_read_array_f_wait: begin
				//Wait for 1 extra cycle for reading
				state <= s_read_encrypted_input;
			end 
			
			s_read_encrypted_input: begin
				f <= q;
				address_e <= k[7:0];
				state <= s_read_encrypted_input_wait;
			end 
			
			s_read_encrypted_input_wait: begin
				//Wait for 1 extra cycle for reading
				state <= s_read_encrypted_input_done;
			end 
			
			s_read_encrypted_input_done: begin
				e_element <= q_e;
				state <= s_decrypted_output;
			end 
			
			s_decrypted_output: begin
				data_check <= (e_element ^ f);
				
				//Check if it is a valid space or char
				if(data_check == 8'd32 || (data_check >= 8'd 97 && data_check <= 8'd122)) begin
					state <= s_write_decrypted_output;
				end
				else begin
					state <= s_brute_key;
				end
			end 
			
			s_write_decrypted_output: begin
				data_d <= (e_element ^ f);
				wren_d <= 1'b1;
				address_d <= k[7:0];
				state <= s_loop_task2b;
			end 
			
			s_loop_task2b: begin
			
				k <= k + 8'd1;
				
				//(message_length - 1) message_length is 32 in our implementation
				if (k == 8'd31) begin
					state <= state_done_success;
				end 
				else begin
					state <= s_sum_i;
				end
			end 
			
			s_brute_key: begin
				// TODO: 
				// secret key + 4 instead of 1
				// check flag if someone has found it
				secretKey <= secretKey + 24'd1;
				
				//Displays secret key in real time
				inHEX0 <= secretKey[3:0];
				inHEX1 <= secretKey[7:4];
				inHEX2 <= secretKey[11:8];
				inHEX3 <= secretKey[15:12];
				inHEX4 <= secretKey[19:16];
				inHEX5 <= secretKey[23:20];
				if (secretKey == keyLimit) begin
					state <= state_done_failure;
				end
				else begin
					state <= s_init_task1;
				end
			end 
			
			state_done_success: begin
				LEDR <= 10'b1;
				state <= state_done_success;
			end 
			
			state_done_failure: begin
				LEDR <= 10'b10;
				state <= state_done_failure;
			end 
		endcase
	end

endmodule