`include "defines.vh"

module montgomery_exp_ladder (clk, rst, start, base_mont, exponent, N, N_prime, one_mont, finish, exp_result);

    input clk;
    input rst;
    input start;
    input [`BITS-1:0] base_mont;
    input [`BITS-1:0] exponent;
    input [`BITS-1:0] N;
    input [`BITS-1:0] N_prime;
    input [`BITS-1:0] one_mont;
    output finish;
    output [`BITS-1:0] exp_result;
	
	wire finish;
	wire [`BITS-1:0] exp_result;

	/* State machine defines*/
    `define STATE_BITS 3
    `define IDLE        `STATE_BITS'd0
    `define MONT_PROD   `STATE_BITS'd1
    `define PROD_0      `STATE_BITS'd2
    `define PROD_1      `STATE_BITS'd3
    `define FINISH      `STATE_BITS'd7
    reg [`STATE_BITS-1:0] state, nxt_state;
	

	reg [`BITS-1:0] base_mont_reg;
	reg [`BITS-1:0] exponent_reg;
	reg [`BITS-1:0] N_reg;
	reg [`BITS-1:0] N_prime_reg;
	reg [`BITS-1:0] one_reg;
	reg [`BITS-1:0]	partial_prod_0, nxt_partial_prod_0;
	reg [`BITS-1:0]	partial_prod_1, nxt_partial_prod_1;
	reg [`LOG_BITS-1:0] count, nxt_count;

	wire [`BITS-1:0] mult_A_0, mult_B_0, mult_result_0;
	wire [`BITS-1:0] mult_A_1, mult_B_1, mult_result_1;
    wire curr_bit;
	
	montgomery_mult mult0 (.A(mult_A_0), .B(mult_B_0), .N(N_reg), .N_prime(N_prime_reg), .P(mult_result_0));
	montgomery_mult mult1 (.A(mult_A_1), .B(mult_B_1), .N(N_reg), .N_prime(N_prime_reg), .P(mult_result_1));
	
	always @(posedge clk) begin
			if(rst) state <= #1 `IDLE;
			else 	state <= #1 nxt_state;
	end

	always @(posedge clk) begin
			if(rst) begin
					base_mont_reg	<=	#1 0;
					exponent_reg	<=	#1 0;
					N_reg			<=	#1 0;
					N_prime_reg		<=	#1 0;
					one_reg			<=	#1 0;
					count	 		<=	#1 {`LOG_BITS{1'b1}};
					partial_prod_0	<=	#1	0;
					partial_prod_1	<=	#1	0;
			end
			else begin
					if(state == `IDLE && start == 1'b1) begin
							base_mont_reg	<=	#1 base_mont;
							exponent_reg	<=	#1 exponent;
							N_reg			<=	#1 N;
							N_prime_reg		<=	#1 N_prime;
							one_reg			<=	#1 one_mont;
					end
					count			<=	#1 nxt_count;
					partial_prod_0	<=	#1 nxt_partial_prod_0;
					partial_prod_1	<=	#1 nxt_partial_prod_1;
			end
	end

	always @* begin
			nxt_state			=	state;
			nxt_count			=	count;
			nxt_partial_prod_0	=	partial_prod_0;
			nxt_partial_prod_1	=	partial_prod_1;
			
			case(state)
                    `IDLE: begin
						if(start) begin
								nxt_state			=	`MONT_PROD;
								nxt_count			=	{`LOG_BITS{1'b1}};
								nxt_partial_prod_0	=	one_mont;
								nxt_partial_prod_1	= 	base_mont;
						end
                     end
					`MONT_PROD:	begin
						if(curr_bit == 1'b1) 
								nxt_state 	=	`PROD_1;
						else if(curr_bit == 1'b0) 
								nxt_state	=	`PROD_0;
                    end
					`PROD_0: begin
						nxt_partial_prod_0	=	mult_result_0;
						nxt_partial_prod_1	=	mult_result_1;
					    if(count == 0)
								nxt_state	=	`FINISH;
						else begin
								nxt_state 	=	`MONT_PROD;
								nxt_count	=	count - 1;
                        end
					end
					`PROD_1: begin
						nxt_partial_prod_0	=	mult_result_0;
						nxt_partial_prod_1	=	mult_result_1;
						if(count == 0)
								nxt_state	=	`FINISH;
                        else begin
								nxt_state 	=	`MONT_PROD;
								nxt_count	=	count - 1;
						end
					end
					`FINISH: begin
						nxt_state	=	`IDLE;
						nxt_count	=	{`LOG_BITS{1'b1}};
					end
					default:
						if(~rst)
							$display("ERROR: unexpected state %d in montgomenry_exp_ladder", state);
			endcase
        end

		assign	mult_A_0	=	partial_prod_0;
		assign 	mult_B_0	=	(state == `PROD_0) ? partial_prod_0 : partial_prod_1;

		assign	mult_A_1	=	(state == `PROD_0) ? partial_prod_0 : partial_prod_1;
		assign 	mult_B_1	=	partial_prod_1;

		assign 	curr_bit	=	exponent_reg[count];
		assign	finish		=	(state == `FINISH);
		assign	exp_result	=	partial_prod_0;

endmodule

// vim: ts=4 et

