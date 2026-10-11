// patch_20261011_allegrolang_v19.java
// util_allegrolang.il v1.8 -> v1.9
//   17.x 机制实机简化（用户实机验证）：intl_enabled 经
//   %HOME%/pcbenv/env 手改区文本增删 set intl_enabled = yes 即生效，
//   拆除 system()/setx/reg/WM_SETTINGCHANGE 广播整条注册表路线。
//   help_map 两条 Allegro UI 条目同步。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_allegrolang_v19.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_allegrolang_v19 {
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

    static String repBetween(String src, String startMark, String endMark, String newS, String tag) {
        String sep = ";------------------------------------------------------------------------\n";
        int s = src.indexOf(startMark);
        int e = src.indexOf(endMark);
        if (s < 0 || e < 0 || e <= s) throw new RuntimeException("ANCHOR MISSING(between): " + tag);
        int sSep = src.lastIndexOf(sep, s);
        int eSep = src.lastIndexOf(sep, e);
        if (sSep < 0 || eSep <= sSep) throw new RuntimeException("SEP MISSING(between): " + tag);
        if (src.substring(sSep, eSep).contains("_ALG_EnvSetIntl")) {
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

        src = rep(src, "; 版本      : 1.8\n", "; 版本      : 1.9\n", "version bump");

        src = rep(src,
            ";             变量 intl_enabled=yes（Qt 面板部分汉化），\n" +
            ";             切回英文时 reg delete 清除；16.6 无官方机制仅提示。\n",
            ";             变量改经 pcbenv env 手改区文本增删 set intl_enabled = yes\n" +
            ";             （Qt 面板部分汉化）；16.6 无官方机制仅提示。\n",
            "header desc");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.8 ASTB Team 切英文不生效修复：reg delete 不广播\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.9 ASTB Team 17.x 机制实机简化（用户实机验证）：\n" +
            ";                intl_enabled 经 pcbenv env 手改区文本增删即生效，\n" +
            ";                拆除 system()/setx/reg/广播整条注册表路线\n" +
            ";   2026-10-11 v1.8 ASTB Team 切英文不生效修复：reg delete 不广播\n",
            "revision record");

        src = repBetween(src,
            "; 函数名  : _ALG_WinExe / _ALG_Setx / _ALG_RegDelete",
            "; 函数名  : ASTB_AllegroLangApply",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _ALG_EnvFile / _ALG_EnvSetIntl\n" +
            "; 功能    : 17.x 界面语言设置：%HOME%/pcbenv/env 手改区文本增删\n" +
            ";           set intl_enabled = yes（用户实机验证此路生效），纯文件\n" +
            ";           读写，重启 Allegro 生效\n" +
            "; 备注    : 替代注册表 setx/reg 路线（本机 ipcBeginProcess 不执行\n" +
            ";           进程、reg delete 不广播环境变更，v1.7/v1.8 已弃）；\n" +
            ";           gets 读行保留 \\n，原样写回\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _ALG_EnvFile()\n" +
            "    prog((home)\n" +
            "        home = getShellEnvVar(\"HOME\")\n" +
            "        unless( home return(nil) )\n" +
            "        return( strcat(home \"/pcbenv/env\") )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_EnvSetIntl(on)\n" +
            "    prog((path port line kept out inserted)\n" +
            "        path = _ALG_EnvFile()\n" +
            "        unless( and(path isFile(path))\n" +
            "            ASTB_LogWarn(\"allegrolang: env file not found\")\n" +
            "            return(nil)\n" +
            "        )\n" +
            "        ;; 读全行并过滤掉已有 intl_enabled 行（幂等）\n" +
            "        port = infile(path)\n" +
            "        unless( port return(nil) )\n" +
            "        while( gets(line port)\n" +
            "            unless( rexMatchp(\"^[ \\t]*set[ \\t]+intl_enabled[ \\t=]\" line)\n" +
            "                kept = nconc(kept list(line))\n" +
            "            )\n" +
            "        )\n" +
            "        close(port)\n" +
            "        ;; 切中文时在 source $TELENV 后补回该行（手改区）\n" +
            "        out = kept\n" +
            "        when( on\n" +
            "            out = nil\n" +
            "            foreach( line kept\n" +
            "                out = nconc(out list(line))\n" +
            "                when( and(not(inserted) rexMatchp(\"^[ \\t]*source[ \\t]+\" line))\n" +
            "                    out = nconc(out list(\"set intl_enabled = yes\\n\"))\n" +
            "                    inserted = t\n" +
            "                )\n" +
            "            )\n" +
            "            unless( inserted\n" +
            "                out = nconc(list(\"set intl_enabled = yes\\n\") kept)\n" +
            "            )\n" +
            "        )\n" +
            "        port = outfile(path)\n" +
            "        unless( port\n" +
            "            ASTB_LogWarn(\"allegrolang: cannot write env\")\n" +
            "            return(nil)\n" +
            "        )\n" +
            "        foreach( line out fprintf(port \"%s\" line) )\n" +
            "        close(port)\n" +
            "        ASTB_LogInfo(sprintf(nil \"allegrolang: env intl_enabled on=%L\" on))\n" +
            "        return(t)\n" +
            "    )\n" +
            ")\n" +
            "\n",
            "env helpers");

        src = rep(src,
            "            ;; 17.2/17.4：用户环境变量（部分汉化；17.4 需 019+ 补丁）\n" +
            "            _ALG_Setx(\"intl_enabled\" \"yes\")\n",
            "            ;; 17.2/17.4：env 手改区写 set intl_enabled = yes（Qt 面板部分汉化）\n" +
            "            _ALG_EnvSetIntl(t)\n",
            "zh branch");

        src = rep(src,
            "            _ALG_RegDelete(\"intl_enabled\")\n" +
            "            _ALG_RegDelete(\"intl_show_bilingual\")\n" +
            "            ;; reg delete 不广播环境变更，补广播刷新 explorer 缓存\n" +
            "            _ALG_BroadcastEnv()\n",
            "            ;; 17.2/17.4：从 env 手改区删除 intl_enabled 行\n" +
            "            _ALG_EnvSetIntl(nil)\n",
            "en branch");

        src = rep(src,
            "printf(\"[ASTB] util_allegrolang.il v1.8 loaded\\n\")\n",
            "printf(\"[ASTB] util_allegrolang.il v1.9 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);

        // ---- help_map.dat 两条 Allegro UI 条目同步 ----
        Path h = Paths.get("G:\\ASTB\\skill_src\\core\\help_map.dat");
        String hs = new String(Files.readAllBytes(h), GBK);
        hs = rep(hs,
            "17.x 删除 intl_enabled 用户环境变量",
            "17.x 从 pcbenv env 手改区删除 intl_enabled 行",
            "help en entry");
        hs = rep(hs,
            "17.x 写 intl_enabled=yes 用户环境变量",
            "17.x 在 pcbenv env 手改区写 set intl_enabled = yes",
            "help zh entry");
        Files.write(h, hs.getBytes(GBK));
        System.out.println("written: " + h);

        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
