#ifndef __TRANSLATOR_H
#define __TRANSLATOR_H

#include <fstream>
#include <vector>
#include <iostream>

using namespace std;

#define SZ_VOID 0
#define SZ_FUNC 0
#define SZ_MATRIX 0
#define SZ_CHAR 1
#define SZ_PTR 4
#define SZ_INT 4
#define SZ_DOUBLE 8

struct SymbolTableEntry;

enum class Opcode{
    ADD = 1,
    SUB,
    MUL,
    DIV,
    MOD,
    ASS,
    CALL,
    PARAM,
    TRANS,
    IND_COPY_L,
    IND_COPY_R,
    ADDRESS,
    DEREF_L,
    DEREF_R,
    U_MINUS,
    CONV_BOOL,
    CONV_CHAR,
    CONV_INT,
    CONV_DOUBLE,
    L_SHIFT,
    R_SHIFT,
    IF_LT,
    IF_GT,
    IF_LTE,
    IF_GTE,
    IF_EQ,
    IF_NEQ,
    GOTO,
    BIT_AND,
    BIT_INC_OR,
    BIT_EXC_OR,
    BIT_NOT
};

enum class BasicType{
    BOOL = 0,
    CHAR,
    INT,
    DOUBLE,
    MATRIX,
    VOID,
    PTR,
    FUNC
};

struct IdentifierType{
    SymbolTableEntry* loc;
    string string_val;
};

struct node{
    int ind;
    node* next;
    node(int _ind);
    node();
};

struct List{
    node* head;
    node* tail;

    List();
    List(int);

    void clear();
    void print();
};

struct UnionType{
    BasicType type;
    int size;
    int h, w;
    UnionType* next;

    UnionType();
    UnionType(BasicType);
    UnionType(BasicType, int, int);

    void print();
};

bool are_equal(UnionType t1, UnionType t2);

struct QuadEntry{
    Opcode op;
    string result, arg1, arg2;

    QuadEntry(Opcode op, string result, string s1, string s2 = "");

    void backpatch(int);
    void print(ostream& f);
};

struct QuadList{
    int width;
    UnionType* type;
    SymbolTableEntry* mat;

    int next_instr;
    vector<QuadEntry> quads;

    void emit(Opcode o, string result, string arg1, string arg2);
    void emit(Opcode o, string result, string arg1);
    void emit(string result, string arg1);
    void emit(Opcode o, string result);
    void print();
    void print(ostream& f);
};

struct ExpressionType{
    List *truelist, *falselist;
    SymbolTableEntry* loc;
    UnionType type;
    bool is_ptr, is_matrix;
    SymbolTableEntry* parent_matrix;

    ExpressionType();
    ExpressionType(ExpressionType& e);
};

union UnionInitialVal{
    int int_val;
    double double_val;
    char char_val;
    vector<double>* Matrix_val;
};

struct SymbolTable;

struct SymbolTableEntry{
    string name;
    UnionType type;
    UnionInitialVal init;
    bool is_param;
    bool was_initialised;
    int size;
    int offset;
    SymbolTable* nested_table;

    SymbolTableEntry();
    SymbolTableEntry(string);

    void print();
};

struct SymbolTable{
    string name;
    vector <SymbolTableEntry*> entries;
    SymbolTable* parent;
    int offset;
    int temp_count;

    SymbolTable(SymbolTable* p = NULL);
    SymbolTable(string, SymbolTable*);

    void print();
    bool is_present(string name);
    void update(SymbolTableEntry*, UnionType, int);
    void update(SymbolTableEntry*, UnionInitialVal);

    SymbolTableEntry* lookup(string);
    SymbolTableEntry* gentemp(UnionType);
};

struct DeclarationType{
    int width;
    UnionType* type;
};

extern SymbolTable *global_st, *current_st;
extern QuadList quad;

List* makelist();
List* makelist(int);
List* merge(List*, List*);
void conv2int(ExpressionType*);
void conv2double(ExpressionType*);
bool check_params(ExpressionType* fn, vector<ExpressionType*>* args);
bool typecheck(ExpressionType*, ExpressionType*, bool b1 = false, bool b2 = false);
void backpatch(List*&, int);

#endif
