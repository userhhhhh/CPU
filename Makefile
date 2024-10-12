PWD := $(CURDIR)

SRC_DIR := $(PWD)/src
TESTSPACE_DIR := $(PWD)/testspace
TESTCASE_DIR := $(PWD)/testcase

SIM_TESTCASE_DIR := $(TESTCASE_DIR)/sim

SIM_DIR := $(PWD)/sim

V_SOURCES := $(shell find $(SRC_DIR) -name '*.v')

all: testcases build_sim

testcases:
	@make -C $(TESTCASE_DIR)

_no_testcase_name_check:
ifndef name
	$(error name is not set)
endif

build_sim: $(SIM_DIR)/testbench.v $(V_SOURCES)
	@iverilog -o $(TESTSPACE_DIR)/test $(SIM_DIR)/testbench.v $(V_SOURCES)

build_sim_test: testcases _no_testcase_name_check
	@cp $(SIM_TESTCASE_DIR)/*$(name)*.c $(TESTSPACE_DIR)/test.c
	@cp $(SIM_TESTCASE_DIR)/*$(name)*.data $(TESTSPACE_DIR)/test.data
	@cp $(SIM_TESTCASE_DIR)/*$(name)*.dump $(TESTSPACE_DIR)/test.dump

run_sim: build_sim build_sim_test
	cd $(TESTSPACE_DIR) && ./test

clean:
	rm -f $(TESTSPACE_DIR)/test*
	@make -C $(TESTCASE_DIR) clean

.PHONY: all build_sim build_sim_test run_sim clean
