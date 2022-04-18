
%%

%class ToYLexer
%implements ToYParser.Lexer
%int
%line
%unicode
%yylexthrow{
  Exception
%yylexthrow}

%{
StringBuilder sb = new StringBuilder();
String op = "";

public String idValue;

public Object getLVal() {
  return idValue;
}

public void yyerror(String msg) {
  throw new RuntimeException("" + (yyline+1) + ": " + msg);
}
%}

LineTerminator = \r|\n|\r\n
InputCharacter = [^\r\n]
WhiteSpace     = {LineTerminator}|[ \t\f]
/* comments */
Comment = {EndOfLineComment} | {ToYComment}

// Comment can be the last line of the file, without line terminator.
EndOfLineComment     = "//" {InputCharacter}* {LineTerminator}?
ToYComment = "##"{InputCharacter}* {LineTerminator}?

Identifier = [a-zA-Z_][a-zA-Z0-9_]*
DIGIT=[0-9]
Symbols = ";"|"<"|">"|"!"|"+"|"."|"="|"-"|"*"|"/"|"{"|"}"|"("|")"|","
IntegerRex = -?{DIGIT}
AlphaDigit = [0-9a-zA-Z_]
%state SSTRING
%%

<YYINITIAL> {

/* comments */
{Comment}                      { /* ignore */ }

/* whitespace */
{WhiteSpace}                   { /* ignore */ }

bool                      {return BOOL;}
int                      {return INT;}
true                      {return TRUE;}
false                      {return FALSE;}
void                      {return VOID;}
printf                      {return PRINTF;}
string                      {return STRING;}
struct                      {return STRUCT;}
if                      {return IF;}
then                      {return THEN;}
else                      {return ELSE;}
for                      {return FOR;}
return                      {return RETURN;}
mod                      {return MOD;}
and                      {return AND;}
or                      {return OR;}

{Identifier}                   { idValue = yytext(); return ID; }

"=="                    {return EQ;}
"<="                    {return LE;}
">="                    {return GE;}
"!="                    {return NE;}
{Symbols}                   { return yytext().charAt(0); }

\"                             { sb.setLength(0); yybegin(SSTRING); }

//NOTE: checking for mixing integer with letters are not done here because we observe:if the code contains
//any numeric values with letters, there will be no matching in the parser, and gives an error automatically
{IntegerRex}{DIGIT}*{AlphaDigit}*                 { sb.setLength(0);sb.append(yytext());
                            if(Short.parseShort(sb.toString())>Short.MAX_VALUE){    //check if integer is out of bound
                                throw new Exception("Integer out of bound <"+
                                    yytext()+">"); }
                            else if(Short.parseShort(sb.toString())<Short.MIN_VALUE){
                                throw new Exception("Integer out of bound <"+
                                    yytext()+">"); }
                            return INT_LITERAL; }
}

<SSTRING>{
\"                             { yybegin(YYINITIAL);
                               return STRING_LITERAL; }
<<EOF>>                         {throw new Exception("Illegal character <"+
                                                yytext()+">");} // if not found a second semicolon at the end of the file
                                                                //there is an error
[^\"\\]+                   { sb.append( yytext() ); }           //otherwise append all characters
\\                              {throw new Exception("Illegal character <"+
                                                yytext()+">");}   //if backslash raise error
}
/* error fallback */
[^]                              { throw new Exception("Illegal character <"+
                                                yytext()+">"); }