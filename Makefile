all: lexer parser

lexer: lex.yy.c ass3_15cs10005.tab.h ass3_15cs10005_lexer.c
	gcc lex.yy.c ass3_15cs10005_lexer.c -o lexer -lfl

lex.yy.c: ass3_15cs10005.l
	flex ass3_15cs10005.l

ass3_15cs10005.tab.h: ass3_15cs10005.y
	bison -d ass3_15cs10005.y

parser: lex.yy.c ass3_15cs10005.tab.c ass3_15cs10005.tab.h ass3_15cs10005_parser.c
	gcc lex.yy.c ass3_15cs10005.tab.c ass3_15cs10005_parser.c -o parser -lfl -ly

ass3_15cs10005.tab.c: ass3_15cs10005.y
	bison -d ass3_15cs10005.y

clean:
	- rm lexer parser lex.yy.c ass3_15cs10005.tab.c ass3_15cs10005.tab.h
