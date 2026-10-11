// patch_20261011_allegrolang_v15.java
// util_allegrolang.il v1.4 -> v1.5
//   实机取证：reg delete 未执行且 reg query 的 log 文件未生成——
//   裸命令名经 ipcBeginProcess 不起进程（openstudio 成功调法是全路径 exe）。
//   v1.5：一律全路径 %SystemRoot%\System32\{setx,reg,cmd}.exe；
//   直起失败回退 cmd.exe /c bat；回读改三态（present/absent/unknown），
//   log 文件未生成按 unknown 报失败，杜绝假成功。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_allegrolang_v15.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_allegrolang_v15 {
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

        src = rep(src, "; 版本      : 1.4\n", "; 版本      : 1.5\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.4 ASTB Team 实机卡死修复：ipcWait/ipcGetExitStatus\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.5 ASTB Team 实机不生效修复：裸命令名不起进程\n" +
            ";                （reg query 连 log 都没生成），改全路径 System32 exe\n" +
            ";                + cmd.exe /c bat 回退；回读三态杜绝假成功\n" +
            ";   2026-10-11 v1.4 ASTB Team 实机卡死修复：ipcWait/ipcGetExitStatus\n",
            "revision record");

        src = rep(src,
            "; 函数名  : _ALG_Spawn / _ALG_RegHas / _ALG_Setx / _ALG_RegDelete\n" +
            "; 功能    : 写/删用户级环境变量（HKCU\\Environment）：ipcBeginProcess\n" +
            ";           直起进程不等待（v1.3 的 ipcWait/ipcGetExitStatus 实机把\n" +
            ";           Allegro 卡死），sleep 后用 reg query 落 log 文件回读\n" +
            ";           验证，成败如实返回\n" +
            "; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走\n" +
            ";           setx/reg；errset 返回值是 list，cid 要 car（v1.2 教训）\n",
            "; 函数名  : _ALG_Spawn / _ALG_WinExe / _ALG_BatRun / _ALG_RegQuery /\n" +
            ";           _ALG_Setx / _ALG_RegDelete\n" +
            "; 功能    : 写/删用户级环境变量（HKCU\\Environment）：ipcBeginProcess\n" +
            ";           直起进程不等待，sleep 后 reg query 落 log 回读验证；\n" +
            ";           一律全路径调 System32 的 exe（裸命令名不起进程，实机\n" +
            ";           取证 reg query 连 log 都没生成；openstudio 成功调法即\n" +
            ";           全路径），直起失败回退 cmd.exe /c bat 再来一次\n" +
            "; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走\n" +
            ";           setx/reg；errset 返回值是 list，cid 要 car（v1.2 教训）\n",
            "block comment");

        src = rep(src,
            "procedure( _ALG_RegHas(name)\n" +
            "    prog((tmp logF port line found)\n" +
            "        tmp = getShellEnvVar(\"TEMP\")\n" +
            "        unless( tmp tmp = \"C:\\\\Windows\\\\Temp\" )\n" +
            "        logF = strcat(tmp \"\\\\astb_alg_regquery.log\")\n" +
            "        when( isFile(logF) deleteFile(logF) )\n" +
            "        unless( _ALG_Spawn(\"reg\" strcat(\"query HKCU\\\\Environment /v \" name) logF)\n" +
            "            return(nil)\n" +
            "        )\n" +
            "        sleep(2)\n" +
            "        found = nil\n" +
            "        when( isFile(logF)\n" +
            "            port = infile(logF)\n" +
            "            when( port\n" +
            "                while( gets(line port)\n" +
            "                    when( rexMatchp(\"REG_SZ\" line) found = t )\n" +
            "                )\n" +
            "                close(port)\n" +
            "            )\n" +
            "        )\n" +
            "        return(found)\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_Setx(name value)\n" +
            "    prog((ok)\n" +
            "        ok = _ALG_Spawn(\"setx\" strcat(name \" \" value) \"\")\n" +
            "        unless( ok return(nil) )\n" +
            "        sleep(1)\n" +
            "        return( _ALG_RegHas(name) )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_RegDelete(name)\n" +
            "    prog((ok)\n" +
            "        ok = _ALG_Spawn(\"reg\" strcat(\"delete HKCU\\\\Environment /v \" name \" /f\") \"\")\n" +
            "        unless( ok return(nil) )\n" +
            "        sleep(1)\n" +
            "        return( not(_ALG_RegHas(name)) )\n" +
            "    )\n" +
            ")\n",
            "procedure( _ALG_WinExe(name)\n" +
            "    prog((root)\n" +
            "        root = getShellEnvVar(\"SystemRoot\")\n" +
            "        unless( root root = \"C:\\\\Windows\" )\n" +
            "        return( strcat(root \"\\\\System32\\\\\" name) )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_BatRun(line)\n" +
            "    prog((tmp batF port)\n" +
            "        tmp = getShellEnvVar(\"TEMP\")\n" +
            "        unless( tmp tmp = \"C:\\\\Windows\\\\Temp\" )\n" +
            "        batF = strcat(tmp \"\\\\astb_alg.bat\")\n" +
            "        port = outfile(batF)\n" +
            "        unless( port\n" +
            "            ASTB_LogWarn(\"allegrolang: cannot write bat fallback\")\n" +
            "            return(nil)\n" +
            "        )\n" +
            "        fprintf(port \"%s\\n\" line)\n" +
            "        close(port)\n" +
            "        return( _ALG_Spawn(_ALG_WinExe(\"cmd.exe\") strcat(\"/c \" batF) \"\") )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "; 回读三态：present=值在 / absent=log 有且值不在 / unknown=没起进程\n" +
            "procedure( _ALG_RegQuery(name)\n" +
            "    prog((tmp logF port line found)\n" +
            "        tmp = getShellEnvVar(\"TEMP\")\n" +
            "        unless( tmp tmp = \"C:\\\\Windows\\\\Temp\" )\n" +
            "        logF = strcat(tmp \"\\\\astb_alg_regquery.log\")\n" +
            "        when( isFile(logF) deleteFile(logF) )\n" +
            "        unless( _ALG_Spawn(_ALG_WinExe(\"reg.exe\") strcat(\"query HKCU\\\\Environment /v \" name) logF)\n" +
            "            return('unknown)\n" +
            "        )\n" +
            "        sleep(2)\n" +
            "        unless( isFile(logF)\n" +
            "            ASTB_LogWarn(\"allegrolang: reg query no log, process not running\")\n" +
            "            return('unknown)\n" +
            "        )\n" +
            "        found = nil\n" +
            "        port = infile(logF)\n" +
            "        when( port\n" +
            "            while( gets(line port)\n" +
            "                when( rexMatchp(\"REG_SZ\" line) found = t )\n" +
            "            )\n" +
            "            close(port)\n" +
            "        )\n" +
            "        return( if(found then 'present else 'absent) )\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_Setx(name value)\n" +
            "    prog((ok)\n" +
            "        _ALG_Spawn(_ALG_WinExe(\"setx.exe\") strcat(name \" \" value) \"\")\n" +
            "        sleep(1)\n" +
            "        ok = eq(_ALG_RegQuery(name) 'present)\n" +
            "        unless( ok\n" +
            "            _ALG_BatRun(strcat(\"setx \" name \" \" value))\n" +
            "            sleep(1)\n" +
            "            ok = eq(_ALG_RegQuery(name) 'present)\n" +
            "        )\n" +
            "        return(ok)\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_RegDelete(name)\n" +
            "    prog((ok)\n" +
            "        _ALG_Spawn(_ALG_WinExe(\"reg.exe\") strcat(\"delete HKCU\\\\Environment /v \" name \" /f\") \"\")\n" +
            "        sleep(1)\n" +
            "        ok = eq(_ALG_RegQuery(name) 'absent)\n" +
            "        unless( ok\n" +
            "            _ALG_BatRun(strcat(\"reg delete HKCU\\\\Environment /v \" name \" /f\"))\n" +
            "            sleep(1)\n" +
            "            ok = eq(_ALG_RegQuery(name) 'absent)\n" +
            "        )\n" +
            "        return(ok)\n" +
            "    )\n" +
            ")\n",
            "fullpath+bat+3state");

        src = rep(src,
            "printf(\"[ASTB] util_allegrolang.il v1.4 loaded\\n\")\n",
            "printf(\"[ASTB] util_allegrolang.il v1.5 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
