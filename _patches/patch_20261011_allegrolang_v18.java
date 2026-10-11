// patch_20261011_allegrolang_v18.java
// util_allegrolang.il v1.7 -> v1.8
//   切英文"没换回来"根因：reg delete 不广播 WM_SETTINGCHANGE，
//   explorer 缓存环境仍带 intl_enabled=yes，新启 Allegro 照样继承。
//   新增 _ALG_BroadcastEnv()：outfile 写 ps1 + system 全路径 powershell
//   补发广播（无引号嵌套），en 分支删除后调用。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_allegrolang_v18.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_allegrolang_v18 {
    static final Charset GBK = Charset.forName("GBK");
    static int applied = 0, skipped = 0;

    static String rep(String src, String oldS, String newS, String tag) {
        int idx = src.indexOf(oldS);
        if (idx < 0) {
            if (src.contains(newS.length() > 60 ? newS.substring(0, 60) : newS)) {
                System.out.println("[skip] " + tag + " (already applied)");
                skipped++;
                return src;
            }
            throw new RuntimeException("ANCHOR MISSING: " + tag);
        }
        if (src.indexOf(oldS, idx + oldS.length()) >= 0)
            throw new RuntimeException("ANCHOR NOT UNIQUE: " + tag);
        applied++;
        System.out.println("[ ok ] " + tag);
        return src.substring(0, idx) + newS + src.substring(idx + oldS.length());
    }

    static void checkParens(String s, Path p) {
        int depth = 0; boolean inStr = false, inCmt = false;
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (inCmt) { if (c == '\n') inCmt = false; continue; }
            if (inStr) { if (c == '\\') i++; else if (c == '"') inStr = false; continue; }
            if (c == ';') inCmt = true;
            else if (c == '"') inStr = true;
            else if (c == '(') depth++;
            else if (c == ')') depth--;
            if (depth < 0) throw new RuntimeException("paren underflow in " + p);
        }
        if (depth != 0 || inStr)
            throw new RuntimeException("paren/string imbalance in " + p + " depth=" + depth);
    }

    public static void main(String[] a) throws Exception {
        Path f = Paths.get("G:\\ASTB\\skill_src\\modules\\utilities\\util_allegrolang.il");
        String src = new String(Files.readAllBytes(f), GBK);

        src = rep(src, "; 版本      : 1.7\n", "; 版本      : 1.8\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.7 ASTB Team 实机定案：本机 17.4 ipcBeginProcess\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.8 ASTB Team 切英文不生效修复：reg delete 不广播\n" +
            ";                WM_SETTINGCHANGE，explorer 缓存仍带旧值（新启\n" +
            ";                Allegro 继承残留）；删除后 outfile 写 ps1 + system\n" +
            ";                全路径 powershell 补发环境变更广播\n" +
            ";   2026-10-11 v1.7 ASTB Team 实机定案：本机 17.4 ipcBeginProcess\n",
            "revision record");

        // 在 _ALG_RegDelete 之后插入 _ALG_BroadcastEnv
        src = rep(src,
            "        return( rc == 0 )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : ASTB_AllegroLangApply\n",
            "        return( rc == 0 )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _ALG_BroadcastEnv\n" +
            "; 功能    : 补发 WM_SETTINGCHANGE 环境变更广播（reg delete 不广播，\n" +
            ";           否则 explorer 缓存环境仍带旧值，新启 Allegro 继承残留）\n" +
            "; 备注    : outfile 写 ps1 再 system 全路径 powershell 执行，\n" +
            ";           命令行无引号嵌套（ps1 内容走文件不经命令行）\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _ALG_BroadcastEnv()\n" +
            "    prog((tmp ps1 port rc)\n" +
            "        tmp = getShellEnvVar(\"TEMP\")\n" +
            "        unless( tmp tmp = \"C:\\\\Windows\\\\Temp\" )\n" +
            "        ps1 = strcat(tmp \"\\\\astb_alg_bcast.ps1\")\n" +
            "        port = outfile(ps1)\n" +
            "        unless( port\n" +
            "            ASTB_LogWarn(\"allegrolang: cannot write broadcast ps1\")\n" +
            "            return(nil)\n" +
            "        )\n" +
            "        fprintf(port \"%s\\n\" \"Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition '[DllImport(\\\"user32.dll\\\", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);'\")\n" +
            "        fprintf(port \"%s\\n\" \"$HWND_BROADCAST = [IntPtr]0xffff\")\n" +
            "        fprintf(port \"%s\\n\" \"$WM_SETTINGCHANGE = 0x1A\")\n" +
            "        fprintf(port \"%s\\n\" \"$result = [UIntPtr]::Zero\")\n" +
            "        fprintf(port \"%s\\n\" \"[void][Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, \\\"Environment\\\", 2, 5000, [ref]$result)\")\n" +
            "        close(port)\n" +
            "        rc = system(strcat(_ALG_WinExe(\"WindowsPowerShell\\\\v1.0\\\\powershell.exe\")\n" +
            "            \" -NoProfile -ExecutionPolicy Bypass -File \" ps1))\n" +
            "        when( rc != 0\n" +
            "            ASTB_LogWarn(sprintf(nil \"allegrolang: broadcast rc=%d\" rc))\n" +
            "        )\n" +
            "        return( rc == 0 )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : ASTB_AllegroLangApply\n",
            "broadcast proc");

        src = rep(src,
            "            _ALG_RegDelete(\"intl_enabled\")\n" +
            "            _ALG_RegDelete(\"intl_show_bilingual\")\n" +
            "            msg = \"Allegro 界面语言 -> English（本地化偏好与 intl_enabled 已清除），重启 Allegro 生效\"\n",
            "            _ALG_RegDelete(\"intl_enabled\")\n" +
            "            _ALG_RegDelete(\"intl_show_bilingual\")\n" +
            "            ;; reg delete 不广播环境变更，补广播刷新 explorer 缓存\n" +
            "            _ALG_BroadcastEnv()\n" +
            "            msg = \"Allegro 界面语言 -> English（本地化偏好与 intl_enabled 已清除），重启 Allegro 生效\"\n",
            "en branch broadcast");

        src = rep(src,
            "printf(\"[ASTB] util_allegrolang.il v1.7 loaded\\n\")\n",
            "printf(\"[ASTB] util_allegrolang.il v1.8 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
