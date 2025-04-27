#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "codegen.h"

/* Declare the parser (yyparse) and the input file handle for lexer */
extern FILE *yyin;
extern int yyparse();

/* Root of AST constructed by parser */
extern void ast_set_main(ASTNode* root); // ensure our parser calls this when done
// (We could also use a global ast_root as in ast.c to retrieve after parse.)

/* Global debug flag */
int debug_mode = 0;

/* Debug print function that only prints when debug mode is enabled */
void debug_print(const char *fmt, ...) {
    if (debug_mode) {
        va_list args;
        va_start(args, fmt);
        vfprintf(stderr, fmt, args);
        va_end(args);
    }
}

/* Print section header in debug mode */
void debug_section_header(const char *title) {
    if (debug_mode) {
        fprintf(stderr, "\n╭─────────────────────────────────────────╮\n");
        fprintf(stderr, "│ %-39s │\n", title);
        fprintf(stderr, "╰─────────────────────────────────────────╯\n");
    }
}

int main(int argc, char** argv) {
    char *inputFile = NULL;
    char *outCFile = NULL;
    
    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--debug") == 0) {
            debug_mode = 1;
            debug_print("● Debug mode enabled\n");
        } else if (inputFile == NULL) {
            inputFile = argv[i];
        } else if (outCFile == NULL) {
            outCFile = argv[i];
        }
    }
    
    if (inputFile == NULL) {
        fprintf(stderr, "Usage: %s [--debug] <input.wzl> [output.c]\n", argv[0]);
        return 1;
    }
    
    // Set default output file if none provided
    if (outCFile == NULL) {
        outCFile = "wizuall_out.c";
    }
    
    debug_section_header("COMPILATION PROCESS");
    debug_print("● Input file: %s\n", inputFile);
    debug_print("● Output file: %s\n", outCFile);
    
    yyin = fopen(inputFile, "r");
    if (!yyin) {
        perror("Error opening input file");
        return 1;
    }

    // Parse the input file
    debug_section_header("PARSING PHASE");
    debug_print("● Starting parsing...\n");
    if (yyparse() != 0) {
        fprintf(stderr, "Parsing failed.\n");
        return 1;
    }
    fclose(yyin);
    debug_print("✓ Parsing completed successfully\n");

    // At this point, the AST is built and stored (we set it via ast_set_main in parser action).
    // We can perform semantic analysis:
    // (Assuming ast_root is accessible or stored in a global variable in ast.c via ast_set_main)
    extern ASTNode *ast_root; // we can expose this from ast.c for simplicity
    debug_section_header("SEMANTIC ANALYSIS");
    debug_print("● Starting semantic analysis...\n");
    ast_check_semantics(ast_root, false);
    debug_print("✓ Semantic analysis completed\n");

    FILE *out = fopen(outCFile, "w");
    if (!out) {
        perror("Could not open output file for writing");
        return 1;
    }

    // Generate C code
    debug_section_header("CODE GENERATION");
    debug_print("● Starting code generation...\n");
    generate_code(ast_root, out);
    fclose(out);
    debug_print("✓ Code generation completed\n");
    
    // Only print these messages in debug mode
    if (debug_mode) {
        debug_section_header("COMPILATION SUMMARY");
        printf("● Generated C code in %s\n", outCFile);
        printf("● Compile it with: gcc -o output_exe %s -lm\n", outCFile);
        printf("● Then run ./output_exe to execute the program.\n");
    }
    
    return 0;
}
