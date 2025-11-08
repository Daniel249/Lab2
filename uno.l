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
    print_upper("in range");
    return INRANGE;
}

{UNCLOSED_STR} {
    printf("Error=\"%s\" ", yytext);
    err_count++;
    mark_error();
    return ERROR_TOKEN;
}

{ID} {
    if (is_keyword(yytext)) {
        print_upper(yytext);
        return get_keyword_token(yytext);
    } else {
        int num = get_id_num(yytext);
        printf("id%d=%s ", num, yytext);
        return IDENTIFIER;
    }
}

"+"     { printf("suma=+ "); return PLUS; }
"-"     { printf("menos=- "); return MINUS; }

{LONGINT}   { printf("long=%s ", yytext); return NUMBER; }
{FLOAT}     { printf("decimal=%s ", yytext); return NUMBER; }
{IMAG}      { printf("imaginario=%s ", yytext); return NUMBER; }
{UINT}      { printf("entero=%s ", yytext); return NUMBER; }

{INVALIDWORD} {
    printf("Error=\"%s\" ", yytext);
    err_count++;
    mark_error();
    return ERROR_TOKEN;
}

{STRING_SQ} { printf("cadena=%s ", yytext); return STRING; }
{STRING_DQ} { printf("cadena=%s ", yytext); return STRING; }

{COMMENT}   { /* ignore comments */ }

"("     { printf("parabre=( "); return LPAREN; }
")"     { printf("parcierr=) "); return RPAREN; }
"["     { printf("corabre=[ "); return LBRACKET; }
"]"     { printf("corcierr=] "); return RBRACKET; }
"="     { printf("asign== "); return ASSIGN; }
";"     { printf("puntoycoma=; "); return SEMICOLON; }
","     { printf("coma=, "); return COMMA; }
":"     { printf("dospunt=: "); return COLON; }
"."     { printf("punto=. "); return DOT; }
"*"     { printf("mult=* "); return MULT; }
"/"     { printf("div=/ "); return DIV; }
"%"     { printf("mod=%% "); return MOD; }
"<"     { printf("menor=< "); return LT; }
">"     { printf("mayor=> "); return GT; }
"<="    { printf("menor_ig=<= "); return LE; }
">="    { printf("mayor_ig=>= "); return GE; }
"=="    { printf("comp=== "); return EQ; }
"!="    { printf("distinto=!= "); return NE; }

[ ]   { printf(" "); }
[\t]  { printf("\t"); }
\r?\n { 
    printf("\n"); 
    line_has_error = 0;
    return NEWLINE; 
}

. {
    printf("Error=\"%s\" ", yytext);
    err_count++;
    mark_error();
    return ERROR_TOKEN;
}

%%

int main() {
    extern int syntax_error_lines[];
    extern int syntax_error_count;
    
    yyparse();
    
    printf("\n\n%d Identificadores\n", id_count);
    for (IdNode *curr = id_table; curr; curr = curr->next)
        printf("id%d=%s\n", curr->num, curr->name);

    printf("\n%d Errores lexicos\n", err_count);
    
    if (error_line_count == 0) {
        printf("No hay errores lexicos\n");
    } else {
        for (int i = 0; i < error_line_count; i++) {
            printf("línea %d error lexico\n", error_lines[i]);
        }
    }
    
    printf("\n%d líneas presentaron error sintáctico\n", syntax_error_count);
    
    if (syntax_error_count == 0) {
        printf("No hay errores sintacticos\n");
    } else {
        for (int i = 0; i < syntax_error_count; i++) {
            printf("línea %d error sintactico\n", syntax_error_lines[i]);
        }
    }
    
    return 0;
}