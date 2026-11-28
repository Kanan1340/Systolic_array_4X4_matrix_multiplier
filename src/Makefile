# Makefile for Systolic Array 4x4 Matrix Multiplier UVM Verification
# Simulator: Synopsys VCS
# Run from the project directory (where top.sv, sys_pkg.sv and the RTL files are).

VCS       ?= vcs
URG       ?= urg
OUT_DIR   ?= work
SIM       := $(OUT_DIR)/simv
LOG_DIR   := $(OUT_DIR)/logs
COV_DIR   := $(OUT_DIR)/systolic.vdb

# Top-level testbench
TOP_FILE   ?= top.sv
TOP_MODULE ?= sys_tb_top

# UVM package
PKG_FILE ?= sys_pkg.sv

# RTL source files (project.v holds tt_um_systolic_mm)
RTL_SRCS ?= pe.v systolic_array.v project.v

# Coverage exclusion file made in Verdi (used only if the file exists)
EXCL_FILE ?= systolic_excl.el

# Runtime controls
TESTNAME  ?= reset_during_compute_test
VERBOSITY ?= UVM_HIGH
SEED      ?= random
ITER      ?= 1
WAVES     ?= 0
GUI       ?= 0

# All UVM components, sequences and tests are included in sys_pkg.sv
PACKAGE_MODE ?= 1

# Include directories
INC_OPTS := +incdir+. +incdir+rtl +incdir+sequences +incdir+test

# Compile interface first, then package, then top-level testbench
SV_SRCS := $(PKG_FILE) $(TOP_FILE)

# UVM test classes available in this project (one per <name>_test.sv).
# all_seq_test is not listed: run it with  make run TESTNAME=all_seq_test
TEST_LIST ?= basic_identity_matrix_test \
             random_matrix_test \
             back_to_back_compute_test \
             incomplete_matrix_load_test \
             maximum_input_test \
             load_a_only_compute_zero_test \
             load_b_only_compute_zero_test \
             overload_input_test \
             read_pause_resume_test \
             read_pointer_wrap_test \
             zero_matrix_test \
             load_a_priority_test \
             load_b_priority_test \
             start_without_load_test \
             all_req_priority_test \
             start_read_together_start_wins_test \
             read_without_done_test \
             ena_independence_test \
             load_a_in_between_load_b_test \
             load_during_busy_test \
             read_during_busy_test \
             load_from_done_test \
             reset_during_compute_test \
             reset_during_load_test \
             result_retention_test \
             start_during_busy_test \
             ctrl_cross_holes_test

# VCS compilation options
VCS_OPTS := -sverilog -full64 -ntb_opts uvm -timescale=1ns/1ps \
            -Mdir=$(OUT_DIR)/csrc -o $(SIM) -top $(TOP_MODULE) -kdb

# Code coverage options
COV_OPTS := -cm line+cond+fsm+tgl+branch+assert

SIM_OPTS :=

ifeq ($(WAVES),1)
  VCS_OPTS += -debug_access+all +define+DUMP_WAVES
endif

ifeq ($(GUI),1)
  VCS_OPTS += -debug_access+all
  SIM_OPTS += -gui
endif

.PHONY: all help setup compile run regression summary report clean show-sources

all: run

help:
	@echo "Systolic Array UVM Verification using Synopsys VCS"
	@echo "  make compile                         Compile RTL and UVM testbench"
	@echo "  make run                             Run default test"
	@echo "  make run TESTNAME=maximum_input_test"
	@echo "  make run SEED=1234"
	@echo "  make run VERBOSITY=UVM_LOW"
	@echo "  make run WAVES=1                     Enable waveform debug"
	@echo "  make run GUI=1                       Launch simulator GUI"
	@echo "  make regression ITER=3               Run all tests three times"
	@echo "  make summary                         Show regression results"
	@echo "  make report                          Generate coverage report"
	@echo "  make show-sources                    Show source files"
	@echo "  make clean                           Remove generated files"

setup:
	@mkdir -p $(OUT_DIR) $(OUT_DIR)/csrc $(LOG_DIR)

show-sources:
	@echo "RTL sources:"
	@printf '%s\n' $(RTL_SRCS)
	@echo ""
	@echo "SystemVerilog sources:"
	@printf '%s\n' $(SV_SRCS)
	@echo ""
	@echo "Top module: $(TOP_MODULE)"
	@echo "Default test: $(TESTNAME)"

compile: setup
	@echo "Compiling Systolic Array RTL and UVM testbench..."
	$(VCS) $(VCS_OPTS) $(INC_OPTS) $(COV_OPTS) \
	  -cm_dir $(COV_DIR) $(RTL_SRCS) $(SV_SRCS) \
	  -l $(OUT_DIR)/compile.log

run: compile
	@set -e; \
	if [ "$(SEED)" = "random" ]; then \
	  RUN_SEED=$$(awk 'BEGIN { srand(); print int(rand()*2147483646)+1 }'); \
	else \
	  RUN_SEED="$(SEED)"; \
	fi; \
	LOG_FILE="$(LOG_DIR)/$(TESTNAME)_$${RUN_SEED}.log"; \
	echo "Running UVM test $(TESTNAME), seed=$${RUN_SEED}"; \
	$(SIM) +UVM_TESTNAME=$(TESTNAME) \
	  +UVM_VERBOSITY=$(VERBOSITY) \
	  +ntb_random_seed=$${RUN_SEED} \
	  $(COV_OPTS) -cm_dir $(COV_DIR) \
	  -cm_name $(TESTNAME)_$${RUN_SEED} \
	  $(SIM_OPTS) -l "$${LOG_FILE}"; \
	echo "Simulation log: $${LOG_FILE}"

regression: compile
	@set +e; \
	rm -f $(OUT_DIR)/regr_status.txt; \
	COUNTER=0; \
	for test in $(TEST_LIST); do \
	  i=1; \
	  while [ $$i -le $(ITER) ]; do \
	    COUNTER=$$((COUNTER+1)); \
	    NOW=$$(date +%s); \
	    CURRENT_SEED=$$((NOW + COUNTER)); \
	    LOG_FILE="$(LOG_DIR)/$${test}_$${CURRENT_SEED}.log"; \
	    echo "Running $${test} (iteration $$i/$(ITER), seed=$${CURRENT_SEED})"; \
	    $(SIM) +UVM_TESTNAME=$${test} \
	      +UVM_VERBOSITY=$(VERBOSITY) \
	      +ntb_random_seed=$${CURRENT_SEED} \
	      $(COV_OPTS) -cm_dir $(COV_DIR) \
	      -cm_name $${test}_$${CURRENT_SEED} \
	      $(SIM_OPTS) -l "$${LOG_FILE}"; \
	    SIM_RC=$$?; \
	    if [ $$SIM_RC -eq 0 ] && \
	      grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0' "$${LOG_FILE}" && \
	      grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0' "$${LOG_FILE}"; then \
	      echo "$${test} $${CURRENT_SEED} PASS" >> $(OUT_DIR)/regr_status.txt; \
	    else \
	      echo "$${test} $${CURRENT_SEED} FAIL" >> $(OUT_DIR)/regr_status.txt; \
	    fi; \
	    i=$$((i+1)); \
	  done; \
	done; \
	$(MAKE) summary

summary:
	@echo ""
	@echo "Regression Summary"
	@echo "TESTNAME SEED STATUS"
	@if [ -f $(OUT_DIR)/regr_status.txt ]; then \
	  cat $(OUT_DIR)/regr_status.txt; \
	  echo "------------------------------"; \
	  TOTAL=$$(wc -l < $(OUT_DIR)/regr_status.txt); \
	  PASSED=$$(grep -c ' PASS$$' $(OUT_DIR)/regr_status.txt || true); \
	  FAILED=$$(grep -c ' FAIL$$' $(OUT_DIR)/regr_status.txt || true); \
	  echo "Total: $$TOTAL | Passed: $$PASSED | Failed: $$FAILED"; \
	else \
	  echo "No regression data found. Run make regression first."; \
	fi

report:
	@echo "Generating coverage report from $(COV_DIR)..."
	$(URG) -dir $(COV_DIR) -report $(OUT_DIR)/urgReport \
	  $(if $(wildcard $(EXCL_FILE)),-elfile $(EXCL_FILE))
	@if [ -f $(EXCL_FILE) ]; then echo "Exclusion file applied: $(EXCL_FILE)"; else echo "No exclusion file ($(EXCL_FILE)) - report is unfiltered"; fi
	@echo "Coverage report: $(OUT_DIR)/urgReport/dashboard.html"

clean:
	rm -rf $(OUT_DIR) *.log *.vpd *.fsdb *.vdb urgReport DVEfiles vc_hdrs.h ucli.key .vlogansetup.args