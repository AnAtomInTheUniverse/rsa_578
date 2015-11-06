########################################################################
# EECS 578  Mini-project (RSA)
########################################################################

GCC = g++
OBJDUMP = objdump
CFLAGS = -Wall

VCS = vcs
VCSFLAGS = +v2k -sverilog -line -full64 +incdir+./rtl

CPP_SRC = sw/mod_exp.cpp
RTL_SRC = rtl/montgomery_mult.v rtl/montgomery_exp_square.v rtl/montgomery_exp_ladder.v
TESTBENCH_MULT = testbench/test_montgomery_mult.v
TESTBENCH_SQUARE = testbench/test_montgomery_exp_square.v
TESTBENCH_LADDER = testbench/test_montgomery_exp_ladder.v

all: sw_impl

# Software implementations
sw_impl: $(CPP_SRC)
	$(GCC) $(CFLAGS) $(CPP_SRC) -o mod_exp
	$(OBJDUMP) -D mod_exp > mod_exp.disasm

go0: sw_impl
	./mod_exp input/sample.txt 0 10000

go1: sw_impl
	./mod_exp input/sample.txt 1 10000

go2: sw_impl
	./mod_exp input/sample.txt 2 10000

go3: sw_impl
	./mod_exp input/sample.txt 3 10000

go: go0

q2: sw_impl
	./mod_exp input/question2.txt 0 10000

q4: sw_impl
	./mod_exp input/question4.txt 1 10000

q6: sw_impl
	./mod_exp input/question6.txt 2 10000

# Hardware implementations
simv_mult: $(TESTBENCH_MULT) $(RTL_SRC)
	$(VCS) $(VCSFLAGS) $(TESTBENCH_MULT) $(RTL_SRC) -o simv

dve_mult: $(TESTBENCH_MULT) $(RTL_SRC)
	$(VCS) $(VCSFLAGS) $(TESTBENCH_MULT) $(RTL_SRC) -o dve -R -gui

run_mult: simv_mult
	./simv

simv_square: $(TESTBENCH_SQUARE) $(RTL_SRC)
	$(VCS) $(VCSFLAGS) $(TESTBENCH_SQUARE) $(RTL_SRC) -o simv

dve_square: $(TESTBENCH_SQUARE) $(RTL_SRC)
	$(VCS) $(VCSFLAGS) $(TESTBENCH_SQUARE) $(RTL_SRC) -o dve -R -gui

run_square: simv_square
	./simv

simv_ladder: $(TESTBENCH_LADDER) $(RTL_SRC)
	$(VCS) $(VCSFLAGS) $(TESTBENCH_LADDER) $(RTL_SRC) -o simv

dve_ladder: $(TESTBENCH_LADDER) $(RTL_SRC)
	$(VCS) $(VCSFLAGS) $(TESTBENCH_LADDER) $(RTL_SRC) -o dve -R -gui

run_ladder: simv_ladder
	./simv

simv: simv_square

run: simv_square
	./simv

.PHONY: clean
clean:
	rm -rf csrc DVEfiles dve.daidir simv.daidir dve.vdb simv.vdb
	rm -f dve simv
	rm -f inter.vpd ucli.key
	rm -f mod_exp mod_exp.disasm

