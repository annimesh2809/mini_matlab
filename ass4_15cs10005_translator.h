#ifndef __TRANSLATOR_H
#define __TRANSLATOR_H

#include <iostream>
#include <vector>

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
    DAT,
    CALL,
    PARAM,
    TRANS
};

enum class BasicType{
    CHAR = 0,
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
    int ind;
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
    UnionType* next;

    UnionType();
    UnionType(BasicType);

    void print();

};

bool are_equal(UnionType t1, UnionType t2);

struct ExpressionType{
    List *truelist, *falselist;
    SymbolTableEntry* loc;
    UnionType type;
    bool is_ptr, is_string;
};

union UnionInitialVal{
    int int_val;
    double double_val;
    char char_val;
    vector<vector<double> >* Matrix_val;
};

struct SymbolTable;

struct SymbolTableEntry{
    string name;
    UnionType type;
    UnionInitialVal init;
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

    SymbolTable(SymbolTable*);
    SymbolTable(string, SymbolTable*);

    void print();
    bool is_present(string name);
    void update(SymbolTableEntry*, UnionType, int);
    void update(SymbolTableEntry*, UnionInitialVal);

    SymbolTableEntry* lookup(string);
    SymbolTableEntry* gentemp(UnionType);
};

extern SymbolTable *global_st, *current_st;

#endif
