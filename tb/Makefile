SIM := verilator
SRCS := $(wildcard *.sv)
TBS := $(SRCS:.sv=.tb)
LINT_OPTS := -Wall -Wno-PINCONNECTEMPTY
LANG_VER := +1364-2005ext+v
EXTRA_OPTS := --prof-cfuncs -CFLAGS -DVL_DEBUG
COVERAGE_OPTS = --coverage

.PHONY: all run-all targets cov-merged cov-info cov-report clean

targets:
	@echo ===== Available targets are: clean all run-all cov-report $(TBS:.tb=)
	@echo ===== To build use: target-name.tb
	@echo ===== To run   use: target-name.run

run-all: $(TBS:.tb=.run)

all: $(TBS)

clean:
	rm -r obj_dir/
	rm *.coverage
	rm -r report/

%.tb : %.sv
	$(SIM) --binary $(LINT_OPTS) $(LANG_VER) --trace-vcd -j `nproc` $(COVERAGE_OPTS) $(EXTRA_OPTS) -f sources.f $^

%.run : %.tb
	./obj_dir/V$* +verilator+coverage+file+$^.coverage

merged.coverage:
	verilator_coverage --write $@ $(wildcard *.coverage)

cov-merged: merged.coverage

merged.info: merged.coverage
	verilator_coverage --write-info $@.1 $^
	sed -ir 's|../src/|src/|' $@.1
	mv $@.1 $@

cov-info: merged.info

cov-report: merged.info
	cd .. && genhtml --branch-coverage --no-function-coverage --legend -o tb/report/ tb/merged.info
