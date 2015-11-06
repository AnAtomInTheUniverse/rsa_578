
`include "defines.vh"

module test_montgomery_exp_square;

    reg clk, rst, start;
    reg [`BITS-1:0] base;
    reg [`BITS-1:0] base_mont;
    reg [`BITS-1:0] exponent;
    reg [`BITS:0] R;
    reg [`BITS-1:0] R_inv;
    reg [`BITS-1:0] N;
    reg [`BITS-1:0] N_prime;
    reg [`BITS-1:0] one_mont;
    wire [`BITS-1:0] exp_result;
    integer test_vector_file;
    integer return_fscanf;
    integer start_time;
    integer end_time;

    montgomery_exp_ladder dut(.clk(clk), .rst(rst), .start(start),
        .base_mont(base_mont), .exponent(exponent), .N(N), .N_prime(N_prime), .one_mont(one_mont),
        .finish(finish), .exp_result(exp_result));

    // clock and reset
    initial begin
        clk = 1'b1;
        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;
    end

    always begin
        #(`CLOCK_PERIOD/2.0);
        clk = ~clk;
    end

    // Test vector
    initial begin
        start = 1'b0;
        base_mont = `BITS'd0;
        exponent = `BITS'd0;
        N = `BITS'd0;
        N_prime = `BITS'd0;
        one_mont = `BITS'd0;

        // FIXME: Change input file
        test_vector_file = $fopen("input/sample.txt", "r");

        @(negedge rst);

        while (1) begin
            @(negedge clk);
            return_fscanf = $fscanf(test_vector_file, "%d,%d,%d\n", base, exponent, N);
            $display("=======================================================================");
            $display("input: base %d exponent %d N %d", base, exponent, N);
            R = 1'b1 << `BITS;
            R_inv = extended_euclid(R%N, N); // Extended Euclidean algorithm
            N_prime = ({{`BITS{1'b0}}, R} * R_inv - 1) / N;
            base_mont = {{`BITS{1'b0}}, base} * R % N;
            one_mont = 1 * R % N;

            @(negedge clk);
            start = 1'b1;
            start_time = $time;

            @(negedge clk);
            start = 1'b0;

            @(negedge finish);
            end_time = $time;
            $display("Exponentiation result: %d", {{{`BITS{1'b0}}, exp_result} * R_inv % N});
            $display("Elapsed clock cycle: %d cycles", (end_time - start_time) / `CLOCK_PERIOD);
            // Debug
            //$display("***** DEBUG MESSAGES *****");
            //$display("base_mont = %d exponent = %d one_mont = %d", base_mont, exponent, one_mont);
            //$display("R = %d R_inv = %d", R, R_inv);
            //$display("N = %d N_prime = %d", N, N_prime);
            //$display("start_time = %d end_time = %d", start_time, end_time);

            if ($feof(test_vector_file)) begin
                // End of simulation
                $display("=======================================================================");
                $finish;
            end
        end
    end

    function [`BITS-1:0] extended_euclid;
        input [`BITS:0] a;
        input [`BITS-1:0] n;

        integer t, t_next;
        integer t_next_temp;
        bit [`BITS-1:0] t_final;

        bit [`BITS:0] r, r_next;
        bit [`BITS:0] r_next_temp;
        bit [`BITS:0] quotient;

        //$display("%d %d", a, n);
        assert(a < n);

        t = 0;
        t_next = 1;
        r = n;
        r_next = a;

        while (r_next != 0) begin
            //$display("t %d t_next %d r %d r_next %d", t, t_next, r, r_next);
            quotient = r / r_next;
            t_next_temp = t_next;
            r_next_temp = r_next;
            t_next = t - quotient * t_next;
            r_next = r - quotient * r_next;
            t = t_next_temp;
            r = r_next_temp;
        end

        //$display("t %d r %d", t, r);

        if (r > 1) begin
            $display("Error: a is not invertible");
            $finish;
        end

        if (t < 0) begin
            t_final = t + n;
        end
        else begin
            t_final = t;
        end

        //$display("final t %d", t_final);

        extended_euclid = t_final;
    endfunction

endmodule

