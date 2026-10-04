// ============================================================================
// File        : TargetPin.java
// Description : target 选定"钉住"状态机（纯逻辑，可测）：
//               - 钉住的 pid 只要还在会话里（含 stale/暂时消失/已退出）就保留
//                 选中，离线期间以 "pid（离线）" 项呈现（offline=true）；
//               - 该 pid 重新上线（回到 ALIVE 集）时自动恢复为正常项；
//               - 只有用户手动切换才改变钉住值（pin()）。
// ============================================================================
package astb.studio.core;

import java.util.Collection;

public final class TargetPin {
    public String pid = "";          // 钉住的 pid；"" = 任一会话
    public boolean offline = false;  // 当前是否以离线项保留

    public void pin(String p) { pid = p == null ? "" : p; }

    /** 每轮刷新调用：alivePids = 当前 ALIVE pid 集合。
     *  offline = 钉住的 pid 非空且不在 ALIVE 集（暂时消失/stale/已退出均保留）。 */
    public void refresh(Collection<String> alivePids) {
        offline = !pid.isEmpty() && !alivePids.contains(pid);
    }

    /** 下拉项显示文本（"" 表示该 pid 无需离线项） */
    public String display() {
        if (pid.isEmpty()) return "";
        return offline ? pid + "（离线）" : pid;
    }
}
