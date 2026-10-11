// patch_20261011_allegrolang_v13.java
// util_allegrolang.il v1.2 -> v1.3
//   实机报错修复：errset 返回值是 list，cid/rc 需 car 取出后再喂
//   ipcWait/ipcGetExitStatus（v1.2 直接传 list 报 type template "oxx"）。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_allegrolang_v13.java
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_allegrolang_v13 {
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

        src = rep(src, "; 版本      : 1.2\n", "; 版本      : 1.3\n", "version bump");

        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.2 ASTB Team 修复 17.x 切换无效：setx/reg 改 ipc\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.3 ASTB Team 实机报错修复：errset 返回值是 list，\n" +
            ";                cid/rc 先 car 再喂 ipcWait/ipcGetExitStatus（v1.2\n" +
            ";                直接传 list 报 type template \"oxx\"）\n" +
            ";   2026-10-11 v1.2 ASTB Team 修复 17.x 切换无效：setx/reg 改 ipc\n",
            "revision record");

        src = rep(src,
            "procedure( _ALG_RunWait(cmd args)\n" +
            "    prog((cid rc)\n" +
            "        cid = errset(ipcBeginProcess(cmd args nil nil nil \"\") t)\n" +
            "        unless( cid\n" +
            "            ASTB_LogWarn(strcat(\"allegrolang: spawn failed: \" cmd \" \" args))\n" +
            "            return(nil)\n" +
            "        )\n" +
            "        errset(ipcWait(cid 30 1) t)\n",
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
            "        errset(ipcWait(cid 30 1) t)\n",
            "car cid");

        src = rep(src,
            "printf(\"[ASTB] util_allegrolang.il v1.2 loaded\\n\")\n",
            "printf(\"[ASTB] util_allegrolang.il v1.3 loaded\\n\")\n",
            "printf bump");

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);
        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
