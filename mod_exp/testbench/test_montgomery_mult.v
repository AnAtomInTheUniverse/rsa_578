
`include "defines.vh"

module test_montgomery_mult;

    reg [`BITS-1:0] A;
    reg [`BITS-1:0] B;
    reg [`BITS-1:0] N;
    reg [`BITS-1:0] N_prime;
    wire [`BITS-1:0] P;

    montgomery_mult dut(.A(A), .B(B), .N(N), .N_prime(N_prime), .P(P));

    // Test vector
    initial begin
        // test vector 1

        A = `BITS'd3797488404;
        B = `BITS'd3797488404;
        N = `BITS'd4292870399;
        N_prime = `BITS'd3235971329;

        #10;

        $display("============================================");
        $display("A = %d B = %d N = %d N_prime = %d", A, B, N, N_prime);
        $display("T = %d m = %d", dut.T, dut.m);
        $display("m*N = %d t_temp = %d", dut.m_mult_N, dut.t_temp);
        $display("t_temp2 = %d t_final = %d", dut.t_temp2, dut.t_final);
        $display("P = %d", P);

        #10;

        // End of simulation
        $display("============================================");
    end

endmodule

