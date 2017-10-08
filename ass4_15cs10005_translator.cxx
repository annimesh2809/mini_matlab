#include "ass4_15cs10005_translator.h"
#include "ass4_15cs10005.tab.h"

SymbolTable *global_st = new SymbolTable();
SymbolTable *current_st = new SymbolTable();

node::node() { next = NULL; }
node::node(int i) { ind = i; next = NULL; }

List::List(int _ind){
    head = new node(_ind);
    tail = head;
}

List::List(){
    head = tail = NULL;
}

void List::print(){
    node *ptr = head;
    while(ptr != NULL){
        cout<<ptr->ind;
        ptr = ptr->next;
    }
}

void List::clear(){
    node * ptr = head, * oldPtr;
    while(ptr != NULL) {
        oldPtr = ptr;
        ptr = ptr->next;
        delete oldPtr;
    }
    head = NULL;
    tail = NULL;
}

int get_size(BasicType b){
    switch(b){
        case BasicType::CHAR: return SZ_CHAR;
        case BasicType::INT: return SZ_INT;
        case BasicType::DOUBLE: return SZ_DOUBLE;
        case BasicType::MATRIX: return SZ_MATRIX;
        case BasicType::VOID: return SZ_VOID;
        case BasicType::PTR: return SZ_PTR;
        case BasicType::FUNC: return SZ_FUNC;
    }
}

UnionType::UnionType(){

}

UnionType::UnionType(BasicType b){
    this->type = b;
    size = get_size(b);
    next = NULL;
}

void UnionType::print(){
    switch (this->type) {
        case BasicType::CHAR: cout<<"char"; return;
        case BasicType::INT: cout<<"int"; return;
        case BasicType::DOUBLE: cout<<"double"; return;
        case BasicType::MATRIX: cout<<"Matrix"; return;
        case BasicType::VOID: cout<<"void"; return;
        case BasicType::PTR: cout<<"pointer"; return;
        case BasicType::FUNC: cout<<"function"; return;
    }
}

SymbolTableEntry::SymbolTableEntry(){
    SymbolTableEntry("");
}

SymbolTableEntry::SymbolTableEntry(string n){
    name = n;
    nested_table = NULL;
    offset = size = 0;
    was_initialised = false;
}

void SymbolTableEntry::print(){
    printf("%s\t", this->name.c_str());
    this->type.print();
    //print initial val
    printf("\t%d\t%d\t%s", this->size, this->offset, ((this->nested_table==NULL)?("NULL"):(this->nested_table->name.c_str())));
}

SymbolTable::SymbolTable(SymbolTable* p = NULL){
    name = "";
    parent = p;
    offset = 0;
    temp_count = 0;
}

SymbolTable::SymbolTable(string s, SymbolTable* p = NULL){
    name = s;
    parent = p;
    offset = 0;
    temp_count = 0;
}

void SymbolTable::print(){
    cout<<this->name<<"\n";
    for(int i=0;i<entries.size();i++){
        entries[i]->print();
        cout<<"\n";
    }
}

SymbolTableEntry* SymbolTable::lookup(string s){
    for(int i=0;i<entries.size();i++)
        if(entries[i]->name == s)
            return entries[i];
    SymbolTableEntry* t = new SymbolTableEntry(s);
    entries.push_back(t);
    return t;
}

bool SymbolTable::is_present(string s){
    for(int i=0;i<entries.size();i++)
        if(entries[i]->name == s)
            return true;
    return false;
}

void SymbolTable::update(SymbolTableEntry* s, UnionInitialVal u){
    s->init = u;
    s->was_initialised = true;
}

void SymbolTable::update(SymbolTableEntry* s, UnionType u, int sz){
    s->type = u;
    s->size = sz;
    s->offset = offset;
    offset += s->size;
}

SymbolTableEntry* SymbolTable::gentemp(UnionType u){
    SymbolTableEntry* s = new SymbolTableEntry("t" + to_string(temp_count++));
    s->type = u;
    int cursz = get_size(u.type);
    s->size = cursz;
    s->offset = offset;
    offset += cursz;
    entries.push_back(s);
    return s;
}

int main(int argc, char const *argv[]) {
    yyparse();
    SymbolTable gst("Global symbol table");
    gst.lookup("aa");
    SymbolTableEntry* t = gst.gentemp(UnionType(BasicType::DOUBLE));
    gst.gentemp(UnionType(BasicType::INT));
    gst.lookup("aa");
    gst.print();
    UnionInitialVal u;
    cout<<t->init.double_val<<"\n";
    u.double_val = 1.2;
    gst.update(t,u);
    gst.print();
    cout<<t->init.double_val<<"\n";
    return 0;
}
