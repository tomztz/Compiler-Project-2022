test: Lexer.class test.txt
	java Lexer test.txt 

Lexer.class: Lexer.java Yytoken.java SymbolTable.java

%.class: %.java
	javac $^

Lexer.java: Lexer.flex
	jflex Lexer.flex


clean:
	rm -f Lexer.java *.class *~

.PHONY: test
