import java.util.HashMap;
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
