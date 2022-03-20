
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
public String idValue;


public Object getLVal() {
  return idValue;
}

public void yyerror(String msg) {
  throw new RuntimeException("" + (yyline+1) + ": " + msg);
}

StringBuilder sb = new StringBuilder();
String op = "";
%}

LineTerminator = \r|\n|\r\n
WhiteSpace     = {LineTerminator}|[ \t]
Comment = ("//"|"##").*

Identifier = [a-zA-Z_][a-zA-Z0-9_]*
DIGIT=[0-9]
Punctuation = ";"|"<"|">"|"!"|"+"|"."|"="|"-"|"*"|"/"|"{"|"}"|"("|")"|","
Integer = -?{DIGIT}{DIGIT}*


%state SSTRING
%state INTEGER


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
not                      {return NOT;}

{Identifier}                   { idValue = yytext(); return ID; }

"=="                    {return EQ;}
"<="                    {return LE;}
">="                    {return GE;}
"!="                    {return NE;}
{Punctuation}                   { return yytext().charAt(0); }

\"                             { sb.setLength(0); yybegin(SSTRING); }


{Integer}                   { Short.parseShort(yytext());
							yybegin(INTEGER);
                            return INT_LITERAL; }
}
<INTEGER>{

{Punctuation}                   {yybegin(YYINITIAL); return yytext().charAt(0);}

{WhiteSpace}                {yybegin(YYINITIAL);}

(!{Punctuation}&&!{WhiteSpace})                    {throw new Error("Illegal character <"+
                                                yytext()+">");}      		
}
<SSTRING>{
\"                             { yybegin(YYINITIAL);
                               return STRING_LITERAL; }
<<EOF>>                         {throw new Exception("unexpected EOF");}
[^\n\r\"\\]+                   { sb.append( yytext() ); }
}

/* error fallback */
[^]                              { throw new Exception("Illegal character <"+
                                                yytext()+">"); }