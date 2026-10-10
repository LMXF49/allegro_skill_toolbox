;========================================================================
; File        : util_bridge.il
; Author      : ASTB Team
; Created     : 2026-08-22
; Version     : 1.5
; Description : ASTB Studio bridge. Polls a file-based job queue under
;               the system TEMP dir so an external app (ASTB Studio)
;               can trigger SKILL commands inside this Allegro session
;               and read back results. Also exports the toolbox menu
;               tree (ASTB_BridgeExportMenuTree -> menu_tree.json).
;               Pure ASCII on purpose: the file loads identically on
;               16.6 / 17.4 / 24.1 and survives the 16.6 reader.
; Depends on  : core/utils.il (ASTB_Log*), core/trans.il
;               (ASTB_RegisterCommand), core/menu.il
;               (ASTB_GetMenuStructure / ASTB_MenuIs*)
; Notes       : background service, intentionally NOT added to the
;               toolbox menu; control goes through the astbbridge
;               command or ASTB_BridgeStart/Stop functions.
; Revision history:
;   2026-08-22 v1.0 heartbeat + job queue + JSON result writer
;   2026-08-22 v1.0.1 protocol doc fix: GBK octal escapes on all
;               versions; result JSON declared GBK-encoded (code
;               unchanged)
;   2026-08-22 v1.1 menu tree export (menu_tree.json, auto-written at
;               bridge start)
;   2026-08-22 v1.1.1 fix: timer callback must accept (window timerId
;               elapsedTime) - zero-arg tick errored on first fire and
;               the oneshot chain died (16.6 real-machine catch);
;               version string now via ASTB_GetVersion() -
;               axlVersion('version) returns a float, not a string
;   2026-08-22 v1.2 repeating timer (third arg nil) instead of a
;               one-shot chain: on 16.6 the re-arm from inside the
;               callback silently fails and the chain dies after the
;               first tick; + stale jobs/results/sessions cleanup at
;               bridge start; globals boundp-guarded so ASTB_Reload
;               lets Start kill the previous timer
;   2026-08-24 v1.2.1 TEMPORARY debug probe ASTB_BridgeTrace ->
;               <root>/trace.log (bridge death hunt, remove after fix)
;   2026-08-28 v1.3 debug probe removed (bridge death root-caused to the
;               16.6 one-shot timer re-arm failure, fixed in v1.2); tick
;               now calls heartbeat + job poll directly
;   2026-09-30 v1.4 busy marker: on job claim the session file gains
;               "busy"/"cmd"/"since" fields, so the app shows
;               "executing" instead of offline while an interactive
;               command starves the tick timer (enterFun blocks
;               axlUIWTimer; cleared by the next normal heartbeat)
;   2026-10-11 v1.5 menu.il v4.3 inline dual labels: menu tree
;               export reads zh straight from structure fields;
;               zh resolver wrapper (ASTB_ZH_GET based) removed
;
; ------------------------- protocol v1 ---------------------------------
; root = <TEMP>/astb_bridge            (backslashes normalized to "/")
;
;   sessions/s_<pid>.session
;       JSON heartbeat, rewritten every tick. The app treats file mtime
;       as the liveness signal (stale > 10 s = session gone; see
;       AstbBridgeClient.sessions max_age - 16.6 tick can lag several
;       seconds under load). Fields:
;       pid, version, design, cwd, root, time.
;
;   jobs/<id>.job
;       SKILL source loaded by the bridge. Must set:
;         ASTB_JOB_ID     string, safe filename chars
;         ASTB_JOB_CMDS   list of expression strings, each eval'd in
;                         order via errset(eval(readstring(cmd)))
;       Optional:
;         ASTB_JOB_TARGET pid string; "" or "*" = any session
;       Encoding rule: file stays ASCII. Non-ASCII payload inside
;       strings must be octal-escaped GBK bytes on ALL versions
;       (16.6/17.4/24.1): Allegro runtime strings are GBK byte strings
;       on Chinese Windows; the 16.6 reader additionally rejects raw
;       high bytes inside strings.
;
;   results/<id>.result.json
;       JSON: {id, pid, design, ok, results:[{i, ok, value, error}],
;              error, time}. Written after the whole job finishes.
;       NOTE: values may carry raw GBK bytes (Chinese messages), so
;       the file is GBK-encoded JSON; readers must decode GBK.
;
; Claiming: before load, the bridge peeks ASTB_JOB_TARGET (no claim if
; it names another pid), then renames <id>.job -> <id>.job.claim.<pid>
; (rename is atomic; losers see the source vanish). One job per tick.
; Interactive commands (canvas picking) return as soon as the command
; activates; the app must treat ok=true as "triggered", not "done".
;------------------------------------------------------------------------

; globals: boundp-guarded so an ASTB_Reload keeps ASTB_BRIDGE_TID visible
; long enough for ASTB_BridgeStart to kill the previous timer
unless( boundp('ASTB_BRIDGE_ON)           ASTB_BRIDGE_ON = nil )
unless( boundp('ASTB_BRIDGE_TID)          ASTB_BRIDGE_TID = nil )
unless( boundp('ASTB_BRIDGE_PID)          ASTB_BRIDGE_PID = nil )
unless( boundp('ASTB_BRIDGE_ROOT)         ASTB_BRIDGE_ROOT = nil )
unless( boundp('ASTB_BRIDGE_DIR_SESSIONS) ASTB_BRIDGE_DIR_SESSIONS = nil )
unless( boundp('ASTB_BRIDGE_DIR_JOBS)     ASTB_BRIDGE_DIR_JOBS = nil )
unless( boundp('ASTB_BRIDGE_DIR_RESULTS)  ASTB_BRIDGE_DIR_RESULTS = nil )
; 300 ms tick: worst-case command latency halves vs the original 700 ms;
; heartbeat mtime stays far fresher than the client's 10 s stale window.
ASTB_BRIDGE_TICK_MS = 300

;------------------------------------------------------------------------
; small string helpers
;------------------------------------------------------------------------
procedure( ASTB_BridgeSlash(s)
  if( stringp(s)
  then buildString(parseString(s "\\") "/")
  else ""
  ))

procedure( ASTB_BridgeStartsWith(s prefix)
  prog((ls lf)
    ls = strlen(s)
    lf = strlen(prefix)
    return( and( ls >= lf equal(substring(s 1 lf) prefix) ) )
  ))

procedure( ASTB_BridgeEndsWith(s suffix)
  prog((ls lf)
    ls = strlen(s)
    lf = strlen(suffix)
    return( and( ls >= lf equal(substring(s ls - lf + 1) suffix) ) )
  ))

procedure( ASTB_BridgeStripSuffix(s suffix)
  prog((ls lf)
    ls = strlen(s)
    lf = strlen(suffix)
    if( and( ls >= lf equal(substring(s ls - lf + 1) suffix) )
    then return(substring(s 1 ls - lf))
    else return(s)
    )
  ))

; JSON string escaping: backslash, quote, newline -> \n, drop CR
procedure( ASTB_BridgeJsonEsc(s)
  prog((out c i)
    out = ""
    when( stringp(s)
      for( i 1 strlen(s)
        c = substring(s i 1)
        cond(
          ( equal(c "\\")  out = strcat(out "\\\\") )
          ( equal(c "\"")  out = strcat(out "\\\"") )
          ( equal(c "\n")  out = strcat(out "\\n") )
          ( equal(c "\r")  nil )
          ( t              out = strcat(out c) )
        )
      )
    )
    return(out)
  ))

;------------------------------------------------------------------------
; session identity / directories
;------------------------------------------------------------------------
procedure( ASTB_BridgeInitPid()
  prog((r)
    r = errset(getpid())
    if( and( r car(r) numberp(car(r)) )
    then ASTB_BRIDGE_PID = sprintf(nil "%d" car(r))
    else
      errset(srandom(stringToTime(getCurrentTime())) t)
      ASTB_BRIDGE_PID = sprintf(nil "r%d" random(1000000))
    )
    return(ASTB_BRIDGE_PID)
  ))

procedure( ASTB_BridgeInitRoot()
  prog((tmp)
    tmp = ASTB_BridgeSlash(getShellEnvVar("TEMP"))
    when( equal(tmp "") tmp = ASTB_BridgeSlash(getShellEnvVar("TMP")) )
    when( and( equal(tmp "") boundp('ASTB_GLOBAL) ASTB_GLOBAL )
      tmp = strcat(ASTB_GLOBAL->ToolboxPath "/_bridge_tmp")
    )
    when( equal(tmp "") tmp = "C:/temp" )
    ASTB_BRIDGE_ROOT         = strcat(tmp "/astb_bridge")
    ASTB_BRIDGE_DIR_SESSIONS = strcat(ASTB_BRIDGE_ROOT "/sessions")
    ASTB_BRIDGE_DIR_JOBS     = strcat(ASTB_BRIDGE_ROOT "/jobs")
    ASTB_BRIDGE_DIR_RESULTS  = strcat(ASTB_BRIDGE_ROOT "/results")
    foreach( d list(ASTB_BRIDGE_ROOT ASTB_BRIDGE_DIR_SESSIONS
                    ASTB_BRIDGE_DIR_JOBS ASTB_BRIDGE_DIR_RESULTS)
      unless( isDir(d) errset(createDir(d) t) )
    )
    return(ASTB_BRIDGE_ROOT)
  ))

procedure( ASTB_BridgeDesign()
  prog((r d)
    d = ""
    r = errset(d = axlCurrentDesign())
    if( and( r stringp(d) ) then return(d) else return("") )
  ))

procedure( ASTB_BridgeCwd()
  prog((r wd)
    wd = ""
    r = errset(wd = getWorkingDir())
    if( and( r stringp(wd) ) then return(ASTB_BridgeSlash(wd)) else return("") )
  ))

;------------------------------------------------------------------------
; heartbeat
;------------------------------------------------------------------------
procedure( ASTB_BridgeHeartbeat(@optional busy cmd)
  prog((path r port ver)
    unless( ASTB_BRIDGE_DIR_SESSIONS return(nil) )
    path = strcat(ASTB_BRIDGE_DIR_SESSIONS "/s_" ASTB_BRIDGE_PID ".session")
    ; 'version returns a float on Allegro; ASTB_GetVersion gives the
    ; cached full string (core/version_adapter.il)
    ver = "unknown"
    r = errset(ver = ASTB_GetVersion())
    unless( and( r stringp(ver) strlen(ver) > 0 ) ver = "unknown" )
    r = errset(port = outfile(path))
    unless( and( r port )
      return(nil)
    )
    fprintf(port "{\"pid\":\"%s\",\"version\":\"%s\",\"design\":\"%s\",\"cwd\":\"%s\",\"root\":\"%s\",\"time\":\"%s\""
      ASTB_BRIDGE_PID
      ASTB_BridgeJsonEsc(ver)
      ASTB_BridgeJsonEsc(ASTB_BridgeDesign())
      ASTB_BridgeJsonEsc(ASTB_BridgeCwd())
      ASTB_BridgeJsonEsc(ASTB_BRIDGE_ROOT)
      ASTB_BridgeJsonEsc(getCurrentTime()))
    ; v1.4: busy marker (see header note)
    when( busy
      unless( and( stringp(cmd) strlen(cmd) > 0 ) cmd = "" )
      when( strlen(cmd) > 80 cmd = substring(cmd 1 80) )
      fprintf(port ",\"busy\":true,\"cmd\":\"%s\",\"since\":\"%s\""
        ASTB_BridgeJsonEsc(cmd)
        ASTB_BridgeJsonEsc(getCurrentTime()))
    )
    fprintf(port "}\n")
    close(port)
    return(t)
  ))

;------------------------------------------------------------------------
; job handling
;------------------------------------------------------------------------
; read ASTB_JOB_TARGET without loading the job; returns "" (broadcast),
; "*", a pid string, or nil when unreadable / absent line unreadable
procedure( ASTB_BridgePeekTarget(path)
  prog((pr port line parts target p)
    target = nil
    pr = errset(p = infile(path))
    unless( and( pr p ) return(nil) )
    port = p
    line = nil
    while( and( gets( line port ) not(target) )
      when( and( stringp(line) ASTB_BridgeStartsWith(line "ASTB_JOB_TARGET") )
        parts = parseString(line "\"")
        if( and( parts cadr(parts) )
        then target = cadr(parts)
        else target = ""
        )
      )
    )
    close(port)
    if( target then return(target) else return("") )
  ))

; claim by atomic rename; returns claimed path or nil
procedure( ASTB_BridgeClaim(f)
  prog((src dst r)
    src = strcat(ASTB_BRIDGE_DIR_JOBS "/" f)
    dst = strcat(src ".claim." ASTB_BRIDGE_PID)
    r = errset(renameFile(src dst))
    if( and( r car(r) ) then return(dst) else return(nil) )
  ))

procedure( ASTB_BridgeWriteResult(jobId resList errTop)
  prog((path r port first it p)
    path = strcat(ASTB_BRIDGE_DIR_RESULTS "/" jobId ".result.json")
    r = errset(p = outfile(path))
    unless( and( r p )
      ASTB_LogError(strcat("bridge: cannot write result " path))
      return(nil)
    )
    port = p
    fprintf(port "{\n")
    fprintf(port "\"id\":\"%s\",\n" ASTB_BridgeJsonEsc(jobId))
    fprintf(port "\"pid\":\"%s\",\n" ASTB_BRIDGE_PID)
    fprintf(port "\"design\":\"%s\",\n" ASTB_BridgeJsonEsc(ASTB_BridgeDesign()))
    if( equal(errTop "")
    then fprintf(port "\"ok\":true,\n")
    else fprintf(port "\"ok\":false,\n")
    )
    fprintf(port "\"results\":[")
    first = t
    foreach( it resList
      unless( first fprintf(port ",") )
      first = nil
      fprintf(port "{\"i\":%d,\"ok\":%s,\"value\":\"%s\",\"error\":\"%s\"}"
        nth(0 it)
        if( nth(1 it) then "true" else "false" )
        ASTB_BridgeJsonEsc(nth(2 it))
        ASTB_BridgeJsonEsc(nth(3 it)))
    )
    fprintf(port "],\n")
    fprintf(port "\"error\":\"%s\",\n" ASTB_BridgeJsonEsc(errTop))
    fprintf(port "\"time\":\"%s\"\n"  ASTB_BridgeJsonEsc(getCurrentTime()))
    fprintf(port "}\n")
    close(port)
    return(t)
  ))

; run one claimed job file; always consumes it (result + delete)
procedure( ASTB_BridgeRunJob(claimedPath jobName)
  prog((r cmd i ok val vs errMsg resList jobId)
    ASTB_JOB_ID     = nil
    ASTB_JOB_CMDS   = nil
    ASTB_JOB_TARGET = nil
    r = errset(load(claimedPath))
    unless( and( r stringp(ASTB_JOB_ID) listp(ASTB_JOB_CMDS) )
      jobId = ASTB_BridgeStripSuffix(jobName ".job")
      ASTB_BridgeWriteResult(jobId nil "malformed job file (need ASTB_JOB_ID + ASTB_JOB_CMDS)")
      errset(deleteFile(claimedPath) t)
      return(t)
    )
    jobId = ASTB_JOB_ID
    ; v1.4: mark busy BEFORE eval -- an interactive command will starve
    ; the tick, and without this marker the app would read "offline"
    errset(ASTB_BridgeHeartbeat(t car(ASTB_JOB_CMDS)) t)
    resList = nil
    for( i 1 length(ASTB_JOB_CMDS)
      cmd = nth(i - 1 ASTB_JOB_CMDS)
      ok = nil
      val = nil
      errMsg = ""
      if( stringp(cmd)
      then
        r = errset(val = eval(readstring(cmd)))
        if( r
        then ok = t
        else errMsg = "eval error (see Allegro command window)"
        )
      else
        errMsg = "command is not a string"
      )
      vs = sprintf(nil "%L" val)
      when( strlen(vs) > 4000 vs = strcat(substring(vs 1 4000) "...") )
      resList = append1(resList list(i ok vs errMsg))
    )
    ASTB_BridgeWriteResult(jobId resList "")
    errset(deleteFile(claimedPath) t)
    ASTB_JOB_ID     = nil
    ASTB_JOB_CMDS   = nil
    ASTB_JOB_TARGET = nil
    return(t)
  ))

procedure( ASTB_BridgePollJobs()
  prog((pr files f src target claimed done)
    done = nil
    unless( ASTB_BRIDGE_DIR_JOBS return(nil) )
    pr = errset(files = sort(getDirFiles(ASTB_BRIDGE_DIR_JOBS) 'alphalessp))
    unless( and( pr files ) return(nil) )
    foreach( f files
      when( and( not(done) stringp(f) ASTB_BridgeEndsWith(f ".job") )
        src = strcat(ASTB_BRIDGE_DIR_JOBS "/" f)
        target = ASTB_BridgePeekTarget(src)
        when( and( target
                   or( equal(target "") equal(target "*")
                       equal(target ASTB_BRIDGE_PID) ) )
          claimed = ASTB_BridgeClaim(f)
          when( claimed
            ASTB_BridgeRunJob(claimed f)
            done = t
          )
        )
      )
    )
    return(done)
  ))

;------------------------------------------------------------------------
; timer tick
; NOTE 1: the timer callback is invoked with (window timerId elapsedTime);
;         declare them @optional or the call fails with "too many arguments"
; NOTE 2: the timer is REPEATING (third arg nil) - on 16.6 a one-shot
;         re-armed from inside the callback silently dies, which killed
;         the heartbeat (real-machine catch, 2026-08-22). No re-arm here.
;------------------------------------------------------------------------
procedure( ASTB_BridgeTick(@optional window timerId elapsedTime)
  when( ASTB_BRIDGE_ON
    errset(ASTB_BridgeHeartbeat() t)
    errset(ASTB_BridgePollJobs() t)
  ))

;------------------------------------------------------------------------
; stale queue debris cleanup (best-effort, run once at bridge start)
;------------------------------------------------------------------------
procedure( ASTB_BridgeCleanupDir(dir maxAge skipOwn)
  prog((r now files f path mt)
    unless( and( dir isDir(dir) ) return(nil) )
    now = nil
    r = errset(now = stringToTime(getCurrentTime()))
    unless( and( r numberp(now) ) return(nil) )
    files = nil
    r = errset(files = getDirFiles(dir))
    unless( and( r listp(files) ) return(nil) )
    foreach( f files
      path = strcat(dir "/" f)
      when( isFile(path)
        mt = nil
        r = errset(mt = fileGetTime(path))
        ; fileGetTime may return an integer or a (atime mtime ...) list
        when( and( r listp(mt) ) mt = cadr(mt) )
        when( and( r numberp(mt) now - mt > maxAge )
          unless( and( skipOwn
                       equal(f strcat("s_" ASTB_BRIDGE_PID ".session")) )
            errset(deleteFile(path) t)
          )
        )
      )
    )
    return(t)
  ))

procedure( ASTB_BridgeCleanup()
  ASTB_BridgeCleanupDir(ASTB_BRIDGE_DIR_JOBS     600 nil)
  ASTB_BridgeCleanupDir(ASTB_BRIDGE_DIR_RESULTS  600 nil)
  ASTB_BridgeCleanupDir(ASTB_BRIDGE_DIR_SESSIONS 60  t)
)

;------------------------------------------------------------------------
; menu tree export (for ASTB Studio's command panel)
; tree node shapes (plain lists):
;   ("popup"    enLabel zhLabel childrenList)
;   ("command"  enLabel zhLabel commandName)
;   ("separator")
;------------------------------------------------------------------------
procedure( ASTB_BridgeBuildMenuTree()
  prog((flat stack frame node topNode topKids item)
    flat = ASTB_GetMenuStructure()
    ; stack of frames; frame = (node childrenSoFar); car = innermost
    stack = list( list(nil nil) )
    foreach( item flat
      cond(
        ( ASTB_MenuIsPopup(item)
          node = list("popup" cadr(item) caddr(item))
          stack = cons(list(node nil) stack)
        )
        ( ASTB_MenuIsEnd(item)
          frame = car(stack)
          stack = cdr(stack)
          node = append(car(frame) list(reverse(cadr(frame))))
          topNode = car(car(stack))
          topKids = cadr(car(stack))
          stack = cons(list(topNode append(topKids list(node)))
                       cdr(stack))
        )
        ( ASTB_MenuIsSeparator(item)
          topNode = car(car(stack))
          topKids = cadr(car(stack))
          stack = cons(list(topNode append(topKids list(list("separator"))))
                       cdr(stack))
        )
        ( ASTB_MenuIsCommand(item)
          topNode = car(car(stack))
          topKids = cadr(car(stack))
          node = list("command" car(item) cadr(item) caddr(item))
          stack = cons(list(topNode append(topKids list(node)))
                       cdr(stack))
        )
        ( t nil )
      )
    )
    ; structure is balanced incl. the root popup: exactly the root frame
    ; remains, its children are the tree
    return( reverse(cadr(car(stack))) )
  ))

procedure( ASTB_BridgeWriteMenuNode(port node first)
  ; writes node JSON; returns nil (value unused)
  unless( first fprintf(port ",") )
  cond(
    ( equal(car(node) "separator")
      fprintf(port "{\"type\":\"separator\"}")
    )
    ( equal(car(node) "popup")
      fprintf(port "{\"type\":\"popup\",\"label\":\"%s\",\"label_zh\":\"%s\",\"children\":["
        ASTB_BridgeJsonEsc(nth(1 node)) ASTB_BridgeJsonEsc(nth(2 node)))
      first = t
      foreach( child nth(3 node)
        ASTB_BridgeWriteMenuNode(port child first)
        first = nil
      )
      fprintf(port "]}")
    )
    ( t
      fprintf(port "{\"type\":\"command\",\"label\":\"%s\",\"label_zh\":\"%s\",\"command\":\"%s\"}"
        ASTB_BridgeJsonEsc(nth(1 node)) ASTB_BridgeJsonEsc(nth(2 node))
        ASTB_BridgeJsonEsc(nth(3 node)))
    )
  )
  nil
)

procedure( ASTB_BridgeExportMenuTree()
  prog((path r port tree first node p ver)
    unless( ASTB_BRIDGE_ROOT ASTB_BridgeInitRoot() )
    path = strcat(ASTB_BRIDGE_ROOT "/menu_tree.json")
    tree = ASTB_BridgeBuildMenuTree()
    ver = "unknown"
    r = errset(ver = ASTB_GetVersion())
    unless( and( r stringp(ver) strlen(ver) > 0 ) ver = "unknown" )
    r = errset(p = outfile(path))
    unless( and( r p )
      ASTB_LogError(strcat("bridge: cannot write " path))
      return(nil)
    )
    port = p
    fprintf(port "{\n")
    fprintf(port "\"version\":\"%s\",\n" ASTB_BridgeJsonEsc(ver))
    fprintf(port "\"pid\":\"%s\",\n" ASTB_BRIDGE_PID)
    fprintf(port "\"tree\":[")
    first = t
    foreach( node tree
      ASTB_BridgeWriteMenuNode(port node first)
      first = nil
    )
    fprintf(port "]\n}\n")
    close(port)
    ASTB_LogInfo(strcat("menu tree exported: " path))
    return(path)
  ))

;------------------------------------------------------------------------
; public control API
;------------------------------------------------------------------------
procedure( ASTB_BridgeStart()
  prog((r)
    when( ASTB_BRIDGE_ON
      ASTB_LogInfo("bridge already running")
      return(t)
    )
    ASTB_BridgeInitPid()
    ASTB_BridgeInitRoot()
    ; kill a leftover repeating timer from a previous load (ASTB_Reload)
    when( and( boundp('ASTB_BRIDGE_TID) ASTB_BRIDGE_TID )
      errset(axlUIWTimerRemove(ASTB_BRIDGE_TID) t)
      ASTB_BRIDGE_TID = nil
    )
    errset(ASTB_BridgeCleanup() t)
    ASTB_BRIDGE_ON = t
    ; repeating timer: third arg nil = fire repeatedly until removed.
    ; A one-shot chain is NOT safe on 16.6 (re-arm from inside the
    ; callback silently fails and the chain dies).
    r = errset(ASTB_BRIDGE_TID = axlUIWTimerAdd(nil ASTB_BRIDGE_TICK_MS nil 'ASTB_BridgeTick))
    if( and( r ASTB_BRIDGE_TID )
    then
      ASTB_LogInfo(strcat("bridge started, root=" ASTB_BRIDGE_ROOT " pid=" ASTB_BRIDGE_PID))
      errset(ASTB_BridgeExportMenuTree() t)
    else
      ASTB_BRIDGE_ON = nil
      ASTB_BRIDGE_TID = nil
      ASTB_LogError("bridge timer start failed; retry ASTB_BridgeStart() after UI is up")
    )
    return(ASTB_BRIDGE_ON)
  ))

procedure( ASTB_BridgeStop()
  prog(()
    ASTB_BRIDGE_ON = nil
    when( and( boundp('ASTB_BRIDGE_TID) ASTB_BRIDGE_TID )
      errset(axlUIWTimerRemove(ASTB_BRIDGE_TID) t)
      ASTB_BRIDGE_TID = nil
    )
    when( ASTB_BRIDGE_DIR_SESSIONS
      errset(deleteFile(strcat(ASTB_BRIDGE_DIR_SESSIONS "/s_" ASTB_BRIDGE_PID ".session")) t)
    )
    ASTB_LogInfo("bridge stopped")
    return(t)
  ))

procedure( ASTB_BridgeStatus()
  prog((rj rr nj nr)
    nj = -1
    nr = -1
    when( ASTB_BRIDGE_DIR_JOBS
      rj = errset(nj = length(getDirFiles(ASTB_BRIDGE_DIR_JOBS)))
      rr = errset(nr = length(getDirFiles(ASTB_BRIDGE_DIR_RESULTS)))
      unless( and( rj numberp(nj) ) nj = -1 )
      unless( and( rr numberp(nr) ) nr = -1 )
    )
    if( ASTB_BRIDGE_ON
    then
      printf("[ASTB] bridge ON  pid=%s root=%s jobs=%L results=%L\n"
        ASTB_BRIDGE_PID ASTB_BRIDGE_ROOT nj nr)
    else
      printf("[ASTB] bridge OFF (type astbbridge or call ASTB_BridgeStart())\n")
    )
    return(ASTB_BRIDGE_ON)
  ))

procedure( ASTB_BridgeToggle()
  prog(()
    if( ASTB_BRIDGE_ON then ASTB_BridgeStop() else ASTB_BridgeStart() )
    ASTB_BridgeStatus()
    return(ASTB_BRIDGE_ON)
  ))

;------------------------------------------------------------------------
; registration + auto-start
; (modules load after the UI is up on all supported versions; if the
;  timer still fails, the error message tells how to start manually)
;------------------------------------------------------------------------
ASTB_RegisterCommand("astbbridge" 'ASTB_BridgeToggle ?cmdType "general" ?undo nil)

; On ASTB_Reload the old ON flag survives (boundp-guarded) while its
; timer chain may already be dead - force a clean stop first so the
; repeating timer is always (re)armed by this load.
when( ASTB_BRIDGE_ON errset(ASTB_BridgeStop() t) )
errset(ASTB_BridgeStart() t)

printf("[ASTB] util_bridge.il loaded, command: astbbridge\n")
