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