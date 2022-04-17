import java.io.*;

public class ToY {
  public static void main(String[] args) throws IOException {
    ToYParser.Lexer lexer = new ToYLexer(new FileReader(args[0]));
    ToYParser parser = new ToYParser(lexer);
    try {
      parser.parse();
      System.out.println("VALID");
    } catch (Exception e) {
      if (args.length > 1) {
        if (args[1].equals("-e")) {
          System.out.println(e.getMessage());
        } else if (args[1].equals("-s")) {
          e.printStackTrace(System.out);
        }
      }
      System.out.println("ERROR");
    }
  }
}