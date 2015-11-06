
`include "defines.vh"

module montgomery_mult (A, B, N, N_prime, P);

    input [`BITS-1:0] A;
    input [`BITS-1:0] B;
    input [`BITS-1:0] N;
    input [`BITS-1:0] N_prime;
    output [`BITS-1:0] P;

    wire [`BITS*2-1:0] T;
    wire [`BITS-1:0] m;
    wire [`BITS*2-1:0] m_mult_N;
    wire [`BITS*2:0] t_temp;
    wire [`BITS:0] t_temp2;
    wire [`BITS-1:0] t_final;

    assign T = A * B;
    assign m = T[`BITS-1:0] * N_prime;
    assign m_mult_N = m * N;
    assign t_temp = T + m_mult_N;
    assign t_temp2 = t_temp[`BITS*2:`BITS];
    assign t_final = (t_temp2 >= N) ? t_temp2 - N : t_temp2;
    assign P = t_final;

endmodule

// vim: ts=4 et

