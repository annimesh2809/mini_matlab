#include "ass4_15cs10005_translator.h"
#include "ass4_15cs10005.tab.h"
#include <assert.h>

SymbolTable *global_st = new SymbolTable();
SymbolTable *current_st = new SymbolTable();

node::node() { next = NULL; }
node::node(int i) { ind = i; next = NULL; }

QuadList quad;

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

// for matrix
UnionType::UnionType(BasicType b, int h, int w){
    this->type = b;
    this->h = h;
    this->w = w;
    size = h*w*SZ_DOUBLE + 2*SZ_INT;
    next = NULL;
}

void UnionType::print(){
    switch (this->type) {
        case BasicType::CHAR: cout<<"char"; return;
        case BasicType::INT: cout<<"int"; return;
        case BasicType::DOUBLE: cout<<"double"; return;
        case BasicType::MATRIX: cout<<"Matrix("<<this->h<<","<<this->w<<")"; return;
        case BasicType::VOID: cout<<"void"; return;
        case BasicType::PTR: cout<<"pointer"; return;
        case BasicType::FUNC: cout<<"function"; return;
    }
}

ExpressionType::ExpressionType(){
    truelist = falselist = NULL;
    loc = NULL;
    type = UnionType();
    is_ptr = is_matrix = false;
    parent_matrix = NULL;
}

ExpressionType::ExpressionType(ExpressionType& e){
    truelist = e.truelist;
    falselist = e.falselist;
    loc = e.loc;
    type = e.type;
    is_ptr = e.is_ptr;
    is_matrix = e.is_matrix;
    parent_matrix = e.parent_matrix;
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

void print_init_val(UnionInitialVal& init, BasicType b){
    switch(b){
        case BasicType::INT: cout<<init.int_val; break;
        case BasicType::DOUBLE: cout<<init.double_val; break;
        case BasicType::CHAR: cout<<init.char_val; break;
        case BasicType::MATRIX: cout<<'{'; for(int i=0;i<init.Matrix_val->size()-1;i++) cout<<(init.Matrix_val->operator[](i))<<','; cout<<init.Matrix_val->operator[](init.Matrix_val->size()-1)<<'}'; break;
    }
}

void SymbolTableEntry::print(){
    printf("%s\t\t", this->name.c_str());
    this->type.print();
    printf("\t\t");
    if(this->was_initialised)
        print_init_val(this->init, this->type.type);
    else
        printf("-\t");
    printf("\t\t%d\t\t%d\t\t%s", this->size, this->offset, ((this->nested_table==NULL)?("NULL"):(this->nested_table->name.c_str())));
}

SymbolTable::SymbolTable(SymbolTable* p){
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
    cout<<"Name\t\tType\t\tInitial value\t\tSize\t\tOffset\t\tNested table\n";
    for(int i=0;i<entries.size();i++){
        entries[i]->print();
        cout<<endl;
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
    int cursz;
    if(u.type == BasicType::MATRIX)
        cursz = u.h*u.w*SZ_DOUBLE + 2*SZ_INT;
    else
        cursz = get_size(u.type);
    s->size = cursz;
    s->offset = offset;
    offset += cursz;
    entries.push_back(s);
    return s;
}

QuadEntry::QuadEntry(Opcode o, string _result, string s1, string s2){
    op = o;
    result = _result;
    arg1 = s1;
    arg2 = s2;
}

void QuadEntry::backpatch(int addr){
    this->result = to_string(addr);
}

void QuadEntry::print(ostream& f){
    switch(op){
        case Opcode::ADD:
            f<<result<<"="<<arg1<<"+"<<arg2;
            break;
        case Opcode::SUB:
            f<<result<<"="<<arg1<<"-"<<arg2;
            break;
        case Opcode::MUL:
            f<<result<<"="<<arg1<<"*"<<arg2;
            break;
        case Opcode::DIV:
            f<<result<<"="<<arg1<<"/"<<arg2;
            break;
        case Opcode::MOD:
            f<<result<<"="<<arg1<<"%"<<arg2;
            break;
        case Opcode::ASS:
            f<<result<<"="<<arg1;
            break;
        case Opcode::CALL:
            f<<result<<"=call "<<arg1<<","<<arg2;
            break;
        case Opcode::PARAM:
            f<<"param "<<result;
            break;
        case Opcode::TRANS:
            f<<result<<"="<<arg1<<".'";
            break;
        case Opcode::IND_COPY_L:
            f<<result<<"["<<arg1<<"]="<<arg2;
            break;
        case Opcode::IND_COPY_R:
            f<<result<<"="<<arg1<<"["<<arg2<<"]";
            break;
        case Opcode::ADDRESS:
            f<<result<<"=&"<<arg1;
            break;
        case Opcode::DEREF_L:
            f<<"*"<<result<<"="<<arg1;
            break;
        case Opcode::DEREF_R:
            f<<result<<"=*"<<arg1;
            break;
        case Opcode::U_MINUS:
            f<<result<<"=-"<<arg1;
            break;
        case Opcode::CONV_BOOL:
            f<<result<<"=(bool)"<<arg1;
            break;
        case Opcode::CONV_CHAR:
            f<<result<<"=(char)"<<arg1;
            break;
        case Opcode::CONV_INT:
            f<<result<<"=(int)"<<arg1;
            break;
        case Opcode::CONV_DOUBLE:
            f<<result<<"=(double)"<<arg1;
            break;
        case Opcode::L_SHIFT:
            f<<result<<"="<<arg1<<"<<"<<arg2;
            break;
        case Opcode::R_SHIFT:
            f<<result<<"="<<arg1<<">>"<<arg2;
            break;
        case Opcode::IF_LT:
            f<<"if "<<arg1<<"<"<<arg2<<" goto "<<result;
            break;
        case Opcode::IF_GT:
            f<<"if "<<arg1<<">"<<arg2<<" goto "<<result;
            break;
        case Opcode::IF_LTE:
            f<<"if "<<arg1<<"<="<<arg2<<" goto "<<result;
            break;
        case Opcode::IF_GTE:
            f<<"if "<<arg1<<">="<<arg2<<" goto "<<result;
            break;
        case Opcode::IF_EQ:
            f<<"if "<<arg1<<"=="<<arg2<<" goto "<<result;
            break;
        case Opcode::IF_NEQ:
            f<<"if "<<arg1<<"!="<<arg2<<" goto "<<result;
            break;
        case Opcode::GOTO:
            f<<"goto "<<result;
            break;
        case Opcode::BIT_AND:
            f<<result<<"="<<arg1<<" & "<<arg2;
            break;
        case Opcode::BIT_INC_OR:
            f<<result<<"="<<arg1<<" | "<<arg2;
            break;
        case Opcode::BIT_EXC_OR:
            f<<result<<"="<<arg1<<" ^ "<<arg2;
            break;
    }
}

void QuadList::emit(Opcode o, string result, string s1, string s2){
    this->quads.push_back(QuadEntry(o, result, s1, s2));
    this->next_instr++;
}

void QuadList::emit(Opcode o, string result, string s1){
    emit(o, result, s1, "");
}

void QuadList::emit(string result, string s1){
    emit(Opcode::ASS, result, s1);
}

void QuadList::emit(Opcode o, string result){
    emit(o, result, "");
}

void QuadList::print(ostream& f = cout){
    for(int i=0;i<quads.size();i++){
        cout<<i<<"\t";
        quads[i].print(f);
        cout<<"\n";
    }
}

bool check_params(ExpressionType* fn, vector<ExpressionType*>* args){
    if(fn->loc->nested_table == NULL){
        printf("%s cannot be called as it is not a function\n", fn->loc->name);
        exit(1);
    }
    vector<SymbolTableEntry*> &fargs = fn->loc->nested_table->entries;
    vector<SymbolTableEntry*>::iterator it1 = fargs.begin();
    vector<ExpressionType*>::iterator it2 = args->begin();
    while(it1!=fargs.end() && it2!=args->end() && (*it1)->is_param){
        if((*it2)->loc->type.type != (*it1)->type.type)
            return false;
        it1++;
        it2++;
    }
    if((*it1)->is_param || it2 != args->end())
        return false;
    return true;
}

BasicType max(BasicType b1, BasicType b2){
    return (BasicType)max((int)b1, (int)b2);
}

void conv2bool(ExpressionType* e){

}

void conv2char(ExpressionType* e){
    string t = e->loc->name;
    e->loc = current_st->gentemp(UnionType(BasicType::CHAR));
    e->type = e->loc->type;
    quad.emit(Opcode::CONV_CHAR, e->loc->name, t);
}

void conv2int(ExpressionType* e){
    string t = e->loc->name;
    e->loc = current_st->gentemp(UnionType(BasicType::INT));
    e->type = e->loc->type;
    quad.emit(Opcode::CONV_INT, e->loc->name, t);
}

void conv2double(ExpressionType* e){
    string t = e->loc->name;
    e->loc = current_st->gentemp(UnionType(BasicType::DOUBLE));
    e->type = e->loc->type;
    quad.emit(Opcode::CONV_DOUBLE, e->loc->name, t);
}

void conv(BasicType b, ExpressionType* t){
    if(b == t->type.type)
        return;
    switch(b){
        case BasicType::BOOL:{
            conv2bool(t); break;
        }
        case BasicType::CHAR:{
            conv2char(t); break;
        }
        case BasicType::INT:{
            conv2int(t); break;
        }
        case BasicType::DOUBLE:{
            conv2double(t); break;
        }
    }
}

bool typecheck(ExpressionType* t1, ExpressionType* t2, bool mat_mul, bool rtl){
    if(t1->type.type == t2->type.type){
        if(t1->type.type == BasicType::MATRIX){
            if(mat_mul){
                if(t1->type.w == t2->type.h){
                    return true;
                }
                cout<<t1->type.w<<" "<<t2->type.h<<"Error: Multiplication of incompatible matrices\n";
                return false;
            }
            if(t1->type.h == t2->type.h && t1->type.w == t2->type.w){
                return true;
            }
            return false;
        }
        return true;
    }
    if((int)t1->type.type > 4 || (int)t2->type.type > 4) return false;
    if(rtl){
        conv(t1->type.type,t2);
        return true;
    }
    BasicType t = max(t1->type.type, t2->type.type);
    conv(t,t1);
    conv(t,t2);
    return true;
}

void backpatch(List* &p, int addr){
    cout<<"******************\n";
    p->print();
    cout<<"\n"<<addr<<"******************\n";
    if(p != NULL && p->head != NULL){
        node *t = p->head;
        while(t != NULL){
            quad.quads[t->ind].backpatch(addr);
            t = t->next;
        }
        p->clear();
        p = NULL;
    }
}

List* makelist(){
    return new List();
}

List* makelist(int ind){
    return new List(ind);
}

List* merge(List* l1, List* l2){
    if(l1 == NULL || l1->head == NULL) return l2;
    if(l2 == NULL || l2->head == NULL) return l1;
    l1->tail->next = l2->head;
    l1->tail = l2->tail;
    return l1;
}

int main(int argc, char const *argv[]) {
    quad.next_instr = 0;
    SymbolTableEntry* a = current_st->lookup("a");
    UnionType umat;
    umat.type = BasicType::MATRIX;
    umat.h = 2;
    umat.w = 1;
    umat.next = NULL;
    current_st->update(a, umat, 2*1*8 + 2*4);
    UnionInitialVal u;
    u.Matrix_val = new vector<double>({1.0, 2.0, 2.0, 1.0});
    current_st->update(a, u);
    SymbolTableEntry* b = current_st->lookup("b");
    current_st->update(b, UnionType(BasicType::INT), 4);
    yyparse();
    cout<<"\n******* SYMBOL TABLE ********\n";
    current_st->print();
    cout<<"\n******** QUAD TABLE *********\n";
    quad.print(cout);
    return 0;
}
