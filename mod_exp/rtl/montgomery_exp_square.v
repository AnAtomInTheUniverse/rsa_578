
`include "defines.vh"

module montgomery_exp_square (clk, rst, start, base_mont, exponent, N, N_prime, one_mont, finish, exp_result);

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


    // State machine
    `define STATE_BITS 3
    `define STATE_IDLE   `STATE_BITS'd0
    `define STATE_SQUARE `STATE_BITS'd1
    `define STATE_MULT   `STATE_BITS'd2
    `define STATE_FINISH `STATE_BITS'd7
    reg [`STATE_BITS-1:0] state, next_state;

    // Registers
    reg [`BITS-1:0] base_mont_reg;
    reg [`BITS-1:0] exponent_reg;
    reg [`BITS-1:0] N_reg;
    reg [`BITS-1:0] N_prime_reg;
    reg [`BITS-1:0] one_reg;
    reg [`LOG_BITS-1:0] counter, next_counter;
    reg [`BITS-1:0] partial_sum, next_partial_sum;

    // signal
    wire [`BITS-1:0] mult_A, mult_B, mult_result;
    wire curr_bit;

    montgomery_mult mult (.A(mult_A), .B(mult_B), .N(N_reg), .N_prime(N_prime_reg), .P(mult_result));

    always @(posedge clk) begin
        if (rst)
            state <= #1 `STATE_IDLE;
        else
            state <= #1 next_state;
    end

    always @(posedge clk) begin
        if (rst) begin
            base_mont_reg <= #1 0;
            exponent_reg <= #1 0;
            N_reg <= #1 0;
            N_prime_reg <= #1 0;
            one_reg <= #1 0;
            counter <= #1 {`LOG_BITS{1'b1}};
            partial_sum <= #1 0;
        end
        else begin
            if (state == `STATE_IDLE && start == 1'b1) begin
                base_mont_reg <= #1 base_mont;
                exponent_reg <= #1 exponent;
                N_reg <= #1 N;
                N_prime_reg <= #1 N_prime;
                one_reg <= #1 one_mont;
            end
            counter <= #1 next_counter;
            partial_sum <= #1 next_partial_sum;
        end
    end

    always @* begin
        next_state = state;
        next_counter = counter;
        next_partial_sum = partial_sum;
        case (state)
            `STATE_IDLE:
                if (start) begin
                    next_state = `STATE_SQUARE;
                    next_counter = {`LOG_BITS{1'b1}};
                    next_partial_sum = one_mont;  // not one_reg due to timing
                end
            `STATE_SQUARE: begin
                next_partial_sum = mult_result;
                if (curr_bit == 1'b1)
                    next_state = `STATE_MULT;
                else if (counter == 0)
                    next_state = `STATE_FINISH;
                else begin
                    next_state = `STATE_SQUARE;
                    next_counter = counter - 1;
                end
            end
            `STATE_MULT: begin
                next_partial_sum = mult_result;
                if (counter == 0)
                    next_state = `STATE_FINISH;
                else begin
                    next_state = `STATE_SQUARE;
                    next_counter = counter - 1;
                end
            end
            `STATE_FINISH: begin
                next_state = `STATE_IDLE;
                next_counter = {`LOG_BITS{1'b1}};
            end
            default:
                if (~rst) // ignore abnormal behaviors during reset
                    $display("Error: unexpected state %d in montgomery_exp_square", state);
        endcase
    end

    assign mult_A = partial_sum;
    assign mult_B = (state == `STATE_MULT) ? base_mont_reg : partial_sum;

    assign curr_bit = exponent_reg[counter];
    assign finish = (state == `STATE_FINISH);
    assign exp_result = partial_sum;

endmodule

// vim: ts=4 et

