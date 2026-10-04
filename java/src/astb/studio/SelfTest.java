// ============================================================================
// File        : SelfTest.java
// Description : Headless module self-checks (run with
//               -Djava.awt.headless=true). Every check prints one line with
//               OK/FAIL; the process exit code is non-zero on any failure.
//               Read-only checks + temp-dir simulations; the one config write
//               test restores byte-identical state afterwards.
// ============================================================================
package astb.studio;

import astb.studio.core.*;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public final class SelfTest {
    private static int failures = 0;

    private static void line(String s) { System.out.println("[selftest] " + s); }
    private static void ok(String name, boolean pass, String detail) {
        line(name + ": " + (pass ? "OK" : "FAIL") + (detail == null || detail.isEmpty() ? "" : " (" + detail + ")"));
        if (!pass) ++failures;
    }

    public static int run() {
        Map<String, Object> cfg = AppConfig.load();
        String root = AppConfig.toolboxRoot(cfg);
        line("config   = " + Util.configPath());
        line("toolbox  = " + root);
        line("bridge   = " + Util.bridgeRoot());

        // sessions 扫描（与 Python 客户端同目录同规则）
        List<Bridge.Session> ss = Bridge.sessions();
        int alive = 0;
        for (Bridge.Session s : ss) if (s.alive) ++alive;
        line("sessions = " + ss.size() + " total, " + alive + " alive");
        for (Bridge.Session s : ss)
            line(String.format("    %s pid=%s version=%s design=%s age=%.1fs",
                               s.alive ? "ALIVE" : "stale", s.pid, s.version, s.design, s.age));

        // skill_escape
        String esc = Bridge.skillEscape("rvia \"x\" 旋转\n");
        ok("skill_escape", esc.equals("rvia \\\"x\\\" \\320\\375\\327\\252\\n"), "<" + esc + ">");

        // job 文件字节级格式（与 Python 产物同构；仅 job_id/生成者注释不同）
        {
            String id = "20260930-000000-abcdef";
            List<String> cmds = List.of(
                    "when(car(errset(_HotkeyEditor_LoadUser() nil)) errset(_HotkeyEditor_Apply() t))");
            String content = Bridge.jobContent(id, "", cmds);
            String[] lines = content.split("\n", -1);
            boolean ok = lines[0].startsWith(";;; ASTB job v1") &&
                         lines[1].equals("ASTB_JOB_ID = \"" + id + "\"") &&
                         lines[2].equals("ASTB_JOB_TARGET = \"\"") &&
                         lines[3].equals("ASTB_JOB_CMDS = list(\"" + cmds.get(0) + "\")") &&
                         content.endsWith(")\n") && isAscii(content);
            ok("job file format", ok, "");
            for (String l : lines) if (!l.isEmpty()) line("    " + l);
            // 中文命令 -> GBK 八进制
            String c2 = Bridge.jobContent(id, "", List.of("axlShell(\"旋转90度\")"));
            ok("job file GBK octal", c2.contains("axlShell(\\\"" +
                       "\\320\\375\\327\\252" + "90\\266\\310" + "\\\")") && isAscii(c2), "");
        }

        // 快捷键 dat 读写往返（空格键）
        {
            List<Hotkeys.Row> rows = new ArrayList<>();
            rows.add(new Hotkeys.Row(" ", "iangle 90", "旋转90度"));
            rows.add(new Hotkeys.Row("F11", "zoom out", "对PCB界面进行放小"));
            String ser = Hotkeys.serialize(rows);
            List<Hotkeys.Row> parsed = Hotkeys.parseText(ser);
            boolean ok = parsed.size() == 2 && parsed.get(0).key.equals(" ") &&
                         parsed.get(0).cmd.equals("iangle 90") &&
                         parsed.get(0).desc.equals("旋转90度") &&
                         parsed.get(1).key.equals("F11") &&
                         new String(ser.getBytes(Util.GBK), Util.GBK).equals(ser);
            ok("hotkeys serialize round-trip (space key)", ok, "");
        }
        boolean[] fromUser = { false };
        List<Hotkeys.Row> hk = Hotkeys.load(root, fromUser);
        // 用户键位文件会随使用增长（自定义加键），只断言用户表生效且不少于工厂数
        ok("hotkeys load effective", hk.size() >= 49 && fromUser[0],
           hk.size() + " rows from " + (fromUser[0] ? "user" : "factory"));
        List<Hotkeys.Row> fac = Hotkeys.loadFactory(root);
        int spaceRows = 0;
        for (Hotkeys.Row r : fac) if (r.key.equals(" ")) ++spaceRows;
        ok("hotkeys factory space-key", fac.size() == 49 && spaceRows == 1,
           "rows=" + fac.size() + " space=" + spaceRows);

        // help_map 解析
        List<HelpMap.Item> help = HelpMap.load(root);
        ok("help_map parse", help.size() >= 70, help.size() + " items");
        ok("helpmap find", help.isEmpty() ||
           (HelpMap.find(help, help.get(0).command) != null &&
            HelpMap.find(help, "__nope__") == null), "");

        // menu_tree 解析 + 分类收集
        @SuppressWarnings("unchecked")
        Map<String, Object>[] mt = new Map[1];
        int src = MenuTree.get(mt);
        int cmds = MenuTree.countCommands(mt[0]);
        int cats = 0;
        for (Object o : MenuTree.categoryRoots(mt[0])) {
            Map<String, Object> n = MiniJson.obj(o);
            if (n != null && "popup".equals(MenuTree.nodeType(n))) ++cats;
        }
        ok("menu_tree parse", src != MenuTree.SRC_NONE && cmds >= 70,
           "source=" + (src == MenuTree.SRC_LIVE ? "live" : src == MenuTree.SRC_CACHE ? "cache" : "none") +
           " commands=" + cmds + " categories=" + cats);
        ok("menu cmd match",
           MenuTree.cmdMatches("hotkey", "快捷键编辑器(&o)", "ASTB_Util_HotkeyEditor") &&
           MenuTree.cmdMatches("旋转", "旋转90度", "ASTB_X") &&
           !MenuTree.cmdMatches("zzz", "abc", "def"), "");

        // mru 推头去重（内存版，不落盘）
        {
            Map<String, Object> c1 = AppConfig.load();
            int before = AppConfig.getMru(c1, Integer.MAX_VALUE).size();
            AppConfig.pushMru(c1, "__selftest_cmd__");
            AppConfig.pushMru(c1, "__selftest_cmd__");
            List<String> mru = AppConfig.getMru(c1, Integer.MAX_VALUE);
            int count = 0;
            for (String s : mru) if (s.equals("__selftest_cmd__")) ++count;
            ok("mru push dedupe",
               !mru.isEmpty() && mru.get(0).equals("__selftest_cmd__") && count == 1 &&
               mru.size() == Math.min(before + 1, 8), "");
        }

        // 参数渲染 + 模板写读往返（临时文件）
        {
            List<String[]> spec = new ArrayList<>();
            spec.add(new String[] { "a", "" });
            spec.add(new String[] { "b", "" });
            Map<String, Object> sp = Params.buildSpec(spec, "");
            Map<String, Object> obj = MiniJson.newObj();
            obj.put("rvia", sp);
            Path tmp = Path.of(System.getProperty("java.io.tmpdir"), "astb_selftest_params.json");
            boolean wok = Params.saveTo(tmp, obj);
            Map<String, Object> back = Params.loadFrom(tmp);
            Map<String, Object> bs = MiniJson.obj(back.get("rvia"));
            String rendered = bs == null ? "" : Params.render("rvia", bs,
                    List.of(new String[] { "a", "VIA-60" }, new String[] { "b", "VIA-80" }));
            boolean ok = wok && bs != null &&
                         "{cmd} {args}".equals(MiniJson.getStr(bs, "template", "")) &&
                         rendered.equals("rvia VIA-60 VIA-80");
            Util.delete(tmp);
            ok("param template write/read round-trip", ok, "rendered=<" + rendered + ">");
            // 无模板渲染
            ok("param render no-spec",
               Params.render("rvia", null, List.of()).equals("rvia"), "");
        }

        // 扫描合并（临时目录）+ mru 优先
        {
            Path base = Path.of(System.getProperty("java.io.tmpdir"), "astb_selftest_scan");
            Util.mkdirs(base);
            Path fresh = base.resolve("fresh.brd");
            Path old = base.resolve("old.brd");
            Util.writeText(fresh, "BRD", Util.GBK);
            Util.writeText(old, "BRD", Util.GBK);
            try {
                java.nio.file.Files.setLastModifiedTime(old,
                        java.nio.file.attribute.FileTime.fromMillis(
                                System.currentTimeMillis() - 200L * 86400_000L));
            } catch (Exception ignored) {}
            List<String[]> scanned = Scanner.scanRecentBoards(List.of(base.toString()), 90, 100);
            String freshSlash = Util.slashes(fresh.toString());
            boolean okScan = scanned.size() == 1 && scanned.get(0)[0].equals(freshSlash);
            List<Scanner.RecentRow> rows = Scanner.mergeRecent(
                    List.of(freshSlash, "ASTB_SomeCommand"), scanned);
            boolean okMerge = rows.size() == 2 && rows.get(0).source.equals("最近") &&
                              rows.get(0).path.equals(freshSlash);
            Util.delete(fresh);
            Util.delete(old);
            try { java.nio.file.Files.delete(base); } catch (Exception ignored) {}
            ok("scan 90d window", okScan, "");
            ok("merge dedupe + mru priority", okMerge, "");
        }

        // 健康解析
        {
            List<String[]> kv = Health.parse(Health.unquote("\"nets=12;design=demo x;empty=;note=\""));
            StringBuilder sb = new StringBuilder();
            for (String[] p : kv) sb.append('[').append(p[0]).append('=').append(p[1]).append(']');
            ok("health parse sample", kv.size() == 4 && kv.get(0)[1].equals("12") &&
               kv.get(1)[1].equals("demo x") && kv.get(2)[1].isEmpty(), sb.toString());
            String cmd = Health.buildCmd();
            ok("health cmd build", cmd.startsWith("progn(s = \"\"") &&
               cmd.contains("version=") && cmd.contains("via_hist=") && cmd.endsWith(" s)"),
               "len=" + cmd.length());
        }

        // 版本探测
        ok("sniff_version(missing)", Projects.sniffVersion("D:/nonexistent.brd").isEmpty(), "");
        ok("version pick default",
           Projects.pickVersionDefault(cfg, "D:/nonexistent.brd")
                   .equals(MiniJson.getStr(cfg, "default_version", "17.4")), "");

        // stale 判定
        {
            long fresh = StaleCheck.toolboxFreshMs(root);
            boolean rule = fresh > 0;
            boolean unknown = StaleCheck.isStale("__no_such_pid__", fresh);
            ok("toolbox fresh + stale logic", rule && !unknown, "fresh=" + fresh);
            for (Bridge.Session s : ss)
                if (s.alive)
                    line("    stale check pid=" + s.pid + " -> " +
                         (StaleCheck.isStale(s.pid, StaleCheck.toolboxFreshMsCached(root)) ? "STALE" : "fresh"));
        }

        // watchdog 迁移
        {
            Watchdog w = new Watchdog();
            w.target = "t1001";
            String lost1 = w.poll(List.of("t1001"));
            String lost2 = w.poll(List.of());
            ok("watchdog migrate", lost1.isEmpty() && lost2.equals("t1001"), "");
        }

        // 16.6 缩放（会话文件模拟）
        {
            Path base = Path.of(System.getProperty("java.io.tmpdir"), "astb_selftest_166");
            Util.mkdirs(base);
            Util.writeText(base.resolve("s_t166.session"),
                           "{\"pid\":\"t166\",\"version\":\"16.6\",\"design\":\"d\"}", Util.GBK);
            List<Bridge.Session> scan = Bridge.sessionsFrom(base, 10.0);
            boolean ok = scan.size() == 1 &&
                         Bridge.waitScaleForVersion(scan.get(0).version) == 2.0 &&
                         Bridge.waitScaleForVersion("17.4-2019 S039") == 1.0;
            Util.delete(base.resolve("s_t166.session"));
            try { java.nio.file.Files.delete(base); } catch (Exception ignored) {}
            ok("16.6 session wait-scale", ok, "");
        }

        // config 未知键保留往返（写后还原）
        {
            Map<String, Object> c1 = AppConfig.load();
            String before = MiniJson.stringify(c1, true);
            Object origMru = c1.get("mru");
            AppConfig.pushMru(c1, "__selftest__/dummy.brd");
            AppConfig.save(c1);
            Map<String, Object> c2 = AppConfig.load();
            List<String> mru = AppConfig.getMru(c2, 8);
            boolean head = !mru.isEmpty() && mru.get(0).equals("__selftest__/dummy.brd");
            c2.put("mru", origMru);
            AppConfig.save(c2);
            Map<String, Object> c3 = AppConfig.load();
            ok("config mru push + exact restore", head &&
               MiniJson.stringify(c3, true).equals(before), "");
        }

        // target 钉住状态机：在/暂时消失/重现 三态迁移
        {
            TargetPin pin = new TargetPin();
            pin.pin("p1");
            pin.refresh(List.of("p1", "p2"));
            boolean s1 = !pin.offline && pin.pid.equals("p1");            // 在：正常项
            pin.refresh(List.of("p2"));
            boolean s2 = pin.offline && pin.pid.equals("p1") &&
                         pin.display().equals("p1（离线）");               // 消失：离线保留不跳走
            pin.refresh(List.of("p9"));
            boolean s3 = pin.offline && pin.pid.equals("p1");             // 持续消失仍钉住
            pin.refresh(List.of("p1", "p2"));
            boolean s4 = !pin.offline && pin.display().equals("p1");      // 重现：自动恢复正常项
            pin.pin("");
            pin.refresh(List.of());
            boolean s5 = !pin.offline && pin.pid.isEmpty();               // 手动切任一：清空
            ok("target pin state machine", s1 && s2 && s3 && s4 && s5, "");
        }

        // target_pid 持久化往返（config 写后还原）
        {
            Map<String, Object> c1 = AppConfig.load();
            String before = MiniJson.stringify(c1, true);
            boolean hadKey = c1.containsKey("target_pid");
            Object orig = c1.get("target_pid");
            c1.put("target_pid", "rSELFTEST");
            AppConfig.save(c1);
            Map<String, Object> c2 = AppConfig.load();
            boolean readBack = "rSELFTEST".equals(MiniJson.getStr(c2, "target_pid", ""));
            if (hadKey) c2.put("target_pid", orig);
            else c2.remove("target_pid");
            AppConfig.save(c2);
            Map<String, Object> c3 = AppConfig.load();
            ok("target_pid persist round-trip", readBack &&
               MiniJson.stringify(c3, true).equals(before), "");
        }

        // 帮助搜索过滤（命中数/不区分大小写/空串恢复）
        {
            boolean f1 = HelpMap.filter(help, "旋转").size() > 0;          // 功能段命中
            boolean f2 = HelpMap.filter(help, "旋转90").size() >= 0;       // 任意子集
            boolean f3 = HelpMap.filter(help, "ASTB").size() >= 70;        // 命令段大写命中（不区分大小写应等同小写）
            boolean f4 = HelpMap.filter(help, "astb").size() == HelpMap.filter(help, "ASTB").size();
            boolean f5 = HelpMap.filter(help, "").size() == help.size();   // 空串恢复全表
            boolean f6 = HelpMap.filter(help, "__zzz_no_such__").isEmpty();// 无命中
            ok("help search filter", f1 && f3 && f4 && f5 && f6,
               "rot=" + HelpMap.filter(help, "旋转").size() +
               " astb=" + HelpMap.filter(help, "astb").size() +
               " all=" + help.size());
        }

        // 超时归因判定（busy vs offline，对齐 Python 客户端语义）
        {
            String busy = Bridge.timeoutDiagnosis(true);
            String offline = Bridge.timeoutDiagnosis(false);
            ok("timeout diagnosis busy/offline",
               busy.contains("会话忙") && offline.contains("桥离线"), "");
        }

        // 条级错误诊断（顶层 ok=true 但 results[i].ok=false）
        {
            Object res = MiniJson.parse(
                "{\"id\":\"j1\",\"pid\":\"p1\",\"design\":\"d\",\"ok\":true,"
                + "\"results\":[{\"i\":0,\"ok\":false,\"value\":\"\","
                + "\"error\":\"eval error (see Allegro command window)\"}],"
                + "\"error\":\"\",\"time\":\"t\"}");
            String errs = Bridge.itemErrors(res);
            String[] item = Bridge.firstItem(res);
            boolean bad = errs.contains("cmd#0") && errs.contains("eval error") &&
                          "false".equals(item[0]) && item[1].contains("eval error") &&
                          item[2].isEmpty();
            Object res2 = MiniJson.parse(
                "{\"ok\":true,\"results\":[{\"i\":0,\"ok\":true,\"value\":\"nets=3;\",\"error\":\"\"}]}");
            boolean good = Bridge.itemErrors(res2).isEmpty() &&
                           "true".equals(Bridge.firstItem(res2)[0]) &&
                           Bridge.firstItem(res2)[2].equals("nets=3;");
            ok("item-level error diagnosis", bad && good, "");
        }

        // 桥 v1.4 busy 标记解析与状态判定（临时目录会话文件）
        {
            Path base = Path.of(System.getProperty("java.io.tmpdir"), "astb_selftest_busy");            Util.mkdirs(base);
            Path b1 = base.resolve("s_b1.session");
            Path b2 = base.resolve("s_b2.session");
            Path b3 = base.resolve("s_b3.session");
            Path b4 = base.resolve("s_b4.session");
            Util.writeText(b1, "{\"pid\":\"b1\",\"version\":\"17.4\",\"design\":\"d\","
                               + "\"busy\":true,\"cmd\":\"rvia test-cmd\",\"since\":\"now\"}",
                           Util.GBK);
            Util.writeText(b2, "{\"pid\":\"b2\",\"version\":\"17.4\",\"design\":\"d\","
                               + "\"busy\":true,\"cmd\":\"long-running-cmd\",\"since\":\"before\"}",
                           Util.GBK);
            Util.writeText(b3, "{\"pid\":\"b3\",\"version\":\"17.4\",\"design\":\"d\","
                               + "\"busy\":true,\"cmd\":\"stuck\",\"since\":\"old\"}", Util.GBK);
            Util.writeText(b4, "{\"pid\":\"b4\",\"version\":\"17.4\",\"design\":\"d\"}", Util.GBK);
            try {
                java.nio.file.Files.setLastModifiedTime(b2,
                        java.nio.file.attribute.FileTime.fromMillis(
                                System.currentTimeMillis() - 20_000L));      // 20s 老化
                java.nio.file.Files.setLastModifiedTime(b3,
                        java.nio.file.attribute.FileTime.fromMillis(
                                System.currentTimeMillis() - 3_600_000L));   // 1h 卡死
            } catch (Exception ignored) {}
            List<Bridge.Session> bss = Bridge.sessionsFrom(base, 10.0);
            Bridge.Session s1 = null, s2 = null, s3 = null, s4 = null;
            for (Bridge.Session s : bss) {
                if (s.pid.equals("b1")) s1 = s;
                else if (s.pid.equals("b2")) s2 = s;
                else if (s.pid.equals("b3")) s3 = s;
                else if (s.pid.equals("b4")) s4 = s;
            }
            boolean ok = s1 != null && s1.busy && s1.cmd.equals("rvia test-cmd") &&
                         s1.effectiveAlive() && !s1.busyTimeout() &&
                         Bridge.statusLabel(s1, false).startsWith("执行中") &&
                         s2 != null && !s2.alive && s2.effectiveAlive() &&
                         !s2.busyTimeout() &&
                         Bridge.statusLabel(s2, false).startsWith("执行中") &&
                         s3 != null && s3.busyTimeout() &&
                         Bridge.statusLabel(s3, false).equals("执行中·超时") &&
                         s4 != null && !s4.busy &&
                         Bridge.statusLabel(s4, false).equals("ALIVE") &&
                         Bridge.anyAlive(bss);
            for (Path f : new Path[] { b1, b2, b3, b4 }) Util.delete(f);
            try { java.nio.file.Files.delete(base); } catch (Exception ignored) {}
            ok("bridge busy marker parse+status", ok,
               "b2.alive=" + (s2 == null ? "?" : s2.alive) +
               " b2.eff=" + (s2 == null ? "?" : s2.effectiveAlive()));
        }

        // pins 探针构造与解析（与 Python 侧逐字节一致由外部 diff 背书）
        {
            String cmd = Health.buildCmd();
            boolean hasPins = cmd.contains("\"PINS\"") && cmd.contains("pins=");
            List<String[]> kv = Health.parse("nets=10;pins=42;vias=7;");
            String pins = "";
            for (String[] p : kv) if (p[0].equals("pins")) pins = p[1];
            ok("health pins probe", hasPins && pins.equals("42"), "len=" + cmd.length());
        }

        // 快捷键重复键判定（纯函数）
        {
            List<Hotkeys.Row> rows = new ArrayList<>();
            rows.add(new Hotkeys.Row("F4", "zoom in", "放大"));
            rows.add(new Hotkeys.Row(" ", "iangle 90", "旋转90度"));
            boolean ok = astb.studio.ui.HotkeysTab.findKey(rows, "F4") == 0 &&
                         astb.studio.ui.HotkeysTab.findKey(rows, " ") == 1 &&
                         astb.studio.ui.HotkeysTab.findKey(rows, "F5") == -1 &&
                         astb.studio.ui.HotkeysTab.findKey(rows, "") == -1;
            ok("hotkeys duplicate-key find", ok, "");
        }

        // 窗口激活脚本构造（Wintop，对齐 Python activate_allegro_window 语义）
        {
            String s1 = Wintop.buildScript("demo174");
            String s2 = Wintop.buildScript("o'x");
            boolean ok = s1.contains("demo174") && s1.contains("allegro") &&
                         s1.contains("SetWindowPos") &&
                         s2.contains("o''x");   // 单引号转义
            ok("wintop script build", ok, "");
        }

        // Skill 网格项装配与过滤（纯函数）
        {
            List<Object> sk = MiniJson.newArr();
            Map<String, Object> a = MiniJson.newObj();
            a.put("name", "rvia");
            a.put("path", "D:/x/rvia.il");
            a.put("cmd", "rvia");
            Map<String, Object> b = MiniJson.newObj();
            b.put("name", "demo2");
            b.put("path", "D:/x/demo2.il");
            b.put("cmd", "");
            sk.add(a);
            sk.add(b);
            List<String[]> all = astb.studio.ui.CommandPanelTab.skillGridItems(sk, "");
            List<String[]> hit = astb.studio.ui.CommandPanelTab.skillGridItems(sk, "rvia");
            List<String[]> none = astb.studio.ui.CommandPanelTab.skillGridItems(sk, "zzz");
            boolean ok = all.size() == 2 && hit.size() == 1 && hit.get(0)[0].equals("rvia") &&
                         none.isEmpty();
            ok("skill grid items filter", ok, "");
        }

        // 会话卡片显示层过滤（visibleSessions：只留"有用"会话）
        {
            Path base = Path.of(System.getProperty("java.io.tmpdir"), "astb_selftest_vis");            Util.mkdirs(base);
            Path fa = base.resolve("s_va.session");
            Path fb = base.resolve("s_vb.session");
            Path fc = base.resolve("s_vc.session");
            Util.writeText(fa, "{\"pid\":\"va\",\"version\":\"17.4\",\"design\":\"d\"}", Util.GBK);
            Util.writeText(fb, "{\"pid\":\"vb\",\"version\":\"17.4\",\"design\":\"d\"}", Util.GBK);
            Util.writeText(fc, "{\"pid\":\"vc\",\"version\":\"17.4\",\"design\":\"d\","
                               + "\"busy\":true,\"cmd\":\"x\",\"since\":\"t\"}", Util.GBK);
            try {   // vb 心跳断 1h（stale 非 busy）；vc busy 老化但 <1800s（执行中）
                java.nio.file.Files.setLastModifiedTime(fb,
                        java.nio.file.attribute.FileTime.fromMillis(
                                System.currentTimeMillis() - 3_600_000L));
                java.nio.file.Files.setLastModifiedTime(fc,
                        java.nio.file.attribute.FileTime.fromMillis(
                                System.currentTimeMillis() - 20_000L));
            } catch (Exception ignored) {}
            List<Bridge.Session> vss = Bridge.sessionsFrom(base, 10.0);
            List<Bridge.Session> vis = Bridge.visibleSessions(vss);
            boolean mixedOk = vss.size() == 3 && vis.size() == 2 &&
                              vis.stream().anyMatch(s -> s.pid.equals("va")) &&
                              vis.stream().anyMatch(s -> s.pid.equals("vc")) &&
                              vis.stream().noneMatch(s -> s.pid.equals("vb"));
            // 全 stale -> 空
            for (Path f : new Path[] { fa, fc }) Util.delete(f);
            List<Bridge.Session> vss2 = Bridge.sessionsFrom(base, 10.0);
            boolean emptyOk = Bridge.visibleSessions(vss2).isEmpty();
            Util.delete(fb);
            try { java.nio.file.Files.delete(base); } catch (Exception ignored) {}
            ok("visible sessions filter", mixedOk && emptyOk,
               "mixed=" + vss.size() + "->" + vis.size());
        }

        // 健康值反转义/清洗（桥 %L 打印的 \" 斜杠值）
        {
            boolean c1 = Health.clean("\\\"17.4\\\"").equals("17.4");
            boolean c2 = Health.clean("\\\"\\\\\\\"mils\\\\\\\"\\\"").equals("mils");
            boolean c3 = Health.clean("\\\"0402:1922  0503:503  \\\"")
                             .equals("0402:1922  0503:503");
            boolean c4 = Health.clean("603").equals("603");
            boolean c5 = Health.clean("旋转90度").equals("旋转90度");
            // 实机抓到的 raw 整体走 parse
            List<String[]> kv = Health.parse(
                "version=\\\"17.4\\\";design=\\\"174\\\";units=\\\"\\\\\\\"mils\\\\\\\"\\\";"
                + "vias=\\\"603\\\";via_hist=\\\"0402:1922  0503:503  \\\";");
            String ver = "", des = "", units = "", hist = "";
            for (String[] p : kv) {
                if (p[0].equals("version")) ver = p[1];
                if (p[0].equals("design")) des = p[1];
                if (p[0].equals("units")) units = p[1];
                if (p[0].equals("via_hist")) hist = p[1];
            }
            boolean c6 = ver.equals("17.4") && des.equals("174") &&
                         units.equals("mils") && hist.equals("0402:1922  0503:503") &&
                         !ver.contains("\\") && !units.contains("\\");
            ok("health value clean/unescape", c1 && c2 && c3 && c4 && c5 && c6,
               "ver=<" + ver + "> units=<" + units + ">");
        }

        // 置顶配置持久化往返 + 托盘菜单规格
        {
            Map<String, Object> c1 = AppConfig.load();
            String before = MiniJson.stringify(c1, true);
            boolean hadKey = c1.containsKey("window_topmost");
            Object orig = c1.get("window_topmost");
            c1.put("window_topmost", Boolean.TRUE);
            AppConfig.save(c1);
            Map<String, Object> c2 = AppConfig.load();
            boolean readBack = MiniJson.bool(c2.get("window_topmost"), false);
            if (hadKey) c2.put("window_topmost", orig);
            else c2.remove("window_topmost");
            AppConfig.save(c2);
            Map<String, Object> c3 = AppConfig.load();
            boolean restored = MiniJson.stringify(c3, true).equals(before);
            List<String[]> spec = astb.studio.ui.MainFrame.trayMenuSpec();
            boolean specOk = spec.size() == 3 &&
                             spec.get(0)[1].equals("show") &&
                             spec.get(1)[1].equals("top") &&
                             spec.get(2)[1].equals("quit");
            ok("window_topmost persist + tray menu spec", readBack && restored && specOk, "");
        }

        // 体检目标闸门：离线目标不提交 job（pidOnline 判定）
        {
            Path base = Path.of(System.getProperty("java.io.tmpdir"), "astb_selftest_gate");
            Util.mkdirs(base);
            Util.writeText(base.resolve("s_g1.session"),
                           "{\"pid\":\"g1\",\"version\":\"17.4\",\"design\":\"d\"}", Util.GBK);
            Util.writeText(base.resolve("s_g2.session"),
                           "{\"pid\":\"g2\",\"version\":\"17.4\",\"design\":\"d\","
                           + "\"busy\":true,\"cmd\":\"x\",\"since\":\"t\"}", Util.GBK);
            try {   // g2 busy（执行中可视）；g3 纯属不存在
                java.nio.file.Files.setLastModifiedTime(base.resolve("s_g2.session"),
                        java.nio.file.attribute.FileTime.fromMillis(
                                System.currentTimeMillis() - 20_000L));
            } catch (Exception ignored) {}
            List<Bridge.Session> gs = Bridge.sessionsFrom(base, 10.0);
            boolean ok = Bridge.pidOnline("g1", gs) &&      // ALIVE 在线
                         Bridge.pidOnline("g2", gs) &&      // busy 执行中算在线
                         !Bridge.pidOnline("g3", gs) &&     // 不存在 -> 离线
                         !Bridge.pidOnline("", gs) &&
                         !Bridge.pidOnline(null, gs);
            Util.delete(base.resolve("s_g1.session"));
            Util.delete(base.resolve("s_g2.session"));
            try { java.nio.file.Files.delete(base); } catch (Exception ignored) {}
            ok("health offline gate (pidOnline)", ok, "");
        }

        line("failures = " + failures);
        return failures == 0 ? 0 : 1;
    }

    private static boolean isAscii(String s) {
        for (char c : s.toCharArray()) if (c >= 128) return false;
        return true;
    }

    private SelfTest() {}
}
