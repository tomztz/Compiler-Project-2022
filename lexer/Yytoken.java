class Yytoken {
  public SymbolTable tType;
  public String tText;

  Yytoken (SymbolTable type, String text) {
    tType = type;
    tText = text;
  }

  public String toString() {
    return "(Text: "+tText+ "    index : "+tType+")\n";
  }
}

