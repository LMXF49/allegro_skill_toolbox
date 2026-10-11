// patch_20261011_menucn_v15.java — util_menucn v1.4 -> v1.5：版本头与加载打印
//（zh->mcnZh 改名已用 Python 完成，本脚本只补版本信息）
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_menucn_v15 {
    public static void main(String[] a) throws Exception {
        Path f = Paths.get("G:\\ASTB\\skill_src\\modules\\utilities\\util_menucn.il");
        Charset GBK = Charset.forName("GBK");
        String s = new String(Files.readAllBytes(f), GBK);
        String[][] rules = {
            {"; 版本      : 1.4\n", "; 版本      : 1.5\n"},
            {"; 修改记录  :\n;   2026-10-11 v1.4 ASTB Team 实机报错修复：prog 变量初始未绑定，\n",
             "; 修改记录  :\n;   2026-10-11 v1.5 ASTB Team 判别实验：模块内 zh 全改名 mcnZh，\n;                区分 unbound 报错来自本模块还是外部回调\n;   2026-10-11 v1.4 ASTB Team 实机报错修复：prog 变量初始未绑定，\n"},
            {"printf(\"[ASTB] util_menucn.il v1.4 loaded\\n\")\n",
             "printf(\"[ASTB] util_menucn.il v1.5 loaded\\n\")\n"},
        };
        for (String[] r : rules) {
            int i = s.indexOf(r[0]);
            if (i < 0) throw new RuntimeException("MISS: " + r[0]);
            s = s.substring(0, i) + r[1] + s.substring(i + r[0].length());
        }
        Files.write(f, s.getBytes(GBK));
        System.out.println("ok");
    }
}
