// ============================================================================
// File        : HelpTab.java
// Description : 帮助页：搜索框（命令/功能/步骤/实现 四段即时过滤，不区分
//               大小写）+ 左侧命令列表 + 右侧详情。清空恢复全表；当前选中
//               不在结果里则改选第一项。
// ============================================================================
package astb.studio.ui;

import astb.studio.core.HelpMap;
import astb.studio.core.Util;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.util.List;
import javax.swing.BorderFactory;
import javax.swing.DefaultListModel;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTextArea;
import javax.swing.ListSelectionModel;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;

public final class HelpTab extends JPanel {

    private final DefaultListModel<String> listModel = new DefaultListModel<>();
    private final JList<String> list = new JList<>(listModel);
    private final javax.swing.JTextPane detail = new javax.swing.JTextPane();
    private final Ui.HintTextField search = new Ui.HintTextField("搜索命令/功能…");
    private final List<HelpMap.Item> items;
    private List<HelpMap.Item> view;
    private final javax.swing.text.Style styleHeading;
    private final javax.swing.text.Style styleBody;
    private final MainFrame app;

    public HelpTab(MainFrame app) {
        super(new BorderLayout());
        this.app = app;
        setBackground(Ui.BG);
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        items = HelpMap.load(app.toolboxRoot);
        view = items;

        list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        list.setFont(Ui.FONT_GRID);   // 左列表 13px
        list.setCellRenderer(new javax.swing.DefaultListCellRenderer() {
            @Override public java.awt.Component getListCellRendererComponent(
                    JList<?> l, Object value, int index, boolean isSelected,
                    boolean cellHasFocus) {
                super.getListCellRendererComponent(l, value, index, isSelected, cellHasFocus);
                setBorder(BorderFactory.createEmptyBorder(5, 8, 5, 8));   // 行高同步加大
                return this;
            }
        });
        list.addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) showItem(list.getSelectedIndex());
        });
        // 左列表右键：先选中该行再弹“复制命令名”（复制命令原文到剪贴板）
        list.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override public void mousePressed(java.awt.event.MouseEvent e) { maybe(e); }
            @Override public void mouseReleased(java.awt.event.MouseEvent e) { maybe(e); }
            private void maybe(java.awt.event.MouseEvent e) {
                if (!e.isPopupTrigger()) return;
                int idx = list.locationToIndex(e.getPoint());
                if (idx < 0) return;
                list.setSelectedIndex(idx);
                javax.swing.JPopupMenu m = new javax.swing.JPopupMenu();
                javax.swing.JMenuItem c = new javax.swing.JMenuItem("复制命令名");
                c.addActionListener(a -> {
                    String cmd = view.get(idx).command;
                    CopyMenu.copy(cmd);
                    app.log("已复制：" + cmd);
                });
                m.add(c);
                m.show(list, e.getX(), e.getY());
            }
        });

        detail.setEditable(false);
        detail.setFont(Ui.FONT_BIG);   // 详情区 14px
        detail.setBorder(Ui.cardBorder());   // 白底卡片感
        detail.setBackground(java.awt.Color.WHITE);
        CopyMenu.attach(detail);   // 右键 复制选中/全部复制/全选（Ctrl+C 原生可用）
        // 样式：加粗小标题（深青）+ 正文行距 0.32 + 段距
        styleHeading = detail.addStyle("heading", null);
        javax.swing.text.StyleConstants.setBold(styleHeading, true);
        javax.swing.text.StyleConstants.setForeground(styleHeading, Ui.ACCENT_TEXT);
        javax.swing.text.StyleConstants.setFontSize(styleHeading, Ui.FONT_BIG.getSize());
        javax.swing.text.StyleConstants.setSpaceAbove(styleHeading, 8f);
        javax.swing.text.StyleConstants.setSpaceBelow(styleHeading, 2f);
        styleBody = detail.addStyle("body", null);
        javax.swing.text.StyleConstants.setFontSize(styleBody, Ui.FONT_BIG.getSize());
        javax.swing.text.StyleConstants.setLineSpacing(styleBody, 0.32f);
        javax.swing.text.StyleConstants.setSpaceBelow(styleBody, 8f);

        search.setFont(Ui.FONT_GRID);   // 搜索框字号同步
        search.getDocument().addDocumentListener(new DocumentListener() {
            public void insertUpdate(DocumentEvent e) { refill(); }
            public void removeUpdate(DocumentEvent e) { refill(); }
            public void changedUpdate(DocumentEvent e) { refill(); }
        });

        JPanel left = new JPanel(new BorderLayout(0, 4));
        left.setBackground(Ui.BG);
        JPanel head = new JPanel(new BorderLayout(0, 4));
        head.setBackground(Ui.BG);
        head.add(new JLabel("命令列表（" + items.size() + " 条）"), BorderLayout.NORTH);
        head.add(search, BorderLayout.CENTER);
        left.add(head, BorderLayout.NORTH);
        left.add(new JScrollPane(list), BorderLayout.CENTER);
        left.setPreferredSize(new Dimension(300, 100));
        JPanel right = new JPanel(new BorderLayout());
        right.add(new JLabel("详情"), BorderLayout.NORTH);
        right.add(new JScrollPane(detail), BorderLayout.CENTER);
        JSplitPane sp = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, left, right);
        sp.setResizeWeight(0.28);
        add(sp, BorderLayout.CENTER);
        app.log("帮助条目：" + items.size() + " 条");
        refill();   // 初始填充（listModel 由 refill 统一维护）
    }

    private String selectedCommand() {
        int i = list.getSelectedIndex();
        return i >= 0 && i < view.size() ? view.get(i).command : "";
    }

    /** 即时过滤：四段包含匹配（不区分大小写）；当前选中不在结果里改选第一项 */
    private void refill() {
        String keep = selectedCommand();
        view = HelpMap.filter(items, Util.lower(Util.trim(search.getText())));
        listModel.clear();
        for (HelpMap.Item it : view) listModel.addElement(it.command);
        int sel = -1;
        for (int i = 0; i < view.size(); ++i)
            if (view.get(i).command.equals(keep)) { sel = i; break; }
        if (sel < 0 && !view.isEmpty()) sel = 0;
        if (sel >= 0) list.setSelectedIndex(sel);
        else detail.setText("");
    }

    private void showItem(int idx) {
        if (idx < 0 || idx >= view.size()) return;
        HelpMap.Item it = view.get(idx);
        javax.swing.text.StyledDocument doc = detail.getStyledDocument();
        try {
            doc.remove(0, doc.getLength());
            doc.insertString(doc.getLength(), "命令：" + it.command + "\n", styleHeading);
            doc.insertString(doc.getLength(), "功能\n", styleHeading);
            doc.insertString(doc.getLength(), it.function + "\n", styleBody);
            doc.insertString(doc.getLength(), "步骤\n", styleHeading);
            doc.insertString(doc.getLength(), it.steps + "\n", styleBody);
            doc.insertString(doc.getLength(), "实现\n", styleHeading);
            doc.insertString(doc.getLength(), it.impl, styleBody);
        } catch (javax.swing.text.BadLocationException ignored) {}
        detail.setCaretPosition(0);
    }
}
