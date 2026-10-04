// ============================================================================
// File        : ProjectsTab.java
// Description : 项目页：projects.json 表格（名称/版本/板子路径/最近打开）+
//               添加（弹版本选择）/移除/编辑/双击打开板子（launch_allegro）/
//               历史/版本路径/重新扫描版本/重载 toolbox/帮助。打开成功后
//               last_opened 更新 + mru 推头（openBoardPath 共享出口）。
// ============================================================================
package astb.studio.ui;

import astb.studio.core.*;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JFileChooser;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.ListSelectionModel;
import javax.swing.table.DefaultTableModel;

public final class ProjectsTab extends JPanel {

    private final MainFrame app;
    private final DefaultTableModel model = new DefaultTableModel(
            new String[] { "名称", "版本", "板子路径", "最近打开" }, 0) {
                @Override public boolean isCellEditable(int r, int c) { return false; }
            };
    private final JTable table = new JTable(model);
    private List<Object> projs = Projects.load();

    public ProjectsTab(MainFrame app) {
        super(new BorderLayout(0, 6));
        this.app = app;
        setBackground(Ui.BG);
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        Ui.styleTable(table);
        table.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override public void mouseClicked(java.awt.event.MouseEvent e) {
                if (e.getClickCount() == 2) openSelected();
            }
        });
        add(new JScrollPane(table), BorderLayout.CENTER);

        JPanel brow = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 0));
        brow.setBackground(Ui.BG);
        Object[][] btns = {
            { "添加…", (Runnable) this::addProject },
            { "移除", (Runnable) this::removeProject },
            { "编辑…", (Runnable) this::editProject },
            { "打开板子", (Runnable) this::openSelected },
            { "历史", (Runnable) this::showHistory },
            { "版本路径…", (Runnable) this::editVersions },
            { "重新扫描版本", (Runnable) this::rescanVersions },
            { "重载 toolbox", (Runnable) this::reloadToolbox },
            { "帮助", (Runnable) this::showHelp },
        };
        for (Object[] b : btns) {
            // 主操作青色圆角钮，其余扁平灰钮
            JButton btn = "打开板子".equals(b[0]) ? Ui.primary((String) b[0])
                                                : Ui.secondary((String) b[0]);
            btn.addActionListener(e -> ((Runnable) b[1]).run());
            brow.add(btn);
        }
        add(brow, BorderLayout.SOUTH);
        reload();
    }

    // ---- helpers ---------------------------------------------------------------------------
    private void reload() {
        projs = Projects.load();
        model.setRowCount(0);
        for (Object o : projs) {
            Map<String, Object> p = MiniJson.obj(o);
            if (p == null) continue;
            model.addRow(new Object[] { MiniJson.getStr(p, "name", ""),
                                        MiniJson.getStr(p, "version", ""),
                                        MiniJson.getStr(p, "brd", ""),
                                        MiniJson.getStr(p, "last_opened", "") });
        }
    }

    private Map<String, Object> selected() {
        int row = table.getSelectedRow();
        if (row < 0 || row >= projs.size()) return null;
        return MiniJson.obj(projs.get(row));
    }

    /** 共享板子打开出口（最近文件页也用）：launch + last_opened/history + mru 推头 */
    public void openBoardPath(String brd, String version) {
        String[] res = Projects.launchAllegro(app.config, brd, version);
        app.log(res[1], "true".equals(res[0]) ? LogPane.OK : LogPane.ERR);
        if (!"true".equals(res[0])) return;
        for (Object o : projs) {
            Map<String, Object> p = MiniJson.obj(o);
            if (p != null && brd.equals(MiniJson.getStr(p, "brd", ""))) {
                p.put("last_opened", Util.nowStamp());
                Projects.logHistory(p, "open", brd);
                Projects.save(projs);
                reload();
                break;
            }
        }
        AppConfig.pushMru(app.config, brd);
        app.saveConfig();
    }

    private void addProject() {
        JFileChooser fc = new JFileChooser();
        fc.setDialogTitle("选择 PCB 板文件");
        fc.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter(
                "Allegro Board (*.brd)", "brd"));
        if (fc.showOpenDialog(this) != JFileChooser.APPROVE_OPTION) return;
        String path = fc.getSelectedFile().getAbsolutePath();
        String detected = Projects.sniffVersion(path);
        // 版本选择（列出注册表键，sniff 命中默认选中）
        List<String> keys = Projects.versionsKeys(app.config);
        String ver = "";
        if (!keys.isEmpty()) {
            String def = Projects.pickVersionDefault(app.config, path);
            Object pick = JOptionPane.showInputDialog(this,
                    "该板子用哪个版本打开：" +
                    (detected.isEmpty() ? "（未识别出版本戳）" : "（识别到 " + detected + "）"),
                    "Allegro 版本", JOptionPane.QUESTION_MESSAGE, null,
                    keys.toArray(), def);
            if (pick == null) return;
            ver = String.valueOf(pick);
        }
        Map<String, Object> p = Projects.add(projs, path, ver, app.config);
        Projects.logHistory(p, "add", "detected=" + (detected.isEmpty() ? "None" : detected));
        Projects.save(projs);
        reload();
        app.log("添加项目：" + MiniJson.getStr(p, "name", "") + "（" +
                MiniJson.getStr(p, "version", "") + "）", LogPane.OK);
    }

    private void removeProject() {
        Map<String, Object> p = selected();
        if (p == null) return;
        String name = MiniJson.getStr(p, "name", "");
        if (!Ui.confirm(this, "从列表移除 " + name + "？（不删文件）", "移除项目")) return;
        projs.remove(table.getSelectedRow());
        Projects.save(projs);
        reload();
        app.log("已移除项目：" + name);
    }

    private void editProject() {
        Map<String, Object> p = selected();
        if (p == null) return;
        JTextField name = new JTextField(MiniJson.getStr(p, "name", ""));
        JTextField ver = new JTextField(MiniJson.getStr(p, "version", ""));
        JTextField note = new JTextField(MiniJson.getStr(p, "note", ""));
        Object[] msg = { MiniJson.getStr(p, "brd", ""), "名称：", name,
                         "版本：", ver, "说明：", note };
        if (JOptionPane.showConfirmDialog(this, msg, "编辑项目",
                JOptionPane.OK_CANCEL_OPTION) != JOptionPane.OK_OPTION)
            return;
        p.put("name", name.getText().trim());
        p.put("version", ver.getText().trim());
        p.put("note", note.getText().trim());
        Projects.logHistory(p, "edit", name.getText().trim() + " / " + ver.getText().trim());
        Projects.save(projs);
        reload();
        app.log("项目已更新：" + name.getText().trim() + "（" + ver.getText().trim() + "）");
    }

    private void openSelected() {
        Map<String, Object> p = selected();
        if (p == null) return;
        openBoardPath(MiniJson.getStr(p, "brd", ""), MiniJson.getStr(p, "version", ""));
    }

    private void showHistory() {
        Map<String, Object> p = selected();
        if (p == null) return;
        StringBuilder text = new StringBuilder();
        List<Object> hist = MiniJson.arr(p.get("history"));
        if (hist != null && !hist.isEmpty()) {
            int start = Math.max(0, hist.size() - 15);
            for (int i = start; i < hist.size(); ++i) {
                Map<String, Object> e = MiniJson.obj(hist.get(i));
                if (e == null) continue;
                text.append(MiniJson.getStr(e, "ts", "")).append("  ")
                    .append(MiniJson.getStr(e, "action", "")).append("  ")
                    .append(MiniJson.getStr(e, "detail", "")).append("\n");
            }
        } else {
            text.append("（无历史记录）");
        }
        Ui.info(this, text.toString());
    }

    private void editVersions() {
        StringBuilder text = new StringBuilder();
        Map<String, Object> vers = MiniJson.obj(app.config.get("versions"));
        if (vers != null)
            for (var e : vers.entrySet())
                text.append(e.getKey()).append('=').append(MiniJson.str(e.getValue(), ""))
                    .append('\n');
        javax.swing.JTextArea area = new javax.swing.JTextArea(text.toString(), 8, 40);
        if (JOptionPane.showConfirmDialog(this, new JScrollPane(area),
                "版本路径（每行一条：版本=allegro.exe 绝对路径）",
                JOptionPane.OK_CANCEL_OPTION) != JOptionPane.OK_OPTION)
            return;
        Map<String, Object> nv = MiniJson.newObj();
        for (String ln : area.getText().split("\n", -1)) {
            ln = Util.trim(ln);
            if (ln.isEmpty() || ln.charAt(0) == ';' || ln.charAt(0) == '#') continue;
            int eq = ln.indexOf('=');
            if (eq < 0) continue;
            String k = Util.trim(ln.substring(0, eq));
            String v = Util.slashes(Util.trim(ln.substring(eq + 1)));
            if (!k.isEmpty() && !v.isEmpty()) nv.put(k, v);
        }
        app.config.put("versions", nv);
        app.saveConfig();
        app.log("版本注册表已更新：" + Projects.versionsKnownList(app.config));
    }

    private void rescanVersions() {
        Map<String, String> found = Projects.autodetectVersions();
        Map<String, Object> vers = Projects.versionsMap(app.config);
        for (var e : found.entrySet()) vers.put(e.getKey(), e.getValue());   // rescan: found wins
        app.saveConfig();
        app.log("版本注册表：" + Projects.versionsKnownList(app.config) +
                (found.isEmpty() ? "（未扫描到新版本）" : "（已合并扫描结果）"));
    }

    private void reloadToolbox() {
        String pid = app.currentTargetPid();
        if (pid.isEmpty()) {
            app.log("请先在“目标”里选定一个在线会话再重载 toolbox", LogPane.WARN);
            return;
        }
        boolean alive = false;
        for (Bridge.Session s : Bridge.sessions())
            if (s.alive && s.pid.equals(pid)) alive = true;
        if (!alive) {
            app.log("目标会话 pid=" + pid + " 不在线，未发送 ASTB_Reload", LogPane.WARN);
            return;
        }
        app.runBridge(List.of("ASTB_Reload()"), pid, ">> ASTB_Reload() -> pid=" + pid);
    }

    private void showHelp() {
        Ui.info(this, "ASTB Studio (Java) 使用速览\n\n" +
                "· 项目：登记 .brd，双击或“打开板子”启动对应版本 Allegro\n" +
                "· 命令面板：ASTB 菜单树，左击按钮直接发到会话执行\n" +
                "· 快捷键：编辑网格后点“应用”写盘并同步会话\n" +
                "· 最近文件：打开过的板子（mru）+ 扫描目录结果，双击重开\n" +
                "· 体检：对目标会话跑板级健康检查\n\n" +
                "桥目录：<TEMP>\\astb_bridge；先启动 Allegro 并加载工具箱。");
    }

    /** 体检存历史（HealthTab 调用）：写入当前选中项目 */
    public boolean storeHealth(String summary) {
        Map<String, Object> p = selected();
        if (p == null) {
            app.log("先在“项目”里选中一个项目再存体检。", LogPane.WARN);
            return false;
        }
        Projects.logHistory(p, "health", summary);
        Projects.save(projs);
        app.log("体检已存入 " + MiniJson.getStr(p, "name", "") + " 历史：" + summary,
                LogPane.OK);
        return true;
    }

    public void onShow() { reload(); }
}
