%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "codegen.h"

/* Declare the lexer function and the token container (yylval) */
extern int yylex();
extern int yyparse();
extern FILE *yyin;

/* Error handling function */
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
%}

/* Bison declarations for token types */
%union {
    double numVal;
    char*  strVal;
    struct ASTNode* node;
    struct ASTNodeList* nodelist;
}

/* Token definitions from lexer */
%token <numVal> NUMBER
%token <strVal> ID
%token PLOT HISTOGRAM SCATTER PRINT IF ELSE WHILE
%token ASSIGN
%token LBRACKET RBRACKET COMMA
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON
%token EQ NEQ GT LT GTE LTE

/* Type declarations for non-terminals */
%type <node> stmt expr program
%type <nodelist> stmt_list vector_elems arg_list arg_list_nonempty

/* Precedence and associativity (if needed) */
%left '+' '-'
%left '*' '/'
%right UMINUS  /* Unary minus */

%%

program:
    stmt_list
    {
        /* The root of the AST is a list of statements */
        ASTNode *root = ast_new_node(AST_PROGRAM);
        root->children = $1;  /* attach the list of statements */
        ast_set_main(root);   /* store root globally or pass it out */
    }
;

stmt_list:
    /* empty */
    {
        $$ = ast_new_list();  /* create an empty list of ASTNode* */
    }
  | stmt_list stmt
    {
        $$ = ast_append_list($1, $2);
    }
;

stmt:
    /* Variable assignment */
    ID ASSIGN expr SEMICOLON
    {
        // Create an assignment AST node: var name and expression
        ASTNode *assignNode = ast_new_node(AST_ASSIGN);
        assignNode->name = $1;           // variable name (string)
        assignNode->child1 = $3;        // expression AST
        $$ = assignNode;
    }
  | /* Print statement */
    PRINT LPAREN expr RPAREN SEMICOLON
    {
        // Create a print AST node
        ASTNode *printNode = ast_new_node(AST_PRINT);
        if ($3) {
            printNode->child1 = $3;  // Expression to print
            printNode->vtype = $3->vtype;  // Inherit the expression's type
        } else {
            // Handle error case
            printNode->child1 = NULL;
            printNode->vtype = TYPE_SCALAR;
        }
        $$ = printNode;
    }
  | /* Plot statement */
    PLOT LPAREN expr RPAREN SEMICOLON
    {
        ASTNode *plotNode = ast_new_node(AST_PLOT);
        plotNode->child1 = $3;
        $$ = plotNode;
    }
  | /* Histogram statement */
    HISTOGRAM LPAREN expr RPAREN SEMICOLON
    {
        ASTNode *histNode = ast_new_node(AST_HIST);
        histNode->child1 = $3;
        $$ = histNode;
    }
  | /* Scatter plot statement */
    SCATTER LPAREN expr COMMA expr RPAREN SEMICOLON
    {
        ASTNode *scatNode = ast_new_node(AST_SCATTER);
        scatNode->child1 = $3;
        scatNode->child2 = $5;
        $$ = scatNode;
    }
  | /* If-Else statement (Else optional) */
    IF LPAREN expr RPAREN LBRACE stmt_list RBRACE 
       {
         /* IF without ELSE */
         ASTNode *ifNode = ast_new_node(AST_IF);
         ifNode->child1 = $3;    // condition expression
         ifNode->child2 = ast_new_stmt_list_node($6);    // true-branch block (list of stmts)
         ifNode->child3 = NULL;  // no else branch
         $$ = ifNode;
       }
    | IF LPAREN expr RPAREN LBRACE stmt_list RBRACE 
       ELSE LBRACE stmt_list RBRACE
       {
         /* IF with ELSE */
         ASTNode *ifNode = ast_new_node(AST_IF);
         ifNode->child1 = $3;   // condition expression
         ifNode->child2 = ast_new_stmt_list_node($6);   // true branch
         ifNode->child3 = ast_new_stmt_list_node($10);  // false branch (else)
         $$ = ifNode;
       }
  | /* While loop */
    WHILE LPAREN expr RPAREN LBRACE stmt_list RBRACE
    {
         ASTNode *whileNode = ast_new_node(AST_WHILE);
         whileNode->child1 = $3;  // loop condition
         whileNode->child2 = ast_new_stmt_list_node($6);  // loop body statements
         $$ = whileNode;
    }
  ;

expr:
    /* numeric literal (scalar) */
    NUMBER 
    {
        $$ = ast_new_num($1);
    }
  | /* variable reference */
    ID 
    {
        $$ = ast_new_var($1);
    }
  | /* vector literal, e.g., [1,2,3] */
    LBRACKET vector_elems RBRACKET
    {
        $$ = ast_new_vector($2);  // $2 is ASTNodeList* of elements
    }
  | /* parenthesized expression */
    LPAREN expr RPAREN 
    {
        $$ = $2;
    }
  | /* binary operations */
    expr '+' expr 
    {
        $$ = ast_new_binop('+', $1, $3);
    }
  | expr '-' expr 
    {
        $$ = ast_new_binop('-', $1, $3);
    }
  | expr '*' expr 
    {
        $$ = ast_new_binop('*', $1, $3);
    }
  | expr '/' expr 
    {
        $$ = ast_new_binop('/', $1, $3);
    }
  | /* comparison operations yield a boolean (could treat as number 0/1) */
    expr GT expr 
    {
        $$ = ast_new_binop('>', $1, $3);
    }
  | expr LT expr 
    {
        $$ = ast_new_binop('<', $1, $3);
    }
  | expr GTE expr 
    {
        $$ = ast_new_binop('G', $1, $3);  /* using 'G' char to represent >= */
    }
  | expr LTE expr 
    {
        $$ = ast_new_binop('L', $1, $3);  /* 'L' for <= */
    }
  | expr EQ expr 
    {
        $$ = ast_new_binop('=', $1, $3);
    }
  | expr NEQ expr 
    {
        $$ = ast_new_binop('N', $1, $3);  /* 'N' for != */
    }
  | /* unary minus (negation) */
    '-' expr %prec UMINUS
    {
        $$ = ast_new_unary('-', $2);
    }
  | /* External function call like sin(expr) or custom functions */
    ID LPAREN arg_list RPAREN 
    {
        $$ = ast_new_func_call($1, $3);
    }
  ;

vector_elems:
    expr 
    {
        /* single element vector [ expr ] */
        $$ = ast_new_list();
        $$ = ast_append_list($$, $1);
    }
  | vector_elems COMMA expr
    {
        $$ = ast_append_list($1, $3);
    }
  ;

arg_list:
    /* empty arguments */
    {
        $$ = ast_new_list();
    }
  | arg_list_nonempty 
    {
        $$ = $1;
    }
  ;

arg_list_nonempty:
    expr 
    {
        $$ = ast_new_list();
        ast_append_list($$, $1);
    }
  | arg_list_nonempty COMMA expr
    {
        $$ = ast_append_list($1, $3);
    }
  ;

%%

/* Optionally, code for main or error handling could be placed here 
   but in our structure, main.c is separate, so we'll leave this part empty. */
