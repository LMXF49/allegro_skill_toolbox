// ============================================================================
// File        : TealTabbedPaneUI.java
// Description : 轻量页签造型（对齐 Python QSS：页签内边距 (16,8)、当前页
//               深青文字 RGB(20,120,110) + 底部 2px #2fbfae 指示条、非当前
//               灰字；去厚重默认边框与焦点框）。用于主 JTabbedPane 与命令
//               面板页签条。
// ============================================================================
package astb.studio.ui;

import java.awt.Color;
import java.awt.FontMetrics;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import javax.swing.JComponent;
import javax.swing.plaf.basic.BasicTabbedPaneUI;

public final class TealTabbedPaneUI extends BasicTabbedPaneUI {

    private static final Color TAB_TEXT_NORMAL = new Color(90, 90, 90);

    public static void install(javax.swing.JTabbedPane tabs) {
        tabs.setUI(new TealTabbedPaneUI());
        tabs.setOpaque(true);
        tabs.setBackground(Ui.BG);
        tabs.setBorder(null);
        // 单行可滚动，不折行（用户反馈分类页签折成两行）
        tabs.setTabLayoutPolicy(javax.swing.JTabbedPane.SCROLL_TAB_LAYOUT);
    }

    @Override protected void paintTabBackground(Graphics g, int tabPlacement, int tabIndex,
                                                int x, int y, int w, int h,
                                                boolean isSelected) {
        Graphics2D g2 = (Graphics2D) g.create();
        g2.setColor(isSelected ? Color.WHITE : Ui.BG);
        g2.fillRect(x, y, w, h);
        if (isSelected) {   // 底部 2px 青色指示条
            g2.setColor(Ui.ACCENT);
            g2.fillRect(x, y + h - 2, w, 2);
        }
        g2.dispose();
    }

    @Override protected void paintTabBorder(Graphics g, int tabPlacement, int tabIndex,
                                            int x, int y, int w, int h, boolean isSelected) {
        // 无厚重边框：只画一条浅灰底部分隔线
        g.setColor(Ui.LINE);
        g.drawLine(x, y + h - 1, x + w, y + h - 1);
    }

    @Override protected void paintText(Graphics g, int tabPlacement, java.awt.Font font,
                                       FontMetrics metrics, int tabIndex, String title,
                                       java.awt.Rectangle textRect, boolean isSelected) {
        Graphics2D g2 = (Graphics2D) g.create();
        g2.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                            RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        g2.setFont(isSelected ? Ui.FONT_BOLD : font);
        g2.setColor(isSelected ? Ui.ACCENT_TEXT : TAB_TEXT_NORMAL);
        g2.drawString(title, textRect.x, textRect.y + metrics.getAscent());
        g2.dispose();
    }

    @Override protected void paintFocusIndicator(Graphics g, int tabPlacement,
                                                 java.awt.Rectangle[] rects, int tabIndex,
                                                 java.awt.Rectangle iconRect,
                                                 java.awt.Rectangle textRect,
                                                 boolean isSelected) {
        // 去掉默认虚线焦点框（浅色基调下突兀）
    }

    @Override protected void paintContentBorder(Graphics g, int tabPlacement,
                                                int selectedIndex) {
        // 不画内容区横线——指示条只允许出现在当前页签自身底部（paintTabBackground），
        // 横贯整条会被误认为“整条都是指示条”（用户截图反馈）
    }
}
