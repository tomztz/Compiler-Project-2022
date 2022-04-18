class Proc {
    final String name;
    final Type[] parameterList;
    final Type returnType;
  
    Proc(String name, Type[] parameterList, Type returnType) {
      this.name = name;
      this.parameterList = parameterList;
      this.returnType = returnType;
    }
  }