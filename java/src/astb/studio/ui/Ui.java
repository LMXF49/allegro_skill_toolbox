// ============================================================================
// File        : Ui.java
// Description : Shared UI constants/helpers: 全站色板（近白底 + 青系强调，
//               对齐 Python QSS）、字体回退链、JTable 统一造型（行高/斑马纹/
//               浅青选中/6px 内边距）、扁平灰钮、占位提示输入框、圆角浅边框、
//               卡片式文本区边框、状态圆点图标。
// ============================================================================
package astb.studio.ui;

import java.awt.Color;
import java.awt.Component;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.GraphicsEnvironment;
import java.awt.RenderingHints;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.UIManager;
import javax.swing.border.Border;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.JTableHeader;

public final class Ui {
    private Ui() {}

    // 全站色板（与 C++ 审美轮一致）
    public static final Color BG = new Color(250, 250, 250);        // 全局底色
    public static final Color ACCENT = new Color(47, 191, 174);     // #2fbfae 强调
    public static final Color ACCENT_TEXT = new Color(20, 120, 110);
    public static final Color BTN_NORMAL = new Color(0x39, 0xc5, 0xbb);  // 网格按钮三态
    public static final Color BTN_HOT = new Color(0x5a, 0xdf, 0xd5);
    public static final Color BTN_DOWN = new Color(0x25, 0xa2, 0x95);
    public static final Color BTN_TEXT = new Color(0x06, 0x32, 0x2e);
    public static final Color ST_GREEN = new Color(0, 150, 70);     // 会话状态（圆点/字色）
    public static final Color ST_ORANGE = new Color(220, 120, 0);
    public static final Color ST_GRAY = new Color(130, 130, 130);
    // 日志级别色（评审单定值）
    public static final Color LOG_INFO = new Color(60, 60, 60);
    public static final Color LOG_OK = new Color(0, 140, 60);
    public static final Color LOG_WARN = new Color(215, 110, 0);
    public static final Color LOG_ERR = new Color(200, 30, 30);
    // 表格/边框
    public static final Color GRID = new Color(230, 230, 230);
    public static final Color SEL_BG = new Color(220, 245, 242);    // 选中行浅青底
    public static final Color SEL_FG = new Color(20, 60, 56);
    public static final Color ZEBRA = new Color(248, 248, 248);     // 隔行近白
    public static final Color HDR_BG = new Color(240, 240, 240);    // 表头浅灰底
    public static final Color LINE = new Color(210, 210, 210);      // 浅边框
    public static final Color HINT = new Color(150, 150, 150);      // 占位提示灰字
    // 扁平次要按钮
    public static final Color FLAT_BG = new Color(238, 238, 238);
    public static final Color FLAT_HOT = new Color(224, 224, 224);
    public static final Color FLAT_DOWN = new Color(208, 208, 208);
    public static final Color FLAT_TEXT = new Color(50, 50, 50);
    public static final Color FLAT_DISABLED_BG = new Color(244, 244, 244);
    // 渲染路径复用的常量（避免每帧 new）
    public static final Border ZEBRA_CELL_BORDER = BorderFactory.createEmptyBorder(0, 6, 0, 6);
    public static final Border HEADER_BORDER = BorderFactory.createCompoundBorder(
            BorderFactory.createMatteBorder(0, 0, 1, 1, LINE),
            BorderFactory.createEmptyBorder(2, 6, 2, 6));

    // ---- 字体（雅黑优先，取不到回退 SansSerif） ----------------------------------------
    public static final Font FONT = pickFont(12);
    public static final Font FONT_BOLD = pickFontBold(12);
    public static final Font FONT_GRID = pickFont(13);
    public static final Font FONT_BIG = pickFont(14);
    public static final Font FONT_BIG_BOLD = pickFontBold(14);
    public static final Font MONO = new Font("Consolas", Font.PLAIN, 12);

    private static boolean hasFamily(String name) {
        for (String f : GraphicsEnvironment.getLocalGraphicsEnvironment()
                        .getAvailableFontFamilyNames())
            if (f.equalsIgnoreCase(name)) return true;
        return false;
    }

    private static Font pickFont(int size) {
        return new Font(hasFamily("Microsoft YaHei UI") ? "Microsoft YaHei UI" : "SansSerif",
                        Font.PLAIN, size);
    }

    private static Font pickFontBold(int size) {
        return new Font(hasFamily("Microsoft YaHei UI") ? "Microsoft YaHei UI" : "SansSerif",
                        Font.BOLD, size);
    }

    // ---- 边框 ---------------------------------------------------------------
    /** 输入框：1px 浅灰线框 + 内边距 4,8,4,8（圆角感由线框色弱化表达） */
    public static Border inputBorder() {
        return BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(LINE, 1),
                BorderFactory.createEmptyBorder(4, 8, 4, 8));
    }

    /** 卡片式文本区（帮助详情/体检报告/预览）：1px 浅灰边框 + 8px 内边距 + 白底 */
    public static Border cardBorder() {
        return BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(LINE, 1),
                BorderFactory.createEmptyBorder(8, 8, 8, 8));
    }

    // ---- 按钮体系 -----------------------------------------------------------
    /** 主操作：青色圆角按钮（应用/打开板子/开始体检/运行类） */
    public static JButton primary(String text) { return new RoundedButton(text); }

    /** 次要操作：扁平灰钮（浅色底 + 深灰字、hover 变深、去金属感） */
    public static JButton secondary(String text) {
        JButton b = new JButton(text) {
            @Override protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                                    RenderingHints.VALUE_ANTIALIAS_ON);
                Color fill = FLAT_BG;
                if (!isEnabled()) fill = FLAT_DISABLED_BG;
                else if (getModel().isPressed() || getModel().isArmed()) fill = FLAT_DOWN;
                else if (getModel().isRollover()) fill = FLAT_HOT;
                g2.setColor(fill);
                g2.fillRoundRect(0, 0, getWidth(), getHeight(), 8, 8);
                g2.dispose();
                super.paintComponent(g);
            }
        };
        b.setContentAreaFilled(false);
        b.setFocusPainted(false);
        b.setBorderPainted(false);
        b.setOpaque(false);
        b.setForeground(FLAT_TEXT);
        b.setFont(FONT);
        b.setBorder(BorderFactory.createEmptyBorder(5, 12, 5, 12));
        return b;
    }

    // ---- JTable 统一造型 --------------------------------------------------------
    public static void styleTable(JTable table) {
        table.setRowHeight(24);
        table.setShowGrid(true);
        table.setGridColor(GRID);
        table.setSelectionBackground(SEL_BG);
        table.setSelectionForeground(SEL_FG);
        table.setIntercellSpacing(new java.awt.Dimension(1, 1));
        table.setDefaultRenderer(Object.class, new ZebraRenderer());
        JTableHeader header = table.getTableHeader();
        header.setDefaultRenderer(new HeaderRenderer(header.getDefaultRenderer()));
        header.setReorderingAllowed(false);
    }

    /** 斑马纹 + 单元格 6px 内边距 + 浅青选中 */
    public static class ZebraRenderer extends DefaultTableCellRenderer {
        @Override public Component getTableCellRendererComponent(
                JTable table, Object value, boolean isSelected, boolean hasFocus,
                int row, int column) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
            setBorder(ZEBRA_CELL_BORDER);
            if (!isSelected) setBackground(row % 2 == 0 ? Color.WHITE : ZEBRA);
            return this;
        }
    }

    /** 表头：半粗 + 浅灰底 + 6px 内边距 */
    private static final class HeaderRenderer extends DefaultTableCellRenderer {
        private final javax.swing.table.TableCellRenderer inner;
        HeaderRenderer(javax.swing.table.TableCellRenderer inner) { this.inner = inner; }
        @Override public Component getTableCellRendererComponent(
                JTable table, Object value, boolean isSelected, boolean hasFocus,
                int row, int column) {
            Component c = inner.getTableCellRendererComponent(table, value, isSelected,
                                                              hasFocus, row, column);
            if (c instanceof JLabel) {
                JLabel l = (JLabel) c;
                l.setFont(FONT_BOLD);
                l.setBackground(HDR_BG);
                l.setBorder(HEADER_BORDER);
                l.setOpaque(true);
            }
            return c;
        }
    }

    // ---- 占位提示输入框（Swing 无原生 placeholder，自绘灰字提示） --------------------------
    public static class HintTextField extends JTextField {
        private final String hint;
        public HintTextField(String hint) {
            this.hint = hint;
            setBorder(inputBorder());
            setBackground(Color.WHITE);
        }
        public HintTextField(String hint, int columns) {
            this(hint);
            setColumns(columns);
        }
        @Override protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            if (getText().isEmpty() && !isFocusOwner()) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                                    RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
                g2.setColor(HINT);
                g2.setFont(getFont());
                var fm = g2.getFontMetrics();
                int y = (getHeight() + fm.getAscent() - fm.getDescent()) / 2;
                g2.drawString(hint, 9, y);
                g2.dispose();
            }
        }
    }

    /** 编辑框光标置尾的文本框（杜绝“全选蓝块”观感：编辑开始即 caret=末尾） */
    public static class TailTextField extends JTextField {
        public TailTextField() {
            setBorder(inputBorder());
            setBackground(Color.WHITE);
            setForeground(new Color(20, 20, 20));
        }
        @Override public void addNotify() {
            super.addNotify();
            javax.swing.SwingUtilities.invokeLater(
                    () -> setCaretPosition(getText().length()));
        }
    }

    // ---- 消息对话框 --------------------------------------------------------------
    public static void info(Component parent, String msg) {
        JOptionPane.showMessageDialog(parent, msg, "提示", JOptionPane.INFORMATION_MESSAGE);
    }

    public static boolean confirm(Component parent, String msg, String title) {
        return JOptionPane.showConfirmDialog(parent, msg, title,
                JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE) ==
                JOptionPane.YES_OPTION;
    }

    /** 状态圆点图标（绿/橙/灰，16px；按 Color 缓存，避免 1s 刷新下每秒新建） */
    private static final java.util.Map<Color, javax.swing.Icon> DOT_CACHE =
            new java.util.concurrent.ConcurrentHashMap<>();

    public static javax.swing.Icon dot(Color c) {
        return DOT_CACHE.computeIfAbsent(c, Ui::makeDot);
    }

    private static javax.swing.Icon makeDot(Color c) {
        return new javax.swing.Icon() {
            @Override public void paintIcon(Component comp, Graphics g, int x, int y) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                                    RenderingHints.VALUE_ANTIALIAS_ON);
                g2.setColor(c);
                g2.fillOval(x + 3, y + 3, 10, 10);
                g2.dispose();
            }
            @Override public int getIconWidth() { return 16; }
            @Override public int getIconHeight() { return 16; }
        };
    }

    // ---- 全局 UIManager defaults（微调，不换 LAF 整包） -------------------------------------
    public static void installDefaults() {
        UIManager.put("Panel.background", BG);
        UIManager.put("OptionPane.background", BG);
        UIManager.put("TabbedPane.background", BG);
        UIManager.put("TabbedPane.contentAreaColor", BG);
        UIManager.put("TabbedPane.focus", BG);
        UIManager.put("TabbedPane.tabInsets", new java.awt.Insets(6, 16, 6, 16));
        UIManager.put("Table.background", Color.WHITE);
        UIManager.put("Table.gridColor", GRID);
        UIManager.put("TableHeader.background", HDR_BG);
        UIManager.put("TextField.background", Color.WHITE);
        UIManager.put("TextArea.background", Color.WHITE);
        UIManager.put("FormattedTextField.background", Color.WHITE);
        UIManager.put("PasswordField.background", Color.WHITE);
        UIManager.put("ComboBox.background", Color.WHITE);
        UIManager.put("List.background", Color.WHITE);
        UIManager.put("ScrollPane.background", BG);
        UIManager.put("Viewport.background", Color.WHITE);
        UIManager.put("SplitPane.background", BG);
        UIManager.put("ScrollBar.background", BG);
        UIManager.put("Button.focusPainted", Boolean.FALSE);
        UIManager.put("CheckBox.background", BG);
        UIManager.put("RadioButton.background", BG);
        UIManager.put("TitledBorder.font", FONT_BOLD);
    }
}
