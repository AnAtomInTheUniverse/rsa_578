#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/time.h>
#include <iostream>
#include <vector>

//#define DEBUG

extern inline unsigned long straightforward(unsigned long base, unsigned long exponent, unsigned long modulus);
extern inline unsigned long square_multiply(unsigned long base, unsigned long exponent, unsigned long modulus);
extern inline unsigned long montgomery_square_multiply(unsigned long base_mont, unsigned long exponent, unsigned long modulus, unsigned long N_prime, unsigned long one_mont);
extern inline unsigned long montgomery_ladder(unsigned long base_mont, unsigned long exponent, unsigned long modulus, unsigned long N_prime, unsigned long one_mont);
extern inline unsigned long montgomery_reduction(unsigned long T, unsigned long modulus, unsigned long N_prime);
extern inline unsigned long extended_euclid(unsigned long a, unsigned long n);


// This cpp file contains three implementations of modular exponentiation.
// The data types are tailored to support 32-bit values for base and exponent.
//
// Simiarly, R in Montgomery modular multiplication is 2^32 (0x100000000).

int main(int argc, char *argv[])
{
    std::vector<std::vector<unsigned long> > input_vector;
    FILE *input_fp;
    int method_index;
    int repeat_count;

    if (argc != 4) {
        std::cout << "Error: incorrect argument" << std::endl;
        std::cout << "Usage: ./mod_exp [input file] [method index] [repeat count]" << std::endl;
        return 1;
    }

    // 1. Read test vectors from the input file
    input_fp = fopen(argv[1], "r");

    while (true) {
        char input_line[256];

        // Read a line from input_fp
        fgets(input_line, 256, input_fp);
        if (feof(input_fp))
            break;

        // Parse the line into three tokens
        char tokens[3][256];
        int curr_token_index = 0;
        int index_within_token = 0;
        for (int index = 0; input_line[index] != 0; index++) {
            if (input_line[index] == ',') {
                tokens[curr_token_index][index_within_token] = 0;
                curr_token_index++;
                index_within_token = 0;
                if (curr_token_index >= 3) {
                    break;
                }
            } else {
                tokens[curr_token_index][index_within_token] = input_line[index];
                index_within_token++;
            }
        }
        tokens[curr_token_index][index_within_token] = 0;

        if (curr_token_index != 2) {
            // Ignore invalid line
            std::cout << "Warning! Input line ignored:" << input_line;
        }
        else {
            // Add the parsed three tokens as a new test vector
            std::vector<unsigned long> new_test_vector;
            new_test_vector.push_back(atol(tokens[0]));
            new_test_vector.push_back(atol(tokens[1]));
            new_test_vector.push_back(atol(tokens[2]));
            input_vector.push_back(new_test_vector);
        }
    }

    fclose(input_fp);

#ifdef DEBUG
    // Print test vectors
    std::cout << "### Test vectors" << std::endl;
    for (int vector_index = 0; vector_index < (int) input_vector.size(); vector_index++) {
        assert(input_vector[vector_index].size() == 3);
        std::cout << input_vector[vector_index][0] << " " << input_vector[vector_index][1] << " " << input_vector[vector_index][2] << std::endl;
    }
#endif

    // 2. Run the exponentiation method
    method_index = atoi(argv[2]);
    repeat_count = atoi(argv[3]);

    for (int vector_index = 0; vector_index < (int) input_vector.size(); vector_index++) {
        unsigned long base = input_vector[vector_index][0];
        unsigned long exponent = input_vector[vector_index][1];
        unsigned long modulus = input_vector[vector_index][2];
        struct timeval time_start, time_end;
        long elapsed_time = 0;
        unsigned long result;

        gettimeofday(&time_start, NULL);

        for (int trial = 0; trial < repeat_count; trial++) {
            if (method_index == 0) {
                result = straightforward(base, exponent, modulus);
            } else if (method_index == 1) {
                result = square_multiply(base, exponent, modulus);
            } else if (method_index == 2) {
                unsigned long R, R_inv;
                unsigned long N_prime;
                unsigned long one_mont;
                unsigned long base_mont;
                unsigned long result_mont;

                // Convert to the Montgomery domain
                R = ((unsigned long) 1 << 32);
                R_inv = extended_euclid(R % modulus, modulus);
                if (R_inv == 0)
                    return 1;
                N_prime = (R * R_inv - 1) / modulus;
                one_mont = (1 * R) % modulus;
                base_mont = (base * R) % modulus;

                // Do exponentiation in the Montgomery domain
                result_mont = montgomery_square_multiply(base_mont, exponent, modulus, N_prime, one_mont);

                // Convert back to the integer domain 
                result = (result_mont * R_inv) % modulus;
            } else if (method_index == 3) {
                unsigned long R, R_inv;
                unsigned long N_prime;
                unsigned long one_mont;
                unsigned long base_mont;
                unsigned long result_mont;

                // Converting to the Montgomery domain
                R = ((unsigned long) 1 << 32);
                R_inv = extended_euclid(R % modulus, modulus);
                if (R_inv == 0)
                    return 1;
                N_prime = (R * R_inv - 1) / modulus;
                one_mont = (1 * R) % modulus;
                base_mont = (base * R) % modulus;

                // Do exponentiation in the Montgomery domain
                result_mont = montgomery_ladder(base_mont, exponent, modulus, N_prime, one_mont);

                // Convert back to the integer domain 
                result = (result_mont * R_inv) % modulus;
            } else {
                std::cout << "Error: the argument [method index] is out of range" << std::endl;
                return 1;
            }
        }

        gettimeofday(&time_end, NULL);
        elapsed_time += (time_end.tv_sec * 1000000 + time_end.tv_usec) - (time_start.tv_sec * 1000000 + time_start.tv_usec);

        std::cout << "Test vector " << (vector_index + 1) << " (" << base << "^" << exponent << "%" << modulus << "=" << result << ") / Total elapsed time " << elapsed_time << " usec (average " << (elapsed_time / repeat_count) << " usec)" << std::endl;
    }

    return 0;
}

inline unsigned long straightforward(unsigned long base, unsigned long exponent, unsigned long modulus)
{
    // Compute modular exponentiation using repeated multiplications

    unsigned long product = 1;

    for (unsigned long count = 0; count < exponent; count++) {
        product = (product * base) % modulus;
    }

    return product;
}

inline unsigned long square_multiply(unsigned long base, unsigned long exponent, unsigned long modulus)
{
    // Compute modular exponentiation using square-and-multiply

    unsigned long product = 1;
    const int bitwidth = 32;

    for (int count = bitwidth - 1; count >= 0; count--) {
        product = (product * product) % modulus;
        if (((exponent >> count) & 0x1) == 0x1) {
            product = (product * base) % modulus;
        }
    }

    return product;
}

inline unsigned long montgomery_square_multiply(unsigned long base_mont, unsigned long exponent, unsigned long modulus, unsigned long N_prime, unsigned long one_mont)
{
    // Compute modular exponentiation using the Montgomery method (paired with square-and-multiply)

    unsigned long product = one_mont;
    const int bitwidth = 32;

    for (int count = bitwidth - 1; count >= 0; count--) {
        product = montgomery_reduction(product * product, modulus, N_prime);
        if (((exponent >> count) & 0x1) == 0x1) {
            product = montgomery_reduction(product * base_mont, modulus, N_prime);
        }
    }

    return product;
}

inline unsigned long montgomery_ladder(unsigned long base_mont, unsigned long exponent, unsigned long modulus, unsigned long N_prime, unsigned long one_mont)
{
    // Compute modular exponentiation using the Montgomery method (paired with Montgomery ladder)

    unsigned long R0 = one_mont;
    unsigned long R1 = base_mont;
    const int bitwidth = 32;

    for (int count = bitwidth - 1; count >= 0; count--) {
        if (((exponent >> count) & 0x1) == 0x0) {
            R1 = montgomery_reduction(R0 * R1, modulus, N_prime);
            R0 = montgomery_reduction(R0 * R0, modulus, N_prime);
        } else {
            R0 = montgomery_reduction(R0 * R1, modulus, N_prime);
            R1 = montgomery_reduction(R1 * R1, modulus, N_prime);
        }
    }

    return R0;
}

inline unsigned long montgomery_reduction(unsigned long T, unsigned long modulus, unsigned long N_prime)
{
    unsigned long m;
    unsigned long P;

    unsigned long T_low = T & 0xFFFFFFFF;
    unsigned long T_high = T >> 32;

    m = (T_low * N_prime) & 0xFFFFFFFF;

    // NOTE: BUG!!! (it does not handle the carryout bit (65th bit)).
    //P = (T + (m * modulus)) >> 32;

    // Below is a fix
    unsigned long m_mult_N = m * modulus;
    unsigned long m_mult_N_low = m_mult_N & 0xFFFFFFFF;
    unsigned long m_mult_N_high = m_mult_N >> 32;
    P = T_high + m_mult_N_high + (((T_low + m_mult_N_low) >> 32) & 0x1);

    if (P >= modulus)
        return P - modulus;
    else
        return P;
}

inline unsigned long extended_euclid(unsigned long a, unsigned long n)
{
    // Calculate modular multiplicative inverse (R_inv)
    // by extended Euclidean algorithm
    // Created based on the pseudocode from
    // https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm

    assert(a < n);

    long t, t_next;
    unsigned long r, r_next;

    t = 0;
    t_next = 1;
    r = n;
    r_next = a;

    while (r_next != 0) {
        unsigned long quotient = r / r_next;
        long t_next_temp = t_next;
        unsigned long r_next_temp = r_next;
        t_next = t - quotient * t_next;
        r_next = r - quotient * r_next;
        t = t_next_temp;
        r = r_next_temp;
    }

    if (r > 1) {
        // Note: This should not happen in RSA decryption keys.
        std::cout << "Error: a is not invertible" << std::endl;
        return 0;
    }
    if (t < 0) {
        t += n;
    }

    return t;
}
