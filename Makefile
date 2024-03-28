
RTL= ./rtl/router.v
RTL_BAD= ./rtl/bad/router.v
SVTB = ./router_test_top.sv ./router_io.sv ./test.sv 
SEED = 1

default: test

test: compile run

test_bad: compile_bad run

run:
	./simv -1 simv.log +ntb_random_seed=$(SEED) 

compile:
	vcs -full64 -sverilog -debug_all $(SVTB) $(RTL)

compile_bad:
	vcs -full64 -sverilog -debug_all $(SVTB) $(RTL_BAD)

debug:
	./simv -1 simv.log -gui -tbug +ntb_random_seed=$(SEED)

clean:
	rm -rf simv* csrc* *.tmp *.vpd *.key *.log urgReport*

nuke: clean
	rm -rf  *.v*  *.sv include .*. lock  .*.old DVE* *.tcl *.h
dve: 
	dve -full64 &
show_func_cov:
    urg -dir simv.vdb
	firefox ./urgReport/dashboard.html &

