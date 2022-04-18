main: ToYParser.class ToYLexer.class ToY.class
start:
	java ToY test.txt
test:
	@for type in parse typecheck; do \
		for f in $$(ls tests/error/$$type/input/*.txt); do \
			output=$$(java ToY "$$f" -e | sed 's/&M$$//'); \
			expected=$$(cat tests/error/$$type/output/$$(basename "$$f").expected); \
			if [ "$$output" != "$$expected" ]; then \
				echo "$$f" fail; \
				echo ---------expected output:; \
				echo "$$expected"; \
				echo ---------actual output:; \
				echo "$$output"; \
				exit 1; \
			fi; \
		done; \
		echo $$type error test cases passed; \
	done; \
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
