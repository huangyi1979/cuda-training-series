IDIR=.
COMPILER=nvcc
COMPILER_FLAGS=-I$(IDIR) -I/usr/local/cuda/include -lcuda --std c++17 -DUSE_STREAMS

srcs=$(filter-out $(wildcard *_solution.cu), $(wildcard *.cu))
targets=$(patsubst %.cu, %, $(srcs))

.PHONY: clean all

%: %.cu
	$(info )
	$(info ----building & running "$@"----)
	$(info )
	@$(COMPILER) $(COMPILER_FLAGS) $< -o $@.exe
	@./$@.exe
	@if [ -f $@_solution.cu ]; then \
		$(COMPILER) $(COMPILER_FLAGS) $@_solution.cu -o $@_solution.exe; \
		./$@_solution.exe; \
	fi;

all: $(targets)

clean:
	@rm -rf *.exe
	@rm -rf a.out
	@rm -rf report*
