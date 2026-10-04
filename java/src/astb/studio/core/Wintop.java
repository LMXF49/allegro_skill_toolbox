// ============================================================================
// File        : Wintop.java
// Description : Best-effort Allegro window activation by title match (port
//               of python session_board.activate_allegro_window semantics):
//               bridge pids are random (not OS pids), so we match the design
//               name inside Allegro window titles. Java can't call Win32
//               directly without JNI, so we drive a tiny PowerShell script
//               through ProcessBuilder (SetWindowPos TOPMOST pulse, which
//               works around the foreground lock better than
//               SetForegroundWindow).
// ============================================================================
package astb.studio.core;

public final class Wintop {
    private Wintop() {}

    /** The PowerShell script text (design single-quote escaped, lowercased). */
    public static String buildScript(String design) {
        String d = design == null ? "" : design.replace("'", "''").toLowerCase();
        return "$d='" + d + "'\n"
             + "Add-Type -TypeDefinition '\n"
             + "using System;\n"
             + "using System.Runtime.InteropServices;\n"
             + "public class W {\n"
             + "  [DllImport(\"user32.dll\")] public static extern bool SetWindowPos("
             + "IntPtr h, IntPtr a, int x, int y, int cx, int cy, int f);\n"
             + "  [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr h, int c);\n"
             + "  [DllImport(\"user32.dll\")] public static extern bool IsZoomed(IntPtr h);\n"
             + "}\n"
             + "'\n"
             + "$hit = Get-Process | Where-Object { $_.MainWindowTitle -and "
             + "$_.MainWindowTitle.ToLower().Contains(\"allegro\") -and "
             + "($d -eq \"\" -or $_.MainWindowTitle.ToLower().Contains($d)) } "
             + "| Select-Object -First 1\n"
             + "if ($hit) {\n"
             + "  if ([W]::IsZoomed($hit.MainWindowHandle)) {\n"
             + "    [W]::ShowWindow($hit.MainWindowHandle, 3) | Out-Null\n"
             + "  } else {\n"
             + "    [W]::ShowWindow($hit.MainWindowHandle, 9) | Out-Null\n"
             + "  }\n"
             + "  [W]::SetWindowPos($hit.MainWindowHandle, [IntPtr](-1), 0,0,0,0, 3) | Out-Null\n"
             + "  [W]::SetWindowPos($hit.MainWindowHandle, [IntPtr](-2), 0,0,0,0, 3) | Out-Null\n"
             + "  \"found=1\"\n"
             + "} else { \"found=0\" }\n";
    }

    /** Raise the matching Allegro window; returns true when a window was found.
     *  （经临时 .ps1 文件执行——-Command 传多行脚本在 Windows 命令行引号下会坏，
     *  实测 -File 稳定。UTF-8 BOM 让 PowerShell 5.1 正确读中文 design。
     *  子进程 10s 超时强制回收，防 powershell 被拦挂死 worker。） */
    public static boolean activate(String design) {
        java.nio.file.Path tmp = null;
        try {
            tmp = java.nio.file.Files.createTempFile("astb_wintop_", ".ps1");
            byte[] body = buildScript(design).getBytes(java.nio.charset.StandardCharsets.UTF_8);
            byte[] withBom = new byte[body.length + 3];
            withBom[0] = (byte) 0xEF;
            withBom[1] = (byte) 0xBB;
            withBom[2] = (byte) 0xBF;
            System.arraycopy(body, 0, withBom, 3, body.length);
            java.nio.file.Files.write(tmp, withBom);
            Process p = new ProcessBuilder("powershell.exe", "-NoProfile",
                                           "-ExecutionPolicy", "Bypass",
                                           "-File", tmp.toString())
                    .redirectErrorStream(true).start();
            boolean done = p.waitFor(10, java.util.concurrent.TimeUnit.SECONDS);
            if (!done) {
                p.destroyForcibly();
                return false;
            }
            String out = new String(p.getInputStream().readAllBytes(), Util.GBK);
            return out.contains("found=1");
        } catch (Exception e) {
            return false;
        } finally {
            if (tmp != null) {
                try { java.nio.file.Files.deleteIfExists(tmp); } catch (Exception ignored) {}
            }
        }
    }
}
