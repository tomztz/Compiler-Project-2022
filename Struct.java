import java.util.HashMap;

class Struct {
  final String name;
  final HashMap<String, Type> fieldTable;
  Struct(String name, HashMap<String, Type> fieldTable) {
    this.name = name;
    this.fieldTable = fieldTable;
  }
}
