// ============================================================================
// File        : Watchdog.java
// Description : Session-crash watchdog decision logic (pure, file-free):
//               tracks the registered target session against the alive-pid
//               set seen at each poll; reports when the watched target
//               vanished. First poll only builds the baseline.
// ============================================================================
package astb.studio.core;

import java.util.ArrayList;
import java.util.List;

public final class Watchdog {
    public String target = "";
    public List<String> alive = new ArrayList<>();
    public boolean initialized = false;

    /** Returns the lost target pid ("" = nothing). curAlive = current ALIVE pids. */
    public String poll(List<String> curAlive) {
        String lost = "";
        if (initialized && !target.isEmpty() && alive.contains(target) &&
            !curAlive.contains(target)) {
            lost = target;
        }
        alive = new ArrayList<>(curAlive);
        initialized = true;
        return lost;
    }
}
