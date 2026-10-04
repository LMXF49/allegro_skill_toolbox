// ============================================================================
// File        : CopyMenu.java
// Description : 只读信息区的右键复制助手（统一行为）：
//               - 有选中时提供"复制选中"，否则提供"复制"（菜单文案区分）；
//               - "全部复制"复制全文；"全选"选中全文；
//               - Ctrl+C 由 JTextComponent 默认键绑定原生支持（不拦截）。
//               剪贴板经 Toolkit.getSystemClipboard + StringSelection。
// ============================================================================
package astb.studio.ui;

import java.awt.Toolkit;
import java.awt.datatransfer.StringSelection;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import javax.swing.JMenuItem;
import javax.swing.JPopupMenu;
import javax.swing.text.JTextComponent;

public final class CopyMenu {
    private CopyMenu() {}

    public static void attach(JTextComponent tc) {
        tc.setFocusable(true);   // 只读但可聚焦可选中（不禁用鼠标）
        tc.addMouseListener(new MouseAdapter() {
            @Override public void mousePressed(MouseEvent e) { maybe(e); }
            @Override public void mouseReleased(MouseEvent e) { maybe(e); }
            private void maybe(MouseEvent e) {
                if (!e.isPopupTrigger()) return;
                JPopupMenu m = new JPopupMenu();
                String sel = tc.getSelectedText();
                if (sel != null && !sel.isEmpty()) {
                    JMenuItem c1 = new JMenuItem("复制选中");
                    c1.addActionListener(a -> copy(sel));
                    m.add(c1);
                }
                JMenuItem c2 = new JMenuItem(sel == null || sel.isEmpty() ? "复制" : "全部复制");
                c2.addActionListener(a -> copy(tc.getText()));
                m.add(c2);
                JMenuItem c3 = new JMenuItem("全选");
                c3.addActionListener(a -> tc.selectAll());
                m.add(c3);
                m.show(tc, e.getX(), e.getY());
            }
        });
    }

    public static void copy(String text) {
        Toolkit.getDefaultToolkit().getSystemClipboard()
               .setContents(new StringSelection(text == null ? "" : text), null);
    }
}
