// ============================================================================
// File        : MainFrame.java
// Description : Main window: JTabbedPane 五个页（项目/命令面板/快捷键/帮助/体检，
//               "最近文件"页已移除）+ 顶部会话栏（target 下拉
//               pid·version·design + 会话 JTable 1s diff 刷新 + 状态圆点与
//               三色 + 行↔下拉双向联动 + 广播输入行）+ 底部日志区 + 系统托盘
//               （气泡 + 右键菜单 显示/退出 + 左键前置）+ watchdog + 通用桥
//               运行器（busy 互斥 + 16.6 等待自适应）。
// ============================================================================
package astb.studio.ui;

import astb.studio.core.*;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.FontMetrics;
import java.awt.SystemTray;
import java.awt.TrayIcon;
import java.awt.event.ActionEvent;
import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;

public final class MainFrame extends JFrame {

    public final Map<String, Object> config = AppConfig.load();
    public final String toolboxRoot = AppConfig.toolboxRoot(config);
    public final LogPane logPane = new LogPane();
    private final JTabbedPane tabs = new JTabbedPane();

    // 会话栏
    private final DefaultComboBoxModel<String> comboModel = new DefaultComboBoxModel<>();
    private final JComboBox<String> targetCombo = new JComboBox<>(comboModel);
    private final List<String> comboPids = new ArrayList<>();
    private List<String> comboLabels = new ArrayList<>();   // 下拉项文本（diff 重建用）
    // 会话卡片列表（对齐 Python session_board：每会话一张卡）
    private final JPanel cardsPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 8));
    private final java.util.LinkedHashMap<String, SessionCard> cards =
            new java.util.LinkedHashMap<>();
    private final JLabel sessEmpty = new JLabel("（无在线会话 - 先启动 Allegro）");
    private final JTextField bcastEdit = new Ui.HintTextField("输入一行命令，点“广播”发到全部会话");
    private List<Bridge.Session> sessions = new ArrayList<>();
    private boolean sessSuppress = false;
    private final List<String> staleLogged = new ArrayList<>();
    private final Watchdog watchdog = new Watchdog();
    private final TargetPin targetPin = new TargetPin();
    private List<String> prevAlivePids = new ArrayList<>();   // 上轮 ALIVE（stale 防闪断噪音用）
    private final List<String> busyWarned = new ArrayList<>();   // busy 卡死已提示的 pid

    private final AtomicBoolean jobBusy = new AtomicBoolean(false);
    private TrayIcon trayIcon;
    private final JToggleButton topBtn = new JToggleButton("置顶");
    private java.awt.CheckboxMenuItem trayTopItem;

    // tabs
    private final ProjectsTab projectsTab;
    private final CommandPanelTab commandTab;
    private final HotkeysTab hotkeysTab;
    private final HealthTab healthTab;

    public MainFrame() {
        super("ASTB Studio (Java)");
        setIconImage(appImage());   // 任务栏/窗口图标（jar 内资源，缺失退回程序化图标）
        targetPin.pin(MiniJson.getStr(config, "target_pid", ""));   // 重启后恢复钉住的 target
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1100, 720);
        setMinimumSize(new Dimension(900, 620));
        setLocationRelativeTo(null);   // 启动居中
        // 最小化即收进托盘（点最小化按钮 → 隐藏到托盘；托盘左键还原；X 关闭仍=退出）
        addWindowStateListener(e -> {
            if ((e.getNewState() & ICONIFIED) != 0) setVisible(false);
        });

        projectsTab = new ProjectsTab(this);
        commandTab = new CommandPanelTab(this);
        hotkeysTab = new HotkeysTab(this);
        HelpTab helpTab = new HelpTab(this);
        healthTab = new HealthTab(this);

        tabs.addTab("项目", projectsTab);
        tabs.addTab("命令面板", commandTab);
        tabs.addTab("快捷键", hotkeysTab);
        tabs.addTab("帮助", helpTab);
        tabs.addTab("体检", healthTab);
        tabs.addChangeListener(e -> onTabShown(tabs.getSelectedIndex()));
        TealTabbedPaneUI.install(tabs);   // 页签青色指示条样式

        JPanel targetRow = new JPanel();
        targetRow.setBackground(Ui.BG);
        targetRow.setLayout(new BoxLayout(targetRow, BoxLayout.X_AXIS));
        targetRow.setBorder(BorderFactory.createEmptyBorder(4, 8, 2, 8));
        targetRow.add(new JLabel("目标："));
        targetCombo.setMaximumRowCount(12);
        targetCombo.setPrototypeDisplayValue("xxxxxxxx");
        // 离线保留项标灰显示
        targetCombo.setRenderer(new DefaultListCellRenderer() {
            @Override public java.awt.Component getListCellRendererComponent(
                    JList<?> list, Object value, int index, boolean isSelected,
                    boolean cellHasFocus) {
                super.getListCellRendererComponent(list, value, index, isSelected,
                                                   cellHasFocus);
                if (value != null && value.toString().endsWith("（离线）"))
                    setForeground(Ui.ST_GRAY);
                return this;
            }
        });
        targetRow.add(targetCombo);
        targetRow.add(Box.createHorizontalStrut(10));
        targetRow.add(new JLabel("广播："));
        bcastEdit.setMaximumSize(new Dimension(200, 26));
        bcastEdit.setPreferredSize(new Dimension(200, 26));
        targetRow.add(bcastEdit);
        targetRow.add(Box.createHorizontalStrut(6));
        JButton bcast = Ui.secondary("广播");
        bcast.addActionListener(e -> runBroadcast());
        targetRow.add(bcast);
        targetRow.add(Box.createHorizontalStrut(6));
        // “置顶”开关（选中态青字区分；与托盘勾选互相同步；config 持久化）
        topBtn.setFocusPainted(false);
        topBtn.setFont(Ui.FONT);
        topBtn.setMargin(new java.awt.Insets(2, 10, 2, 10));
        topBtn.addItemListener(e -> applyTopmost(topBtn.isSelected(), true));
        topBtn.setSelected(MiniJson.bool(config.get("window_topmost"), false));
        applyTopmost(topBtn.isSelected(), false);
        syncTopBtnVisual();
        targetRow.add(topBtn);
        targetRow.add(Box.createHorizontalGlue());

        targetCombo.addActionListener(e -> onTargetComboChanged());

        // 会话卡片列表（替换原 JTable：对齐 Python session_board 的卡片呈现）
        cardsPanel.setBackground(Ui.BG);
        cardsPanel.setBorder(BorderFactory.createEmptyBorder(2, 6, 2, 6));
        sessEmpty.setForeground(Ui.ST_GRAY);
        cardsPanel.add(sessEmpty);

        JPanel sessPanel = new JPanel(new BorderLayout());
        sessPanel.setBackground(Ui.BG);
        JPanel lblRow = new JPanel();
        lblRow.setBackground(Ui.BG);
        lblRow.setLayout(new BoxLayout(lblRow, BoxLayout.X_AXIS));
        lblRow.setBorder(BorderFactory.createEmptyBorder(0, 8, 0, 8));
        lblRow.add(new JLabel("在线会话："));
        lblRow.add(Box.createHorizontalGlue());
        // target 下拉 + 广播行必须进布局（之前构建后漏 add，导致不可见）
        JPanel sessNorth = new JPanel(new BorderLayout());
        sessNorth.setBackground(Ui.BG);
        sessNorth.add(targetRow, BorderLayout.NORTH);
        sessNorth.add(lblRow, BorderLayout.CENTER);
        sessPanel.add(sessNorth, BorderLayout.NORTH);
        JScrollPane sessScroll = new JScrollPane(cardsPanel);
        sessScroll.setPreferredSize(new Dimension(100, 130));
        sessScroll.getVerticalScrollBar().setUnitIncrement(20);
        sessPanel.add(sessScroll, BorderLayout.CENTER);

        JPanel logWrap = new JPanel(new BorderLayout());
        logWrap.setBackground(Ui.BG);
        JPanel logHead = new JPanel(new BorderLayout());
        logHead.setBackground(Ui.BG);
        JLabel outLbl = new JLabel("输出");
        outLbl.setBorder(BorderFactory.createEmptyBorder(0, 8, 0, 8));
        logHead.add(outLbl, BorderLayout.WEST);
        // 日志过滤：全部 / 警告+ / 仅错误（小号扁平互斥钮）
        JPanel filterRow = new JPanel(new FlowLayout(FlowLayout.RIGHT, 4, 0));
        filterRow.setBackground(Ui.BG);
        ButtonGroup fgroup = new ButtonGroup();
        String[] fnames = { "全部", "警告+", "仅错误" };
        for (int i = 0; i < fnames.length; ++i) {
            final int f = i;
            JToggleButton tb = new JToggleButton(fnames[i], i == 0);
            tb.setFont(Ui.FONT);
            tb.setFocusPainted(false);
            tb.setMargin(new java.awt.Insets(1, 10, 1, 10));
            tb.addActionListener(e -> logPane.setFilter(f));
            fgroup.add(tb);
            filterRow.add(tb);
        }
        logHead.add(filterRow, BorderLayout.EAST);
        logWrap.add(logHead, BorderLayout.NORTH);
        logWrap.add(logPane, BorderLayout.CENTER);

        JSplitPane lower = new JSplitPane(JSplitPane.VERTICAL_SPLIT, sessPanel, logWrap);
        lower.setResizeWeight(0.55);
        JSplitPane outer = new JSplitPane(JSplitPane.VERTICAL_SPLIT, tabs, lower);
        outer.setResizeWeight(0.62);
        outer.setDividerSize(5);
        lower.setDividerSize(5);
        getContentPane().setBackground(Ui.BG);
        getContentPane().add(outer, BorderLayout.CENTER);

        setupTray();
        log("ASTB Studio (Java) 启动");
        log("配置文件：" + Util.configPath());
        log("工具箱目录：" + toolboxRoot);
        log("桥目录：" + Util.bridgeRoot());
        scheduleCollect(true);
        new Timer(1000, e -> scheduleCollect(false)).start();
    }

    // ---- 日志 / 状态 ------------------------------------------------------------------
    public void log(String s) { logPane.log(s); }
    public void log(String s, int level) { logPane.log(s, level); }
    public boolean isBusy() { return jobBusy.get(); }

    public String currentTargetPid() {
        return targetPin.pid;   // 钉住的 target（用户手动切换才变；刷新/离线不丢）
    }

    public boolean anyAlive() {
        for (Bridge.Session s : sessions) if (s.effectiveAlive()) return true;
        return false;
    }

    public boolean saveConfig() {
        if (AppConfig.save(config)) return true;
        log("保存 config.json 失败：" + Util.configPath(), LogPane.ERR);
        return false;
    }

    /** 共享板子打开出口（最近文件页 → 项目页逻辑，version ""=sniff/default） */
    public void openBoardPathShared(String brd) {
        projectsTab.openBoardPath(brd, "");
    }

    /** 体检存历史 → 当前选中项目（HealthTab 调用） */
    public void storeHealthShared(String summary) {
        projectsTab.storeHealth(summary);
    }

    /** 置顶开关统一点：应用 setAlwaysOnTop + 持久化 + 托盘勾选同步 */
    private void applyTopmost(boolean on, boolean persist) {
        setAlwaysOnTop(on);
        if (persist && on != MiniJson.bool(config.get("window_topmost"), false)) {
            config.put("window_topmost", on);
            saveConfig();
        }
        if (trayTopItem != null && trayTopItem.getState() != on) trayTopItem.setState(on);
        syncTopBtnVisual();
    }

    private void syncTopBtnVisual() {
        boolean on = topBtn.isSelected();
        topBtn.setForeground(on ? Ui.ACCENT_TEXT : Ui.FLAT_TEXT);
        topBtn.setBorder(BorderFactory.createLineBorder(on ? Ui.ACCENT : Ui.LINE, 1));
    }

    /** 目标会话三态判定（HotkeysTab / CommandPanelTab 共用，取代各处拷贝）：
     *  返回 [pid, reason]；pid != null 时可投送（"" = 任一会话）；
     *  pid == null 时 reason ∈ {"target-offline", "no-session"}，各 Tab 自写降级文案。 */
    public String[] resolveTarget() {
        String t = currentTargetPid();
        List<Bridge.Session> ss = sessionsSnapshot();
        if (!t.isEmpty())
            return Bridge.pidOnline(t, ss) ? new String[] { t, "" }
                                           : new String[] { null, "target-offline" };
        return Bridge.anyAlive(ss) ? new String[] { "", "" }
                                   : new String[] { null, "no-session" };
    }

    /** 托盘菜单项规格（逻辑层可测）：[显示文本, 动作id] */
    public static List<String[]> trayMenuSpec() {
        List<String[]> out = new ArrayList<>();
        out.add(new String[] { "显示 / 隐藏", "show" });
        out.add(new String[] { "置顶", "top" });
        out.add(new String[] { "退出", "quit" });
        return out;
    }

    /** 激活 Allegro 窗口（对齐 Python SessionCard“窗口”按钮：按 design 匹配标题置顶） */
    private void activateAllegro(Bridge.Session s) {
        if (s == null) return;
        log(">> 激活 Allegro 窗口：pid=" + s.pid + " design=" + s.design);
        new Thread(() -> {
            boolean found = Wintop.activate(s.design);
            log(found ? "已置顶 Allegro 窗口（design=" + s.design + "）"
                      : "未找到对应 Allegro 窗口（design=" + s.design + "）",
                found ? LogPane.OK : LogPane.WARN);
        }, "astb-wintop").start();
    }

    /** 重载指定会话的 toolbox（对齐 Python SessionCard 的 Reload 按钮） */
    private void reloadSession(String pid) {
        boolean alive = false;
        for (Bridge.Session s : sessionsSnapshot())
            if (s.effectiveAlive() && s.pid.equals(pid)) alive = true;
        if (!alive) {
            log("会话 pid=" + pid + " 不在线，未发送 ASTB_Reload", LogPane.WARN);
            return;
        }
        runBridge(List.of("ASTB_Reload()"), pid, ">> ASTB_Reload() -> pid=" + pid);
    }

    // ---- 通用桥运行器 --------------------------------------------------------------------
    public double waitScaleFor(String target) {
        String ver = "";
        for (Bridge.Session s : sessions)
            if (s.pid.equals(target)) { ver = s.version; break; }
        if (ver.isEmpty())
            for (Bridge.Session s : sessions)
                if (s.effectiveAlive() && s.version.contains("16.6")) { ver = s.version; break; }
        return Bridge.waitScaleForVersion(ver);
    }

    /** 提交->等待->一行摘要日志（worker 线程，busy 互斥） */
    public void runBridge(List<String> cmds, String target, String echo) {
        if (!jobBusy.compareAndSet(false, true)) {
            log("上一个桥任务尚未完成，请稍候", LogPane.WARN);
            return;
        }
        if (echo != null && !echo.isEmpty()) log(echo);
        new Thread(() -> {
            try {
                String jobId = Bridge.submitJob(cmds, target, null);
                if (jobId.isEmpty()) {
                    log("桥提交失败：无法写入 " + Util.join(Util.bridgeRoot(), "jobs"),
                        LogPane.ERR);
                    return;
                }
                log("job=" + jobId + " 已提交" +
                    (target.isEmpty() ? "（任一会话）" : "（target=" + target + "）"));
                Object res = Bridge.waitResult(jobId, 30.0 * waitScaleFor(target));
                if (res == null) {
                    log("job=" + jobId + "：超时（" +
                        Bridge.timeoutDiagnosis(Bridge.anyAlive(Bridge.sessions())) + "）",
                        LogPane.ERR);
                    return;
                }
                Map<String, Object> o = MiniJson.obj(res);
                String resp = o == null ? "" : MiniJson.getStr(o, "pid", target);
                boolean ok = Bridge.resultOk(res);
                String vals = Bridge.resultsSummary(res);
                log("pid=" + resp + (ok ? " ok=true" : " ok=false") +
                    (vals.isEmpty() ? "" : ": " + vals), ok ? LogPane.OK : LogPane.ERR);
                // 条级错误上屏：顶层 ok=true 也可能有 results[i].ok=false（eval 失败）
                String itemErrs = Bridge.itemErrors(res);
                if (!itemErrs.isEmpty())
                    log("  条级错误: " + itemErrs + "（详见 Allegro 命令窗口 *Error* 行）",
                        LogPane.WARN);
            } finally {
                jobBusy.set(false);
            }
        }, "astb-job").start();
    }

    /** 广播：输入框一行命令逐个发全部 ALIVE 会话（串行，对齐 Python run_all_sessions） */
    public void runBroadcast() {
        String line = bcastEdit.getText().trim();
        if (line.isEmpty()) {
            log("（广播输入框是空的，没有可广播的命令）", LogPane.WARN);
            return;
        }
        List<String> pids = new ArrayList<>();
        for (Bridge.Session s : sessionsSnapshot()) if (s.effectiveAlive()) pids.add(s.pid);
        if (pids.isEmpty()) {
            log("无在线会话：广播未发送", LogPane.WARN);
            return;
        }
        if (!jobBusy.compareAndSet(false, true)) {
            log("上一个桥任务尚未完成，请稍候", LogPane.WARN);
            return;
        }
        log(">> 广播到 " + pids.size() + " 个会话: axlShell(\"" + line + "\")");
        String esc = line.replace("\\", "\\\\").replace("\"", "\\\"");
        List<String> cmds = List.of("axlShell(\"" + esc + "\")");
        new Thread(() -> {
            try {
                int okN = 0;
                for (String pid : pids) {
                    String jobId = Bridge.submitJob(cmds, pid, null);
                    if (jobId.isEmpty()) {
                        log("  pid=" + pid + ": 提交失败", LogPane.ERR);
                        continue;
                    }
                    Object res = Bridge.waitResult(jobId, 15.0 * waitScaleFor(pid));
                    if (res == null) {
                        log("  pid=" + pid + ": " +
                            Bridge.timeoutDiagnosis(Bridge.anyAlive(Bridge.sessions())),
                            LogPane.WARN);
                        continue;
                    }
                    boolean ok = Bridge.resultOk(res);
                    if (ok) ++okN;
                    String vals = Bridge.resultsSummary(res);
                    log("  pid=" + pid + (ok ? " ok=true" : " ok=false") +
                        (vals.isEmpty() ? "" : ": " + vals));
                    String itemErrs = Bridge.itemErrors(res);
                    if (!itemErrs.isEmpty())
                        log("  pid=" + pid + " 条级错误: " + itemErrs, LogPane.WARN);
                }
                log("广播完成：" + okN + "/" + pids.size() + " 个会话 ok");
            } finally {
                jobBusy.set(false);
            }
        }, "astb-bcast").start();
    }

    // ---- 会话刷新（1s diff）：磁盘 IO 在后台线程采集，渲染在 EDT --------------------------------

    /** 最近一轮采集结果（动作处理器复用，不再各自现读磁盘） */
    public List<Bridge.Session> sessionsSnapshot() { return sessions; }

    private final java.util.concurrent.ExecutorService collectExec =
            java.util.concurrent.Executors.newSingleThreadExecutor(r -> {
                Thread t = new Thread(r, "astb-collect");
                t.setDaemon(true);
                return t;
            });
    private final AtomicBoolean collectPending = new AtomicBoolean(false);

    /** Timer/启动都走这里：单线程后台采集（去重：上一轮没跑完就跳过本轮）。 */
    private void scheduleCollect(boolean first) {
        if (!collectPending.compareAndSet(false, true)) return;
        collectExec.execute(() -> {
            try {
                List<Bridge.Session> ss = Bridge.sessions();
                long fresh = StaleCheck.toolboxFreshMsCached(toolboxRoot);
                SwingUtilities.invokeLater(() -> applySessions(ss, fresh, first));
            } finally {
                collectPending.set(false);
            }
        });
    }

    /** EDT 渲染：现有 diff 刷新主体（迁移/日志/卡片/下拉/watchdog/年龄/状态）。 */
    private void applySessions(List<Bridge.Session> ss, long fresh, boolean first) {
        if (!first) {
            for (Bridge.Session s : ss) {
                if (!s.effectiveAlive()) continue;
                boolean was = false;
                for (Bridge.Session o : sessions)
                    if (o.effectiveAlive() && o.pid.equals(s.pid)) was = true;
                if (!was) log("会话上线：pid=" + s.pid + " design=" + s.design);
            }
            for (Bridge.Session o : sessions) {
                if (!o.effectiveAlive()) continue;
                boolean still = false;
                for (Bridge.Session s : ss)
                    if (s.effectiveAlive() && s.pid.equals(o.pid)) still = true;
                if (!still) log("会话退出：pid=" + o.pid + " design=" + o.design, LogPane.WARN);
            }
        }
        // watchdog：登记的 target 消失 -> 托盘气泡
        {
            List<String> curAlive = new ArrayList<>();
            for (Bridge.Session s : ss) if (s.effectiveAlive()) curAlive.add(s.pid);
            watchdog.target = currentTargetPid();
            String lost = watchdog.poll(curAlive);
            if (!lost.isEmpty()) {
                String d = "";
                for (Bridge.Session o : sessions) if (o.pid.equals(lost)) d = o.design;
                trayBalloon("Allegro 会话退出",
                            "pid=" + lost + (d.isEmpty() ? "" : "  design=" + d));
                log("watchdog：目标会话 pid=" + lost + " 已退出", LogPane.WARN);
            }
        }
        sessions = ss;

        List<String> curStale = new ArrayList<>();

        // 卡片对账：pid 集/顺序变了才重建卡片，否则只更新各卡内容（防 1s 闪烁）。
        // 显示层过滤：stale（掉线且非 busy）的卡片不渲染（用户拍板）；底层数据不动。
        List<Bridge.Session> vis = Bridge.visibleSessions(ss);
        List<String> pids = new ArrayList<>();
        for (Bridge.Session s : vis) pids.add(s.pid);
        if (!new ArrayList<>(cards.keySet()).equals(pids)) {
            cardsPanel.removeAll();
            cardsPanel.add(sessEmpty);
            cards.clear();
            for (Bridge.Session s : vis) {
                SessionCard c = new SessionCard(s.pid);
                cards.put(s.pid, c);
                cardsPanel.add(c);
            }
        }
        String curPid = currentTargetPid();
        for (int i = 0; i < ss.size(); ++i) {
            Bridge.Session s = ss.get(i);
            // stale 检查只对"本轮+上轮连续在线"的会话做——心跳闪断（退出/上线连跳）
            // 不再产生过期噪音；消失的会话不做检查（对齐用户反馈）
            boolean stale = s.alive && !s.busy && prevAlivePids.contains(s.pid) &&
                            StaleCheck.isStale(s.pid, fresh);
            if (stale) curStale.add(s.pid);
            // busy 疑似卡死（>=1800s）：每次运行只提示一次
            if (s.busyTimeout() && !busyWarned.contains(s.pid)) {
                log("会话 pid=" + s.pid + " 执行中超过 30 分钟（可能卡死）：" + s.cmd,
                    LogPane.WARN);
                busyWarned.add(s.pid);
            }
            if (!s.busyTimeout()) busyWarned.remove(s.pid);
            SessionCard c = cards.get(s.pid);
            if (c != null) c.update(s, stale, s.pid.equals(curPid));
        }
        cardsPanel.revalidate();
        cardsPanel.repaint();
        sessEmpty.setVisible(vis.isEmpty());
        for (String pid : curStale)
            if (!staleLogged.contains(pid))
                log("会话 pid=" + pid +
                    " 的工具箱已过期：磁盘 toolbox 有更新（项目页“重载 toolbox”可刷新）",
                    LogPane.WARN);
        staleLogged.retainAll(curStale);
        for (String pid : curStale)
            if (!staleLogged.contains(pid)) staleLogged.add(pid);

        // 下拉重建：钉住的 pid 永远保留（不在了以“（离线）”项钉住，不自动跳走）；
        // 只有用户手动切换才改变钉住值
        List<String> alivePids = new ArrayList<>();
        for (Bridge.Session s : ss) if (s.effectiveAlive()) alivePids.add(s.pid);
        targetPin.refresh(alivePids);
        int aliveN = alivePids.size();
        // 先算出新模型；label/pid 列表与现状相同就直接跳过重建（不再每秒
        // removeAllElements + 逐项测宽 + revalidate）
        List<String> newPids = new ArrayList<>();
        List<String> newLabels = new ArrayList<>();
        newPids.add("");
        newLabels.add(aliveN > 0 ? "任一会话" : "无在线会话（先启动 Allegro）");
        for (Bridge.Session s : ss) {
            if (!s.effectiveAlive()) continue;
            newPids.add(s.pid);
            newLabels.add(s.pid + " · " + s.version + " · " + s.design +
                          (s.busy && !s.busyTimeout() ? " ·执行中" : ""));
        }
        if (targetPin.offline) {
            newPids.add(targetPin.pid);
            newLabels.add(targetPin.display());
        }
        prevAlivePids = alivePids;   // 供下轮 stale 连续在线判定
        if (newPids.equals(comboPids) && newLabels.equals(comboLabels)) {
            // 模型没变：只同步钉住项的选中态（用户可能刚切了 target）
            int keep = targetPin.pid.isEmpty() ? 0 : comboPids.indexOf(targetPin.pid);
            if (keep >= 0 && targetCombo.getSelectedIndex() != keep) {
                sessSuppress = true;
                targetCombo.setSelectedIndex(keep);
                sessSuppress = false;
            }
        } else {
            comboLabels = newLabels;
            int wantW = 0;
            FontMetrics fm = targetCombo.getFontMetrics(targetCombo.getFont());
            sessSuppress = true;
            comboModel.removeAllElements();
            comboPids.clear();
            for (String lb : newLabels) {
                comboModel.addElement(lb);
                wantW = Math.max(wantW, fm.stringWidth(lb));
            }
            comboPids.addAll(newPids);
            int sel = 0;
            if (!targetPin.pid.isEmpty()) {
                int i = comboPids.indexOf(targetPin.pid);
                if (i >= 0) sel = i;
            }
            targetCombo.setSelectedIndex(sel);
            sessSuppress = false;
            wantW = Math.min(Math.max(wantW + 46, 300), 640);
            Dimension d = new Dimension(wantW, targetCombo.getPreferredSize().height);
            targetCombo.setPreferredSize(d);
            targetCombo.setMaximumSize(d);
            targetCombo.revalidate();
        }

        if (first) {
            if (aliveN > 0) log("发现 " + aliveN + " 个在线会话");
            else log("无在线会话（Allegro 未启动或 util_bridge 未加载）", LogPane.WARN);
        }
    }

    // ---- age 友好格式（<60s 原样 / <1h Xm / >=1h X.Xh / >=1d X.Xd） -------------------------
    private static String friendlyAge(double age) {
        if (age < 60) return String.format("%.1fs", age);
        if (age < 3600) return String.format("%dm", (int) (age / 60));
        if (age < 86400) return String.format("%.1fh", age / 3600);
        return String.format("%.1fd", age / 86400);
    }

    private void onTargetComboChanged() {
        if (sessSuppress) return;
        // 用户手动切换：改钉住值并持久化（刷新/离线本身不动钉住值）
        int idx = targetCombo.getSelectedIndex();
        String pid = idx >= 0 && idx < comboPids.size() ? comboPids.get(idx) : "";
        if (!pid.equals(targetPin.pid)) {
            targetPin.pin(pid);
            config.put("target_pid", pid);
            saveConfig();
            healthTab.onTargetChanged();   // health_auto：目标切换后触发一次
        }
        // 下拉切换联动会话卡片高亮（双向）
        for (SessionCard c : cards.values())
            c.setSelected(c.pid.equals(pid));
    }

    private void onTabShown(int idx) {
        switch (idx) {
            case 0 -> projectsTab.onShow();
            case 1 -> commandTab.onShow();
            case 2 -> hotkeysTab.onShow();
            case 4 -> healthTab.onShow();
            default -> { }
        }
    }

    // ---- 托盘 -------------------------------------------------------------------------------
    // 应用图标：优先 jar 内资源 /astb/studio/resources/astb.png，缺失退回程序化图标
    private static java.awt.Image appImage() {
        try (var in = MainFrame.class.getResourceAsStream("/astb/studio/resources/astb.png")) {
            if (in != null) return javax.imageio.ImageIO.read(in);
        } catch (Exception ignore) {}
        return trayImage();
    }

    private static BufferedImage trayImage() {
        BufferedImage img = new BufferedImage(16, 16, BufferedImage.TYPE_INT_ARGB);
        var g2 = img.createGraphics();
        g2.setRenderingHint(java.awt.RenderingHints.KEY_ANTIALIASING,
                            java.awt.RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setColor(Ui.BTN_NORMAL);
        g2.fillRoundRect(0, 0, 16, 16, 5, 5);
        g2.setColor(Ui.BTN_TEXT);
        g2.setFont(g2.getFont().deriveFont(java.awt.Font.BOLD, 10f));
        g2.drawString("A", 5, 12);
        g2.dispose();
        return img;
    }

    private void setupTray() {
        if (!SystemTray.isSupported()) return;
        try {
            SystemTray tray = SystemTray.getSystemTray();
            java.awt.PopupMenu menu = new java.awt.PopupMenu();
            java.awt.MenuItem show = new java.awt.MenuItem("显示 / 隐藏");
            show.addActionListener(e -> toggleVisible());
            trayTopItem = new java.awt.CheckboxMenuItem("置顶");
            trayTopItem.setState(topBtn.isSelected());
            trayTopItem.addItemListener(e -> topBtn.setSelected(trayTopItem.getState()));
            java.awt.MenuItem quit = new java.awt.MenuItem("退出");
            quit.addActionListener(e -> dispose());
            menu.add(show);
            menu.add(trayTopItem);
            menu.add(quit);
            trayIcon = new TrayIcon(appImage(), "ASTB Studio", menu);
            trayIcon.setImageAutoSize(true);
            trayIcon.addActionListener(e -> toFrontVisible());   // 左键（双击）前置
            trayIcon.addMouseListener(new java.awt.event.MouseAdapter() {
                @Override public void mouseClicked(java.awt.event.MouseEvent e) {
                    if (e.getButton() == java.awt.event.MouseEvent.BUTTON1) toFrontVisible();
                }
            });
            tray.add(trayIcon);
        } catch (Exception e) {
            trayIcon = null;
        }
    }

    private void toFrontVisible() {
        setVisible(true);
        setExtendedState(NORMAL);
        toFront();
        requestFocus();
    }

    private void toggleVisible() {
        if (isVisible()) setVisible(false);
        else toFrontVisible();
    }

    private void trayBalloon(String title, String text) {
        if (trayIcon != null)
            trayIcon.displayMessage(title, text, TrayIcon.MessageType.INFO);
    }

    @Override public void dispose() {
        collectExec.shutdownNow();   // 后台采集线程随窗口回收（防残留）
        if (trayIcon != null) {
            try { SystemTray.getSystemTray().remove(trayIcon); } catch (Exception ignored) {}
            trayIcon = null;
        }
        super.dispose();
    }

    // ---- 会话卡片（对齐 Python SessionCard：version+pid 标题/design/状态/三按钮） -----------
    private static Color statusColor(String st) {
        if (st.startsWith("执行中·超时")) return Ui.ST_ORANGE;
        if (st.startsWith("执行中")) return Ui.ACCENT;
        if ("ALIVE".equals(st)) return Ui.ST_GREEN;
        if (st.startsWith("ALIVE")) return Ui.ST_ORANGE;
        return Ui.ST_GRAY;
    }

    private final class SessionCard extends JPanel {
        final String pid;
        private Bridge.Session sess;
        private boolean staleFlag;
        private boolean selected;
        private final JLabel title = new JLabel();
        private final JLabel design = new JLabel();
        private final JLabel status = new JLabel();
        private final JButton bTarget = Ui.secondary("选定");
        private final JButton bWin = Ui.secondary("窗口");
        private final JButton bReload = Ui.secondary("Reload");

        SessionCard(String pid) {
            super();
            this.pid = pid;
            setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
            setPreferredSize(new Dimension(252, 108));
            title.setFont(Ui.FONT_BOLD);
            design.setFont(Ui.FONT);
            design.setForeground(new Color(80, 80, 80));
            status.setFont(Ui.FONT);
            add(title);
            add(design);
            add(status);
            JPanel brow = new JPanel(new FlowLayout(FlowLayout.LEFT, 4, 0));
            brow.setOpaque(false);
            Dimension bs = new Dimension(64, 22);
            for (JButton b : new JButton[] { bTarget, bWin, bReload }) {
                b.setPreferredSize(bs);
                b.setMargin(new java.awt.Insets(0, 2, 0, 2));
                brow.add(b);
            }
            add(brow);
            // 点卡片空白处 = 设为 target
            java.awt.event.MouseAdapter click = new java.awt.event.MouseAdapter() {
                @Override public void mouseClicked(java.awt.event.MouseEvent e) {
                    pickTarget(pid);
                }
            };
            addMouseListener(click);
            title.addMouseListener(click);
            design.addMouseListener(click);
            status.addMouseListener(click);
            brow.addMouseListener(click);
            bTarget.addActionListener(e -> pickTarget(pid));
            bWin.addActionListener(e -> activateAllegro(sess));
            bReload.addActionListener(e -> reloadSession(pid));
        }

        void update(Bridge.Session s, boolean stale, boolean sel) {
            sess = s;
            staleFlag = stale;
            title.setText(s.version + "  " + s.pid);
            design.setText(s.design.isEmpty() ? "(无设计)" : s.design);
            design.setToolTipText(design.getText());
            String st = Bridge.statusLabel(s, stale);
            status.setIcon(Ui.dot(statusColor(st)));
            status.setText(st + " · " + friendlyAge(s.age));
            status.setForeground(statusColor(st));
            bWin.setEnabled(s.effectiveAlive());
            bReload.setEnabled(s.effectiveAlive());
            setSelected(sel);
        }

        void setSelected(boolean sel) {
            if (sel == selected) return;   // 1s 刷新下同态重设不触发重绘
            selected = sel;
            setBackground(sel ? Ui.SEL_BG : Color.WHITE);
            setBorder(BorderFactory.createCompoundBorder(
                    BorderFactory.createLineBorder(sel ? Ui.ACCENT : Ui.LINE, sel ? 2 : 1),
                    BorderFactory.createEmptyBorder(6, 8, 6, 8)));
            for (java.awt.Component c : getComponents()) c.setBackground(getBackground());
            for (java.awt.Component c : new java.awt.Component[] { title, design, status })
                c.setBackground(getBackground());
        }

        boolean isSelectedCard() { return selected; }
    }

    /** 选定某会话为 target（卡片点击/“选定”按钮共用：等效用户切下拉） */
    private void pickTarget(String pid) {
        int idx = comboPids.indexOf(pid);
        if (idx >= 0) targetCombo.setSelectedIndex(idx);
    }

    // ---- 入口 -----------------------------------------------------------------------------------
    public static void start() {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception ignored) {}
            Ui.installDefaults();   // 近白底/控件白底/浅网格线/页签内边距等 defaults 微调
            // 全局字体
            java.util.Enumeration<Object> keys = UIManager.getDefaults().keys();
            List<Object> fontKeys = new ArrayList<>();
            while (keys.hasMoreElements()) {
                Object k = keys.nextElement();
                if (String.valueOf(k).endsWith(".font")) fontKeys.add(k);
            }
            for (Object k : fontKeys) UIManager.put(k, Ui.FONT);
            MainFrame frame = new MainFrame();
            frame.setVisible(true);
            frame.toFront();          // 启动后置顶一次
            frame.requestFocus();
        });
    }
}
