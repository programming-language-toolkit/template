# Practical makefiles, by example: http://nuclear.mutantstargoat.com/articles/make/
# Automatic variables: https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html

CXX      := g++
CXXFLAGS := -std=c++20 -fmodules-ts -fmax-errors=10
CPPFLAGS := -MMD

INCLUDES := -Iexternal -Isrc

COMPILE  := $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(INCLUDES)

# Set the display of the time command. See https://man7.org/linux/man-pages/man1/time.1.html
TIME_FORMAT="%E elapsed  (%U user  %S system)  |  %P CPU  |  %Xk text  %Dk data  %Mk max  |  %I inputs  %O outputs  |  %F major + %R minor pagefaults  |  %W swaps\n"


.PHONY: error
error:
	@echo "Error: no default make rule provided"


.PHONY: all
all:
	$(MAKE) tests
	$(MAKE) examples
	$(MAKE) docs


# ======================================================================================================================
# Tests
# ======================================================================================================================
TEST_SRCS = $(filter-out tests/main.test.cpp,$(shell find tests/ -name "*.test.cpp"))
TEST_EXES = $(addprefix build/,$(TEST_SRCS:.cpp=.out))


.PHONY: tests
tests: build/tests/main.test.o $(TEST_EXES)


build/tests/%.test.out: tests/%.test.cpp
	@echo "building $(@F) ..."
	@mkdir -p $(@D)
	@time -f $(TIME_FORMAT) -- $(COMPILE) -ggdb build/tests/main.test.o $< -o $@


build/tests/main.test.o: tests/main.test.cpp
	@echo "building $(@F) ..."
	@mkdir -p $(@D)
	@time -f $(TIME_FORMAT) -- $(COMPILE) -O3 -ggdb $< -c -o $@


TEST_DEPS := $(TEST_EXES:.out=.d)
-include $(TEST_DEPS)


# Recompiles on change, so the test harness can autorun. Pass relative src= on the command line.
.PHONY: watch-test
watch-test: exe=build/$(basename $(src)).out
watch-test:
	@if [ -f "$(src)" ]; then                     \
		while true; do                            \
			clear;                                \
			$(MAKE) $(exe) --no-print-directory;  \
			                                      \
			echo "watching $(notdir $(src)) ..."; \
			inotifywait -qq -e modify $(src);     \
		done;                                     \
	else                                          \
		echo "file doesn't exist: $(src)";        \
	fi


# ======================================================================================================================
# Examples
# ======================================================================================================================



# ======================================================================================================================
# Docs
# ======================================================================================================================
.PHONY: docs
docs:
	$(MAKE) -C docs html


# ======================================================================================================================
# Misc
# ======================================================================================================================
.PHONY: clean-all clean-tests clean-examples clean-docs
clean-all:
	rm -rf build/


clean-tests:
	rm -rf build/tests


clean-examples:
	rm -rf build/examples


clean-docs:
	rm -rf build/docs


.PHONY: troubleshoot
troubleshoot:
	@echo $(TEST_SRCS)
	@echo $(TEST_EXES)
	@echo $(TEST_DEPS)
