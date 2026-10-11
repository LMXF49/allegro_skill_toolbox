// patch_20261011_allegrolang_v14.java
// util_allegrolang.il v1.3 -> v1.4
//   实机卡死修复：ipcWait/ipcGetExitStatus/ipcReadProcess 在本机会挂住
//   Allegro（切英文卡死）。改为 ipcBeginProcess 直起进程不等待，
//   sleep 后以 reg query 落 log 文件回读验证写入结果（如实报成败）。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_allegrolang_v14.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_allegrolang_v14 {
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

        src = rep(src, "; 版本      : 1.3\n", "; 版本      : 1.4\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.3 ASTB Team 实机报错修复：errset 返回值是 list，\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.4 ASTB Team 实机卡死修复：ipcWait/ipcGetExitStatus\n" +
            ";                本机挂住 Allegro（切英文卡死）；改直起进程不等待，\n" +
            ";                sleep 后 reg query 落 log 回读验证，成败如实返回\n" +
            ";   2026-10-11 v1.3 ASTB Team 实机报错修复：errset 返回值是 list，\n",
            "revision record");

        src = rep(src,
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _ALG_RunWait / _ALG_Setx / _ALG_RegDelete\n" +
            "; 功能    : 经 ipcBeginProcess 四件套（ipcWait+退出码+排空输出）写/删\n" +
            ";           用户级环境变量（HKCU\\Environment），同步等待并回读成败\n" +
            "; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走\n" +
            ";           setx/reg；v1.1 异步起进程实机不落盘（17.4 切换无效根因），\n" +
            ";           v1.2 改四件套同步执行（pitfalls §6.1 标准件）\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _ALG_RunWait(cmd args)\n" +
            "    prog((r cid rc)\n" +
            "        ;; errset 返回值是 list，cid 要 car 出来（v1.2 把 list 直接\n" +
            "        ;; 喂 ipcWait，实机报 type template \"oxx\"）\n" +
            "        r = errset(ipcBeginProcess(cmd args nil nil nil \"\") t)\n" +
            "        unless( and(r car(r))\n" +
            "            ASTB_LogWarn(strcat(\"allegrolang: spawn failed: \" cmd \" \" args))\n" +
            "            return(nil)\n" +
            "        )\n" +
            "        cid = car(r)\n" +
            "        errset(ipcWait(cid 30 1) t)\n" +
            "        rc = errset(ipcGetExitStatus(cid) t)\n" +
            "        errset(ipcReadProcess(cid 1) t)\n" +
            "        unless( and(rc equal(car(rc) 0))\n" +
            "            ASTB_LogWarn(sprintf(nil \"allegrolang: %s %s rc=%L\" cmd args rc))\n" +
            "            return(nil)\n" +
            "        )\n" +
            "        return(t)\n" +
            "    )\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_Setx(name value)\n" +
            "    _ALG_RunWait(\"setx\" strcat(name \" \" value))\n" +
            ")\n" +
            "\n" +
            "procedure( _ALG_RegDelete(name)\n" +
            "    _ALG_RunWait(\"reg\" strcat(\"delete HKCU\\\\Environment /v \" name \" /f\"))\n" +
            ")\n",
            ";------------------------------------------------------------------------\n" +
            "; 函数名  : _ALG_Spawn / _ALG_RegHas / _ALG_Setx / _ALG_RegDelete\n" +
            "; 功能    : 写/删用户级环境变量（HKCU\\Environment）：ipcBeginProcess\n" +
            ";           直起进程不等待（v1.3 的 ipcWait/ipcGetExitStatus 实机把\n" +
            ";           Allegro 卡死），sleep 后用 reg query 落 log 文件回读\n" +
            ";           验证，成败如实返回\n" +
            "; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走\n" +
            ";           setx/reg；errset 返回值是 list，cid 要 car（v1.2 教训）\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _ALG_Spawn(cmd args logF)\n" +
            "    prog((r)\n" +
            "        r = errset(ipcBeginProcess(cmd args nil nil nil logF) t)\n" +
            "        unless( and(r car(r))\n" +
            "            ASTB_LogWarn(strcat(\"allegrolang: spawn failed: \" cmd \" \" args))\n" +
            "            return(nil)\n" +
            "        )\n" +
            "        return(t)\n" +
            "    )\n" +
            ")\n" +
            "\n" +
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
            "spawn+verify");

        src = rep(src,
            "printf(\"[ASTB] util_allegrolang.il v1.3 loaded\\n\")\n",
            "printf(\"[ASTB] util_allegrolang.il v1.4 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
