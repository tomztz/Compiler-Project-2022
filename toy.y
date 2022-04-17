%language "Java"
%define api.parser.class {ToYParser}
%define api.parser.public
%define lex_throws {Exception}
%define throws {Exception}

%code imports {
import java.util.*;
}

%code {
  public final HashMap<String, Proc> procTable = new HashMap<String, Proc>();
  private final HashMap<String, Struct> structTable = new HashMap<String, Struct>();
  private Scope scope;
  /**
   * a map from function names to expected procedure types.
   */
  private final HashMap<String, Proc> pendingProcCalls = new HashMap<String, Proc>();
}

%token INT_LITERAL
%token STRING_LITERAL
%token <String> ID
%token BOOL INT TRUE FALSE VOID PRINTF STRING STRUCT IF THEN ELSE FOR RETURN

%type <Type> return_type type expr l_expr var
%type <Type[]> argument_list
%type <ArrayList<Type>> nonempty_argument_list
%type <HashMap<String, Type>> declaration_list nonempty_declaration_list
%type <VarDecl> declaration

%nonassoc '>' '<' GE LE EQ NE AND OR NOT
%left '*' '/' MOD
%left '+' '-'
%precedence NEG '!'
%precedence THEN
%precedence ELSE

%%

top:
  pgm
  {
    Proc proc = procTable.get("main");
    if (proc == null || proc.returnType != Type.VOID
        || proc.parameterList.length != 0) {
      throw new Exception("missing void main()");
    }

    for (String name : pendingProcCalls.keySet()) {
      if (!procTable.containsKey(name)) {
        throw new Exception("undef proc " + name);
      }
    }
  }
  ;

pgm:
  pgm proc
  | pgm struct
  | 
  ;

proc:
  return_type ID '(' declaration_list ')' '{'
    {
      scope=new Scope(null);
      scope.varTable.putAll($4);
      scope=new Scope(scope);
      if (procTable.containsKey($2) || structTable.containsKey($2)) {
        throw new Exception("redef toplevel name " + $2);
      }
      procTable.put($2, new Proc($4.values().toArray(new Type[0]), $1));
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
    $1.put($3.name,$3.type);$$=$1;
  }
  | declaration
  {
    HashMap<String,Type> decls=new LinkedHashMap<String, Type>();
    decls.put($1.name, $1.type);$$=decls;
  }
  ;

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
        throw new Exception("undef struct " + $1);
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

struct:
  STRUCT ID '{' nonempty_declaration_list '}'
  {
    if (procTable.containsKey($2) || structTable.containsKey($2)) {
      throw new Exception("redef toplevel name " + $2);
    }
    structTable.put($2,new Struct($4));
  }
  ;

stmt:
  FOR '(' ID '=' expr ';' expr ';' for_step_stmt ')' stmt
  | IF '(' expr ')' THEN stmt
  | IF '(' expr ')' THEN stmt ELSE stmt %prec ELSE
  | PRINTF '(' STRING_LITERAL ')' ';'
  | RETURN expr ';'
  | '{' {scope=new Scope(scope);} statement_list '}'
    {
      scope = scope.parent;
    }
  | type ID ';'
    {
      if (scope.varTable.containsKey($2)) {
        throw new Exception("redef var " + $2);
      }
      scope.varTable.put($2, $1);
    }
  | l_expr '=' expr ';'
    {
    }
  | l_expr '=' ID '(' argument_list ')' ';'
    {
      pendingProcCalls.put($3, new Proc($5, $1));
    }
  | ID '(' argument_list ')' ';'
    {
      pendingProcCalls.put($1, new Proc($3, Type.ANY));
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
        throw new Exception("not struct");
      }
      Type type = $1.struct.fieldTable.get($3);
      if (type == null) {
        throw new Exception("undef field " + $3);
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
        throw new Exception("undef var " + $1);
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

expr:
  INT_LITERAL  {$$=Type.INT;}
  | STRING_LITERAL {$$=Type.STRING;}
  | TRUE {$$=Type.BOOL;}
  | FALSE {$$=Type.BOOL;}
  | '-' expr %prec NEG {$$=Type.INT;}
  | '!' expr {$$=Type.BOOL;}
  | l_expr {$$=$1;}
  | '(' expr ')' {$$=$2;}
  | expr '+' expr {$$=Type.INT;}
  | expr '-' expr {$$=Type.INT;}
  | expr '*' expr {$$=Type.INT;}
  | expr '/' expr {$$=Type.INT;}
  | expr MOD expr {$$=Type.INT;}
  | expr AND expr {$$=Type.BOOL;}
  | expr OR expr {$$=Type.BOOL;}
  | expr NOT expr {$$=Type.BOOL;}
  | expr EQ expr {$$=Type.BOOL;}
  | expr '>' expr {$$=Type.BOOL;}
  | expr '<' expr {$$=Type.BOOL;}
  | expr GE expr {$$=Type.BOOL;}
  | expr LE expr {$$=Type.BOOL;}
  | expr NE expr {$$=Type.BOOL;}

%%

class Type {
  enum Kind {
    Void,
    Int,
    Bool,
    String,
    Struct,
    Any,
  }

  public final Kind kind;
  public final String id;
  public final Struct struct;

  static final Type VOID = new Type(Kind.Void);
  static final Type INT = new Type(Kind.Int);
  static final Type BOOL = new Type(Kind.Bool);
  static final Type STRING = new Type(Kind.String);
  static final Type ANY = new Type(Kind.Any);

  public Type(Kind kind) {
    this.kind = kind;
    this.id = "";
    this.struct = null;
  }

  public Type(String id, Struct struct) {
    kind = Kind.Struct;
    this.id = id;
    this.struct = struct;
  }
}

class Struct {
  final HashMap<String, Type> fieldTable;
  Struct(HashMap<String, Type> fieldTable) {
    this.fieldTable = fieldTable;
  }
}

class VarDecl {
  final String name;
  final Type type;

  VarDecl(String name, Type type) {
    this.name = name;
    this.type = type;
  }
}

class Proc {
  final Type[] parameterList;
  final Type returnType;

  Proc(Type[] parameterList, Type returnType) {
    this.parameterList = parameterList;
    this.returnType = returnType;
  }
}

class Scope {
  final Scope parent;
  final HashMap<String, Type> varTable = new HashMap<String, Type>();

  Scope(Scope parent) {
    this.parent = parent;
  }

  Type find(String name) {
    Scope scope = this;
    while (scope != null) {
      Type type = scope.varTable.get(name);
      if (type != null) {
        return type;
      }
      scope = scope.parent;
    }
    return null;
  }
}