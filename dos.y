%{
#include <stdio.h>
#include <string.h>

extern int yylex();
extern int yylineno;
extern int error_lines[];
extern int error_line_count;
int yyerror(const char *s);
int syntax_error_lines[1000];
int syntax_error_count = 0;

int line_has_lexical_error(int line_num) {
    for (int i = 0; i < error_line_count; i++) {
        if (error_lines[i] == line_num) {
            return 1;
        }
    }
    return 0;
}

int line_already_has_syntax_error(int line_num) {
    for (int i = 0; i < syntax_error_count; i++) {
        if (syntax_error_lines[i] == line_num) {
            return 1;
        }
    }
    return 0;
}

void mark_syntax_error_at_line(int line) {
    /* Store the exact line number where error was detected, only if unique */
    if (!line_has_lexical_error(line) && !line_already_has_syntax_error(line)) {
        syntax_error_lines[syntax_error_count++] = line;
    }
}

void mark_syntax_error() {
    /* Use current line number without adjustment */
    mark_syntax_error_at_line(yylineno);
}
%}

%token IDENTIFIER KEYWORD NUMBER STRING INRANGE
%token LPAREN RPAREN LBRACKET RBRACKET ASSIGN SEMICOLON COMMA COLON DOT
%token PLUS MINUS MULT DIV MOD LT GT LE GE EQ NE
%token ERROR_TOKEN NEWLINE

%token DEF IF ELIF ELSE FOR WHILE IN RANGE RETURN PASS BREAK CONTINUE PRINT IMPORT
%token TRUE FALSE AND OR NOT IS

/* Operator precedence and associativity (lowest to highest) */
%left OR
%left AND
%left NOT
%left LT GT LE GE EQ NE IS
%left PLUS MINUS
%left MULT DIV MOD
%right UMINUS UPLUS
%left LBRACKET
%left LPAREN

%start program

%%

program:
    lines
  ;

lines:
    /* empty */
  | lines line
  ;

line:
    statement NEWLINE           { /* Valid statement on this line */ }
  | statement                   { /* Statement without newline */ }
  | NEWLINE                     { /* Empty line */ }
  | error NEWLINE               { yyerrok; yychar = YYEMPTY; }  /* Skip invalid lines completely */
  ;

statement:
    assignment
  | function_def_line
  | if_statement_line
  | for_statement_line
  | while_statement_line
  | pass_statement
  | break_statement
  | continue_statement
  | print_statement
  | import_statement
  | return_statement
  | expression_statement
  | error  /* Default error recovery */
  ;

/* Assignment: identifier = expression OR identifier1, identifier2 = expression1, expression2 */
assignment:
    IDENTIFIER ASSIGN expression                                    /* Single assignment */
  | identifier_list ASSIGN expression_list                         /* Multiple assignment - balanced */
  | identifier_list ASSIGN expression                              
    { 
        mark_syntax_error_at_line(yylineno - 1);  /* Error is on the line we just finished processing */
        printf("Error: Assignment mismatch - multiple variables, single value\n"); 
    }
  ;

identifier_list:
    IDENTIFIER                                                      /* Single identifier */
  | identifier_list COMMA IDENTIFIER                               /* Multiple identifiers */
  ;

expression_list:
    expression                                                      /* Single expression */
  | expression_list COMMA expression                               /* Multiple expressions */
  ;

/* Function definition: def identifier([param1, param2, ...]): statements [return expression] */
function_def_line:
    DEF IDENTIFIER LPAREN parameter_list RPAREN COLON
    { /* Valid function definition line */ }
  | DEF IDENTIFIER LPAREN parameter_list RPAREN
    { 
        mark_syntax_error_at_line(yylineno - 1);  /* Error is on the line we just finished processing */
        printf("Error: Missing ':' after function definition\n"); 
    }
  ;

/* Single-line versions for immediate evaluation */
if_statement_line:
    IF expression COLON
  | IF expression 
    { 
        mark_syntax_error_at_line(yylineno);
        printf("Error: Missing ':' after if condition\n"); 
    }
  ;

for_statement_line:
    FOR IDENTIFIER IN RANGE LPAREN expression RPAREN COLON          /* for i in range(expression) */
  | FOR IDENTIFIER RANGE LPAREN expression RPAREN COLON             /* for i range(expression) - IN optional */
  | FOR IDENTIFIER INRANGE expression COLON                         /* for i inrange expression */  
  | FOR IDENTIFIER IN IDENTIFIER COLON                              /* for i in identifier */
  | FOR IDENTIFIER COLON
    { 
        mark_syntax_error_at_line(yylineno);
        printf("Error: Invalid for loop syntax\n"); 
    }
  | FOR IDENTIFIER RANGE
    { 
        mark_syntax_error_at_line(yylineno);
        printf("Error: Missing parentheses after 'range' in for loop\n"); 
    }
  ;

while_statement_line:
    WHILE expression COLON
  | WHILE expression
    { 
        mark_syntax_error_at_line(yylineno);
        printf("Error: Missing ':' after while condition\n"); 
    }
  ;

parameter_list:
    /* empty */
  | IDENTIFIER
  | parameter_list COMMA IDENTIFIER
  ;

/* Range: range(expression[, expression]) */
range_expression:
    RANGE LPAREN expression RPAREN
  | RANGE LPAREN expression COMMA expression RPAREN
  ;

/* Simple statements */
pass_statement:
    PASS
  ;

break_statement:
    BREAK
  ;

continue_statement:
    CONTINUE
  ;

print_statement:
    PRINT LPAREN expression_list RPAREN
  | PRINT LPAREN RPAREN
  ;

import_statement:
    IMPORT IDENTIFIER
  ;

return_statement:
    RETURN expression
  | RETURN
  ;

expression_statement:
    expression
  ;

/* Expressions - simplified to reduce conflicts */
expression:
    expression PLUS expression
  | expression MINUS expression
  | expression MULT expression
  | expression DIV expression
  | expression MOD expression
  | expression LT expression
  | expression GT expression
  | expression LE expression
  | expression GE expression
  | expression EQ expression
  | expression NE expression
  | expression IS expression
  | expression AND expression
  | expression OR expression
  | NOT expression
  | MINUS expression %prec UMINUS
  | PLUS expression %prec UPLUS
  | primary_expression
  ;

primary_expression:
    NUMBER
  | STRING
  | TRUE
  | FALSE
  | IDENTIFIER
  | list_expression
  | list_access
  | function_call
  | range_expression
  | LPAREN expression RPAREN
  ;

/* Arithmetic expressions - removed to avoid conflicts */

/* List: [[expression1, expression2, ...]] */
list_expression:
    LBRACKET RBRACKET
  | LBRACKET expression_list RBRACKET
  ;

/* List access: expression[expression] to allow chaining like exp[i][j] */
list_access:
    IDENTIFIER LBRACKET expression RBRACKET
  | list_access LBRACKET expression RBRACKET
  ;

/* Function call: identifier([expression1, expression2, ...]) */
function_call:
    IDENTIFIER LPAREN expression_list RPAREN
  | IDENTIFIER LPAREN RPAREN
  ;

%%

int yyerror(const char *s) { 
    mark_syntax_error();
    return 0; 
}
