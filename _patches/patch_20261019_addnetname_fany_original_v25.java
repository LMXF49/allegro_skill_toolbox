import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetEncoder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class patch_20261019_addnetname_fany_original_v25 {
    private static final Charset GBK = Charset.forName("GBK");
    private static final Path ORIGINAL = Paths.get("D:/Cadence/share/local/pcb/skill/FanySkill/SkillCode/FanySkill_create_net_silk.il");
    private static final Path TARGET = Paths.get("G:/ASTB/skill_src/modules/text/text_addnetname.il");
    private static final Path HELP = Paths.get("G:/ASTB/skill_src/core/help_map.dat");

    private static void require(boolean condition, String message) {
        if (!condition) throw new IllegalStateException(message);
    }

    private static void writeGbk(Path path, String text) throws IOException {
        CharsetEncoder encoder = GBK.newEncoder();
        if (!encoder.canEncode(text)) throw new IllegalStateException(path + ": text is not GBK-encodable");
        Files.write(path, text.getBytes(GBK));
    }

    public static void main(String[] args) throws Exception {
        require(Files.isRegularFile(ORIGINAL), "original FanySkill file not found: " + ORIGINAL);
        String original = new String(Files.readAllBytes(ORIGINAL), GBK);
        int bodyStart = original.indexOf(";;主函数");
        require(bodyStart >= 0, "original body anchor not found: ;;主函数");
        String body = original.substring(bodyStart);

        require(body.contains("procedure(dbCreateNetSilk()"), "original entry procedure not found");
        body = body.replaceFirst("procedure\\(dbCreateNetSilk\\(\\)", "procedure( ASTB_Text_AddNetName()");

        require(body.contains("addr = \"./CreateNetSilk.form\""), "original form path not found");
        body = body.replace("addr = \"./CreateNetSilk.form\"", "addr = \"./ASTB_CreateNetSilk.form\"");

        String header =
            ";========================================================================\n" +
            "; 文件名    : text_addnetname.il\n" +
            "; 作者      : FYNN（原作）；ASTB（工具箱集成）\n" +
            "; 创建日期  : [未知]\n" +
            "; 版本      : 1.25\n" +
            "; 功能描述  : 在指定位置添加网络名称文本，支持交互式拾取管脚/过孔/图形并拖动放置\n" +
            "; 依赖模块  : core（ASTB_RegisterCommand）\n" +
            "; 修改记录  :\n" +
            ";   [原始日期] v1.0 FYNN 初始创建（FanySkill_create_net_silk.il）\n" +
            ";   2026-10-19 v1.25 ASTB 按用户要求回退为 FanySkill 原版表单流程：\n" +
            ";             命令改名 ASTB_Text_AddNetName；临时表单改 ASTB_CreateNetSilk.form；\n" +
            ";             注册改 ASTB_RegisterCommand，保留原版 Done/Oops/Cancel 交互\n" +
            ";========================================================================\n" +
            "\n" +
            ";; ============================================================\n" +
            ";; File: text_addnetname.il\n" +
            ";; Purpose: Add net name\n" +
            ";; Encoding: GBK\n" +
            ";; Source: FanySkill_create_net_silk.il\n" +
            ";; ============================================================\n" +
            "\n" +
            ";--- 全局变量保护（表单句柄/事务标记/放置状态） ---\n" +
            "unless(boundp('_dbCreateNetSilkFinish) _dbCreateNetSilkFinish = nil)\n" +
            "unless(boundp('fm_crtn)                fm_crtn = nil)\n" +
            "unless(boundp('mk_crtn)                mk_crtn = nil)\n" +
            "unless(boundp('_dbCreateNetSilkStage)  _dbCreateNetSilkStage = nil)\n" +
            "\n";

        String registration =
            "\n\n" +
            ";--- ASTB 命令注册：命令名改为 ASTB_Text_AddNetName，交互流程保持原版 ---\n" +
            "ASTB_RegisterCommand(\"ASTB_Text_AddNetName\" \"ASTB_Text_AddNetName\"\n" +
            "    ?cmdType \"interactive\" ?undo nil\n" +
            "    ?doneCmd '_dbCreateNetSilkDone ?cancelCmd '_dbCreateNetSilkCancel)\n" +
            "\n" +
            "printf(\"[ASTB] text_addnetname.il v1.25 loaded (FanySkill original flow).\\n\")\n";

        String updated = header + body.trim() + registration;
        require(updated.contains("procedure( ASTB_Text_AddNetName()"), "renamed entry missing");
        require(updated.contains("addr = \"./ASTB_CreateNetSilk.form\""), "renamed form path missing");
        require(updated.contains("_dbCreatCreateNetSilkForm"), "original form generator missing");
        require(updated.contains("axlMiniStatusLoad"), "original ministatus load missing");
        require(!updated.contains("_TANN_inlineForm"), "stale inline ministatus token remains");
        require(!updated.contains("_TANN_placedBatches"), "stale ASTB undo stack token remains");
        require(!updated.contains("ASTB_RegisterUndo(\"text_addnetname\""), "stale ASTB undo registration remains");
        require(updated.contains("; 版本      : 1.25\n"), "v1.25 header missing");
        writeGbk(TARGET, updated);
        System.out.println("[ok] restored FanySkill original flow as ASTB_Text_AddNetName v1.25");

        String help = new String(Files.readAllBytes(HELP), GBK);
        String prefix = "ASTB_Text_AddNetName|";
        int lineStart = help.indexOf(prefix);
        require(lineStart >= 0, "help map ASTB_Text_AddNetName line not found");
        int lineEnd = help.indexOf('\n', lineStart);
        if (lineEnd < 0) lineEnd = help.length();
        String newLine =
            "ASTB_Text_AddNetName|在版图上添加网络名称文本（点哪个对象就放哪个网名）|①命令弹出选项小表单（层固定丝印顶，可设镜像/角度/字块/对齐）②点选管脚/过孔/铜皮/线段 ③该对象的网络名文本随光标拖动，点击放置 ④可连续放多个，右键 Done 提交/Cancel 回滚/Oops 单步撤销|axlMiniStatusLoad 选项表单（当前目录 ASTB_CreateNetSilk.form）加 axlDBTransactionStart 事务，拾取对象取 net->name 后 axlDBCreateText 加 axlDynamicsObject 拖动放置（modules/text/text_addnetname.il，FanySkill 原版流程）";
        String oldLine = help.substring(lineStart, lineEnd);
        if (!oldLine.equals(newLine)) {
            help = help.substring(0, lineStart) + newLine + help.substring(lineEnd);
            writeGbk(HELP, help);
            System.out.println("[ok] help map updated for original form flow");
        } else {
            System.out.println("[skip] help map already updated");
        }
    }
}
