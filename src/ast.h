#ifndef WIZUALL_AST_H
#define WIZUALL_AST_H

#include <stdbool.h>
#include <stdarg.h>

/* Debug mode flag and print function */
extern int debug_mode;
void debug_print(const char *fmt, ...);
void debug_section_header(const char *title);

/* Data type for values (for type checking) */
typedef enum { TYPE_SCALAR, TYPE_VECTOR } ValueType;

/* Node types for AST */
typedef enum {
    AST_PROGRAM,
    AST_STMT_LIST,
    AST_STMT_LIST_NODE,  /* A node that wraps stmt_list for if/while statements */
    AST_ASSIGN,
    AST_IF,
    AST_WHILE,
    AST_PLOT,
    AST_HIST,
    AST_SCATTER,
    AST_PRINT,     /* print statement */
    AST_BINOP,
    AST_UNOP,
    AST_NUM,       /* numeric literal */
    AST_VAR,       /* variable reference */
    AST_VECTOR,    /* vector literal (or constructed vector) */
    AST_FUNCALL    /* external or built-in function call */
} NodeType;

/* Forward declaration for ASTNode (because ASTNodeList will hold ASTNode*) */
struct ASTNode;

/* A simple linked list to hold lists of AST nodes (e.g., statements or vector elements) */
typedef struct ASTNodeList {
    struct ASTNode* node;
    struct ASTNodeList* next;
} ASTNodeList;

/* AST Node structure */
typedef struct ASTNode {
    NodeType type;
    ValueType vtype;      /* whether this node (expression) is scalar or vector */
    char op;              /* for AST_BINOP/AST_UNOP: operator symbol or code */
    char *name;           /* for AST_VAR or AST_FUNCALL: variable or function name */
    double numValue;      /* for AST_NUM: store numeric constant */
    ASTNodeList *children;/* for AST_PROGRAM or AST_VECTOR or function args: list of child nodes */
    struct ASTNode *child1, *child2, *child3;  /* for binary/unary ops and statements */
} ASTNode;

/* Symbol table entry */
typedef struct {
    char *name;
    ValueType type;
    double *vecData;   /* pointer to vector data (if vector constant or loaded) */
    int vecLen;        /* length of vector if applicable */
    bool isVector;     /* explicit flag to mark vector variables */
} Symbol;

/* Simple symbol table (array of symbols) */
#define MAX_SYMBOLS 100
extern Symbol symbolTable[MAX_SYMBOLS];
extern int symbolCount;

/* Global AST root */
extern ASTNode *ast_root;

/* AST node creation functions */
ASTNode* ast_new_node(NodeType type);
ASTNode* ast_new_num(double value);
ASTNode* ast_new_var(char* name);
ASTNode* ast_new_vector(ASTNodeList* elements);
ASTNode* ast_new_binop(char op, ASTNode* left, ASTNode* right);
ASTNode* ast_new_unary(char op, ASTNode* expr);
ASTNode* ast_new_func_call(char* funcName, ASTNodeList* args);
ASTNode* ast_new_stmt_list_node(ASTNodeList* stmts);  /* New function for statement lists */

/* AST node list management */
ASTNodeList* ast_new_list();
ASTNodeList* ast_append_list(ASTNodeList* list, ASTNode* node);

/* Semantic checks (optional: could be integrated into ast_new_* functions) */
void ast_set_main(ASTNode* root);   /* Set the root program node (for global access) */
void ast_check_semantics(ASTNode* root, bool is_lhs);  /* e.g., ensure types match in operations */

/* Symbol table management */
Symbol* sym_lookup(const char* name);
Symbol* sym_add(const char* name, ValueType type);
void sym_mark_as_vector(const char* name);

/* Utility for error reporting */
void semantic_error(const char *msg);

#endif
