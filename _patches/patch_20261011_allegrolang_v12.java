// patch_20261011_allegrolang_v12.java
// util_allegrolang.il v1.1 -> v1.2
//   修复 17.x 语言切换无效根因：setx/reg 由异步 ipcBeginProcess 改为
//   ipc 四件套（ipcWait+ipcGetExitStatus+ipcReadProcess，pitfalls §6.1），
//   同步等待并校验退出码；提示信息逐条如实反映写入成败；
//   17.4 汉化范围勘正为 Qt 界面部分汉化（allegrodict_zh.qm 实体证据）。
//   help_map.dat 两条 Allegro UI 条目同步勘正。
// GBK 显式往返；锚点缺失即中止；幂等可重入。
// 运行：java -Dfile.encoding=UTF-8 _patches/patch_20261011_allegrolang_v12.java
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.*;

public class patch_20261011_allegrolang_v12 {
    static final Charset GBK = Charset.forName("GBK");
    static int applied = 0, skipped = 0;

    static String rep(String src, String oldS, String newS, String tag, boolean all) {
        int oldCount = count(src, oldS);
        if (oldCount == 0) {
            if (src.contains(newS.length() > 60 ? newS.substring(0, 60) : newS)) {
                System.out.println("[skip] " + tag + " (already applied)");
                skipped++;
                return src;
            }
            throw new RuntimeException("ANCHOR MISSING: " + tag);
        }
        if (!all && oldCount != 1)
            throw new RuntimeException("ANCHOR NOT UNIQUE (" + oldCount + "): " + tag);
        applied++;
        System.out.println("[ ok ] " + tag);
        return all ? src.replace(oldS, newS)
                   : src.replaceFirst(java.util.regex.Pattern.quote(oldS),
                                      java.util.regex.Matcher.quoteReplacement(newS));
    }

    static int count(String s, String sub) {
        int n = 0, i = 0;
        while ((i = s.indexOf(sub, i)) >= 0) { n++; i += sub.length(); }
        return n;
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
        Path root = Paths.get("G:\\ASTB\\skill_src");
        Path f = root.resolve("modules\\utilities\\util_allegrolang.il");
        String src = new String(Files.readAllBytes(f), GBK);

        // P1 头部功能描述
        src = rep(src,
            "; 版本      : 1.1\n" +
            "; 功能描述  : Allegro 本体界面语言设置（System->Allegro UI 子菜单\n" +
            ";             独立入口，与工具箱菜单语言切换解耦）：\n" +
            ";             Allegro X（22.1/23.1/24.1/25.1）写 pcbenv env 偏好\n" +
            ";             allegro_enable_localization（开）/ allegro_english_menu\n" +
            ";             （关，其默认 on 会把菜单锁英文）；17.2/17.4 写用户环境\n" +
            ";             变量 intl_enabled=yes（部分汉化，17.4 需 019+ 补丁），\n" +
            ";             切回英文时 reg delete 清除；16.6 无官方机制仅提示。\n",
            "; 版本      : 1.2\n" +
            "; 功能描述  : Allegro 本体界面语言设置（System->Allegro UI 子菜单\n" +
            ";             独立入口，与工具箱菜单语言切换解耦）：\n" +
            ";             Allegro X（22.1/23.1/24.1/25.1）写 pcbenv env 偏好\n" +
            ";             allegro_enable_localization（开）/ allegro_english_menu\n" +
            ";             （关，其默认 on 会把菜单锁英文）；17.2/17.4 写用户环境\n" +
            ";             变量 intl_enabled=yes（Qt 界面部分汉化，字典为\n" +
            ";             share/i18n/dict/allegrodict_zh.qm；经典菜单栏保持英文），\n" +
            ";             切回英文时 reg delete 清除；16.6 无官方机制仅提示。\n",
            "header desc", false);

        // P2 修订记录
        src = rep(src,
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.1 ASTB Team 与工具箱菜单语言切换解耦：新增独立\n",
            "; 修改记录  :\n" +
            ";   2026-10-11 v1.2 ASTB Team 修复 17.x 切换无效：setx/reg 改 ipc\n" +
            ";                四件套（ipcWait+退出码校验，v1.1 异步起进程实机\n" +
            ";                不落盘）；提示逐条如实反映写入成败；汉化范围勘正\n" +
            ";                为 Qt 界面部分汉化（share/i18n/dict/allegrodict_zh.qm）\n" +
            ";   2026-10-11 v1.1 ASTB Team 与工具箱菜单语言切换解耦：新增独立\n",
            "revision record", false);

        // P3 写盘助手改四件套
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
            "; 函数名  : _ALG_RunWait / _ALG_Setx / _ALG_RegDelete\n" +
            "; 功能    : 经 ipcBeginProcess 四件套（ipcWait+退出码+排空输出）写/删\n" +
            ";           用户级环境变量（HKCU\\Environment），同步等待并回读成败\n" +
            "; 备注    : 进程级 setShellEnvVar 不持久化且对当前进程已晚，故走\n" +
            ";           setx/reg；v1.1 异步起进程实机不落盘（17.4 切换无效根因），\n" +
            ";           v1.2 改四件套同步执行（pitfalls §6.1 标准件）\n" +
            ";------------------------------------------------------------------------\n" +
            "procedure( _ALG_RunWait(cmd args)\n" +
            "    prog((cid rc)\n" +
            "        cid = errset(ipcBeginProcess(cmd args nil nil nil \"\") t)\n" +
            "        unless( cid\n" +
            "            ASTB_LogWarn(strcat(\"allegrolang: spawn failed: \" cmd \" \" args))\n" +
            "            return(nil)\n" +
            "        )\n" +
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
            "four-piece ipc", false);

        // P4 ASTB_AllegroLangApply 注释块
        src = rep(src,
            "; 函数名  : ASTB_AllegroLangApply\n" +
            "; 功能    : 按目标语言联动 Allegro 本体界面语言（持久化设置，\n" +
            ";           重启 Allegro 生效；当前会话界面不变）\n" +
            "; 参数    : lang - \"zh-CN\" / \"en\"\n" +
            "; 返回值  : 一行中文结果说明（供 ASTB_SetLanguage 汇总进确认框）\n",
            "; 函数名  : ASTB_AllegroLangApply\n" +
            "; 功能    : 设置 Allegro 本体界面语言（持久化设置，\n" +
            ";           重启 Allegro 生效；当前会话界面不变）\n" +
            "; 参数    : lang - \"zh-CN\" / \"en\"\n" +
            "; 返回值  : 多行中文结果说明（逐条如实反映各机制写入成败）\n",
            "apply comment", false);

        // P5 ASTB_AllegroLangApply 函数体
        src = rep(src,
            "procedure( ASTB_AllegroLangApply(lang)\n" +
            "    prog((zh msg)\n" +
            "        zh = equal(lang \"zh-CN\")\n" +
            "        if( zh then\n" +
            "            ;; Allegro X 系列：env 偏好（EFF_ONRESTART）\n" +
            "            ;; allegro_english_menu 默认 on 会把菜单锁英文，必须一并摘除\n" +
            "            errset(axlSetVariableFile(\"allegro_enable_localization\" t) t)\n" +
            "            errset(axlUnsetVariableFile(\"allegro_english_menu\") t)\n" +
            "            ;; 17.2/17.4：用户环境变量（部分汉化；17.4 需 019+ 补丁）\n" +
            "            _ALG_Setx(\"intl_enabled\" \"yes\")\n" +
            "            msg = \"Allegro 界面: 已联动为中文（24.1+ 走本地化偏好，17.x 走 intl_enabled），重启 Allegro 生效\"\n" +
            "        else\n" +
            "            errset(axlUnsetVariableFile(\"allegro_enable_localization\") t)\n" +
            "            errset(axlUnsetVariableFile(\"allegro_english_menu\") t)\n" +
            "            _ALG_RegDelete(\"intl_enabled\")\n" +
            "            _ALG_RegDelete(\"intl_show_bilingual\")\n" +
            "            msg = \"Allegro 界面: 已联动为英文（本地化偏好与 intl_enabled 已清除），重启 Allegro 生效\"\n" +
            "        )\n" +
            "        ASTB_LogInfo(strcat(\"allegrolang: applied \" lang))\n" +
            "        ;; 16.6 无官方汉化机制，附注说明\n" +
            "        when( ASTB_IsVersion166()\n" +
            "            msg = strcat(msg \"；当前 16.6 无官方汉化机制，界面保持英文\")\n" +
            "        )\n" +
            "        return(msg)\n" +
            "    )\n" +
            ")\n",
            "procedure( ASTB_AllegroLangApply(lang)\n" +
            "    prog((zh okX ok17 msg)\n" +
            "        zh = equal(lang \"zh-CN\")\n" +
            "        if( zh then\n" +
            "            ;; Allegro X 系列：env 偏好（EFF_ONRESTART）\n" +
            "            ;; allegro_english_menu 默认 on 会把菜单锁英文，必须一并摘除\n" +
            "            okX = and( errset(axlSetVariableFile(\"allegro_enable_localization\" t) t)\n" +
            "                       errset(axlUnsetVariableFile(\"allegro_english_menu\") t) )\n" +
            "            ;; 17.2/17.4：用户环境变量（Qt 界面部分汉化）\n" +
            "            ok17 = _ALG_Setx(\"intl_enabled\" \"yes\")\n" +
            "            msg = \"Allegro 界面语言 -> 中文（重启 Allegro 后生效）\\n\"\n" +
            "            if( okX\n" +
            "            then msg = strcat(msg \"  24.1+: 本地化偏好已写入 env\\n\")\n" +
            "            else msg = strcat(msg \"  24.1+: 偏好写入失败，请手动 Setup->Preferences 勾选 Use local language\\n\")\n" +
            "            )\n" +
            "            if( ok17\n" +
            "            then msg = strcat(msg \"  17.2/17.4: intl_enabled=yes 已写入（Qt 界面部分汉化）\\n\")\n" +
            "            else msg = strcat(msg \"  17.x: 写入失败，请手动执行 setx intl_enabled yes\\n\")\n" +
            "            )\n" +
            "        else\n" +
            "            okX = and( errset(axlUnsetVariableFile(\"allegro_enable_localization\") t)\n" +
            "                       errset(axlUnsetVariableFile(\"allegro_english_menu\") t) )\n" +
            "            ok17 = and( _ALG_RegDelete(\"intl_enabled\")\n" +
            "                        _ALG_RegDelete(\"intl_show_bilingual\") )\n" +
            "            msg = \"Allegro 界面语言 -> English（重启 Allegro 后生效）\\n\"\n" +
            "            if( okX\n" +
            "            then msg = strcat(msg \"  24.1+: 本地化偏好已清除\\n\")\n" +
            "            else msg = strcat(msg \"  24.1+: 偏好清除失败，请手动 Setup->Preferences 取消 Use local language\\n\")\n" +
            "            )\n" +
            "            msg = strcat(msg \"  17.x: intl_enabled 已清除\\n\")\n" +
            "        )\n" +
            "        ASTB_LogInfo(sprintf(nil \"allegrolang: applied %s okX=%L ok17=%L\" lang okX ok17))\n" +
            "        ;; 16.6 无官方汉化机制，附注说明\n" +
            "        when( ASTB_IsVersion166()\n" +
            "            msg = strcat(msg \"  当前 16.6 无官方汉化机制，界面保持英文\\n\")\n" +
            "        )\n" +
            "        return(msg)\n" +
            "    )\n" +
            ")\n",
            "apply body", false);

        // P6 load 打印
        src = rep(src,
            "printf(\"[ASTB] util_allegrolang.il v1.1 loaded\\n\")\n",
            "printf(\"[ASTB] util_allegrolang.il v1.2 loaded\\n\")\n",
            "printf bump", false);

        checkParens(src, f);
        Files.write(f, src.getBytes(GBK));
        System.out.println("written: " + f);

        // ---- help_map.dat 两条 Allegro UI 条目勘正 ----
        Path h = root.resolve("core\\help_map.dat");
        String hs = new String(Files.readAllBytes(h), GBK);
        hs = rep(hs,
            "：与工具箱菜单语言切换相互独立；16.6 无官方汉化机制（modules/utilities/util_allegrolang.il）",
            "：与工具箱菜单语言切换相互独立；17.x 为 Qt 界面部分汉化（经典菜单栏除外），16.6 无官方汉化机制（modules/utilities/util_allegrolang.il）",
            "help_map scope fix", true);
        Files.write(h, hs.getBytes(GBK));
        System.out.println("written: " + h);

        System.out.println("DONE applied=" + applied + " skipped=" + skipped);
    }
}
