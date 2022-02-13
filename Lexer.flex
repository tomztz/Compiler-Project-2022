import java.util.Stack;
%%

%class Lexer
%unicode
%debug

%{
StringBuffer stringBuffer = new StringBuffer();
%}

LineTerminator = \r|\n|\r\n
InputCharacter = [^\r\n]
WhiteSpace     = {LineTerminator} | [ \t\f]

/* comments */
Comment = {TraditionalComment} | {EndOfLineComment} | {DocumentationComment}

TraditionalComment   = "/*" [^*] ~"*/" | "/*" "*"+ "/"
// Comment can be the last line of the file, without line terminator.
EndOfLineComment     = "//" {InputCharacter}* {LineTerminator}?
DocumentationComment = "/**" {CommentContent} "*"+ "/"
CommentContent       = ( [^*] | \*+ [^/*] )*

Identifier = [:jletter:] [:jletterdigit:]*

DecIntegerLiteral = 0 | [1-9][0-9]*

%state STRING

%%


<YYINITIAL> {
/* identifiers */
{Identifier}                   { return new Yytoken(SymbolTable.IDENTIFIER,yytext()); }

/* literals */
\"                             { stringBuffer.setLength(0); yybegin(STRING); }

/* operators */
"="                            { return new Yytoken(SymbolTable.EQ, yytext()); }

/* comments */
{Comment}                      { /* ignore */ }

/* whitespace */
{WhiteSpace}                   { /* ignore */ }
}

<STRING> {
\"                             { yybegin(YYINITIAL);
                               return new Yytoken(SymbolTable.STRING_LITERAL,
                               stringBuffer.toString()); }
[^\n\r\"\\]+                   { stringBuffer.append( yytext() ); }
\\t                            { stringBuffer.append('\t'); }
\\n                            { stringBuffer.append('\n'); }

\\r                            { stringBuffer.append('\r'); }
\\\"                           { stringBuffer.append('\"'); }
\\                             { stringBuffer.append('\\'); }
}

/* error fallback */
[^]                              { throw new Error("Illegal character <"+
                                                yytext()+">"); }