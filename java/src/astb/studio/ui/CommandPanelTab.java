// ============================================================================
// File        : CommandPanelTab.java
// Description : 命令面板（Python CommandPanel 式）: 搜索框 + 页签条（最近 |
//               各分类 | 自定义Skill）+ 3 列圆角按钮网格（JScrollPane 内
//               GridLayout）。左击=立即运行（MRU 推头）；右击=带参数运行
//               （params.json 模板 + 实时预览 + 保存为模板）。“刷新”有在线
//               会话时先桥发 ASTB_BridgeExportMenuTree() 再读 live。
// ============================================================================
package astb.studio.ui;

import astb.studio.core.*;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.GridLayout;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import javax.swing.table.DefaultTableModel;

public final class CommandPanelTab extends JPanel {

    private final MainFrame app;
    private final JTextField search = new Ui.HintTextField("搜索命令（中文/英文/命令名）…");
    private final JTabbedPane strip = new JTabbedPane();
    private final JPanel gridHolder = new JPanel(new BorderLayout());
    private final JButton refreshBtn = Ui.secondary("刷新");

    private Map<String, Object> data = MiniJson.newObj();
    private int source = MenuTree.SRC_NONE;
    private int lastCount = -1;
    // 分类页: (页签名, [(标签, 命令)])
    private final List<Map.Entry<String, List<String[]>>> cats = new ArrayList<>();
    private final Map<String, String> labelOf = new HashMap<>();

    // skill 页（命令面板同款按钮网格 + “＋ 添加 Skill”幽灵钮，对齐 Python 自定义 Skill 网格）
    private List<Object> skills = Skills.load();

    // 搜索防抖：150ms Swing Timer restart（refillGrid 不再逐键触发）
    private final javax.swing.Timer searchDebounce = new javax.swing.Timer(150, null);
    // 网格滚动容器只建一次，refillGrid 只换内容
    private final JPanel gridWrap = new JPanel(new BorderLayout());
    private final JScrollPane gridScroll;

    public CommandPanelTab(MainFrame app) {
        super(new BorderLayout(0, 6));
        this.app = app;
        setBackground(Ui.BG);
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

        searchDebounce.setRepeats(false);
        searchDebounce.addActionListener(e -> refillGrid());
        search.getDocument().addDocumentListener(new DocumentListener() {
            public void insertUpdate(DocumentEvent e) { searchDebounce.restart(); }
            public void removeUpdate(DocumentEvent e) { searchDebounce.restart(); }
            public void changedUpdate(DocumentEvent e) { searchDebounce.restart(); }
        });

        JPanel topRow = new JPanel(new BorderLayout(6, 0));
        topRow.setBackground(Ui.BG);
        topRow.add(search, BorderLayout.CENTER);
        JPanel stripRow = new JPanel(new BorderLayout(6, 0));
        stripRow.setBackground(Ui.BG);
        stripRow.add(strip, BorderLayout.CENTER);
        // 刷新按钮：FlowLayout 包裹，保持 60x26 顶对齐在页签行右侧，绝不竖向拉伸
        JPanel refreshWrap = new JPanel(new FlowLayout(FlowLayout.RIGHT, 0, 2));
        refreshWrap.setOpaque(false);
        refreshWrap.add(refreshBtn);
        stripRow.add(refreshWrap, BorderLayout.EAST);
        TealTabbedPaneUI.install(strip);   // 页签青色指示条（Python QSS 风）
        // 刷新按钮固定小宽（用户反馈“太长了”）
        refreshBtn.setPreferredSize(new java.awt.Dimension(60, 26));
        refreshBtn.setMaximumSize(new java.awt.Dimension(60, 26));
        JPanel head = new JPanel(new BorderLayout(0, 4));
        head.setBackground(Ui.BG);
        head.add(topRow, BorderLayout.NORTH);
        head.add(stripRow, BorderLayout.CENTER);
        add(head, BorderLayout.NORTH);

        gridWrap.setBackground(java.awt.Color.WHITE);
        gridScroll = new JScrollPane(gridWrap);
        gridScroll.getVerticalScrollBar().setUnitIncrement(16);
        gridHolder.add(gridScroll, BorderLayout.CENTER);
        add(gridHolder, BorderLayout.CENTER);
        refreshBtn.addActionListener(e -> refreshTree());
        strip.addChangeListener(e -> refillGrid());
        reload(false);
    }

    // ---- 数据装配 ----------------------------------------------------------------
    private void rebuildCats() {
        cats.clear();
        labelOf.clear();
        for (Object o : MenuTree.categoryRoots(data)) {
            Map<String, Object> n = MiniJson.obj(o);
            if (n == null || !"popup".equals(MenuTree.nodeType(n))) continue;
            List<String[]> acc = new ArrayList<>();
            MenuTree.collectCommands(MenuTree.children(n), acc);
            if (acc.isEmpty()) continue;
            for (String[] lc : acc)
                if (!lc[1].isEmpty()) labelOf.put(lc[1], lc[0]);
            cats.add(Map.entry(MenuTree.nodeLabel(n), acc));
        }
        // 页签: 最近 | 分类 | 自定义Skill
        int cur = strip.getSelectedIndex();
        strip.removeAll();
        strip.addTab("最近", null);
        for (var e : cats) strip.addTab(e.getKey(), null);
        strip.addTab("自定义Skill", null);
        int max = cats.size() + 1;
        if (cur < 0 || cur > max) cur = 0;
        strip.setSelectedIndex(cur);
    }

    private int skillTabIndex() { return cats.size() + 1; }

    private String needle() { return Util.lower(Util.trim(search.getText())); }

    private void refillGrid() {
        int idx = strip.getSelectedIndex();
        // 只换内容：滚动容器/gridWrap 构造期已建好，这里仅替换网格与空态标签
        gridWrap.removeAll();
        JPanel grid = new JPanel(new GridLayout(0, 3, 6, 6));
        grid.setBackground(java.awt.Color.WHITE);
        grid.setBorder(BorderFactory.createEmptyBorder(6, 8, 6, 8));
        String nd = needle();
        List<String[]> items = new ArrayList<>();
        int cells = 0;
        boolean skillTab = idx == skillTabIndex();

        if (skillTab) {
            // “＋ 添加 Skill”幽灵钮固定第一格（虚线浅色，对齐 Python 的虚线添加钮）
            GhostButton add = new GhostButton("＋ 添加 Skill");
            add.addActionListener(e -> skillAdd());
            grid.add(add);
            ++cells;
            for (String[] it : skillGridItems(skills, nd)) {
                RoundedButton b = new RoundedButton(it[0]);
                b.setFont(Ui.FONT_GRID);
                b.setPreferredSize(new java.awt.Dimension(160, 38));
                b.setToolTipText(it[1] + (it[2].isEmpty() ? "" : "（加载后执行 " + it[2] + "）") +
                                 "（右击：移除）");
                b.addActionListener(e -> skillRun(it));
                b.addMouseListener(new java.awt.event.MouseAdapter() {
                    @Override public void mouseClicked(java.awt.event.MouseEvent e) {
                        if (SwingUtilities.isRightMouseButton(e)) skillRemoveConfirm(it);
                    }
                });
                grid.add(b);
                ++cells;
            }
        } else {
            if (idx == 0) {   // 最近（命令 MRU）：只显示菜单里认识的命令（跳过 brd 路径类）
                for (String cmd : AppConfig.getMru(app.config, 8)) {
                    if (cmd.contains("/") || cmd.contains("\\")) continue;
                    String label = labelOf.getOrDefault(cmd, cmd);
                    if (MenuTree.cmdMatches(nd, label, cmd)) items.add(new String[] { label, cmd });
                }
            } else if (idx >= 1 && idx - 1 < cats.size()) {
                for (String[] lc : cats.get(idx - 1).getValue())
                    if (MenuTree.cmdMatches(nd, lc[0], lc[1])) items.add(lc);
            }
            for (String[] lc : items) {
                RoundedButton b = new RoundedButton(lc[0]);
                b.setFont(Ui.FONT_GRID);   // 网格按钮雅黑 13px
                b.setPreferredSize(new java.awt.Dimension(160, 38));   // 行高收敛（网格密度）
                b.setToolTipText(lc[1] + "（右击：带参数运行）");   // 命令原文 + 右击提示
                String cmd = lc[1];
                b.addActionListener(e -> runCommand(cmd));
                b.addMouseListener(new java.awt.event.MouseAdapter() {
                    @Override public void mouseClicked(java.awt.event.MouseEvent e) {
                        if (SwingUtilities.isRightMouseButton(e)) paramRun(cmd);
                    }
                });
                grid.add(b);
                ++cells;
            }
        }
        // GridLayout 行数自适应：空位补齐防拉伸
        int rows = (cells + 2) / 3;
        for (int i = cells; i < rows * 3; ++i) {
            JLabel pad = new JLabel();
            pad.setOpaque(false);
            grid.add(pad);
        }
        // 顶对齐：网格放 NORTH（保持首选高度从顶部排，不再沉底留大空白）
        gridWrap.add(grid, BorderLayout.NORTH);
        if (!skillTab && items.isEmpty()) {
            // 空态提示（“最近”无 MRU / 搜索无命中）：灰字居中，不留大白板
            JLabel empty = new JLabel(idx == 0 && needle().isEmpty() ? "暂无最近命令"
                                                                      : "无匹配命令",
                                      SwingConstants.CENTER);
            empty.setForeground(Ui.ST_GRAY);
            empty.setFont(Ui.FONT_GRID);
            empty.setBorder(BorderFactory.createEmptyBorder(30, 0, 0, 0));
            gridWrap.add(empty, BorderLayout.CENTER);
        }
        gridWrap.revalidate();
        gridWrap.repaint();
    }

    /** Skill 网格项（纯函数，可测）：[名称, 路径, 启动命令]，按 needle 过滤（小写）。 */
    public static List<String[]> skillGridItems(List<Object> skills, String needleLower) {
        List<String[]> out = new ArrayList<>();
        for (Object o : skills) {
            Map<String, Object> s = MiniJson.obj(o);
            if (s == null) continue;
            String name = MiniJson.getStr(s, "name", "");
            String path = MiniJson.getStr(s, "path", "");
            String cmd = MiniJson.getStr(s, "cmd", "");
            if (needleLower == null || needleLower.isEmpty() ||
                Util.lower(name).contains(needleLower) ||
                Util.lower(path).contains(needleLower) ||
                Util.lower(cmd).contains(needleLower)) {
                out.add(new String[] { name, path, cmd });
            }
        }
        return out;
    }

    /** 幽灵按钮（＋ 添加 Skill）：浅色底 + 青色虚线框 + 青字，与命令按钮区分。 */
    private static final class GhostButton extends RoundedButton {
        GhostButton(String text) {
            super(text);
            setForeground(Ui.ACCENT_TEXT);
        }
        @Override protected java.awt.Color fillColor() {
            return new java.awt.Color(238, 250, 248);
        }
        @Override protected void paintComponent(java.awt.Graphics g) {
            super.paintComponent(g);   // 浅色填充（fillColor 钩子）+ 文字
            java.awt.Graphics2D g2 = (java.awt.Graphics2D) g.create();
            g2.setRenderingHint(java.awt.RenderingHints.KEY_ANTIALIASING,
                                java.awt.RenderingHints.VALUE_ANTIALIAS_ON);
            g2.setColor(Ui.ACCENT);
            g2.setStroke(new java.awt.BasicStroke(
                    1.2f, java.awt.BasicStroke.CAP_BUTT, java.awt.BasicStroke.JOIN_MITER,
                    10f, new float[] { 5f, 4f }, 0f));
            g2.drawRoundRect(1, 1, getWidth() - 3, getHeight() - 3, 12, 12);
            g2.dispose();
        }
    }

    private void reload(boolean verbose) {
        @SuppressWarnings("unchecked")
        Map<String, Object>[] out = new Map[1];
        source = MenuTree.get(out);
        data = out[0];
        int n = MenuTree.countCommands(data);
        rebuildCats();
        refillGrid();
        if (source == MenuTree.SRC_NONE) {
            if (verbose || lastCount != 0)
                app.log("命令面板：无菜单数据（启动 Allegro 后自动刷新）", LogPane.WARN);
        } else if (verbose || n != lastCount) {
            String src = source == MenuTree.SRC_LIVE ? "live（桥目录）" : "cache（本地缓存）";
            String ver = MiniJson.getStr(data, "version", "");
            app.log("命令面板已加载：" + src + (ver.isEmpty() ? "" : "，" + ver) + "，" +
                    cats.size() + " 个分类 / " + n + " 条命令");
        }
        lastCount = n;
    }

    /** 刷新：有在线会话时先桥发 ASTB_BridgeExportMenuTree() 再读 live；无会话只读缓存 */
    private void refreshTree() {
        if (app.isBusy()) {
            app.log("上一个桥任务尚未完成，请稍候", LogPane.WARN);
            return;
        }
        String[] rt = app.resolveTarget();
        if (rt[0] == null) {
            reload(true);
            app.log("target-offline".equals(rt[1]) ? "目标会话不在线，直接重读菜单树"
                                                   : "无在线会话，直接重读缓存菜单树");
            return;
        }
        String exportTarget = rt[0];
        refreshBtn.setEnabled(false);
        app.log(">> 桥请求：ASTB_BridgeExportMenuTree()");
        final String et = exportTarget;
        new Thread(() -> {
            String jobId = Bridge.submitJob(List.of("ASTB_BridgeExportMenuTree()"), et, null);
            boolean ok = false;
            boolean timedOut = false;
            if (!jobId.isEmpty()) {
                Object res = Bridge.waitResult(jobId, 15.0 * app.waitScaleFor(et));
                timedOut = res == null;
                ok = Bridge.resultOk(res);
            }
            final String failMsg = jobId.isEmpty() ? "桥提交失败"
                    : timedOut ? Bridge.timeoutDiagnosis(Bridge.anyAlive(Bridge.sessions()))
                               : "菜单树导出失败";
            final boolean fok = ok;
            SwingUtilities.invokeLater(() -> {
                app.log(fok ? "菜单树已让会话重新导出" : failMsg + "，重读现有 live/缓存",
                        fok ? LogPane.OK : LogPane.WARN);
                reload(true);
                refreshBtn.setEnabled(true);
            });
        }, "astb-mtree").start();
    }

    // ---- 运行 ---------------------------------------------------------------------------
    private boolean checkAlive(String what) {
        if (app.anyAlive()) return true;
        app.log("无在线会话：" + what + " 未运行（先启动 Allegro）", LogPane.WARN);
        return false;
    }

    private static String shellEscape(String line) {
        return line.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    /** 左击 = 立即运行（对齐 Python run_panel_command：MRU 推头 + axlShell） */
    private void runCommand(String cmd) {
        if (!checkAlive(cmd)) return;
        AppConfig.pushMru(app.config, cmd);
        app.saveConfig();
        app.runBridge(List.of("axlShell(\"" + shellEscape(cmd) + "\")"),
                      app.currentTargetPid(), ">> axlShell(\"" + cmd + "\")");
        if (strip.getSelectedIndex() == 0) refillGrid();   // “最近”页即时更新
    }

    private void runComposedLine(String line) {
        if (line.isEmpty()) return;
        if (!checkAlive(line)) return;
        String esc = shellEscape(line);
        app.runBridge(List.of("axlShell(\"" + esc + "\")"), app.currentTargetPid(),
                      ">> axlShell(\"" + esc + "\")");
    }

    // ---- 带参数运行（实时预览 + 保存模板） ---------------------------------------------------
    private void paramRun(String cmd) {
        Map<String, Object> params = Params.load();
        Map<String, Object> spec = MiniJson.obj(params.get(cmd));
        List<String[]> labels = Params.fieldLabels(spec);

        JDialog dlg = new JDialog(app, "带参数运行 - " + cmd, true);
        JPanel body = new JPanel();
        body.setLayout(new BoxLayout(body, BoxLayout.Y_AXIS));
        body.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        List<JTextField> edits = new ArrayList<>();
        if (!labels.isEmpty()) {
            for (String[] lf : labels) {
                JPanel row = new JPanel(new BorderLayout(6, 0));
                row.add(new JLabel(lf[1]), BorderLayout.WEST);
                JTextField e = new JTextField(Params.fieldDefault(spec, lf[0]));
                row.add(e, BorderLayout.CENTER);
                row.setMaximumSize(new java.awt.Dimension(Integer.MAX_VALUE, 26));
                edits.add(e);
                body.add(row);
                body.add(Box.createVerticalStrut(4));
            }
        } else {
            body.add(new JLabel("参数原样拼在命令后面，例如: VIA-60 VIA-80"));
            JTextField e = new JTextField();
            e.setMaximumSize(new java.awt.Dimension(Integer.MAX_VALUE, 26));
            edits.add(e);
            body.add(e);
        }
        // 实时预览
        JTextField preview = new JTextField();
        preview.setBorder(Ui.cardBorder());
        preview.setBackground(java.awt.Color.WHITE);
        preview.setEditable(false);
        JPanel prow = new JPanel(new BorderLayout(6, 0));
        prow.add(new JLabel("预览"), BorderLayout.WEST);
        prow.add(preview, BorderLayout.CENTER);
        body.add(Box.createVerticalStrut(6));
        body.add(prow);

        Runnable updatePreview = () -> {
            if (!labels.isEmpty()) {
                List<String[]> values = new ArrayList<>();
                for (int i = 0; i < labels.size(); ++i)
                    values.add(new String[] { labels.get(i)[0], edits.get(i).getText().trim() });
                preview.setText(Params.render(cmd, spec, values));
            } else {
                preview.setText((cmd + " " + edits.get(0).getText().trim()).trim());
            }
        };
        DocumentListener dl = new DocumentListener() {
            public void insertUpdate(DocumentEvent e) { updatePreview.run(); }
            public void removeUpdate(DocumentEvent e) { updatePreview.run(); }
            public void changedUpdate(DocumentEvent e) { updatePreview.run(); }
        };
        for (JTextField e : edits) e.getDocument().addDocumentListener(dl);
        updatePreview.run();

        JPanel brow = new JPanel(new FlowLayout(FlowLayout.RIGHT, 6, 0));
        JButton saveTpl = Ui.secondary("保存为参数模板");
        JButton go = Ui.primary("运行");
        JButton cancel = Ui.secondary("取消");
        brow.add(saveTpl);
        brow.add(go);
        brow.add(cancel);
        body.add(Box.createVerticalStrut(8));
        body.add(brow);
        dlg.getContentPane().add(body);
        dlg.pack();
        dlg.setSize(460, dlg.getHeight() + 20);
        dlg.setLocationRelativeTo(app);

        saveTpl.addActionListener(e -> {
            if (labels.isEmpty()) {
                Ui.info(dlg, "自由参数模式无需模板。");
                return;
            }
            if (params.containsKey(cmd) &&
                !Ui.confirm(dlg, "命令 " + cmd + " 已有参数模板，覆盖？", "保存为参数模板"))
                return;
            List<String[]> fv = new ArrayList<>();
            for (int i = 0; i < labels.size(); ++i)
                fv.add(new String[] { labels.get(i)[0], edits.get(i).getText().trim() });
            Map<String, Object> ns = Params.buildSpec(fv, MiniJson.getStr(spec, "template", ""));
            params.put(cmd, ns);
            if (Params.save(params)) {
                app.log("参数模板已保存：" + cmd + "（params.json）", LogPane.OK);
                Ui.info(dlg, "已保存。");
            } else {
                app.log("参数模板保存失败：params.json 不可写", LogPane.ERR);
            }
        });
        go.addActionListener(e -> {
            dlg.dispose();
            app.log(">> 带参数运行: " + preview.getText());
            runComposedLine(preview.getText());
        });
        cancel.addActionListener(e -> dlg.dispose());
        dlg.setVisible(true);
    }

    // ---- 自定义Skill（按钮网格交互：左击运行 / 右击移除 / ＋号添加） -----------------------------

    private void skillRun(String[] it) {
        String name = it[0], path = it[1], cmd = it[2];
        if (!checkAlive(name)) return;
        List<String> cmds = new ArrayList<>();
        cmds.add("load(\"" + shellEscape(path) + "\")");
        if (!cmd.isEmpty()) cmds.add("axlShell(\"" + shellEscape(cmd) + "\")");
        app.runBridge(cmds, app.currentTargetPid(),
                      ">> load(\"" + path + "\")" +
                      (cmd.isEmpty() ? "" : " ; axlShell(\"" + cmd + "\")"));
    }

    private void skillAdd() {
        JFileChooser fc = new JFileChooser();
        fc.setDialogTitle("选择 SKILL 文件");
        fc.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter(
                "SKILL 文件 (*.il *.ile)", "il", "ile"));
        if (fc.showOpenDialog(this) != JFileChooser.APPROVE_OPTION) return;
        String path = fc.getSelectedFile().getAbsolutePath();
        JTextField name = new JTextField(Util.stem(path));
        JTextField cmd = new JTextField();
        Object[] msg = { "显示名称：", name, "启动命令（可选，加载后 axlShell 执行）：", cmd };
        if (JOptionPane.showConfirmDialog(this, msg, "添加 Skill",
                JOptionPane.OK_CANCEL_OPTION) != JOptionPane.OK_OPTION)
            return;
        Map<String, Object> s = Skills.add(skills, path, name.getText().trim(),
                                           cmd.getText().trim());
        Skills.save(skills);
        refillGrid();
        String c = MiniJson.getStr(s, "cmd", "");
        app.log("添加 Skill：" + MiniJson.getStr(s, "name", "") + "（" +
                MiniJson.getStr(s, "path", "") + "）" + (c.isEmpty() ? "" : "，启动命令 " + c));
    }

    private void skillRemoveConfirm(String[] it) {
        if (!Ui.confirm(this, "从面板移除 " + it[0] + "？（不删文件）", "移除 Skill")) return;
        for (int i = 0; i < skills.size(); ++i) {
            Map<String, Object> s = MiniJson.obj(skills.get(i));
            if (s != null && it[1].equals(MiniJson.getStr(s, "path", ""))) {
                skills.remove(i);
                break;
            }
        }
        Skills.save(skills);
        refillGrid();
        app.log("已移除 Skill：" + it[0]);
    }

    public void onShow() {
        if (source == MenuTree.SRC_NONE) reload(false);
    }
}
