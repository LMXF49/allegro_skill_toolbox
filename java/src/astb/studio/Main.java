// ============================================================================
// File        : Main.java
// Description : Entry point. Normal launch runs the Swing GUI; hidden
//               headless mode:
//                 --selftest    module self-checks (no GUI, exit != 0 on fail)
// ============================================================================
package astb.studio;

public final class Main {
    public static void main(String[] args) {
        if (args.length > 0 && args[0].equals("--selftest")) {
            System.exit(SelfTest.run());
            return;
        }
        astb.studio.ui.MainFrame.start();
    }

    private Main() {}
}
