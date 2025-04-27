# Compiler and flags
CC      = gcc
CFLAGS  = -Wall -Wextra -O2

# Flex/Bison generated files
LEX_SRC = src/wizuall.l
YACC_SRC = src/wizuall.y
LEX_OUT = src/lex.yy.c
YACC_OUT_C = src/wizuall.tab.c
YACC_OUT_H = src/wizuall.tab.h

# Source files
SRCS = src/main.c src/ast.c src/codegen.c
OBJS = $(SRCS:.c=.o)

# Output compiler name and directory
BIN_DIR = bin
COMPILER = $(BIN_DIR)/wizuallc

all: $(COMPILER)

# Create bin directory if it doesn't exist
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# Generate parser and lexer code
$(YACC_OUT_C) $(YACC_OUT_H): $(YACC_SRC)
	@echo "Generating parser from Bison grammar..."
	bison -d -v $(YACC_SRC) -o $(YACC_OUT_C)

$(LEX_OUT): $(LEX_SRC) $(YACC_OUT_H)
	@echo "Generating lexer from Flex specs..."
	flex -o $(LEX_OUT) $(LEX_SRC)

# Compile all sources and generated code into the compiler executable
$(COMPILER): $(BIN_DIR) $(YACC_OUT_C) $(LEX_OUT) $(OBJS)
	$(CC) $(CFLAGS) -o $(COMPILER) $(OBJS) $(LEX_OUT) $(YACC_OUT_C) -lm

# Compile object files
src/%.o: src/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Clean up generated and compiled files
clean:
	rm -f $(COMPILER) $(OBJS) $(LEX_OUT) $(YACC_OUT_C) $(YACC_OUT_H) wizuall_out.c

# Phony targets (not actual files)
.PHONY: all clean
