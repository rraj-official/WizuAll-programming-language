#ifndef WIZUALL_CODEGEN_H
#define WIZUALL_CODEGEN_H

#include <stdio.h>
#include <stdarg.h>
#include "ast.h"

/* Debug print function declaration */
extern int debug_mode;
void debug_print(const char *fmt, ...);
void debug_section_header(const char *title);

/* Generate C code from the AST, and write to given file pointer (already opened). */
void generate_code(ASTNode* root, FILE *out);

/* Helper to generate code for an expression and return a C expression string */
char* gen_expr_code(ASTNode* expr, FILE *out);

/* Optionally, function to generate declarations or setup code for variables */
void gen_var_declarations(FILE *out);

#endif
