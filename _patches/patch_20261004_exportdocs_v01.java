/* ============================================================================
 * File        : patch_20261004_exportdocs_v01.java
 * Author      : ASTB Team
 * Created     : 2026-10-04
 * Version     : 1.0
 * Description : 新增 modules/manufacturing/mfg_exportdocs.il v0.1
 *               (PDF/DXF/3D 导出参数基座): payload(UTF-8) 显式转 GBK
 *               落盘 skill_src, 括号平衡/无 CR/GBK 可逆三校验。
 * ============================================================================
 */
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class patch_20261004_exportdocs_v01 {

    static final Charset GBK = Charset.forName("GBK");
    static final Charset UTF8 = Charset.forName("UTF-8");
    static final Path ROOT = Paths.get("G:/ASTB");

    static void checkParen(String tag, String s) {
        int depth = 0; boolean inStr = false, inComment = false, esc = false;
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            if (inComment) { if (ch == '\n') inComment = false; continue; }
            if (inStr) {
                if (esc) esc = false;
                else if (ch == '\\') esc = true;
                else if (ch == '"') inStr = false;
                continue;
            }
            if (ch == '"') inStr = true;
            else if (ch == ';') inComment = true;
            else if (ch == '(') depth++;
            else if (ch == ')') { depth--; if (depth < 0) throw new RuntimeException(tag + " paren NEGATIVE"); }
        }
        if (depth != 0 || inStr) throw new RuntimeException(tag + " UNBALANCED depth=" + depth);
    }

    public static void main(String[] args) throws Exception {
        Path payload = ROOT.resolve("_patches/patch_20261004_exportdocs_v01_payload.il");
        Path dst = ROOT.resolve("skill_src/modules/manufacturing/mfg_exportdocs.il");
        String mod = new String(Files.readAllBytes(payload), UTF8);
        if (mod.indexOf('\r') >= 0) throw new RuntimeException("payload has CR");
        checkParen("module", mod);
        byte[] gbk = mod.getBytes(GBK);
        if (!new String(gbk, GBK).equals(mod)) throw new RuntimeException("GBK roundtrip mismatch");
        Files.write(dst, gbk);
        System.out.println("ALL OK: mfg_exportdocs.il written (GBK, " + gbk.length + " bytes)");
    }
}
