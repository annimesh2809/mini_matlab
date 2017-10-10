%{
#include <stdio.h>
#include <iostream>
#include <string>
#include "ass4_15cs10005_translator.h"

using namespace std;

void yyerror(string c){}
extern int yylex(void);

%}

%union {
    string* string_val;
    int int_val;
    double double_val;
    char char_val;
    string* id_type;
    ExpressionType* exp_type;
    DeclarationType* decl_type;
    vector<ExpressionType*>* args_type;
    List* list;
}

%token UNSIGNED BREAK RETURN VOID CASE FLOAT SHORT CHAR FOR SIGNED WHILE GOTO BOOL CONTINUE IF DEFAULT DO INT SWITCH DOUBLE LONG ELSE MATRIX
%token <char_val> CHAR_CONSTANT
%token <string_val> STRING_LITERAL
%token <string_val> IDENTIFIER
%token <int_val> INT_CONSTANT
%token <double_val> DOUBLE_CONSTANT
%token ARROW PLUSPLUS MINUSMINUS LEFT_SHIFT RIGHT_SHIFT LESS_EQUAL GREATER_EQUAL IS_EQUAL IS_NOT_EQUAL LOGICAL_AND LOGICAL_OR MUL_EQUAL DIV_EQUAL MOD_EQUAL ADD_EQUAL SUB_EQUAL LEFT_SHIFT_EQUAL RIGHT_SHIFT_EQUAL AND_EQUAL XOR_EQUAL OR_EQUAL TRANSPOSE

%type <int_val> N
%type <list> M
%type <char_val> unary-operator
%type <exp_type> expression primary-expression postfix-expression unary-expression assigment-expression assigment-expression-opt
                cast-expression multiplicative-expression additive-expression shift-expression relational-expression equality-expression
                AND-expression exclusive-OR-expression inclusive-OR-expression logical-AND-expression logical-OR-expression
                conditional-expression constant-expression init-declarator-list-opt init-declarator-list direct-declarator declarator
                identifier-list-opt identifier-list initializer init-declarator
%type <decl_type> declaration-list declaration-list-opt type-specifier declaration-specifiers declaration-specifiers-opt
%type <args_type> argument-expression-list argument-expression-list-opt

%start prog

%%

prog:
  translation-unit { printf("Parsing successful\n"); }
;

primary-expression:
    IDENTIFIER          {
                            $$ = new ExpressionType();
                            if(global_st->is_present(*$1))
                                $$->loc = global_st->lookup(*$1);
                            else if(current_st->is_present(*$1))
                                $$->loc = current_st->lookup(*$1);
                            else{
                                cout<<*$1<<" used before declaration\n";
                                exit(1);
                            }
                            $$->type = $$->loc->type;
                            $$->truelist = $$->falselist = NULL;
                        }
    | INT_CONSTANT      {
                            $$ = new ExpressionType();
                            $$->loc = current_st->gentemp(UnionType(BasicType::INT));
                            $$->type = $$->loc->type;
                            $$->truelist = $$->falselist = NULL;
                            UnionInitialVal init;
                            init.int_val = $1;
                            current_st->update($$->loc, init);
                            quad.emit(Opcode::ASS, $$->loc->name, to_string($1));
                        }
    | DOUBLE_CONSTANT   {
                            $$ = new ExpressionType();
                            $$->loc = current_st->gentemp(UnionType(BasicType::DOUBLE));
                            $$->type = $$->loc->type;
                            $$->truelist = $$->falselist = NULL;
                            UnionInitialVal init;
                            init.double_val = $1;
                            current_st->update($$->loc, init);
                            quad.emit(Opcode::ASS, $$->loc->name, to_string($1));
                        }
    | CHAR_CONSTANT     {
                            $$ = new ExpressionType();
                            $$->loc = current_st->gentemp(UnionType(BasicType::CHAR));
                            $$->type = $$->loc->type;
                            $$->truelist = $$->falselist = NULL;
                            UnionInitialVal init;
                            init.char_val = $1;
                            current_st->update($$->loc, init);
                            quad.emit(Opcode::ASS, $$->loc->name, to_string($1));
                        }
    | STRING_LITERAL    {
                            // NOT SUPPORTED
                        }
    | '(' expression ')'{
                            $$ = $2;
                        }
;

postfix-expression:
  primary-expression { $$ = $1; }
| postfix-expression '[' expression ']' '[' expression ']'{
                                            $$ = new ExpressionType(*$1);
                                            if($1->type.type != BasicType::MATRIX)
                                                cout<<"Error: trying to access members of non Matrix type\n";
                                            if($3->type.type != BasicType::INT || $6->type.type != BasicType::INT)
                                                cout<<"Error: index is not integer\n";
                                            $$->loc = current_st->gentemp(UnionType(BasicType::INT));
                                            $$->type = UnionType(BasicType::DOUBLE);
                                            $$->is_matrix = true;
                                            $$->parent_matrix = $1->loc;
                                            quad.emit(Opcode::MUL, $$->loc->name, $3->loc->name, to_string($1->type.w));
                                            quad.emit(Opcode::ADD, $$->loc->name, $$->loc->name, $6->loc->name);
                                            quad.emit(Opcode::MUL, $$->loc->name, $$->loc->name, "8");
                                        }
| postfix-expression '(' argument-expression-list-opt ')'  {
    $$ = $1;
    if(!check_params($1, $3)){
        cout << "Function arguments mismatch";
        exit(1);
    }
    else{
        for(int i=(int)$3->size()-1; i>=0; i--){
            quad.emit(Opcode::PARAM, $3->operator[](i)->loc->name);
        }
        $$->loc = current_st->gentemp($1->loc->nested_table->entries[0]->type);
        $$->type = $$->loc->type;
        $$->truelist = $$->falselist = NULL;
        quad.emit(Opcode::CALL, $$->loc->name, $1->loc->name, to_string((int)$3->size()));
    }
}
| postfix-expression '.' IDENTIFIER { // NOT SUPPORTED
    }
| postfix-expression ARROW IDENTIFIER { // NOT SUPPORTED
    }
| postfix-expression PLUSPLUS {
    $$ = new ExpressionType(*$1);
    $$->loc = current_st->gentemp($1->type);
    if($1->is_matrix){
        quad.emit(Opcode::IND_COPY_R, $$->loc->name, $1->parent_matrix->name, $1->loc->name);
        SymbolTableEntry* t = current_st->gentemp(UnionType(BasicType::DOUBLE));
        quad.emit(Opcode::ADD, t->name, $$->loc->name, "1");
        quad.emit(Opcode::IND_COPY_L, $1->parent_matrix->name, $1->loc->name, t->name);
    }
    else{
        quad.emit(Opcode::ASS, $$->loc->name, $1->loc->name);
        quad.emit(Opcode::ADD, $1->loc->name, $1->loc->name, "1");
    }
    $$->is_matrix = false;
}
| postfix-expression MINUSMINUS {
    $$ = new ExpressionType(*$1);
    $$->loc = current_st->gentemp($1->type);
    if($1->is_matrix){
        quad.emit(Opcode::IND_COPY_R, $$->loc->name, $1->parent_matrix->name, $1->loc->name);
        SymbolTableEntry* t = current_st->gentemp(UnionType(BasicType::DOUBLE));
        quad.emit(Opcode::SUB, t->name, $$->loc->name, "1");
        quad.emit(Opcode::IND_COPY_L, $1->parent_matrix->name, $1->loc->name, t->name);
    }
    else{
        quad.emit(Opcode::ASS, $$->loc->name, $1->loc->name);
        quad.emit(Opcode::SUB, $1->loc->name, $1->loc->name, "1");
    }
    $$->is_matrix = false;
}
| postfix-expression TRANSPOSE {
    if($1->type.type != BasicType::MATRIX){
        cout<<"Error: Transpose can be taken of only Matrices\n";
        exit(1);
    }
    UnionType u(BasicType::MATRIX, $1->type.w, $1->type.h);
    $$ = new ExpressionType(*$1);
    $$->loc = current_st->gentemp(u);
    $$->type = $$->loc->type;
    quad.emit(Opcode::TRANS, $$->loc->name, $1->loc->name);
}
;

argument-expression-list-opt:
  argument-expression-list { $$ = $1; }
| %empty { $$ = new vector<ExpressionType*>(); }
;

argument-expression-list:
  assigment-expression { $$ = new vector<ExpressionType*>(); $$->push_back($1); }
| argument-expression-list ',' assigment-expression { $$ = $1; $$->push_back($3); }
;

unary-expression:
  postfix-expression { $$ = new ExpressionType(*$1); }
| PLUSPLUS unary-expression {
    $$ = new ExpressionType(*$2);
    $$->loc = current_st->gentemp($2->type);
    $$->type = $$->loc->type;

    if($$->is_matrix){
        quad.emit(Opcode::IND_COPY_R, $$->loc->name, $$->parent_matrix->name, $2->loc->name);
        quad.emit(Opcode::ADD, $$->loc->name, $$->loc->name, "1");
        quad.emit(Opcode::IND_COPY_L, $$->parent_matrix->name, $2->loc->name, $$->loc->name);
    }
    else{
        quad.emit(Opcode::ADD, $2->loc->name, $2->loc->name, "1");
        quad.emit(Opcode::ASS, $$->loc->name, $2->loc->name);
    }
    $$->is_matrix = false;
}
| MINUSMINUS unary-expression {
    $$ = new ExpressionType(*$2);
    $$->loc = current_st->gentemp($2->type);
    $$->type = $$->loc->type;

    if($$->is_matrix){
        quad.emit(Opcode::IND_COPY_R, $$->loc->name, $$->parent_matrix->name, $2->loc->name);
        quad.emit(Opcode::SUB, $$->loc->name, $$->loc->name, "1");
        quad.emit(Opcode::IND_COPY_L, $$->parent_matrix->name, $2->loc->name, $$->loc->name);
    }
    else{
        quad.emit(Opcode::SUB, $2->loc->name, $2->loc->name, "1");
        quad.emit(Opcode::ASS, $$->loc->name, $2->loc->name);
    }
    $$->is_matrix = false;
}
| unary-operator cast-expression {
    $$ = new ExpressionType(*$2);
    switch($1){
        case '&':{
            UnionType u(BasicType::PTR);
            u.next = &($2->type);
            $$->loc = current_st->gentemp(u);
            $$->type = $$->loc->type;
            if($2->is_matrix){
                quad.emit(Opcode::ADD, $$->loc->name, $2->parent_matrix->name, $2->loc->name);
                $$->is_matrix = false;
            }
            else
                quad.emit(Opcode::ADDRESS, $$->loc->name, $2->loc->name);
            break;
        }
        case '*':{
            if($2->type.next == NULL){
                cout<<"Error: non-pointer objects cannot be dereferenced!\n";
                exit(1);
            }
            $$->type = *($2->type.next);
            $$->is_ptr = true;
            break;
        }
        case '+':{
            if($2->is_matrix){
                $$->is_matrix = false;
                $$->loc = current_st->gentemp(UnionType(BasicType::DOUBLE));
                $$->type = $$->loc->type;
                quad.emit(Opcode::IND_COPY_R, $$->loc->name, $2->parent_matrix->name, $2->loc->name);
            }
            else if($2->is_ptr){
                $$->is_ptr = false;
                $$->loc = current_st->gentemp($2->type);
                $$->type = $$->loc->type;
                quad.emit(Opcode::DEREF_R, $$->loc->name, $2->loc->name);
            }
            break;
        }
        case '-':{
            if($2->is_matrix){
                $$->is_matrix = false;
                $$->loc = current_st->gentemp(UnionType(BasicType::DOUBLE));
                $$->type = $$->loc->type;
                quad.emit(Opcode::IND_COPY_R, $$->loc->name, $2->parent_matrix->name, $2->loc->name);
                quad.emit(Opcode::U_MINUS, $$->loc->name, $$->loc->name);
            }
            else if($2->is_ptr){
                $$->is_ptr = false;
                $$->loc = current_st->gentemp($2->type);
                $$->type = $$->loc->type;
                quad.emit(Opcode::DEREF_R, $$->loc->name, $2->loc->name);
                quad.emit(Opcode::U_MINUS, $$->loc->name, $$->loc->name);
            }
            else{
                quad.emit(Opcode::U_MINUS, $$->loc->name, $2->loc->name);
            }
            break;
        }
    }
}
;

unary-operator:
  '&' {
    $$ = '&';
}
| '*' {
    $$ = '*';
}
| '+' {
    $$ = '+';
}
| '-' {
    $$ = '-';
}
;

cast-expression:
    unary-expression {
        $$ = new ExpressionType(*$1);
    }
;

multiplicative-expression:
  cast-expression {
      $$ = new ExpressionType(*$1);
      if($1->is_matrix){
          $$->is_matrix = false;
          $$->loc = current_st->gentemp(UnionType(BasicType::DOUBLE));
          $$->type = $$->loc->type;
          quad.emit(Opcode::IND_COPY_R, $$->loc->name, $1->parent_matrix->name, $1->loc->name);
      }
      else if($1->is_ptr){
          $$->is_ptr = false;
          $$->loc = current_st->gentemp($1->type);
          $$->type = $$->loc->type;
          quad.emit(Opcode::DEREF_R, $$->loc->name, $1->loc->name);
      }
  }
| multiplicative-expression '*' cast-expression {
    $$ = new ExpressionType();
    if($3->is_matrix){
        $3->is_matrix = false;
        SymbolTableEntry* t = current_st->gentemp(UnionType(BasicType::DOUBLE));
        quad.emit(Opcode::IND_COPY_R, t->name, $3->parent_matrix->name, $3->loc->name);
        $3->loc = t;
        $3->type = $3->loc->type;
    }
    else if($3->is_ptr){
        $3->is_ptr = false;
        SymbolTableEntry* t = current_st->gentemp($3->type);
        quad.emit(Opcode::DEREF_R, t->name, $3->loc->name);
        $3->loc = t;
        $3->type = $3->loc->type;
    }
    if(!typecheck($1,$3,true)){
        cout<<"Error: implicit type conversion failed\n";
        exit(1);
    }
    if($1->type.type == BasicType::MATRIX){
        UnionType u(BasicType::MATRIX, $1->type.h, $3->type.w);
        $$->loc = current_st->gentemp(u);
        $$->type = $$->loc->type;
        quad.emit(Opcode::MUL, $$->loc->name, $1->loc->name, $3->loc->name);
    }
    else{
        $$->loc = current_st->gentemp($1->type);
        $$->type = $$->loc->type;
        quad.emit(Opcode::MUL, $$->loc->name, $1->loc->name, $3->loc->name);
    }
}
| multiplicative-expression '/' cast-expression {
    $$ = new ExpressionType();
    if($3->is_matrix){
        $3->is_matrix = false;
        SymbolTableEntry* t = current_st->gentemp(UnionType(BasicType::DOUBLE));
        quad.emit(Opcode::IND_COPY_R, t->name, $3->parent_matrix->name, $3->loc->name);
        $3->loc = t;
        $3->type = $3->loc->type;
    }
    else if($3->is_ptr){
        $3->is_ptr = false;
        SymbolTableEntry* t = current_st->gentemp($3->type);
        quad.emit(Opcode::DEREF_R, t->name, $3->loc->name);
        $3->loc = t;
        $3->type = $3->loc->type;
    }
    if(!typecheck($1,$3)){
        cout<<"Error: implicit type conversion failed in /\n";
        exit(1);
    }
    if($1->type.type == BasicType::MATRIX || $3->type.type == BasicType::MATRIX){
        cout<<"Error: Matrix division is prohibited\n";
        exit(1);
    }
    $$->loc = current_st->gentemp($1->type);
    $$->type = $$->loc->type;
    quad.emit(Opcode::DIV, $$->loc->name, $1->loc->name, $3->loc->name);
}
| multiplicative-expression '%' cast-expression {
    $$ = new ExpressionType();
    if($3->is_matrix){
        $3->is_matrix = false;
        SymbolTableEntry* t = current_st->gentemp(UnionType(BasicType::DOUBLE));
        quad.emit(Opcode::IND_COPY_R, t->name, $3->parent_matrix->name, $3->loc->name);
        $3->loc = t;
        $3->type = $3->loc->type;
    }
    else if($3->is_ptr){
        $3->is_ptr = false;
        SymbolTableEntry* t = current_st->gentemp($3->type);
        quad.emit(Opcode::DEREF_R, t->name, $3->loc->name);
        $3->loc = t;
        $3->type = $3->loc->type;
    }
    if((int)$1->type.type > 2 || (int)$3->type.type > 2){
        cout<<"Error: modulus can be taken of integers only\n";
        exit(1);
    }
    if($1->type.type != BasicType::INT)
        conv2int($1);
    if($3->type.type != BasicType::INT)
        conv2int($3);
    $$->loc = current_st->gentemp($1->type);
    $$->type = $$->loc->type;
    quad.emit(Opcode::MOD, $$->loc->name, $1->loc->name, $3->loc->name);
}
;

additive-expression:
  multiplicative-expression { $$ = $1; }
| additive-expression '+' multiplicative-expression {
    $$ = new ExpressionType();
    if(!typecheck($1,$3)){
        cout<<"Error: Implicit type conversion failed in +\n";
        exit(1);
    }
    $$->loc = current_st->gentemp($1->type);
    $$->type = $$->loc->type;
    quad.emit(Opcode::ADD, $$->loc->name, $1->loc->name, $3->loc->name);
}
| additive-expression '-' multiplicative-expression {
    $$ = new ExpressionType();
    if(!typecheck($1,$3)){
        cout<<"Error: Implicit type conversion failed in -\n";
        exit(1);
    }
    $$->loc = current_st->gentemp($1->type);
    $$->type = $$->loc->type;
    quad.emit(Opcode::SUB, $$->loc->name, $1->loc->name, $3->loc->name);
}
;

shift-expression:
  additive-expression  { $$ = $1; }
| shift-expression LEFT_SHIFT additive-expression  {
    $$ = new ExpressionType();
    if((int)$1->type.type >= 3 || (int)$3->type.type >= 3){
        cout<<"Error: left shift is allowed only for integers\n";
        exit(1);
    }
    if($1->type.type != BasicType::INT)
        conv2int($1);
    if($3->type.type != BasicType::INT)
        conv2int($3);
    $$->loc = current_st->gentemp($1->type);
    $$->type = $$->loc->type;
    quad.emit(Opcode::L_SHIFT, $$->loc->name, $1->loc->name, $3->loc->name);
}
| shift-expression RIGHT_SHIFT additive-expression  {
    $$ = new ExpressionType();
    if((int)$1->type.type >= 3 || (int)$3->type.type >= 3){
        cout<<"Error: left shift is allowed only for integers\n";
        exit(1);
    }
    if($1->type.type != BasicType::INT)
        conv2int($1);
    if($3->type.type != BasicType::INT)
        conv2int($3);
    $$->loc = current_st->gentemp($1->type);
    $$->type = $$->loc->type;
    quad.emit(Opcode::R_SHIFT, $$->loc->name, $1->loc->name, $3->loc->name);
}
;

relational-expression:
  shift-expression    { $$ = $1; }
| relational-expression '<' shift-expression    {
    if((int)$1->type.type > 3 || (int)$3->type.type > 3){
        cout<<"Error: invalid operands for <\n";
        exit(1);
    }
    typecheck($1,$3);
    $$->truelist = makelist(quad.next_instr);
    quad.emit(Opcode::IF_LT, "", $1->loc->name, $3->loc->name);
    $$->falselist = makelist(quad.next_instr);
    quad.emit(Opcode::GOTO, "");
}
| relational-expression '>' shift-expression    {
    if((int)$1->type.type > 3 || (int)$3->type.type > 3){
        cout<<"Error: invalid operands for >\n";
        exit(1);
    }
    typecheck($1,$3);
    $$->truelist = makelist(quad.next_instr);
    quad.emit(Opcode::IF_GT, "", $1->loc->name, $3->loc->name);
    $$->falselist = makelist(quad.next_instr);
    quad.emit(Opcode::GOTO, "");
}
| relational-expression LESS_EQUAL shift-expression    {
    if((int)$1->type.type > 3 || (int)$3->type.type > 3){
        cout<<"Error: invalid operands for <=\n";
        exit(1);
    }
    typecheck($1,$3);
    $$ = new ExpressionType();
    $$->type = UnionType(BasicType::BOOL);
    $$->truelist = makelist(quad.next_instr);
    quad.emit(Opcode::IF_LTE, "", $1->loc->name, $3->loc->name);
    $$->falselist = makelist(quad.next_instr);
    quad.emit(Opcode::GOTO, "");
}
| relational-expression GREATER_EQUAL shift-expression    {
    if((int)$1->type.type > 3 || (int)$3->type.type > 3){
        cout<<"Error: invalid operands for >=\n";
        exit(1);
    }
    typecheck($1,$3);
    $$ = new ExpressionType();
    $$->type = UnionType(BasicType::BOOL);
    $$->truelist = makelist(quad.next_instr);
    quad.emit(Opcode::IF_GTE, "", $1->loc->name, $3->loc->name);
    $$->falselist = makelist(quad.next_instr);
    quad.emit(Opcode::GOTO, "");
}
;

equality-expression:
  relational-expression      { $$ = $1; }
| equality-expression IS_EQUAL relational-expression      {
    typecheck($1,$3);
    $$ = new ExpressionType();
    $$->type = UnionType(BasicType::BOOL);
    $$->truelist = makelist(quad.next_instr);
    quad.emit(Opcode::IF_EQ, "", $1->loc->name, $3->loc->name);
    $$->falselist = makelist(quad.next_instr);
    quad.emit(Opcode::GOTO, "");
}
| equality-expression IS_NOT_EQUAL relational-expression      {
    typecheck($1,$3);
    $$ = new ExpressionType();
    $$->type = UnionType(BasicType::BOOL);
    $$->truelist = makelist(quad.next_instr);
    quad.emit(Opcode::IF_NEQ, "", $1->loc->name, $3->loc->name);
    $$->falselist = makelist(quad.next_instr);
    quad.emit(Opcode::GOTO, "");
}
;

AND-expression:
  equality-expression    { $$ = $1; }
| AND-expression '&' equality-expression    {
    $$ = new ExpressionType();
    if((int)$1->type.type >= 3 || (int)$3->type.type >= 3){
        cout<<"Error: invalid operands for &\n";
        exit(1);
    }
    if($1->type.type != BasicType::INT)
        conv2int($1);
    if($3->type.type != BasicType::INT)
        conv2int($3);
    $$->loc = current_st->gentemp(UnionType(BasicType::INT));
    $$->type = $$->loc->type;
    quad.emit(Opcode::BIT_AND, $$->loc->name, $1->loc->name, $3->loc->name);
}
;

exclusive-OR-expression:
  AND-expression    { $$ = $1; }
| exclusive-OR-expression '^' AND-expression  {
    $$ = new ExpressionType();
    if((int)$1->type.type >= 3 || (int)$3->type.type >= 3){
        cout<<"Error: invalid operands for ^\n";
        exit(1);
    }
    if($1->type.type != BasicType::INT)
        conv2int($1);
    if($3->type.type != BasicType::INT)
        conv2int($3);
    $$->loc = current_st->gentemp(UnionType(BasicType::INT));
    $$->type = $$->loc->type;
    quad.emit(Opcode::BIT_EXC_OR, $$->loc->name, $1->loc->name, $3->loc->name);
}
;

inclusive-OR-expression:
  exclusive-OR-expression    { $$ = $1; }
| inclusive-OR-expression '|' exclusive-OR-expression    {
    $$ = new ExpressionType();
    if((int)$1->type.type >= 3 || (int)$3->type.type >= 3){
        cout<<"Error: invalid operands for |\n";
        exit(1);
    }
    if($1->type.type != BasicType::INT)
        conv2int($1);
    if($3->type.type != BasicType::INT)
        conv2int($3);
    $$->loc = current_st->gentemp(UnionType(BasicType::INT));
    $$->type = $$->loc->type;
    quad.emit(Opcode::BIT_INC_OR, $$->loc->name, $1->loc->name, $3->loc->name);
}
;

N:  /* empty */ {
    $$ = quad.next_instr;
}
;

logical-AND-expression:
  inclusive-OR-expression    { $$ = $1; }
| logical-AND-expression LOGICAL_AND N inclusive-OR-expression    {
    backpatch($1->truelist, $3);
    $$ = new ExpressionType();
    $$->type = UnionType(BasicType::BOOL);
    $$->truelist = $4->truelist;
    $$->falselist = merge($1->falselist, $4->falselist);
}
;

logical-OR-expression:
  logical-AND-expression    { $$ = $1; }
| logical-OR-expression LOGICAL_OR N logical-AND-expression    {
    backpatch($1->falselist, $3);
    $$ = new ExpressionType();
    $$->type = UnionType(BasicType::BOOL);
    $$->falselist = $4->falselist;
    $$->truelist = merge($1->truelist, $4->truelist);
}
;

M: /*empty*/ {
    $$ = makelist(quad.next_instr);
    quad.emit(Opcode::GOTO, "");
}

conditional-expression:
  logical-OR-expression    { $$ = $1; }
| logical-OR-expression M '?' N expression M ':' N conditional-expression    {
    if(!typecheck($5,$9)){
        cout<<"Error: expressions mut have same type in conditional operator\n";
        exit(1);
    }
    $$ = new ExpressionType();
    $$->loc = current_st->gentemp($5->type);
    if($1->type.type == BasicType::BOOL){
        quad.emit(Opcode::ASS, $$->loc->name, $9->loc->name);
        List * l = makelist(quad.next_instr);
        quad.emit(Opcode::GOTO, "");
        backpatch($6, quad.next_instr);
        quad.emit(Opcode::ASS, $$->loc->name, $5->loc->name);
        l = merge(l, makelist(quad.next_instr));
        quad.emit(Opcode::GOTO, "");
        backpatch($1->truelist, $4);
        backpatch($1->falselist, $8);
        backpatch($2, quad.next_instr);
        backpatch(l, quad.next_instr);
    }
}
;

assigment-expression:
  conditional-expression    { $$ = $1; }
| unary-expression assignment-operator assigment-expression    {
    if(!typecheck($1,$3,false,true)){
        cout<<"Error: Assignment failed due to incompatible types";
    }
    if($1->is_matrix){
        quad.emit(Opcode::IND_COPY_L, $1->parent_matrix->name, $1->loc->name, $3->loc->name);
    }
    else if($1->is_ptr)
        quad.emit(Opcode::DEREF_L, $1->loc->name, $3->loc->name);
    else
        quad.emit(Opcode::ASS, $1->loc->name, $3->loc->name);
    $$ = new ExpressionType(*$3);
    $$->is_matrix = $$->is_ptr = false;
}
;

assignment-operator:
  '='    { }
;

expression:
  assigment-expression      { $$ = $1; }
| expression ',' assigment-expression   { /* NOT SUPPORTED */ }
;

constant-expression:
  conditional-expression    { $$ = $1; }
;

declaration:
  declaration-specifiers init-declarator-list-opt ';'    { printf("declaration --> declaration-specifiers init-declarator-list-opt;\n"); }
;

init-declarator-list-opt:
  init-declarator-list  { $$ = $1; }
| %empty  { $$ = new ExpressionType(); }
;

declaration-specifiers:
  type-specifier declaration-specifiers-opt    {
      $$->type = $1->type;
      $$->width = $1->width;
      quad.width = $1->width;
      quad.type = $1->type;
  }
;

declaration-specifiers-opt:
  declaration-specifiers  { $$ = $1; }
| %empty   { $$ = new DeclarationType(); }
;

init-declarator-list:
  init-declarator    {

  }
| init-declarator-list ',' init-declarator    { printf("init-declarator-list --> init-declarator-list, init-declarator\n"); }
;

init-declarator:
  declarator    { printf("init-declarator --> declarator\n"); }
| declarator '=' initializer    {
    if(!typecheck($1,$3,false,true)){
        printf("Error: cannot initialise\n");
        exit(1);
    }
    if($3->loc->was_initialised)
        current_st->update($1->loc, $3->loc->init);
    quad.emit(Opcode::ASS, $1->loc->name, $3->loc->name);
    $$ = $1;
}
;

type-specifier:
  VOID    {
      $$ = new DeclarationType();
      $$->type = new UnionType(BasicType::VOID);
      $$->width = SZ_VOID;
  }
| CHAR    { printf("type-specifier --> char\n"); }
| SHORT    { // NOT SUPPORTED
}
| INT    {
    $$ = new DeclarationType();
    $$->type = new UnionType(BasicType::INT);
    $$->width = SZ_INT;
}
| LONG    { // NOT SUPPORTED
}
| FLOAT    { // NOT SUPPORTED
}
| DOUBLE    {
    $$ = new DeclarationType();
    $$->type = new UnionType(BasicType::DOUBLE);
    $$->width = SZ_DOUBLE;
}
| MATRIX    {
    $$ = new DeclarationType();
    $$->type = new UnionType(BasicType::MATRIX);
    $$->width = SZ_MATRIX;
 }
| SIGNED    { // NOT SUPPORTED
 }
| UNSIGNED    { // NOT SUPPORTED
}
| BOOL    { // NOT SUPPORTED
}
;

declarator:
  pointer-opt direct-declarator    { $$ = $2; }
;

pointer-opt:
  pointer  {}
| %empty  { printf("pointer-opt --> %%empty\n"); }
;

direct-declarator:
  IDENTIFIER    {
      $$ = new ExpressionType();
      $$->loc = current_st->lookup(*$1);
      current_st->update($$->loc, *quad.type, quad.width);
      $$->type = $$->loc->type;
  }
| '(' declarator ')'    { $$ = $2; }
| IDENTIFIER '[' INT_CONSTANT ']' '[' INT_CONSTANT ']'   {
    $$ = new ExpressionType();
    $$->loc = current_st->lookup(*$1);
    if(quad.type->type != BasicType::MATRIX){
        cout<<"Type of "<<(*$1)<<" must be Matrix\n";
        exit(1);
    }
    UnionType u(BasicType::MATRIX, $3, $6);
    current_st->update($$->loc, u, u.size);
    $$->type = $$->loc->type;
}
| direct-declarator '(' parameter-type-list ')'    { // NOT SUPPORTED
}
| direct-declarator '(' identifier-list-opt ')'    { // NOT SUPPORTED
}
;

assigment-expression-opt:
  assigment-expression  { $$ = $1; }
| %empty  { $$ = new ExpressionType(); }
;

identifier-list-opt:
  identifier-list  { $$ = $1; }
| %empty  { $$ = new ExpressionType(); }
;

pointer:
  '*' pointer-opt    {
      // Must be changed for functions
      UnionType* t = new UnionType();
      t->type = BasicType::PTR;
      t->size = SZ_PTR;
      t->next = quad.type;
      quad.type = t;
  }
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
  IDENTIFIER    { }
| identifier-list ',' IDENTIFIER    { printf("identifier-list --> identifier-list, Identifier\n"); }
;

initializer:
  assigment-expression    { $$ = $1; }
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
