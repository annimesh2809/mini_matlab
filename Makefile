all: translator

translator: lex.yy.c ass4_15cs10005.tab.h ass4_15cs10005.tab.c ass4_15cs10005_translator.cxx ass4_15cs10005_translator.h
	g++ lex.yy.c ass4_15cs10005.tab.c ass4_15cs10005_translator.cxx -o translator

lex.yy.c: ass4_15cs10005.l
	flex ass4_15cs10005.l

ass4_15cs10005.tab.h: ass4_15cs10005.y
	bison -d ass4_15cs10005.y

ass4_15cs10005.tab.c: ass4_15cs10005.y
	bison -d ass4_15cs10005.y

clean:
	- rm lex.yy.c ass4_15cs10005.tab.c ass4_15cs10005.tab.h translator
