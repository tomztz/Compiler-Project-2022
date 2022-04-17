main: ToYParser.class ToYLexer.class ToY.class

test:
	java ToY test.txt

%.class: %.java
	javac $<

ToYParser.java: toy.y
	bison $< -o $@

ToYLexer.java: toy.l
	jflex $<

clean:
	rm -f ToYParser.java ToYLexer.java *.class *~

.PHONY: clean test