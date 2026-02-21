SIM = verilator
SRCS = $(wildcard *.sv)
TBS = $(SRCS:.sv=.tb)

.PHONY: all

targets:
	@echo ===== Available targets are: clean all run-all $(TBS:.tb=)
	@echo ===== To build use: target-name.tb
	@echo ===== To run   use: target-name.run

run-all: $(TBS:.tb=.run)

all: $(TBS)

clean:
	rm -r obj_dir/

%.tb : %.sv
	$(SIM) --binary -Wall -Wno-PINCONNECTEMPTY +1364-2005ext+v --trace-vcd -j `nproc` --prof-cfuncs -CFLAGS -DVL_DEBUG -f sources.f $^

%.run : %.tb
	./obj_dir/V$*
