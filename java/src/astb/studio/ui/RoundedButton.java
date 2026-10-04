// ============================================================================
// File        : RoundedButton.java
// Description : 圆角三态按钮（对齐 Python QSS：常态 #39c5bb / hover #5adfd5 /
//               pressed #25a295、字色 #06322e）。
// ============================================================================
package astb.studio.ui;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import javax.swing.JButton;

public class RoundedButton extends JButton {

    public RoundedButton(String text) {
        super(text);
        setContentAreaFilled(false);
        setFocusPainted(false);
        setBorderPainted(false);
        setOpaque(false);
        setForeground(Ui.BTN_TEXT);
        setFont(Ui.FONT);
        setPreferredSize(new Dimension(160, 42));
    }

    /** 填充色（GhostButton 覆写为浅色并自绘虚线框） */
    protected Color fillColor() {
        if (getModel().isPressed() || getModel().isArmed()) return Ui.BTN_DOWN;
        if (getModel().isRollover()) return Ui.BTN_HOT;
        return Ui.BTN_NORMAL;
    }

    @Override protected void paintComponent(Graphics g) {
        Graphics2D g2 = (Graphics2D) g.create();
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                            RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setColor(fillColor());
        g2.fillRoundRect(0, 0, getWidth(), getHeight(), 14, 14);
        g2.dispose();
        super.paintComponent(g);
    }
}
