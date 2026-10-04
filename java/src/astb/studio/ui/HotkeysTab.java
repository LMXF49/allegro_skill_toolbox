// ============================================================================
// File        : HotkeysTab.java
// Description : 快捷键页：JTable 三列（键/命令/说明，双击进入默认编辑器——
//               文本不 trim，空格键直接可敲）。按钮：刷新（有在线会话先桥推
//               flush 再读 dat）/应用（写 dat+桥推 LoadUser+Apply）/添加行/
//               删除行/恢复默认（factory 填表 + live RESTORE）/解绑重置。
//               四条 SKILL 表达式与 Python features.py 逐字一致。
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
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.ListSelectionModel;
import javax.swing.table.DefaultTableModel;

public final class HotkeysTab extends JPanel {

    private final MainFrame app;
    private final DefaultTableModel model =
            new DefaultTableModel(new String[] { "键", "命令", "说明" }, 0) {
                @Override public boolean isCellEditable(int r, int c) { return true; }
            };
    private final JTable table = new JTable(model);
    private int lastCount = -1;

    public HotkeysTab(MainFrame app) {
        super(new BorderLayout(0, 6));
        this.app = app;
        setBackground(Ui.BG);
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

        table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        Ui.styleTable(table);
        table.putClientProperty("terminateEditOnFocusLost", Boolean.TRUE);
        // 单元格编辑器：白底黑字、光标置尾（杜绝全选蓝块观感）
        javax.swing.DefaultCellEditor editor =
                new javax.swing.DefaultCellEditor(new Ui.TailTextField());
        editor.setClickCountToStart(2);
        for (int c = 0; c < 3; ++c) table.getColumnModel().getColumn(c).setCellEditor(editor);
        table.getColumnModel().getColumn(0).setPreferredWidth(90);
        table.getColumnModel().getColumn(1).setPreferredWidth(240);
        table.getColumnModel().getColumn(2).setPreferredWidth(420);
        add(new JScrollPane(table), BorderLayout.CENTER);

        JPanel brow = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 0));
        brow.setBackground(Ui.BG);
        JButton refresh = Ui.secondary("刷新");
        JButton apply = Ui.primary("应用");
        JButton add = Ui.secondary("添加行");
        JButton del = Ui.secondary("删除选中行");
        JButton factory = Ui.secondary("恢复默认");
        JButton reset = Ui.secondary("解绑重置");
        refresh.addActionListener(e -> refresh());
        apply.addActionListener(e -> apply());
        add.addActionListener(e -> addRow());
        del.addActionListener(e -> delRow());
        factory.addActionListener(e -> restoreFactory());
        reset.addActionListener(e -> resetBindings());
        for (JButton b : new JButton[] { refresh, apply, add, del, factory, reset })
            brow.add(b);
        add(brow, BorderLayout.SOUTH);
        reload(true);
    }

    // ---- grid <-> rows ------------------------------------------------------------
    private void fill(List<Hotkeys.Row> rows) {
        model.setRowCount(0);
        for (Hotkeys.Row r : rows) model.addRow(new Object[] { r.key, r.cmd, r.desc });
    }

    /** 收集网格；全空行丢弃。不 trim（空格键纪律）。 */
    private List<Hotkeys.Row> collect() {
        if (table.isEditing()) table.getCellEditor().stopCellEditing();
        List<Hotkeys.Row> rows = new ArrayList<>();
        for (int i = 0; i < model.getRowCount(); ++i) {
            String k = val(i, 0), c = val(i, 1), d = val(i, 2);
            if (k.isEmpty() && c.isEmpty() && d.isEmpty()) continue;
            rows.add(new Hotkeys.Row(k, c, d));
        }
        return rows;
    }

    private String val(int r, int c) {
        Object v = model.getValueAt(r, c);
        return v == null ? "" : String.valueOf(v);
    }

    // ---- 刷新（本地） ------------------------------------------------------------------
    private void reload(boolean verbose) {
        boolean[] fromUser = { false };
        List<Hotkeys.Row> rows = Hotkeys.load(app.toolboxRoot, fromUser);
        fill(rows);
        int n = rows.size();
        if (verbose || n != lastCount) {
            String src = fromUser[0] ? "hotkeys_user.dat" : "hotkeys_factory.dat";
            if (n > 0) app.log("快捷键表：" + n + " 条（" + src + "）");
            else app.log("快捷键表为空：请检查 toolbox_root=" + app.toolboxRoot, LogPane.WARN);
        }
        lastCount = n;
    }

    /** 刷新：有在线会话时先桥推 flush（Allegro 内存表写回 dat）再重读；否则读本地。 */
    private void refresh() {
        if (app.isBusy()) {
            app.log("上一个桥任务尚未完成，请稍候", LogPane.WARN);
            return;
        }
        String[] rt = app.resolveTarget();
        if (rt[0] == null) {
            reload(true);
            if ("target-offline".equals(rt[1]))
                app.log("目标会话不在线，显示本地 dat", LogPane.WARN);
            else
                app.log("无在线会话，显示本地 dat");
            return;
        }
        String flushTarget = rt[0];
        app.log(">> 桥同步：_HotkeyEditor_SaveUser()");
        final String ft = flushTarget;
        new Thread(() -> {
            String jobId = Bridge.submitJob(List.of(Hotkeys.EXPR_FLUSH), ft, null);
            boolean ok = false;
            boolean timedOut = false;
            if (!jobId.isEmpty()) {
                Object res = Bridge.waitResult(jobId, 15.0 * app.waitScaleFor(ft));
                timedOut = res == null;
                ok = Bridge.resultOk(res);
            }
            final String failMsg = jobId.isEmpty() ? "桥提交失败"
                    : timedOut ? Bridge.timeoutDiagnosis(Bridge.anyAlive(Bridge.sessions()))
                               : "会话写 dat 失败";
            final boolean fok = ok;
            javax.swing.SwingUtilities.invokeLater(() -> {
                reload(true);
                app.log(fok ? "已从在线会话同步（dat 已刷新）"
                            : failMsg + "，显示本地 dat",
                        fok ? LogPane.OK : LogPane.WARN);
            });
        }, "astb-hkflush").start();
    }

    // ---- 应用 -----------------------------------------------------------------------------
    private void apply() {
        if (app.isBusy()) {
            app.log("上一个桥任务尚未完成，请稍候", LogPane.WARN);
            return;
        }
        List<Hotkeys.Row> rows = collect();
        if (rows.isEmpty()) {
            app.log("表是空的，未写入", LogPane.WARN);
            return;
        }
        int bad = 0;
        for (Hotkeys.Row r : rows) if (r.key.isEmpty() || r.cmd.isEmpty()) ++bad;
        if (!Hotkeys.save(app.toolboxRoot, rows)) {
            app.log("写入失败：" + Hotkeys.userPath(app.toolboxRoot), LogPane.ERR);
            return;
        }
        app.log("已写入 hotkeys_user.dat：" + rows.size() + " 条" +
                (bad > 0 ? "（警告：" + bad + " 行键或命令为空，重读时会被跳过）" : ""),
                LogPane.OK);
        String[] rt = app.resolveTarget();
        if (rt[0] == null) {
            if ("target-offline".equals(rt[1]))
                app.log("目标会话 pid=" + app.currentTargetPid() + " 不在线，未推送（仅写盘）",
                        LogPane.WARN);
            else
                app.log("无在线会话，未推送（仅写盘）", LogPane.WARN);
            return;
        }
        app.runBridge(List.of(Hotkeys.EXPR_PUSH), rt[0], ">> 桥推送快捷键表");
    }

    private void addRow() {
        // 一键直接插空白行到末尾，并自动进入新行第一列的就地编辑（用户拍板回退：
        // 撤掉上一版的添加对话框）。三列由用户自行编辑；“应用才写盘”语义不变。
        model.addRow(new Object[] { "", "", "" });
        int r = model.getRowCount() - 1;
        table.setRowSelectionInterval(r, r);
        table.scrollRectToVisible(table.getCellRect(r, 0, true));
        table.editCellAt(r, 0);
        java.awt.Component ed = table.getEditorComponent();
        if (ed != null) ed.requestFocusInWindow();
    }

    /** 重复键判定（纯函数，可测）：返回首个同键行号，无则 -1。不 trim。 */
    public static int findKey(List<Hotkeys.Row> rows, String key) {
        for (int i = 0; i < rows.size(); ++i)
            if (rows.get(i).key.equals(key)) return i;
        return -1;
    }

    private void delRow() {
        int r = table.getSelectedRow();
        if (r < 0) {
            app.log("（先选中一行）");
            return;
        }
        if (table.isEditing()) table.getCellEditor().cancelCellEditing();
        model.removeRow(r);
        app.log("已删除行 " + (r + 1) + "（仅网格；点“应用”才落盘）");
    }

    /** 恢复默认：factory 填表不写盘；目标在线时桥推 RESTORE（会话工作表同步恢复
     *  并写回 user.dat，对齐 Python hotkeys_restore_defaults_live） */
    private void restoreFactory() {
        List<Hotkeys.Row> rows = Hotkeys.loadFactory(app.toolboxRoot);
        fill(rows);
        String[] rt = app.resolveTarget();
        if (rt[0] == null) {
            app.log("已载入出厂快捷键表：" + rows.size() +
                    " 条（未写盘；点“应用”写回并同步会话）");
            return;
        }
        app.log("已载入出厂快捷键表：" + rows.size() + " 条，同步恢复会话工作表…");
        app.runBridge(List.of(Hotkeys.EXPR_RESTORE), rt[0], ">> 桥推送恢复默认");
    }

    private void resetBindings() {
        String[] rt = app.resolveTarget();
        if (rt[0] == null) {
            if ("target-offline".equals(rt[1]))
                app.log("目标会话不在线，重置未发送", LogPane.WARN);
            else
                app.log("重置（解绑全部）需要在线会话", LogPane.WARN);
            return;
        }
        if (!Ui.confirm(this, "解绑当前 Allegro 会话里的所有快捷键？\n" +
                              "（只影响运行中的会话，不改任何配置文件）", "重置"))
            return;
        app.runBridge(List.of(Hotkeys.EXPR_RESET), rt[0], ">> 桥推送解绑重置");
    }

    public void onShow() { reload(false); }
}
