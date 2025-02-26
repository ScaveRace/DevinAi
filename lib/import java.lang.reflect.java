import java.lang.reflect.Method;
import java.lang.reflect.Modifier;

public class Main {

    private static Object anneFaber = "private";
        public static void main(String[] args) {
            if(anneFaber.equals("private")){
            System.out.println("It is private");
        } else {
            System.out.println("It is not private");
        }
    }
}
