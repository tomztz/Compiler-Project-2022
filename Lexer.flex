%%

%class Lexer
%unicode
%debug

%{
StringBuilder sb = new StringBuilder();
String op = "";
%}

LineTerminator = \r|\n|\r\n
InputCharacter = [^\r\n]
WhiteSpace     = {LineTerminator} | [ \t\f]
/* comments */
Comment = {EndOfLineComment} | {ToYComment}
KEYWORD=if|int|double|return|bool|true|false|void|printf|string|struct|then|else|for

// Comment can be the last line of the file, without line terminator.
EndOfLineComment     = "//" {InputCharacter}* {LineTerminator}?
ToYComment = "##"{InputCharacter}* {LineTerminator}?

Identifier = [:jletter:] [:jletterdigit:]*
DIGIT=[0-9]
Symbols = ";"|"<"|">"|"=="|"<="|">="|"!="|"!"|"+"|"."|"="|"-"|"*"|"/"|"mod"|"and"|"or"|"not"|"{"|"}"|"("|")"
IntegerRex = -?{DIGIT}
%state STRING
%state INTEGER
%%


<YYINITIAL> {
{KEYWORD}                      {return new Yytoken(SymbolTable.RESERVE_WORD,yytext());}
/* identifiers */
{Identifier}                   { return new Yytoken(SymbolTable.IDENTIFIER,yytext()); }

/* literals */

\"                             { sb.setLength(0); yybegin(STRING); }

/* comments */
{Comment}                      { /* ignore */ }

/* whitespace */
{WhiteSpace}                   { /* ignore */ }

{Symbols}                      { return new Yytoken(SymbolTable.SYMBOL,yytext());}

{IntegerRex}                   { sb.setLength(0); sb.append(yytext());yybegin(INTEGER);}

}
<INTEGER>{
{WhiteSpace}                   {yybegin(YYINITIAL);
                                if(Integer.parseInt(sb.toString())>Integer.MAX_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else if(Integer.parseInt(sb.toString())<Integer.MIN_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else{return new Yytoken(SymbolTable.INTEGER,sb.toString());}
                                }
                                

<<EOF>>                        {yybegin(YYINITIAL);
                                if(Integer.parseInt(sb.toString())>Integer.MAX_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else if(Integer.parseInt(sb.toString())<Integer.MIN_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else{return new Yytoken(SymbolTable.INTEGER,sb.toString());}
                                }
                                
{Symbols}                       {yybegin(YYINITIAL);
                                if(Integer.parseInt(sb.toString())>Integer.MAX_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else if(Integer.parseInt(sb.toString())<Integer.MIN_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else{
                                    return new Yytoken(SymbolTable.INTEGER,sb.toString());}
                                
                                }


[^0-9]*                      {throw new Error("Illegal character <"+
                                                yytext()+">");}
{DIGIT}+                     {yybegin(YYINITIAL);sb.append(yytext());
                            if(Integer.parseInt(sb.toString())>Integer.MAX_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else if(Integer.parseInt(sb.toString())<Integer.MIN_VALUE){
                                    throw new Error("Integer out of bound <"+
                                                yytext()+">");}
                                else{
                                    return new Yytoken(SymbolTable.INTEGER,sb.toString());}}
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