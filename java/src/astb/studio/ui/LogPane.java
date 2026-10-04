// ============================================================================
// File        : LogPane.java
// Description : 日志区：JTextPane 白底卡片边距，按级别着色（深灰/绿/橙/红），
//               时间戳，自动滚底；全部行缓存（5000 条），“全部/警告+/仅错误”
//               过滤切换时重排显示。级别由关键词启发式判定，可显式指定。
//               性能细节：4 级各缓存一个静态 SimpleAttributeSet；用户上翻时
//               不抢滚动（仅滚动条已在底部才自动滚底）。
// ============================================================================
package astb.studio.ui;

import astb.studio.core.Util;
import java.awt.BorderLayout;
import java.awt.Color;
import java.util.ArrayList;
import java.util.List;
import javax.swing.BorderFactory;
import javax.swing.JPanel;
import javax.swing.JScrollBar;
import javax.swing.JScrollPane;
import javax.swing.JTextPane;
import javax.swing.SwingUtilities;
import javax.swing.text.SimpleAttributeSet;
import javax.swing.text.StyleConstants;
import javax.swing.text.StyledDocument;

public final class LogPane extends JPanel {
    public static final int INFO = 0, OK = 1, WARN = 2, ERR = 3;

    private static final class Entry {
        final String line;
        final int level;
        Entry(String l, int lv) { line = l; level = lv; }
    }

    // 4 级各缓存一个静态样式（append 热路径不再逐行 new）
    private static final SimpleAttributeSet[] STYLES = new SimpleAttributeSet[4];

    static {
        Color[] colors = { Ui.LOG_INFO, Ui.LOG_OK, Ui.LOG_WARN, Ui.LOG_ERR };
        for (int i = 0; i < 4; ++i) {
            SimpleAttributeSet as = new SimpleAttributeSet();
            StyleConstants.setForeground(as, colors[i]);
            StyleConstants.setFontFamily(as, Ui.MONO.getFamily());
            StyleConstants.setFontSize(as, Ui.MONO.getSize());
            STYLES[i] = as;
        }
    }

    private final JTextPane pane = new JTextPane();
    private final JScrollPane scroll;
    private final List<Entry> cache = new ArrayList<>();
    private int filter = 0;   // 0=全部 1=警告+ 2=仅错误

    public LogPane() {
        super(new BorderLayout());
        setBackground(Ui.BG);
        setBorder(BorderFactory.createEmptyBorder(0, 8, 6, 8));   // 融入页底
        pane.setEditable(false);
        pane.setFont(Ui.MONO);
        pane.setBackground(Color.WHITE);
        pane.setBorder(Ui.cardBorder());
        scroll = new JScrollPane(pane);
        add(scroll, BorderLayout.CENTER);
    }

    /** 关键词启发式分级（与 C++ 版同一套词表） */
    public static int classify(String s) {
        final String[] err = { "失败", "错误", "无法", "超时", "error" };
        final String[] warn = { "警告", "不在线", "无在线", "未推送", "未写入", "未发送",
                                "未运行", "过期", "跳过" };
        final String[] ok = { "成功", "已写入", "已同步", "已启动", "已加载", "已刷新",
                              "已合并", "OK" };
        for (String k : err) if (s.contains(k)) return ERR;
        for (String k : warn) if (s.contains(k)) return WARN;
        for (String k : ok) if (s.contains(k)) return OK;
        return INFO;
    }

    private boolean passes(int level) {
        if (filter == 1) return level >= WARN;
        if (filter == 2) return level == ERR;
        return true;
    }

    private boolean atBottom() {
        JScrollBar bar = scroll.getVerticalScrollBar();
        return bar.getValue() >= bar.getMaximum() - bar.getVisibleAmount() - 6;
    }

    private void appendColored(String line, int level, boolean scrollEnd) {
        StyledDocument doc = pane.getStyledDocument();
        try {
            doc.insertString(doc.getLength(), line + "\n", STYLES[level]);
            if (scrollEnd) pane.setCaretPosition(doc.getLength());
        } catch (javax.swing.text.BadLocationException ignored) {}
    }

    /** 过滤切换：0 全部 / 1 警告+ / 2 仅错误（缓存重排；caret 只在末尾设一次） */
    public void setFilter(int f) {
        filter = f;
        pane.setText("");
        for (Entry e : cache)
            if (passes(e.level)) appendColored(e.line, e.level, false);
        StyledDocument doc = pane.getStyledDocument();
        pane.setCaretPosition(doc.getLength());
    }

    public void log(String text) { log(text, classify(text)); }

    public void log(String text, int level) {
        String line = "[" + Util.nowHms() + "] " + text;
        Runnable r = () -> {
            cache.add(new Entry(line, level));
            if (cache.size() > 5000) cache.subList(0, 1000).clear();
            // 用户上翻时不抢滚动：仅已在底部才跟随
            if (passes(level) && atBottom()) appendColored(line, level, true);
            else if (passes(level)) appendColored(line, level, false);
        };
        if (SwingUtilities.isEventDispatchThread()) r.run();
        else SwingUtilities.invokeLater(r);
    }
}
