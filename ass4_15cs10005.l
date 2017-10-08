%{
#include "ass3_15cs10005.tab.h"
#include <stdlib.h>
%}

%x                      single_lc multi_lc
ws                      [\n\t\r\f ]
keyword                 unsigned|break|return|void|case|float|short|char|for|signed|while|goto|Bool|continue|if|default|do|int|switch|double|long|else|Matrix
identifier              {identifier-nondigit}({identifier-nondigit}|{digit})*
identifier-nondigit     [_a-zA-Z]
digit                   [0-9]
constant                {integer-constant}|{floating-constant}|{character-constant}|{zero-constant}
zero-constant           0
integer-constant        {nonzero-digit}({digit})*
nonzero-digit           [1-9]
floating-constant       {fractional-constant}{exponent-part}?|{digit-sequence}{exponent-part}
fractional-constant     {digit-sequence}?\.{digit-sequence}|{digit-sequence}\.
exponent-part           e{sign}?{digit-sequence}|E{sign}?{digit-sequence}
sign                    \+|\-
digit-sequence          {digit}+
character-constant      \'{c-char-sequence}\'
c-char-sequence         {c-char}+
c-char                  [^'\\\n]|{escape-sequence}
escape-sequence         \\\'|\\\"|\\\?|\\\\|\\a|\\b|\\f|\\n|\\r|\\t|\\v
ds                      \/\/
single-punctuator       \[|\]|\(|\)|\{|\}|\.|"\&"|"\*"|"\+"|"\-"|"\~"|"\!"|"\/"|"\%"|"\<"|"\>"|"\^"|\||"\?"|"\:"|"\;"|"\="|\,|\#
string-literal          \"{s-char-sequence}?\"
s-char-sequence         {s-char}+
s-char                  {c-char}

%%
unsigned		{ return UNSIGNED; }
break { return BREAK; }
return { return RETURN; }
void { return VOID; }
case { return CASE; }
float { return FLOAT; }
short { return SHORT; }
char { return CHAR; }
for { return FOR; }
signed { return SIGNED; }
while { return WHILE; }
goto { return GOTO; }
Bool { return BOOL; }
continue { return CONTINUE; }
if { return IF; }
default { return DEFAULT; }
int { return INT; }
do { return DO; }
switch { return SWITCH; }
double { return DOUBLE; }
long { return LONG; }
else { return ELSE; }
Matrix { return MATRIX; }

\-\> { return ARROW; }
\+\+ { return PLUSPLUS; }
\-\- { return MINUSMINUS; }
\<\< { return LEFT_SHIFT; }
\>\> { return RIGHT_SHIFT; }
\<\= { return LESS_EQUAL; }
\>\= { return GREATER_EQUAL; }
\=\= { return IS_EQUAL; }
\!\= { return IS_NOT_EQUAL; }
\&\& { return LOGICAL_AND; }
\|\| { return LOGICAL_OR; }
\*\= { return MUL_EQUAL; }
\/\= { return DIV_EQUAL; }
\%\= { return MOD_EQUAL; }
\+\= { return ADD_EQUAL; }
\-\= { return SUB_EQUAL; }
\<\<\= { return LEFT_SHIFT_EQUAL; }
\>\>\= { return RIGHT_SHIFT_EQUAL; }
\&\= { return AND_EQUAL; }
\^\= { return XOR_EQUAL; }
\|\= { return OR_EQUAL; }
\.\' { return TRANSPOSE; }

{single-punctuator} { return *yytext; }
{identifier}            {   yylval.string_val = yytext; return IDENTIFIER; }
{integer-constant}      {   yylval.int_val = atoi(yytext);  return INT_CONSTANT;   }
{floating-constant}     {   yylval.double_val = atof(yytext);   return DOUBLE_CONSTANT; }
{character-constant}    {   yylval.string_val = yytext; return CHAR_CONSTANT; }
{string-literal}        {   yylval.string_val = yytext; return STRING_LITERAL;  }
{ds}            { BEGIN(single_lc);    }
<single_lc>\n     { BEGIN(0);}
<single_lc>[^\n]*    {}
\/\*            {  BEGIN(multi_lc);  }
<multi_lc>[*]*[\/]    { BEGIN(0); }
<multi_lc>[*]*[^\/] {}
<multi_lc>[^*]*     {}
{ws}            {}
.				{ printf("Lexical error!\n"); exit(1); }
%%
