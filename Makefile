main: ToYParser.class ToYLexer.class ToY.class

test:
	@for f in $$(ls tests/error/input/*.txt); do \
		output=$$(java ToY "$$f" -e); \
		expected=$$(cat tests/error/output/$$(basename "$$f").expected); \
		if [ "$$output" != "$$expected" ]; then \
			echo "$$f" fail; \
			echo ---------expected output:; \
			echo "$$expected"; \
			echo ---------actual output:; \
			echo "$$output"; \
			exit 1; \
		fi; \
	done; \
	echo Error test cases passed; \
	for f in $$(ls tests/valid/*.txt); do \
		output=$$(java ToY "$$f" -e); \
		if [ "$$output" != "VALID" ]; then \
			echo "$$f" fail; \
			echo output:; \
			echo "$$output"; \
			exit 1; \
		fi; \
	done; \
	echo Valid test cases passed;

%.class: %.java
	javac $<

ToYParser.java: toy.y
	bison $< -o $@

ToYLexer.java: toy.l
	jflex $<

clean:
	rm -f ToYParser.java ToYLexer.java *.class *~

.PHONY: clean test