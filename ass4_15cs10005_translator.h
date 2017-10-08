#ifndef __TRANSLATOR_H
#define __TRANSLATOR_H

#include <iostream>

using namespace std;

#define SZ_VOID 0
#define SZ_FUNC 0
#define SZ_BOOL 1
#define SZ_CHAR 1
#define SZ_PTR 4
#define SZ_INT 4
#define SZ_DOUBLE 8

set<string> string_set;

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

class IdentifierType{
    SymbolTableEntry* loc;
    string string_val;
};

class ExpressionType{
    List *truelist, *falselist;
    SymbolTableEntry* loc;
    UnionType type;
    bool is_ptr, is_string;
    set<string>::iterator string_index;
};

class UnionType{
    BasicType type;
    int size;
    UnionType* next;

    UnionType();
    UnionType(BasicType _type);

    void print();

};

bool are_equal(UnionType t1, UnionType t2);

union UnionInitialVal{
    int int_val;
    double double_val;
    char char_val;
};

class SymbolTableEntry{
    string name;
    UnionType type;
    UnionInitialVal init;
    bool was_initialised;
    int size;
    int offset;
    SymbolTable* nested_table;

    SymbolTableEntry(string);

    void print();
};

class SymbolTable{
    int offset;
    string name;
    vector <SymbolTableEntry*> entries;
    SymbolTable* parent;

    SymbolTable();
    SymbolTable(string);

    void print();
    bool is_present(string name);
    void update(SymbolTableEntry*, UnionType, int);
    void update(SymbolTableEntry*, UnionInitialVal);

    SymbolTableEntry* lookup(string);
    SymbolTableEntry* gentemp(UnionType);
};

#endif
