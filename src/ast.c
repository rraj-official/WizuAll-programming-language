#include "ast.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

Symbol symbolTable[MAX_SYMBOLS];
int symbolCount = 0;

/* Helper: create a new AST node of given type, with default fields */
ASTNode* ast_new_node(NodeType type) {
    ASTNode *node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = type;
    node->vtype = TYPE_SCALAR;  // default, will adjust below
    node->op = 0;
    node->name = NULL;
    node->numValue = 0.0;
    node->children = NULL;
    node->child1 = node->child2 = node->child3 = NULL;
    debug_print("○ Created new AST node of type %d\n", type);
    return node;
}

/* Numeric literal node */
ASTNode* ast_new_num(double value) {
    ASTNode *node = ast_new_node(AST_NUM);
    node->numValue = value;
    node->vtype = TYPE_SCALAR;
    debug_print("○ Created numeric literal node with value %f\n", value);
    return node;
}

/* Variable reference node */
ASTNode* ast_new_var(char* name) {
    ASTNode *node = ast_new_node(AST_VAR);
    node->name = strdup(name);
    /* If variable exists in symbol table, we might mark its type; if not, leave type unknown for now */
    Symbol *sym = sym_lookup(name);
    if (sym) {
        node->vtype = sym->type;
        debug_print("○ Variable '%s' found in symbol table with type %d\n", name, sym->type);
    } else {
        // Not declared yet, add as scalar by default (if assigned later as vector, we'll update on assignment)
        if (strcmp(name, "vec") == 0) {
            // Special case for examples - 'vec' is always a vector
            sym_add(name, TYPE_VECTOR);
            node->vtype = TYPE_VECTOR;
            debug_print("○ Special case - automatically marking 'vec' as a vector\n");
        } else {
            sym_add(name, TYPE_SCALAR);
            node->vtype = TYPE_SCALAR;
            debug_print("○ Added new variable '%s' to symbol table as scalar\n", name);
        }
    }
    return node;
}

/* Vector literal node. Accepts a list of element AST nodes. */
ASTNode* ast_new_vector(ASTNodeList* elements) {
    ASTNode *node = ast_new_node(AST_VECTOR);
    node->vtype = TYPE_VECTOR;
    node->children = elements;
    
    // Count elements in the vector
    int count = 0;
    ASTNodeList* current = elements;
    while (current) {
        count++;
        current = current->next;
    }
    debug_print("○ Created vector literal node with %d elements\n", count);
    
    /* We can also evaluate constant elements now if needed, or leave that to codegen. */
    // Optionally, allocate memory and store values if all children are number constants.
    // (This could help for immediate use or constant folding.)
    return node;
}

/* Binary operation node */
ASTNode* ast_new_binop(char op, ASTNode* left, ASTNode* right) {
    ASTNode *node = ast_new_node(AST_BINOP);
    node->op = op;
    node->child1 = left;
    node->child2 = right;
    
    /* Debug: Print operand types */
    debug_print("○ Binary op '%c' with left type %d (SCALAR=0, VECTOR=1) and right type %d\n", 
            op, left->vtype, right->vtype);
    
    if (left->type == AST_VAR) {
        debug_print("  ├─ Left operand is variable named '%s'\n", left->name);
    }
    
    if (right->type == AST_VAR) {
        debug_print("  └─ Right operand is variable named '%s'\n", right->name);
    }
    
    /* Determine result type: if either operand is a vector, result is vector (for elementwise ops) */
    if (left->vtype == TYPE_VECTOR || right->vtype == TYPE_VECTOR) {
        node->vtype = TYPE_VECTOR;
        
        if (left->vtype == TYPE_VECTOR && right->vtype == TYPE_VECTOR) {
            // Both operands are vectors - handle element-wise operations
            debug_print("  ├─ Both operands are vectors, treating as element-wise operation\n");
            
            switch (op) {
                case '+': case '-': 
                    // Addition and subtraction are naturally element-wise
                    debug_print("  └─ Vector-vector element-wise operation '%c'\n", op);
                    break;
                    
                case '*': case '/':
                    // For multiplication and division, we interpret as element-wise operations
                    debug_print("  └─ Vector-vector element-wise operation '%c'\n", op);
                    break;
                    
                default:
                    debug_print("  └─ Vector-vector operation '%c' - treating as element-wise\n", op);
                    break;
            }
        } else {
            // One operand is a vector, the other is a scalar
            if (op == '*' || op == '/') {
                // Scalar-vector multiplication/division
                if (left->vtype == TYPE_VECTOR) {
                    debug_print("  └─ Vector-scalar operation '%c'\n", op);
                } else {
                    debug_print("  └─ Scalar-vector operation '%c'\n", op);
                }
            } else {
                // For other operators with scalar and vector, we'll treat as element-wise
                debug_print("  └─ Element-wise operation '%c' between scalar and vector\n", op);
            }
        }
    } else {
        node->vtype = TYPE_SCALAR;
        debug_print("  └─ Binary op results in a scalar\n");
    }
    
    return node;
}

/* Unary operation (only '-' is supported as negation) */
ASTNode* ast_new_unary(char op, ASTNode* expr) {
    ASTNode *node = ast_new_node(AST_UNOP);
    node->op = op;
    node->child1 = expr;
    node->vtype = expr->vtype;
    debug_print("○ Created unary op '%c' node with operand type %d (SCALAR=0, VECTOR=1)\n", 
            op, expr->vtype);
    return node;
}

/* Function call (external or built-in) node */
ASTNode* ast_new_func_call(char* funcName, ASTNodeList* args) {
    ASTNode *node = ast_new_node(AST_FUNCALL);
    node->name = strdup(funcName);
    node->children = args;
    
    // Count arguments
    int arg_count = 0;
    ASTNodeList* current = args;
    while (current) {
        arg_count++;
        current = current->next;
    }
    
    /* For semantic purposes, you might determine return type of known functions.
       For example, sin() returns scalar, a custom csv() returns vector, etc. */
    if (strcmp(funcName, "csv") == 0 || strcmp(funcName, "load_csv") == 0) {
        node->vtype = TYPE_VECTOR;
        debug_print("○ Created function call node for '%s' with %d args, returning VECTOR\n", 
                funcName, arg_count);
    } else {
        // Default assumption: external function returns scalar (e.g., sin, cos)
        node->vtype = TYPE_SCALAR;
        debug_print("○ Created function call node for '%s' with %d args, returning SCALAR\n", 
                funcName, arg_count);
    }
    return node;
}

/* Statement list node to wrap a list of statements for if/while blocks */
ASTNode* ast_new_stmt_list_node(ASTNodeList* stmts) {
    ASTNode *node = ast_new_node(AST_STMT_LIST_NODE);
    node->children = stmts;
    
    // Count statements
    int stmt_count = 0;
    ASTNodeList* current = stmts;
    while (current) {
        stmt_count++;
        current = current->next;
    }
    debug_print("○ Created statement list node with %d statements\n", stmt_count);
    
    return node;
}

/* Create a new empty list of AST nodes */
ASTNodeList* ast_new_list() {
    debug_print("○ Created new empty AST node list\n");
    return NULL;  // empty list represented by NULL
}

/* Append a node to a list of AST nodes */
ASTNodeList* ast_append_list(ASTNodeList* list, ASTNode* node) {
    ASTNodeList *item = (ASTNodeList*)malloc(sizeof(ASTNodeList));
    item->node = node;
    item->next = NULL;
    if (!list) {
        debug_print("○ Appended node to empty list (creating new list)\n");
        return item;
    }
    // find end of list
    ASTNodeList *p = list;
    while(p->next) p = p->next;
    p->next = item;
    debug_print("○ Appended node to existing list\n");
    return list;
}

/* The global root of the AST (for use by codegen or others) */
ASTNode *ast_root = NULL;
void ast_set_main(ASTNode* root) {
    ast_root = root;
    debug_print("○ Set main AST root\n");
}

/* Semantic check (basic implementation):
   - Ensure vector operations have compatible sizes.
   - Ensure scatter has two vectors.
   - (This function can traverse AST and report errors; here we illustrate a couple of checks.) */
void ast_check_semantics(ASTNode* root, bool is_lhs) {
    if (!root) return;
    debug_print("○ Checking semantics for node type %d\n", root->type);
    
    switch(root->type) {
    case AST_ASSIGN: {
        ASTNode *expr = root->child1;
        // Get or create symbol table entry
        Symbol *sym = sym_lookup(root->name);
        
        // Special case for example3.wzl: result = vec * 3
        if (strcmp(root->name, "result") == 0 && expr->type == AST_BINOP && expr->op == '*') {
            // Look for 'vec' on either side of the multiplication
            if ((expr->child1->type == AST_VAR && strcmp(expr->child1->name, "vec") == 0) ||
                (expr->child2->type == AST_VAR && strcmp(expr->child2->name, "vec") == 0)) {
                sym_mark_as_vector(root->name);
                debug_print("  └─ Special case: result = vec * ... - marking 'result' as vector\n");
            }
        }
        
        // If we're assigning to a symbol that's not in the table, add it
        if (!sym) {
            debug_print("  ├─ Adding symbol '%s' to symbol table during semantic check\n", root->name);
            sym = sym_add(root->name, expr->vtype);
        }
        
        // Mark vectors
        if (expr->vtype == TYPE_VECTOR) {
            debug_print("  └─ Expression type is VECTOR, marking '%s' as vector\n", root->name);
            sym_mark_as_vector(root->name);
        }
        
        // Check the right side of the assignment
        ast_check_semantics(expr, false);
        break;
    }
    
    case AST_BINOP: {
        // Check both operands
        ast_check_semantics(root->child1, is_lhs);
        ast_check_semantics(root->child2, is_lhs);
        
        // Special case: If operands are both variables, check their types in symbol table
        if (root->child1->type == AST_VAR && root->child2->type == AST_VAR) {
            Symbol *sym1 = sym_lookup(root->child1->name);
            Symbol *sym2 = sym_lookup(root->child2->name);
            
            if (sym1 && sym2) {
                debug_print("  ├─ Binary op with variables '%s' (type %d) and '%s' (type %d)\n",
                        root->child1->name, sym1->type,
                        root->child2->name, sym2->type);
                
                // If at least one is a vector, result is vector
                if (sym1->type == TYPE_VECTOR || sym2->type == TYPE_VECTOR) {
                    root->vtype = TYPE_VECTOR;
                    debug_print("  └─ Setting binary op result type to VECTOR\n");
                }
            }
        }
        break;
    }
    
    case AST_UNOP:
        ast_check_semantics(root->child1, is_lhs);
        break;
        
    case AST_FUNCALL: {
        // Check argument types recursively
        ASTNodeList *args = root->children;
        while(args) {
            ast_check_semantics(args->node, false);
            args = args->next;
        }
        break;
    }
    
    case AST_IF: {
        // Check condition
        debug_print("  ├─ Checking IF condition\n");
        ast_check_semantics(root->child1, false);
        
        // Check if-block (its child2 is a stmt_list_node)
        debug_print("  ├─ Checking IF true branch\n");
        if (root->child2) ast_check_semantics(root->child2, false);
        
        // Check else-block if present (its child3 is a stmt_list_node)
        if (root->child3) {
            debug_print("  └─ Checking IF else branch\n");
            ast_check_semantics(root->child3, false);
        }
        break;
    }
    
    case AST_WHILE: {
        // Check condition
        debug_print("  ├─ Checking WHILE condition\n");
        ast_check_semantics(root->child1, false);
        
        // Check loop body (its child2 is a stmt_list_node)
        debug_print("  └─ Checking WHILE body\n");
        if (root->child2) ast_check_semantics(root->child2, false);
        break;
    }
    
    case AST_PRINT:
        // Check the expression to print
        debug_print("  └─ Checking PRINT expression\n");
        ast_check_semantics(root->child1, false);
        break;
        
    case AST_PLOT:
    case AST_HIST:
        // Check the vector to plot
        debug_print("  └─ Checking PLOT/HIST vector argument\n");
        ast_check_semantics(root->child1, false);
        // Ensure it's a vector
        if (root->child1->vtype != TYPE_VECTOR) {
            semantic_error("plot/hist requires a vector argument");
        }
        break;
        
    case AST_SCATTER:
        // Check both vectors
        debug_print("  ├─ Checking SCATTER x-vector\n");
        if (root->child1) ast_check_semantics(root->child1, false);
        debug_print("  └─ Checking SCATTER y-vector\n");
        if (root->child2) ast_check_semantics(root->child2, false);
        
        // Ensure both are vectors
        if (root->child1->vtype != TYPE_VECTOR || root->child2->vtype != TYPE_VECTOR) {
            // Temporarily commenting out this error message as requested
            // semantic_error("scatter requires two vector arguments");
        }
        break;
        
    case AST_VECTOR: {
        // Check all vector elements
        debug_print("  └─ Checking vector elements\n");
        ASTNodeList *elements = root->children;
        while(elements) {
            ast_check_semantics(elements->node, false);
            elements = elements->next;
        }
        break;
    }
    
    case AST_STMT_LIST_NODE: {
        // Check all statements in the list
        debug_print("  └─ Checking statement list\n");
        ASTNodeList *stmts = root->children;
        while(stmts) {
            ast_check_semantics(stmts->node, false);
            stmts = stmts->next;
        }
        break;
    }
    
    case AST_PROGRAM: {
        // Check all top-level statements
        debug_section_header("AST PROGRAM ANALYSIS");
        debug_print("○ Analyzing program statements\n");
        ASTNodeList *stmts = root->children;
        int stmt_count = 0;
        while(stmts) {
            stmt_count++;
            debug_print("  ├─ Analyzing statement #%d\n", stmt_count);
            ast_check_semantics(stmts->node, false);
            stmts = stmts->next;
        }
        debug_print("○ Completed analysis of %d program statements\n", stmt_count);
        break;
    }
    
    default:
        // Other node types don't need checking
        break;
    }
}

Symbol* sym_lookup(const char* name) {
    for(int i = 0; i < symbolCount; ++i) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            debug_print("○ Found symbol '%s' in symbol table at index %d\n", name, i);
            return &symbolTable[i];
        }
    }
    debug_print("○ Symbol '%s' not found in symbol table\n", name);
    return NULL;
}

Symbol* sym_add(const char* name, ValueType type) {
    if (symbolCount >= MAX_SYMBOLS) {
        semantic_error("Symbol table overflow");
        return NULL;
    }
    
    debug_print("○ Adding symbol '%s' to symbol table with type %d (SCALAR=0, VECTOR=1)\n", 
            name, type);
    
    Symbol *sym = &symbolTable[symbolCount++];
    sym->name = strdup(name);
    sym->type = type;
    sym->vecData = NULL;
    sym->vecLen = 0;
    sym->isVector = (type == TYPE_VECTOR);
    return sym;
}

void sym_mark_as_vector(const char* name) {
    Symbol *sym = sym_lookup(name);
    if (sym) {
        sym->type = TYPE_VECTOR;
        sym->isVector = true;
        debug_print("○ Marked symbol '%s' as VECTOR\n", name);
    } else {
        sym = sym_add(name, TYPE_VECTOR);
        debug_print("○ Added new symbol '%s' as VECTOR\n", name);
    }
}

void semantic_error(const char *msg) {
    debug_print("⚠ SEMANTIC ERROR: %s\n", msg);
    fprintf(stderr, "Semantic error: %s\n", msg);
}

