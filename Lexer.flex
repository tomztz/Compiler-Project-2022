import java.util.Stack;
%%

%class Lexer
%unicode
%debug

%{
StringBuilder sb = new StringBuilder();
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

DIGIT=[0-9]


%state STRING
%state INTEGER
%%


<YYINITIAL> {
/* identifiers */
{Identifier}                   { return new Yytoken(SymbolTable.IDENTIFIER,yytext()); }

/* literals */

\"                             { sb.setLength(0); yybegin(STRING); }
/* operators */
"="                            { return new Yytoken(SymbolTable.EQ, yytext()); }

/* comments */
{Comment}                      { /* ignore */ }

/* whitespace */
{WhiteSpace}                   { /* ignore */ }

{DIGIT}                        { sb.setLength(0); sb.append(yytext());yybegin(INTEGER);}                         
}
<INTEGER>{
{WhiteSpace}                   {yybegin(YYINITIAL);
                                if(Integer.parseInt(sb.toString())>Integer.MAX_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else{return new Yytoken(SymbolTable.INTEGER,sb.toString());}
}
<<EOF>>                        {yybegin(YYINITIAL);
                                if(Integer.parseInt(sb.toString())>Integer.MAX_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else{return new Yytoken(SymbolTable.INTEGER,sb.toString());}


}
[^0-9]*                      {throw new Error("Illegal character <"+
                                                yytext()+">");}
{DIGIT}+                       {sb.append(yytext());}
}

<STRING>{
\"                             { yybegin(YYINITIAL);
                               return new Yytoken(SymbolTable.STRING_LITERAL,
                               sb.toString()); }
<<EOF>>                         {throw new Error("Illegal character <"+
                                                yytext()+">");}
[^\n\r\"\\]+                   { sb.append( yytext() ); }
\\                              {throw new Error("Illegal character <"+
                                                yytext()+">");}
}
/* error fallback */
[^]                              { throw new Error("Illegal character <"+
                                                yytext()+">"); }