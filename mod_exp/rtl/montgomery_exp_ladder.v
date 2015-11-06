
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

endmodule

// vim: ts=4 et

