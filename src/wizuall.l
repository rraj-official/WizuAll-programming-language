%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "wizuall.tab.h"
%}

%option noyywrap

/* Basic definitions */
DIGIT    [0-9]
LETTER   [a-zA-Z]
ID       {LETTER}({LETTER}|{DIGIT}|_)*
NUMBER   {DIGIT}+(\.{DIGIT}+)?([eE][+-]?{DIGIT}+)?
WS       [ \t\r\n]+

%%

{WS}        { /* ignore whitespaces */ }

"plot"      { return PLOT; }
"histogram" { return HISTOGRAM; }
"scatter"   { return SCATTER; }
"print"     { return PRINT; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }

"="         { return ASSIGN; }
";"         { return SEMICOLON; }
","         { return COMMA; }

"("         { return LPAREN; }
")"         { return RPAREN; }
"["         { return LBRACKET; }
"]"         { return RBRACKET; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }

"=="        { return EQ; }
"!="        { return NEQ; }
">"         { return GT; }
"<"         { return LT; }
">="        { return GTE; }
"<="        { return LTE; }

"+"         { return '+'; }
"-"         { return '-'; }
"*"         { return '*'; }
"/"         { return '/'; }

{NUMBER}    { 
              yylval.numVal = atof(yytext);
              return NUMBER; 
            }

{ID}        {
              yylval.strVal = strdup(yytext);
              return ID;
            }

"//".*      { /* ignore single line comments */ }
"#".*       { /* ignore single line comments */ }

.           { fprintf(stderr, "Unrecognized character: %s\n", yytext); }

%%

