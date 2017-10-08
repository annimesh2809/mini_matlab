%{
#include <stdio.h>
#include "y.tab.h"
%}

%union {
    string string_val;
    int int_val;
    double double_val;
    IdentifierType id_type;
    ExpressionType exp_type;
};

%token UNSIGNED BREAK RETURN VOID CASE FLOAT SHORT CHAR FOR SIGNED WHILE GOTO BOOL CONTINUE IF DEFAULT DO INT SWITCH DOUBLE LONG ELSE MATRIX
%token <string_val> CHAR_CONSTANT STRING_LITERAL
%token <id_type> IDENTIFIER
%token <int_val> INT_CONSTANT
%token <double_val> DOUBLE_CONSTANT
%token ARROW PLUSPLUS MINUSMINUS LEFT_SHIFT RIGHT_SHIFT LESS_EQUAL GREATER_EQUAL IS_EQUAL IS_NOT_EQUAL LOGICAL_AND LOGICAL_OR MUL_EQUAL DIV_EQUAL MOD_EQUAL ADD_EQUAL SUB_EQUAL LEFT_SHIFT_EQUAL RIGHT_SHIFT_EQUAL AND_EQUAL XOR_EQUAL OR_EQUAL TRANSPOSE

%type <exp_type> primary-expression postfix-expression

%%

prog:
  translation-unit { printf("Parsing successful\n"); }
;

primary-expression:
    IDENTIFIER          {
                            if(!global_st->is_present($1.string_val))
                                $$.loc = current_st->lookup($1.string_val);
                            else
                                $$.loc = global_st->lookup($1.string_val);
                            $$.type = $$.loc->type;
                            $$.truelist = $$.falselist = NULL;
                        }
    | INT_CONSTANT      {
                            $$.loc = current_st->gentemp(UnionType(BasicType::INT));
                            $$.type = $$.loc->type;
                            $$.truelist = $$.falselist = NULL;
                            UnionInitialVal init;
                            init.int_val = $1;
                            current_st->update($$.loc, init);
                            quad.emit(QuadEntry(Opcode::ASS, $$.loc->name, $1));
                        }
    | DOUBLE_CONSTANT   {
                            $$.loc = current_st->gentemp(UnionType(BasicType::DOUBLE));
                            $$.type = $$.loc->type;
                            $$.truelist = $$.falselist = NULL;
                            UnionInitialVal init;
                            init.double_val = $1;
                            current_st->update($$.loc, init);
                            quad.emit(QuadEntry(Opcode::ASS, $$.loc->name, $1));
                        }
    | CHAR_CONSTANT     { }
    | STRING_LITERAL    {
                            // Not Required
                            $$.loc = current_st->gentemp(UnionType(BasicType::PTR));
                            $$.type = UnionType(BasicType::PTR);
                            $$.type->next = new UnionType(BasicType::CHAR);
                            $$.is_string = true;
                            $$.string_index = string_set.insert($1).first;
                            quad.emit(QuadEntry(Opcode::DAT, $$))
                        }
    | '(' expression ')'{
                            $$ = $2;
                        }
;

postfix-expression:
  primary-expression { $$ = $1; }
| postfix-expression '[' expression ']' {
    // DONT KNOW IF CORRECT
            $$ = $1;
            if($$.type.type == BasicType::MATRIX){
                $$.type = UnionType(BasicType::PTR);
                $$.type.next = new UnionType(BasicType::DOUBLE);
                $$.loc = current_st->gentemp(UnionType(BasicType::INT));
                $$.is_ptr = true;
                quad.emit(QuadEntry(Opcode::MUL, $$.loc->name, $3.loc->name, to_string(SZ_DOUBLE)));
                quad.emit(QuadEntry(Opcode::ADD, $$.loc->name, $$.loc->name, ))
            }
            else if($$.type.type == BasicType::PTR){
                $$.type = $1.type.next;
                SymbolTableEntry* temp = current_st->gentemp(UnionType(BasicType::INT));
                quad.emit(QuadEntry(Opcode::MUL, temp->name, $3.loc->name, to_string($1.type->next->getSize())));
                quad.emit(QuadEntry(Opcode::ADD, $$.loc->name, $$.loc->name, temp->name));
            }
            else{
                throw_error("Expression is neither a matrix nor a pointer!")
            }
        }
| postfix-expression '(' argument-expression-list-opt ')'  {
    $$ = $1;
    if($1.loc->nested_table == NULL || !check_params($1, $3)){
        cout << "Function call error!";
        exit(1);
    }
    else{
        for(int i=(int)$3->size()-1; i>=0; i--){
            quad.emit(QuadEntry(Opcode::PARAM, $3[i]->loc->name));
        }
        $$.loc = current_st->gentemp($1.loc->nested_table->entries[0]->type);
        $$.type = $$.loc->type;
        $$.truelist = $$.falselist = NULL;
        quad.emit(QuadEntry(Opcode::CALL, $$.loc->name, $1.loc->name, to_string((int)$3->size())));
    }
}
| postfix-expression '.' IDENTIFIER { // NOT SUPPORTED }
| postfix-expression ARROW IDENTIFIER { // NOT SUPPORTED }
| postfix-expression PLUSPLUS {
    $$ = $1;
    $$.loc = current_st->gentemp($1.type);
    quad.emit(QuadEntry(Opcode::ASS, $$.loc->name, $1.loc->name));
    quad.emit(QuadEntry(Opcode::ADD, $1.loc->name, $1.loc->name, "1"));
}
| postfix-expression MINUSMINUS {
    $$ = $1;
    $$.loc = current_st->gentemp($1.type);
    quad.emit(QuadEntry(Opcode::ASS, $$.loc->name, $1.loc->name));
    quad.emit(QuadEntry(Opcode::SUB, $1.loc->name, $1.loc->name, "1"));
}
| postfix-expression TRANSPOSE { printf("postfix-expression --> postfix-expression.'\n"); }
;

argument-expression-list-opt:
  argument-expression-list { printf("argument-expression-list-opt --> argument-expression-list\n"); }
| %empty { printf("argument-expression-list-opt --> %%empty\n"); }
;

argument-expression-list:
  assigment-expression { printf("argument-expression-list --> assigment-expression\n"); }
| argument-expression-list ',' assigment-expression { printf("argument-expression-list --> argument-expression-list, assigment-expression\n"); }
;

unary-expression:
  postfix-expression { printf("unary-expression --> postfix-expression\n"); }
| PLUSPLUS unary-expression { printf("unary-expression --> ++ unary-expression\n"); }
| MINUSMINUS unary-expression { printf("unary-expression --> -- unary-expression\n"); }
| unary-operator cast-expression { printf("unary-expression --> unary-expression cast-expression\n"); }
;

unary-operator:
  '&' { printf("unary-operator --> &\n"); }
| '*' { printf("unary-operator --> *\n"); }
| '+' { printf("unary-operator --> +\n"); }
| '-' { printf("unary-operator --> -\n"); }
;

cast-expression:
  unary-expression { printf("cast-expression --> unary-expression\n"); }
;

multiplicative-expression:
  cast-expression { printf("multiplicative-expression --> cast-expression\n"); }
| multiplicative-expression '*' cast-expression { printf("multiplicative-expression --> multiplicative-expression * cast-expression\n"); }
| multiplicative-expression '/' cast-expression { printf("multiplicative-expression --> multiplicative-expression / cast-expression\n"); }
| multiplicative-expression '%' cast-expression { printf("multiplicative-expression --> multiplicative-expression %% cast-expression\n"); }
;

additive-expression:
  multiplicative-expression { printf("additive-expression --> multiplicative-expression\n"); }
| additive-expression '+' multiplicative-expression { printf("additive-expression --> additive-expression + multiplicative-expression\n"); }
| additive-expression '-' multiplicative-expression { printf("additive-expression --> additive-expression - multiplicative-expression\n"); }
;

shift-expression:
  additive-expression  { printf("shift-expression --> additive-expression\n"); }
| shift-expression LEFT_SHIFT additive-expression  { printf("shift-expression --> shift-expression << additive-expression\n"); }
| shift-expression RIGHT_SHIFT additive-expression  { printf("shift-expression --> shift-expression >> additive-expression\n"); }
;

relational-expression:
  shift-expression    { printf("relational-expression --> shift-expression\n"); }
| relational-expression '<' shift-expression    { printf("relational-expression --> relational-expression < shift-expression\n"); }
| relational-expression '>' shift-expression    { printf("relational-expression --> relational-expression > shift-expression\n"); }
| relational-expression LESS_EQUAL shift-expression    { printf("relational-expression --> relational-expression <= shift-expression\n"); }
| relational-expression GREATER_EQUAL shift-expression    { printf("relational-expression --> relational-expression >= shift-expression\n"); }
;

equality-expression:
  relational-expression      { printf("equality-expression --> relational-expression\n"); }
| equality-expression IS_EQUAL relational-expression      { printf("equality-expression --> equality-expression == relational-expression\n"); }
| equality-expression IS_NOT_EQUAL relational-expression      { printf("equality-expression --> equality-expression != relational-expression\n"); }
;

AND-expression:
  equality-expression    { printf("AND-expression --> equality-expression\n"); }
| AND-expression '&' equality-expression    { printf("AND-expression --> AND-expression & equality-expression\n"); }
;

exclusive-OR-expression:
  AND-expression    { printf("exclusive-OR-expression --> AND-expression\n"); }
| exclusive-OR-expression '^' AND-expression  { printf("exclusive-OR-expression --> exclusive-OR-expression ^ AND-expression\n"); }
;

inclusive-OR-expression:
  exclusive-OR-expression    { printf("inclusive-OR-expression --> exclusive-OR-expression\n"); }
| inclusive-OR-expression '|' exclusive-OR-expression    { printf("inclusive-OR-expression --> inclusive-OR-expression | exclusive-OR-expression\n"); }
;

logical-AND-expression:
  inclusive-OR-expression    { printf("logical-AND-expression --> inclusive-OR-expression\n"); }
| logical-AND-expression LOGICAL_AND inclusive-OR-expression    { printf("logical-AND-expression --> logical-AND-expression && inclusive-OR-expression\n"); }
;

logical-OR-expression:
  logical-AND-expression    { printf("logical-OR-expression --> logical-AND-expression\n"); }
| logical-OR-expression LOGICAL_OR logical-AND-expression    { printf("logical-OR-expression --> logical-OR-expression || logical-AND-expression\n"); }
;

conditional-expression:
  logical-OR-expression    { printf("conditional-expression --> logical-OR-expression\n"); }
| logical-OR-expression '?' expression ':' conditional-expression    { printf("conditional-expression --> logical-OR-expression ? expression : conditional-expression\n"); }
;

assigment-expression:
  conditional-expression    { printf("assigment-expression --> conditional-expression\n"); }
| unary-expression assignment-operator assigment-expression    { printf("assigment-expression --> unary-expression assignment-operator assigment-expression\n"); }
;

assignment-operator:
  '='    { printf("assignment-operator --> =\n"); }
| MUL_EQUAL  { printf("assignment-operator --> *=\n"); }
| DIV_EQUAL  { printf("assignment-operator --> /=\n"); }
| MOD_EQUAL  { printf("assignment-operator --> %%=\n"); }
| ADD_EQUAL  { printf("assignment-operator --> +=\n"); }
| SUB_EQUAL  { printf("assignment-operator --> -=\n"); }
| LEFT_SHIFT_EQUAL  { printf("assignment-operator --> <<=\n"); }
| RIGHT_SHIFT_EQUAL  { printf("assignment-operator --> >>=\n"); }
| AND_EQUAL  { printf("assignment-operator --> &=\n"); }
| XOR_EQUAL  { printf("assignment-operator --> ^=\n"); }
| OR_EQUAL  { printf("assignment-operator --> |=\n"); }
;

expression:
  assigment-expression      { printf("expression --> assigment-expression\n"); }
| expression ',' assigment-expression   { printf("expression --> expression, assigment-expression\n"); }
;

constant-expression:
  conditional-expression    { printf("constant-expression --> conditional-expression\n"); }
;

declaration:
  declaration-specifiers init-declarator-list-opt ';'    { printf("declaration --> declaration-specifiers init-declarator-list-opt;\n"); }
;

init-declarator-list-opt:
  init-declarator-list  { printf("init-declarator-list-opt --> init-declarator-list\n"); }
| %empty  { printf("init-declarator-list-opt --> %%empty\n"); }
;

declaration-specifiers:
  type-specifier declaration-specifiers-opt    { printf("declaration-specifiers --> type-specifier declaration-specifiers-opt\n"); }
;

declaration-specifiers-opt:
  declaration-specifiers  { printf("declaration-specifiers-opt --> declaration-specifiers\n"); }
| %empty   { printf("declaration-specifiers-opt --> %%empty\n"); }
;

init-declarator-list:
  init-declarator    { printf("init-declarator-list --> init-declarator\n"); }
| init-declarator-list ',' init-declarator    { printf("init-declarator-list --> init-declarator-list, init-declarator\n"); }
;

init-declarator:
  declarator    { printf("init-declarator --> declarator\n"); }
| declarator '=' initializer    { printf("init-declarator --> declarator = initializer\n"); }
;

type-specifier:
  VOID    { printf("type-specifier --> void\n"); }
| CHAR    { printf("type-specifier --> char\n"); }
| SHORT    { printf("type-specifier --> short\n"); }
| INT    { printf("type-specifier --> int\n"); }
| LONG    { printf("type-specifier --> long\n"); }
| FLOAT    { printf("type-specifier --> float\n"); }
| DOUBLE    { printf("type-specifier --> double\n"); }
| MATRIX    { printf("type-specifier --> Matrix\n"); }
| SIGNED    { printf("type-specifier --> signed\n"); }
| UNSIGNED    { printf("type-specifier --> unsigned\n"); }
| BOOL    { printf("type-specifier --> Bool\n"); }
;

declarator:
  pointer-opt direct-declarator    { printf("declarator --> pointer-opt direct-declarator\n"); }
;

pointer-opt:
  pointer  { printf("pointer-opt --> pointer\n"); }
| %empty  { printf("pointer-opt --> %%empty\n"); }
;

direct-declarator:
  IDENTIFIER    { printf("direct-declarator --> Identifier\n"); }
| '(' declarator ')'    { printf("direct-declarator --> (declarator)\n"); }
| direct-declarator '[' assigment-expression-opt ']'    { printf("direct-declarator --> direct-declarator [assigment-expression-opt]\n"); }
| direct-declarator '(' parameter-type-list ')'    { printf("direct-declarator --> direct-declarator (parameter-type-list)\n"); }
| direct-declarator '(' identifier-list-opt ')'    { printf("direct-declarator --> direct-declarator (identifier-list-opt)\n"); }
;

assigment-expression-opt:
  assigment-expression  { printf("assigment-expression-opt --> assigment-expression\n"); }
| %empty  { printf("assigment-expression-opt --> %%empty\n"); }
;

identifier-list-opt:
  identifier-list  { printf("identifier-list-opt --> identifier-list\n"); }
| %empty  { printf("identifier-list-opt --> %%empty\n"); }
;

pointer:
  '*' pointer-opt    { printf("pointer --> * pointer-opt\n"); }
;

parameter-type-list:
  parameter-list    { printf("parameter-type-list --> parameter-list\n"); }
;

parameter-list:
  parameter-declaration    { printf("parameter-list --> parameter-declaration\n"); }
| parameter-list ',' parameter-declaration    { printf("parameter-list --> parameter-list, parameter-declaration\n"); }
;

parameter-declaration:
  declaration-specifiers declarator    { printf("parameter-declaration --> declaration-specifiers declarator\n"); }
| declaration-specifiers    { printf("parameter-declaration --> declaration-specifiers\n"); }
;

identifier-list:
  IDENTIFIER    { printf("identifier-list --> Identifier\n"); }
| identifier-list ',' IDENTIFIER    { printf("identifier-list --> identifier-list, Identifier\n"); }
;

initializer:
  assigment-expression    { printf("initializer --> assigment-expression\n"); }
| '{' initializer-row-list '}'    { printf("initializer --> { initializer-row-list }\n"); }
;

initializer-row-list:
  initializer-row    { printf("initializer-row-list --> initializer-row\n"); }
| initializer-row-list ';' initializer-row    { printf("initializer-row-list --> initializer-row-list; initializer-row\n"); }
;

initializer-row:
  designation-opt initializer    { printf("initializer-row --> designation-opt initializer\n"); }
| initializer-row ',' designation-opt initializer    { printf("initializer-row --> initializer-row, designation-opt initializer\n"); }
;

designation-opt:
  designation  { printf("designation-opt --> designation\n"); }
| %empty  { printf("designation-opt --> %%empty\n"); }
;

designation:
  designator-list '='    { printf("designation --> designator-list =\n"); }
;

designator-list:
  designator    { printf("designator-list --> designator\n"); }
| designator-list designator    { printf("designator-list --> designator-list designator\n"); }
;

designator:
  '[' constant-expression ']'    { printf("designator --> [ constant-expression ]\n"); }
| '.' IDENTIFIER    { printf("designator --> . Identifier\n"); }
;

statement:
  labeled-statement    { printf("statement --> labeled-statement\n"); }
| compound-statement    { printf("statement --> compound-statement\n"); }
| expression-statement    { printf("statement --> expression-statement\n"); }
| selection-statement    { printf("statement --> selection-statement\n"); }
| iteration-statement    { printf("statement --> iteration-statement\n"); }
| jump-statement    { printf("statement --> jump-statement\n"); }
;

labeled-statement:
  IDENTIFIER ':' statement    { printf("labeled-statement --> Identifier : statement\n"); }
| CASE constant-expression ':' statement    { printf("labeled-statement --> case constant-expression : statement\n"); }
| DEFAULT ':' statement    { printf("labeled-statement --> default : statement\n"); }
;

compound-statement:
  '{' block-item-list-opt '}'    { printf("compound-statement --> { block-item-list-opt }\n"); }
;

block-item-list-opt:
  block-item-list  { printf("block-item-list-opt --> block-item-list\n"); }
| %empty  { printf("block-item-list-opt --> %%empty\n"); }
;

block-item-list:
  block-item    { printf("block-item-list --> block-item\n"); }
| block-item-list block-item    { printf("block-item-list --> block-item-list block-item\n"); }
;

block-item:
  declaration    { printf("block-item --> declaration\n"); }
| statement    { printf("block-item --> statement\n"); }
;

expression-statement:
  expression-opt ';'    { printf("expression-statement --> expression-opt;\n"); }
;

expression-opt:
  expression  { printf("expression-opt --> expression\n"); }
| %empty  { printf("expression-opt --> %%empty\n"); }
;

selection-statement:
  IF '(' expression ')' statement    { printf("selection-statement --> if ( expression ) statement\n"); }
| IF '(' expression ')' statement ELSE statement    { printf("selection-statement --> if ( expression ) statement else statement\n"); }
| SWITCH '(' expression ')' statement    { printf("iteration-statement --> switch ( expression ) statement\n"); }
;

iteration-statement:
  WHILE '(' expression ')' statement    { printf("iteration-statement --> while ( expression ) statement\n"); }
| DO statement WHILE '(' expression ')' ';'    { printf("iteration-statement --> do statement while ( expression );\n"); }
| FOR '(' expression-opt ';' expression-opt ';' expression-opt ')' statement    { printf("iteration-statement --> for ( expression-opt; expression-opt; expression-opt ) statement\n"); }
| FOR '(' declaration expression-opt ';' expression-opt ')' statement    { printf("iteration-statement --> for ( declaration expression-opt; expression-opt) statement\n"); }
;

jump-statement:
  GOTO IDENTIFIER ';'    { printf("jump-statement --> goto Identifier;\n"); }
| CONTINUE ';'    { printf("jump-statement --> continue;\n"); }
| BREAK ';'    { printf("jump-statement --> break;\n"); }
| RETURN expression-opt ';'    { printf("jump-statement --> return expression-opt;\n"); }
;

translation-unit:
  external-declaration    { printf("translation-unit --> external-declaration\n"); }
| translation-unit external-declaration    { printf("translation-unit --> translation-unit external-declaration\n"); }
;

external-declaration:
  function-definition    { printf("external-declaration --> function-definition\n"); }
| declaration    { printf("external-declaration --> declaration\n"); }
;

function-definition:
  declaration-specifiers declarator declaration-list-opt compound-statement    { printf("function-definition --> declaration-specifiers declarator declaration-list-opt compound-statement\n"); }
;

declaration-list-opt:
  declaration-list  { printf("declaration-list-opt --> declaration-list\n"); }
| %empty  { printf("declaration-list-opt --> %%empty\n"); }
;

declaration-list:
  declaration    { printf("declaration-list --> declaration\n"); }
| declaration-list declaration    { printf("declaration-list --> declaration-list declaration\n"); }
;

%%
