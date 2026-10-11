// patch_20261011_allegrolang_v17.java
// util_allegrolang.il v1.1 -> v1.7（基于 v1.1 回退版）
//   实机定案：本机 17.4 ipcBeginProcess 只建通道不执行进程
//   （裸名 ipc:3 / 全路径同，注册表均无变化）；
//   system() 全路径直调 setx 实机 rc=0 且注册表确认落盘 → 采用。
//   无引号嵌套、无空格路径，避开 pitfalls §6.1 两个 system() 坑。
//   提示语"已联动"改为解耦措辞；删未实证的"17.4 需 019+ 补丁"。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_allegrolang_v17.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_allegrolang_v17 {
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

        src = rep(src, "; 版本      : 1.1\n", "; 版本      : 1.7\n", "version bump");

        src = rep(src,
            ";             变量 intl_enabled=yes（部分汉化，17.4 需 019+ 补丁），\n",
            ";             变量 intl_enabled=yes（Qt 面板部分汉化），\n",
            "header desc");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.1 ASTB Team 与工具箱菜单语言切换解耦：新增独立\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.7 ASTB Team 实机定案：本机 17.4 ipcBeginProcess\n" +
            ";                只建通道不执行进程（裸名/全路径同，注册表无变化），\n" +
            ";                改 system() 全路径直调 setx/reg（rc=0 实查注册表\n" +
            ";                确认落盘）；v1.2~v1.6 各写盘方案均已回退\n" +
            ";   2026-10-11 v1.1 ASTB Team 与工具箱菜单语言切换解耦：新增独立\n",
            "revision record");

        src = rep(src,
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _ALG_Setx / _ALG_RegDelete\n" +
            "; 功能    : 经 ipcBeginProcess 写/删用户级环境变量（HKCU\\Environment），\n" +
            ";           异步不阻塞不等待；errset 包裹，失败仅记日志\n" +
            "; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走\n" +
            ";           setx/reg（与 util_openstudio.il 同款的进程拉起方式）\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _ALG_Setx(name value)\n" +
            "    prog((cid)\n" +
            "        cid = errset(ipcBeginProcess(\"setx\" strcat(name \" \" value) nil nil nil \"\") t)\n" +
            "        unless( cid\n" +
            "            ASTB_LogWarn(strcat(\"allegrolang: setx failed for \" name))\n" +
            "        )\n" +
            "        return( and(cid t) )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_RegDelete(name)\n" +
            "    prog((cid)\n" +
            "        cid = errset(ipcBeginProcess(\"reg\"\n" +
            "            strcat(\"delete HKCU\\\\Environment /v \" name \" /f\") nil nil nil \"\") t)\n" +
            "        unless( cid\n" +
            "            ASTB_LogWarn(strcat(\"allegrolang: reg delete failed for \" name))\n" +
            "        )\n" +
            "        return( and(cid t) )\n" +
            "    )\n" +
            ")\n",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _ALG_WinExe / _ALG_Setx / _ALG_RegDelete\n" +
            "; 功能    : 经 system() 全路径直调 setx/reg 写/删用户级环境变量\n" +
            ";           （HKCU\\Environment），非零返回码记日志\n" +
            "; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走\n" +
            ";           setx/reg；本机 17.4 实机定案：ipcBeginProcess 只建通道\n" +
            ";           不执行进程，system() 全路径可落盘；命令无引号嵌套、\n" +
            ";           路径无空格，避开 pitfalls §6.1 两个 system() 坑\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _ALG_WinExe(name)\n" +
            "    prog((root)\n" +
            "        root = getShellEnvVar(\"SystemRoot\")\n" +
            "        unless( root root = \"C:\\\\Windows\" )\n" +
            "        return( strcat(root \"\\\\System32\\\\\" name) )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_Setx(name value)\n" +
            "    prog((rc)\n" +
            "        rc = system(strcat(_ALG_WinExe(\"setx.exe\") \" \" name \" \" value))\n" +
            "        when( rc != 0\n" +
            "            ASTB_LogWarn(sprintf(nil \"allegrolang: setx %s rc=%d\" name rc))\n" +
            "        )\n" +
            "        return( rc == 0 )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_RegDelete(name)\n" +
            "    prog((rc)\n" +
            "        rc = system(strcat(_ALG_WinExe(\"reg.exe\")\n" +
            "            \" delete HKCU\\\\Environment /v \" name \" /f\"))\n" +
            "        when( rc != 0\n" +
            "            ASTB_LogWarn(sprintf(nil \"allegrolang: reg delete %s rc=%d\" name rc))\n" +
            "        )\n" +
            "        return( rc == 0 )\n" +
            "    )\n" +
            ")\n",
            "system() helpers");

        src = rep(src,
            "            msg = \"Allegro 界面: 已联动为中文（24.1+ 走本地化偏好，17.x 走 intl_enabled），重启 Allegro 生效\"\n",
            "            msg = \"Allegro 界面语言 -> 中文（24.1+ 本地化偏好，17.x intl_enabled），重启 Allegro 生效\"\n",
            "zh msg");

        src = rep(src,
            "            msg = \"Allegro 界面: 已联动为英文（本地化偏好与 intl_enabled 已清除），重启 Allegro 生效\"\n",
            "            msg = \"Allegro 界面语言 -> English（本地化偏好与 intl_enabled 已清除），重启 Allegro 生效\"\n",
            "en msg");

        src = rep(src,
            "printf(\"[ASTB] util_allegrolang.il v1.1 loaded\\n\")\n",
            "printf(\"[ASTB] util_allegrolang.il v1.7 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
