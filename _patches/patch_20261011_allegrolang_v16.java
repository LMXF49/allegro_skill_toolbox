// patch_20261011_allegrolang_v16.java
// util_allegrolang.il v1.5 -> v1.6
//   用户决策：写盘机制回退 v1.0 形式（ipcBeginProcess 异步直起、
//   不等待不验证、失败仅记日志）。保留唯一修正：exe 全路径
//   （裸命令名实机不起进程）；提示补一行手动兜底命令。
//   入口命令 ASTB_SetAllegroLang*（v1.1 解耦）保持不变。
// GBK 显式往返；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_allegrolang_v16.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_allegrolang_v16 {
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

    // 把 startMark 之前最近的 sep 行 到 endMark 之前最近的 sep 行 之间的内容整体替换
    static String repBetween(String src, String startMark, String endMark, String newS, String tag) {
        String sep = ";------------------------------------------------------------------------\n";
        int s = src.indexOf(startMark);
        int e = src.indexOf(endMark);
        if (s < 0 || e < 0 || e <= s) throw new RuntimeException("ANCHOR MISSING(between): " + tag);
        int sSep = src.lastIndexOf(sep, s);
        int eSep = src.lastIndexOf(sep, e);
        if (sSep < 0 || eSep <= sSep) throw new RuntimeException("SEP MISSING(between): " + tag);
        if (src.substring(sSep, eSep).contains("v1.0 形式")) {
            System.out.println("[skip] " + tag + " (already applied)");
            skipped++;
            return src;
        }
        applied++;
        System.out.println("[ ok ] " + tag);
        return src.substring(0, sSep) + newS + src.substring(eSep);
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

        src = rep(src, "; 版本      : 1.5\n", "; 版本      : 1.6\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.5 ASTB Team 实机不生效修复：裸命令名不起进程\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.6 ASTB Team 用户决策：写盘回退 v1.0 形式\n" +
            ";                （ipcBeginProcess 异步直起，不等待不验证，失败仅\n" +
            ";                记日志）；保留全路径 exe 修正（裸命令名实机不起\n" +
            ";                进程）；提示附手动兜底命令\n" +
            ";   2026-10-11 v1.5 ASTB Team 实机不生效修复：裸命令名不起进程\n",
            "revision record");

        // 助手区整体回退 v1.0 形式（保留 _ALG_WinExe 全路径修正）
        src = repBetween(src,
            "; 函数名  : _ALG_Spawn / _ALG_WinExe / _ALG_BatRun / _ALG_RegQuery /",
            "; 函数名  : ASTB_AllegroLangApply",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _ALG_WinExe / _ALG_Setx / _ALG_RegDelete\n" +
            "; 功能    : 经 ipcBeginProcess 写/删用户级环境变量（HKCU\\Environment），\n" +
            ";           异步不阻塞不等待（v1.0 形式，用户决策回退）；errset\n" +
            ";           包裹，失败仅记日志\n" +
            "; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走\n" +
            ";           setx/reg；exe 用全路径（裸命令名实机不起进程——v1.5\n" +
            ";           取证：reg query 连 log 文件都没生成）\n" +
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
            "    prog((cid)\n" +
            "        cid = errset(ipcBeginProcess(_ALG_WinExe(\"setx.exe\")\n" +
            "            strcat(name \" \" value) nil nil nil \"\") t)\n" +
            "        unless( cid\n" +
            "            ASTB_LogWarn(strcat(\"allegrolang: setx failed for \" name))\n" +
            "        )\n" +
            "        return( and(cid t) )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_RegDelete(name)\n" +
            "    prog((cid)\n" +
            "        cid = errset(ipcBeginProcess(_ALG_WinExe(\"reg.exe\")\n" +
            "            strcat(\"delete HKCU\\\\Environment /v \" name \" /f\") nil nil nil \"\") t)\n" +
            "        unless( cid\n" +
            "            ASTB_LogWarn(strcat(\"allegrolang: reg delete failed for \" name))\n" +
            "        )\n" +
            "        return( and(cid t) )\n" +
            "    )\n" +
            ")\n" +
            "\n",
            "helpers revert v1.0");

        // ASTB_AllegroLangApply 整体回退简洁版
        src = repBetween(src,
            "; 函数名  : ASTB_AllegroLangApply",
            "; 函数名  : ASTB_SetAllegroLanguage",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : ASTB_AllegroLangApply\n" +
            "; 功能    : 设置 Allegro 本体界面语言（持久化设置，重启 Allegro\n" +
            ";           生效；当前会话界面不变）\n" +
            "; 参数    : lang - \"zh-CN\" / \"en\"\n" +
            "; 返回值  : 结果说明（供命令入口弹确认框）\n" +
            "; 备注    : env 偏好与 intl_enabled 两条机制都写（多版本共用 HOME\n" +
            ";           与用户环境变量，各自读各自的）；errset 包裹单项失败\n" +
            ";           不阻断其余\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( ASTB_AllegroLangApply(lang)\n" +
            "    prog((zh msg)\n" +
            "        zh = equal(lang \"zh-CN\")\n" +
            "        if( zh then\n" +
            "            ;; Allegro X 系列：env 偏好（EFF_ONRESTART）\n" +
            "            ;; allegro_english_menu 默认 on 会把菜单锁英文，必须一并摘除\n" +
            "            errset(axlSetVariableFile(\"allegro_enable_localization\" t) t)\n" +
            "            errset(axlUnsetVariableFile(\"allegro_english_menu\") t)\n" +
            "            ;; 17.2/17.4：用户环境变量（Qt 界面部分汉化）\n" +
            "            _ALG_Setx(\"intl_enabled\" \"yes\")\n" +
            "            msg = \"Allegro 界面语言 -> 中文（24.1+ 本地化偏好，17.x intl_enabled），重启 Allegro 生效\"\n" +
            "            msg = strcat(msg \"\\n若重启后 17.x 未生效，请手动执行: setx intl_enabled yes\")\n" +
            "        else\n" +
            "            errset(axlUnsetVariableFile(\"allegro_enable_localization\") t)\n" +
            "            errset(axlUnsetVariableFile(\"allegro_english_menu\") t)\n" +
            "            _ALG_RegDelete(\"intl_enabled\")\n" +
            "            _ALG_RegDelete(\"intl_show_bilingual\")\n" +
            "            msg = \"Allegro 界面语言 -> English（本地化偏好与 intl_enabled 已清除），重启 Allegro 生效\"\n" +
            "        )\n" +
            "        ASTB_LogInfo(strcat(\"allegrolang: applied \" lang))\n" +
            "        ;; 16.6 无官方汉化机制，附注说明\n" +
            "        when( ASTB_IsVersion166()\n" +
            "            msg = strcat(msg \"；当前 16.6 无官方汉化机制，界面保持英文\")\n" +
            "        )\n" +
            "        return(msg)\n" +
            "    )\n" +
            ")\n" +
            "\n",
            "apply revert v1.0");

        src = rep(src,
            "printf(\"[ASTB] util_allegrolang.il v1.5 loaded\\n\")\n",
            "printf(\"[ASTB] util_allegrolang.il v1.6 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
