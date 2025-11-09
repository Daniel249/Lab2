%{
#include "dos.tab.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

int id_count = 0;
int err_count = 0;
int line_has_error = 0;
int error_lines[1000];
int error_line_count = 0;

typedef struct IdNode {
    char *name;
    int num;
    struct IdNode *next;
} IdNode;

IdNode *id_table = NULL;

int get_id_num(char *yytext) {
    IdNode *curr = id_table;
    while (curr) {
        if (strcmp(curr->name, yytext) == 0)
            return curr->num;
        curr = curr->next;
    }
    IdNode *newnode = (IdNode *)malloc(sizeof(IdNode));
    newnode->name = strdup(yytext);
    newnode->num = ++id_count;
    newnode->next = id_table;
    id_table = newnode;
    return newnode->num;
}

int get_keyword_token(const char *s) {
    if (strcmp(s, "def") == 0) return DEF;
    if (strcmp(s, "if") == 0) return IF;
    if (strcmp(s, "elif") == 0) return ELIF;
    if (strcmp(s, "else") == 0) return ELSE;
    if (strcmp(s, "for") == 0) return FOR;
    if (strcmp(s, "while") == 0) return WHILE;
    if (strcmp(s, "in") == 0) return IN;
    if (strcmp(s, "range") == 0) return RANGE;
    if (strcmp(s, "return") == 0) return RETURN;
    if (strcmp(s, "pass") == 0) return PASS;
    if (strcmp(s, "break") == 0) return BREAK;
    if (strcmp(s, "continue") == 0) return CONTINUE;
    if (strcmp(s, "print") == 0) return PRINT;
    if (strcmp(s, "import") == 0) return IMPORT;
    if (strcmp(s, "True") == 0) return TRUE;
    if (strcmp(s, "False") == 0) return FALSE;
    if (strcmp(s, "and") == 0) return AND;
    if (strcmp(s, "or") == 0) return OR;
    if (strcmp(s, "not") == 0) return NOT;
    if (strcmp(s, "is") == 0) return IS;
    return KEYWORD; /* fallback for any other keywords */
}

int is_keyword(const char *s) {
    static const char *kw[] = {
        "and","else","is","return","break","for","not","while",
        "continue","if","or","def","import","pass","elif","print",
        "True","False","in","range", NULL
    };
    for (int i = 0; kw[i]; i++) {
        if(strcmp(s, kw[i]) == 0) return 1;
    }
    return 0;
}

void print_upper(const char *s) {
    for (const char *p = s; *p; ++p)
        putchar(toupper((unsigned char)*p));
    putchar(' ');
}

void mark_error() {
    if (!line_has_error) {
        line_has_error = 1;
        error_lines[error_line_count++] = yylineno;
    }
}
%}

%option noyywrap
%option yylineno

DIGIT       [0-9]
LETTER      [a-zA-ZáéíóúÁÉÍÓÚñÑ_]
ID          {LETTER}[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ_]*
INVALIDWORD [@$%#&0-9][a-zA-Z0-9áéíóúÁÉÍÓÚñÑ_@$%#&-]*
UNCLOSED_STR \"[^\"\r\n]*
UINT        {DIGIT}+
LONGINT     {UINT}[lL]
FLOAT       ({DIGIT}+"."{DIGIT}*)|({DIGIT}*"."{DIGIT}+)|({DIGIT}+[eE][+-]?{DIGIT}+)
IMAG        ({UINT}|{FLOAT})[jJ]
STRING_SQ   \'([^\\\'\r\n])*\'
STRING_DQ   \"([^\\\"\r\n])*\"
COMMENT     \#.*

%%

"in"[ \t]+"range" {
    return INRANGE;
}

{UNCLOSED_STR} {
    err_count++;
    mark_error();
    return ERROR_TOKEN;
}

{ID} {
    if (is_keyword(yytext)) {
        return get_keyword_token(yytext);
    } else {
        int num = get_id_num(yytext);
        return IDENTIFIER;
    }
}

"+"     { return PLUS; }
"-"     { return MINUS; }

{LONGINT}   { return NUMBER; }
{FLOAT}     { return NUMBER; }
{IMAG}      { return NUMBER; }
{UINT}      { return NUMBER; }

{INVALIDWORD} {
    err_count++;
    mark_error();
    return ERROR_TOKEN;
}

{STRING_SQ} { return STRING; }
{STRING_DQ} { return STRING; }

{COMMENT}   { /* ignore comments */ }

"("     { return LPAREN; }
")"     { return RPAREN; }
"["     { return LBRACKET; }
"]"     { return RBRACKET; }
"="     { return ASSIGN; }
";"     { return SEMICOLON; }
","     { return COMMA; }
":"     { return COLON; }
"."     { return DOT; }
"*"     { return MULT; }
"/"     { return DIV; }
"%"     { return MOD; }
"<"     { return LT; }
">"     { return GT; }
"<="    { return LE; }
">="    { return GE; }
"=="    { return EQ; }
"!="    { return NE; }

[ ]   { /* ignore spaces */ }
[\t]  { /* ignore tabs */ }
\r?\n { 
    line_has_error = 0;
    return NEWLINE; 
}

. {
    err_count++;
    mark_error();
    return ERROR_TOKEN;
}

%%

int main() {
    extern int syntax_error_lines[];
    extern int syntax_error_count;
    
    yyparse();
    
    printf("%d líneas presentaron error sintáctico\n", syntax_error_count);
    
    if (syntax_error_count == 0) {
        printf("No hay errores sintacticos\n");
    } else {
        for (int i = 0; i < syntax_error_count; i++) {
            printf("línea %d error sintactico\n", syntax_error_lines[i]);
        }
    }
    
    return 0;
}