/*
This is a parser for the Toy language, and semantic checks based on Bison 
semantic rules defined along the AST.
*/
%language "Java"
%define api.parser.class {ToYParser}
%define api.parser.public
%define lex_throws {Exception}
%define throws {Exception}

%code imports {
import java.util.*;
}

%code {
  public final HashMap<String, Proc> procTable = new HashMap<String, Proc>();   //Symbol table recording all procedures
  private final HashMap<String, Struct> structTable = new HashMap<String, Struct>(); // Symbol table recoding all structs
  private Proc currentProc;   //current procedure return type
  private Scope scope;        //scope
  /**
   * a map from function names to expected procedure types.
   */
  private final HashMap<String, Proc> pendingProcCalls = new HashMap<String, Proc>(); //pending procedures

//this is a function used to check types of given expression
  private void checkType(String name, Type actual, Type expected) throws Exception {
    if (actual.kind == Type.Kind.Any || expected.kind == Type.Kind.Any) {
      return;
    }
    if (actual.kind != expected.kind) {
      throw new Exception(
        "expected " + expected.kind + " for " + name + ", found " + actual.kind);
    }
    if (actual.kind == Type.Kind.Struct) {
      if (actual.struct != expected.struct) {
        throw new Exception(
          "expected struct " + expected.struct.name + " for " + name +
          ", found struct " + actual.struct.name);
      }
    }
  }
}

//definitions
%token INT_LITERAL
%token STRING_LITERAL
%token <String> ID
%token BOOL INT TRUE FALSE VOID PRINTF STRING STRUCT IF THEN ELSE FOR RETURN

%type <Type> return_type type expr l_expr var
%type <Type[]> argument_list
%type <ArrayList<Type>> nonempty_argument_list
%type <HashMap<String, Type>> declaration_list nonempty_declaration_list
%type <VarDecl> declaration

%nonassoc '>' '<' GE LE EQ NE AND OR
%left '*' '/' MOD
%left '+' '-'
%precedence NEG '!'
%precedence THEN
%precedence ELSE

%%

top:
  pgm
  {
    //check if main methods exsists
    Proc proc = procTable.get("main");
    if (proc == null || proc.returnType != Type.VOID
        || proc.parameterList.length != 0) {
      throw new Exception("missing void main()");
    }
    //check all the peding procedures are defined
    for (HashMap.Entry<String, Proc> entry : pendingProcCalls.entrySet()) {
      String name = entry.getKey();
      Proc actual = entry.getValue();
      Proc expected = procTable.get(name);
      if (expected == null) {
        throw new Exception("undef proc " + name);
      }
      //check procedure assignments are well typed
      checkType("assignment", expected.returnType, actual.returnType);
      //check if number of parameters mismatchs
      if (actual.parameterList.length != expected.parameterList.length) {
        throw new Exception("arity of function " + name + " mismatch");
      }
      //check if parameters of procedure are well typed
      for (int i = 0; i < actual.parameterList.length; i++) {
        checkType(String.format("argument %d of function call %s", i+1, name),
          actual.parameterList[i], expected.parameterList[i]);
      }
    }
  }
  ;

pgm:
  pgm proc
  | pgm struct
  | 
  ;
//procedure definition
proc:
  return_type ID '(' declaration_list ')' '{'
    {
      scope=new Scope(null);          //enter a new scope once a new function definition is found
      scope.varTable.putAll($4);      //record are parameters declaration
      scope=new Scope(scope);
      if (procTable.containsKey($2) || structTable.containsKey($2)) { //check if function name is redecleared
        throw new Exception("redef toplevel name " + $2);
      }
      currentProc = new Proc($2, $4.values().toArray(new Type[0]), $1); //put function in symboltable
      procTable.put($2, currentProc);
    }
    stmt '}'
  ;



declaration_list:
  nonempty_declaration_list
  { $$=$1; }
  |
  { $$=new LinkedHashMap<String, Type>(); }
  ;

nonempty_declaration_list:
  nonempty_declaration_list ',' declaration
  {
    if ($1.containsKey($3.name)) {
      throw new Exception("redef field/param " +$3.name);
    }
    $1.put($3.name,$3.type);
    $$=$1;
  }
  | declaration
  {
    HashMap<String,Type> decls=new LinkedHashMap<String, Type>();
    decls.put($1.name, $1.type);
    $$=decls;
  }
  ;
//variable declaration
declaration:
  type ID
  { $$=new VarDecl($2,$1); }
  ;

type:
  INT       {$$=Type.INT;}
  | BOOL    {$$=Type.BOOL;}
  | STRING  {$$=Type.STRING;}
  | ID
    {
      Struct s = structTable.get($1);
      if (s == null) {
        throw new Exception("undef struct " + $1); //check if struct is undefined
      }
      $$=new Type($1, s);
    }
  ;

return_type:
  type    { $$=$1; }
  | VOID  { $$=Type.VOID; }
  ;

statement_list:
  statement_list stmt
  |
  ;

//struct definition
struct:
  STRUCT ID '{' nonempty_declaration_list '}'
  {
    if (procTable.containsKey($2) || structTable.containsKey($2)) {  //check if repeated struct name
      throw new Exception("redef toplevel name " + $2);
    }
    structTable.put($2,new Struct($2,$4));   //put in symbol table
  }
  ;

stmt:
  FOR '(' var '=' expr ';' expr ';' for_step_stmt ')' stmt
    {
      checkType("condition of for-loop", $7, Type.BOOL);    //check 2nd expression in for loop is boolean
      checkType("initial assignment of for-loop", $5, $3);
    }
  | IF '(' expr ')' THEN stmt
    {
      checkType("condition of if-statement", $3, Type.BOOL);//check boolean after if statement 
    }
  | IF '(' expr ')' THEN stmt ELSE stmt %prec ELSE
    {
      checkType("condition of if-statement", $3, Type.BOOL); 
    }
  | PRINTF '(' STRING_LITERAL ')' ';'
  | RETURN expr ';'
    {
      checkType("return value of function " + currentProc.name, $2, currentProc.returnType); //check correct return type
    }
  | '{' {scope=new Scope(scope);} statement_list '}'
    {
      scope = scope.parent;
    }
  | type ID ';'
    {
      if (scope.varTable.containsKey($2)) {
        throw new Exception("redef var " + $2);     //check if variable is redeclered
      }
      scope.varTable.put($2, $1);
    }
  | l_expr '=' expr ';'
    {
      checkType("assignment", $3, $1);      //check variable assignment is well-typed
    }
  | l_expr '=' ID '(' argument_list ')' ';'
    {
      pendingProcCalls.put($3, new Proc($3, $5, $1));   //add to pending function calls
    }
  | ID '(' argument_list ')' ';'
    {
      pendingProcCalls.put($1, new Proc($1, $3, Type.ANY));
    }
  ;

for_step_stmt:
  stmt
  |
  ;

l_expr:
  l_expr '.' ID
    {
      if ($1.kind != Type.Kind.Struct) {
        throw new Exception("not struct");          //check if calling is a struct
      }
      Type type = $1.struct.fieldTable.get($3);
      if (type == null) {
        throw new Exception("undef field " + $3 + " in struct " + $1.struct.name);//check if struct is defined
      }
      $$ = type;
    }
  | var
    {$$=$1;}
  ;

var:
  ID
    {
      Type type = scope.find($1);
      if (type == null) {
        throw new Exception("undef var " + $1); //check if variable is defined
      }
      $$ = type;
    }
  ;

argument_list:
  nonempty_argument_list { $$=$1.toArray(new Type[0]); }
  | { $$=new Type[0]; }
  ;

nonempty_argument_list:
  nonempty_argument_list ',' expr
    {
      $1.add($3);
      $$=$1;
    }
  | expr
    {
      ArrayList<Type> p=new ArrayList<Type>();
      p.add($1);
      $$=p;
    }
  ;
//expression definition with type checks
expr:
  INT_LITERAL  {$$=Type.INT;}
  | STRING_LITERAL {$$=Type.STRING;}
  | TRUE {$$=Type.BOOL;}
  | FALSE {$$=Type.BOOL;}
  | '-' expr %prec NEG
    {
      checkType("operand of integer negation", $2, Type.INT);
      $$=Type.INT;
    }
  | '!' expr
    {
      checkType("operand of logical negation", $2, Type.BOOL);
      $$=Type.BOOL;
    }
  | l_expr {$$=$1;}
  | '(' expr ')' {$$=$2;}
  | expr '+' expr
    {
      if ($1 != Type.INT && $1 != Type.STRING) {
        throw new Exception("expected Int or String for LHS of +, found " + $1.kind);
      }
      if ($3 != Type.INT && $3 != Type.STRING) {
        throw new Exception("expected Int or String for RHS of +, found " + $3.kind);
      }
      if ($1.kind != $3.kind) {
        throw new Exception("type mismatch for +, " + $1.kind + " != " + $3.kind);
      }
      $$=$1;
    }
  | expr '-' expr
    {
      checkType("LHS of -", $1, Type.INT);
      checkType("RHS of -", $3, Type.INT);
      $$=Type.INT;
    }
  | expr '*' expr
    {
      checkType("LHS of *", $1, Type.INT);
      checkType("RHS of *", $3, Type.INT);
      $$=Type.INT;
    }
  | expr '/' expr
    {
      checkType("LHS of /", $1, Type.INT);
      checkType("RHS of /", $3, Type.INT);
      $$=Type.INT;
    }
  | expr MOD expr
    {
      checkType("LHS of modulo", $1, Type.INT);
      checkType("RHS of modulo", $3, Type.INT);
      $$=Type.INT;
    }
  | expr AND expr
    {
      checkType("LHS of logical-and", $1, Type.BOOL);
      checkType("RHS of logical-and", $3, Type.BOOL);
      $$=Type.BOOL;
    }
  | expr OR expr
    {
      checkType("LHS of logical-or", $1, Type.BOOL);
      checkType("RHS of logical-or", $3, Type.BOOL);
      $$=Type.BOOL;
    }
  | expr EQ expr
    {
      if ($1 == Type.VOID) {
        throw new Exception("expected Bool, Int, String or Struct for LHS of ==, found " + $1.kind);
      }
      if ($3 == Type.VOID) {
        throw new Exception("expected Bool, Int, String or Struct for RHS of ==, found " + $3.kind);
      }
      if ($1.kind != $3.kind) {
        throw new Exception("type mismatch for ==, " + $1.kind + " != " + $3.kind);
      }
      if ($1.kind == Type.Kind.Struct) {
        if ($1.struct.name != $3.struct.name) {
          throw new Exception("struct mismatch for ==, " + $1.struct.name + " != " + $3.struct.name);
        }
      }
      $$=Type.BOOL;
    }
  | expr NE expr
    {
      if ($1 == Type.VOID) {
        throw new Exception("expected Bool, Int, String or Struct for LHS of !=, found " + $1.kind);
      }
      if ($3 == Type.VOID) {
        throw new Exception("expected Bool, Int, String or Struct for RHS of !=, found " + $3.kind);
      }
      if ($1.kind != $3.kind) {
        throw new Exception("type mismatch for !=, " + $1.kind + " != " + $3.kind);
      }
      if ($1.kind == Type.Kind.Struct) {
        if ($1.struct.name != $3.struct.name) {
          throw new Exception("struct mismatch for !=, " + $1.struct.name + " != " + $3.struct.name);
        }
      }
      $$=Type.BOOL;
    }
  | expr '>' expr
    {
      if ($1 != Type.INT && $1 != Type.STRING) {
        throw new Exception("expected Int or String for LHS of >, found " + $1.kind);
      }
      if ($3 != Type.INT && $3 != Type.STRING) {
        throw new Exception("expected Int or String for RHS of >, found " + $3.kind);
      }
      if ($1.kind != $3.kind) {
        throw new Exception("type mismatch for >, " + $1.kind + " != " + $3.kind);
      }
      $$=Type.BOOL;
    }
  | expr '<' expr
    {
      if ($1 != Type.INT && $1 != Type.STRING) {
        throw new Exception("expected Int or String for LHS of <, found " + $1.kind);
      }
      if ($3 != Type.INT && $3 != Type.STRING) {
        throw new Exception("expected Int or String for RHS of <, found " + $3.kind);
      }
      if ($1.kind != $3.kind) {
        throw new Exception("type mismatch for <, " + $1.kind + " != " + $3.kind);
      }
      $$=Type.BOOL;
    }
  | expr GE expr
    {
      if ($1 != Type.INT && $1 != Type.STRING) {
        throw new Exception("expected Int or String for LHS of >=, found " + $1.kind);
      }
      if ($3 != Type.INT && $3 != Type.STRING) {
        throw new Exception("expected Int or String for RHS of >=, found " + $3.kind);
      }
      if ($1.kind != $3.kind) {
        throw new Exception("type mismatch for >=, " + $1.kind + " != " + $3.kind);
      }
      $$=Type.BOOL;
    }
  | expr LE expr
    {
      if ($1 != Type.INT && $1 != Type.STRING) {
        throw new Exception("expected Int or String for LHS of <=, found " + $1.kind);
      }
      if ($3 != Type.INT && $3 != Type.STRING) {
        throw new Exception("expected Int or String for RHS of <=, found " + $3.kind);
      }
      if ($1.kind != $3.kind) {
        throw new Exception("type mismatch for <=, " + $1.kind + " != " + $3.kind);
      }
      $$=Type.BOOL;
    }

%%





