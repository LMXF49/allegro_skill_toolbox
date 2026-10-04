// ============================================================================
// File        : HealthTab.java
// Description : 体检页：对目标会话跑板级健康检查（features.board_health 移植，
//               含 pins 探针）。报告用 JTextPane 重排：标题行加粗深青、字段
//               两列对齐（字段名灰/数值深色加粗）、过孔分布独立段落；顶层
//               ok=true 但条级失败/全空时把 error 原文上屏；formatError/
//               timeoutDiagnosis 错误链路不变。health_auto 勾选时切换目标
//               自动触发一次；成功报告可存入当前选中项目的历史。
// ============================================================================
package astb.studio.ui;

import astb.studio.core.*;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.util.List;
import java.util.Map;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextPane;
import javax.swing.text.SimpleAttributeSet;
import javax.swing.text.StyleConstants;
import javax.swing.text.StyledDocument;

public final class HealthTab extends JPanel {

    private final MainFrame app;
    private final JButton runBtn;
    private final JButton saveBtn = Ui.secondary("存入项目历史");
    private final JCheckBox autoCk = new JCheckBox("切换目标后自动体检");
    private final JTextPane report = new JTextPane();
    private String lastSummary = "";
    private boolean lastOk = false;

    // worker -> EDT 的结果包（成功走 vals 样式渲染，失败走 text 纯文本）
    private static final class HealthResult {
        String text = "";            // 失败/错误文本（formatError/诊断）——默认空串防 NPE
        List<String[]> vals;         // 成功：解析出的 k=v
        String summary = "";
        boolean ok = false;
    }

    public HealthTab(MainFrame app) {
        super(new BorderLayout(0, 6));
        this.app = app;
        setBackground(Ui.BG);
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

        JPanel brow = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 0));
        brow.setBackground(Ui.BG);
        runBtn = Ui.primary("开始体检（使用下方“目标”会话）");
        runBtn.addActionListener(e -> runHealth());
        saveBtn.setEnabled(false);
        saveBtn.addActionListener(e -> {
            if (lastOk) app.storeHealthShared(lastSummary);
        });
        autoCk.setSelected(MiniJson.bool(app.config.get("health_auto"), true));
        autoCk.setBackground(Ui.BG);
        autoCk.addActionListener(e -> {
            app.config.put("health_auto", autoCk.isSelected());
            app.saveConfig();
        });
        brow.add(runBtn);
        brow.add(saveBtn);
        brow.add(autoCk);
        add(brow, BorderLayout.NORTH);

        report.setEditable(false);
        report.setFont(Ui.FONT_GRID);   // 13px
        report.setBorder(Ui.cardBorder());   // 白底卡片感
        report.setBackground(java.awt.Color.WHITE);
        CopyMenu.attach(report);   // 右键 复制选中/全部复制/全选（与帮助详情同行为）
        report.setText("选择目标会话后点“开始体检”");
        add(new JScrollPane(report), BorderLayout.CENTER);
    }

    // ---- 报告渲染（JTextPane 样式） -------------------------------------------------
    private static final String[][] FIELDS = {
        { "版本", "version" }, { "设计", "design" }, { "单位", "units" },
        { "网络", "nets" }, { "过孔", "vias" }, { "元件", "symbols" },
        { "引脚", "pins" }, { "走线", "clines" }, { "铜皮", "shapes" },
        { "DRC", "drcs" },
    };

    private static String valOf(List<String[]> vals, String key) {
        for (String[] kv : vals)
            if (kv[0].equals(key)) return kv[1];
        return "";
    }

    private static SimpleAttributeSet attrs(java.awt.Color fg, boolean bold, int size,
                                            float lineSpacing) {
        SimpleAttributeSet as = new SimpleAttributeSet();
        StyleConstants.setForeground(as, fg);
        StyleConstants.setBold(as, bold);
        StyleConstants.setFontSize(as, size);
        StyleConstants.setLineSpacing(as, lineSpacing);
        return as;
    }

    private void renderReport(List<String[]> vals) {
        StyledDocument doc = report.getStyledDocument();
        int sz = Ui.FONT_GRID.getSize();
        SimpleAttributeSet title = attrs(Ui.ACCENT_TEXT, true, sz + 1, 0.2f);
        SimpleAttributeSet label = attrs(Ui.ST_GRAY, false, sz, 0.25f);
        SimpleAttributeSet value = attrs(new java.awt.Color(30, 30, 30), true, sz, 0.25f);
        SimpleAttributeSet head = attrs(Ui.ACCENT_TEXT, true, sz, 0.25f);
        SimpleAttributeSet body = attrs(new java.awt.Color(50, 50, 50), false, sz, 0.25f);
        try {
            doc.remove(0, doc.getLength());
            doc.insertString(doc.getLength(), "板子体检\n\n", title);
            for (String[] f : FIELDS) {
                String v = valOf(vals, f[1]);
                if ("units".equals(f[1])) {
                    int sp = v.indexOf(' ');
                    if (sp >= 0) v = v.substring(0, sp);
                }
                if (("version".equals(f[1]) || "design".equals(f[1]) || "units".equals(f[1])) &&
                    v.isEmpty())
                    v = "?";
                if (v.isEmpty()) v = "-";
                doc.insertString(doc.getLength(), f[0] + "  ", label);
                doc.insertString(doc.getLength(), v + "\n", value);
            }
            String hist = valOf(vals, "via_hist");
            doc.insertString(doc.getLength(), "\n过孔分布\n", head);
            doc.insertString(doc.getLength(), hist.isEmpty() ? "-" : hist, body);
        } catch (javax.swing.text.BadLocationException ignored) {}
        report.setCaretPosition(0);
    }

    // ---- 体检流程 ---------------------------------------------------------------------
    private void runHealth() {
        String pid = app.currentTargetPid();
        if (pid.isEmpty()) {
            report.setText("请先在“目标”里选定一个在线会话。");
            return;
        }
        if (app.isBusy()) {
            app.log("上一个桥任务尚未完成，请稍候", LogPane.WARN);
            return;
        }
        // 目标离线（含离线钉住）：报告并打日志，不提交 job（健康检查只对在线会话有意义）
        if (!Bridge.pidOnline(pid, app.sessionsSnapshot())) {
            report.setText("目标会话 pid=" + pid + " 不在线，未体检。\n" +
                           "（钉住的会话离线时会保留在 target 列表里，等它重新上线即可）");
            app.log("体检跳过：目标会话 pid=" + pid + " 不在线", LogPane.WARN);
            return;
        }
        runBtn.setEnabled(false);
        report.setText("体检中…");
        app.log(">> 体检（target=" + pid + "）");
        new Thread(() -> {
            HealthResult r = new HealthResult();
            try {
                String jobId = Bridge.submitJob(List.of(Health.buildCmd()), pid, null);
                if (jobId.isEmpty()) {
                    r.text = Health.formatError("无法写 jobs 目录");
                } else {
                    Object res = Bridge.waitResult(jobId, 30.0 * app.waitScaleFor(pid));
                    if (res == null || !Bridge.resultOk(res)) {
                        r.text = Health.formatError(
                                res == null
                                    ? Bridge.timeoutDiagnosis(Bridge.anyAlive(Bridge.sessions()))
                                    : "no result from bridge");
                    } else {
                        String[] item = Bridge.firstItem(res);
                        boolean itemOk = "true".equals(item[0]);
                        String itemErr = item[1];
                        String raw = item[2];
                        List<String[]> vals = Health.parse(raw);   // parse 内逐值 clean（反转义+剥引号）
                        r.vals = vals;
                        r.summary = "vias=" + valOf(vals, "vias") + " nets=" + valOf(vals, "nets") +
                                    " drcs=" + valOf(vals, "drcs");
                        r.ok = true;
                        // 顶层 ok=true 但条级失败/全空报告：把真正的 error 上屏（不再吞掉）
                        boolean allEmpty = vals.isEmpty();
                        if (!allEmpty) {
                            allEmpty = true;
                            for (String[] kv : vals)
                                if (!kv[1].isEmpty()) { allEmpty = false; break; }
                        }
                        if (!itemOk || !itemErr.isEmpty() || allEmpty) {
                            String diag = !itemErr.isEmpty() ? itemErr
                                          : !itemOk ? "探针 eval 失败（results[0].ok=false）"
                                                    : "探针返回为空（报告字段全空）";
                            r.text = diag;   // 复用 text 字段携带诊断（vals 非空时附加渲染）
                            String raw300 = raw.length() > 300 ? raw.substring(0, 300) : raw;
                            app.log("体检探针原始返回前 300 字符: " +
                                    (raw300.isEmpty() ? "（空串）" : raw300), LogPane.WARN);
                        }
                    }
                }
            } catch (Throwable t) {
                // worker 异常兜底：绝不把 null text 交给 EDT
                r.vals = null;
                r.text = Health.formatError("内部异常: " + t);
            }
            final HealthResult fr = r;
            javax.swing.SwingUtilities.invokeLater(() -> {
                if (fr.vals != null) {
                    renderReport(fr.vals);
                    if (fr.text != null && !fr.text.isEmpty()) {
                        // 附加诊断段（vals 已渲染，诊断以纯文本追加显示在日志+报告尾）
                        StyledDocument doc = report.getStyledDocument();
                        SimpleAttributeSet warn = attrs(Ui.LOG_WARN, false,
                                                        Ui.FONT_GRID.getSize(), 0.2f);
                        try {
                            doc.insertString(doc.getLength(),
                                             "\n\n条级错误: " + fr.text +
                                             "\n（同时请看 Allegro 命令窗口的 *Error* 行）",
                                             warn);
                        } catch (javax.swing.text.BadLocationException ignored) {}
                    }
                } else {
                    report.setText(fr.text == null ? "（无结果）" : fr.text);
                }
                lastSummary = fr.summary;
                lastOk = fr.ok;
                saveBtn.setEnabled(fr.ok);
                runBtn.setEnabled(true);
                app.log("体检完成" + (fr.ok ? "" : "（失败）"), fr.ok ? LogPane.OK : LogPane.ERR);
            });
        }, "astb-health").start();
    }

    /** health_auto：目标切换后自动触发一次 */
    public void onTargetChanged() {
        boolean au = MiniJson.bool(app.config.get("health_auto"), true);
        if (!au || app.currentTargetPid().isEmpty() || app.isBusy()) return;
        runHealth();
    }

    public void onShow() {}
}
