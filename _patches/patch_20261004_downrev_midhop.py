# -*- coding: utf-8 -*-
"""
patch_20261004_downrev_midhop.py — util_downrev17.il v3.1 -> v3.2
背景: 免补丁 adl(阿狸狗/精灵构建)读不了"对话框存出的 17.4"——24.x 第一跳
走原生对话框(save7, 22.1 血统)产出的 174 中间件 exe 报 error in open
drawing = 32000016; 连 17.4 编辑器打开重存也无法洗掉该血统(实测)。
但 exe 认 17.4 对话框 save6 存出的 S019(QIR3)血统(实测 total converted:1,
层数据与源完全一致)。故 24.x 链路插中间跳:
  24.x 对话框(22.1 血统) -> 17.4 对话框 save6(S019 血统) -> exe -> 16.6
改动:
  1. 文件头 版本 3.2 + 功能描述 + 修改记录
  2. 新增 _DR17_Find174Allegro / _DR17_RunMidHop174
  3. _DR17_RunX2Hop 两条分支(批处理/会话内回放)都插中间跳
GBK 显式往返写盘, 留档 _patches/。
"""
import codecs
import sys

PATH = "G:/ASTB/skill_src/modules/utilities/util_downrev17.il"

src = codecs.open(PATH, "r", "gbk").read()
crlf = "\r\n" in src


def E(text):
    t = text.replace("\r\n", "\n")
    if crlf:
        t = t.replace("\n", "\r\n")
    return t


edits = []

# ---- 1. 版本号 ----
edits.append((
    E("; 版本      : 3.1\n"),
    E("; 版本      : 3.2\n"),
))

# ---- 2. 功能描述追加 24.x 三跳说明 ----
edits.append((
    E(";             构建无此 bug（同 md5 8876705d）。\n"),
    E(";             构建无此 bug（同 md5 8876705d）。\n"
      ";             24.x 会话三跳：原生对话框存 17.4(22.1 血统) -> 17.4\n"
      ";             对话框存 S019(QIR3 血统，免补丁 exe 只认这种) -> exe\n"
      ";             转 16.6。对话框血统的文件 exe 直读报 32000016(实测)，\n"
      ";             17.4 编辑器重存也洗不掉(实测)。\n"),
))

# ---- 3. 修改记录加 v3.2 ----
edits.append((
    E(";                     8876705d）；bat 内 rt/bin 置顶 PATH（混用 17.4\n"
      ";                     DLL 静默退出，实测）；exe 缺失指引同步更新\n"),
    E(";                     混用 17.4\n"
      ";                     DLL 静默退出，实测）；exe 缺失指引同步更新\n"
      ";   2026-10-04 v3.2 ASTB Team 修 24.x 链路：免补丁 exe 读不了对话框\n"
      ";                     存的 17.4(22.1 血统, error 32000016, 17.4 重存\n"
      ";                     无效, 实测)，但认 17.4 对话框 save6 存的 S019\n"
      ";                     血统(实测层数据与源一致)；X2Hop 插第二跳(起\n"
      ";                     17.4 实例回放 save6), 24.x 全程三跳；新增\n"
      ";                     _DR17_Find174Allegro/_DR17_RunMidHop174\n"),
))

# ---- 4. X2Hop 批处理分支插中间跳 ----
edits.append((
    E("    path174 = _DR17_RunX2HopBatch(dir name brd)\n"
      "    when( path174\n"
      "      axlMsgPut(\"第二跳: 17.4 -> 16.6 转换中...\")\n"
      "      return( _DR17_RunExe(exe dir name path174) )\n"
      "    )\n"),
    E("    path174 = _DR17_RunX2HopBatch(dir name brd)\n"
      "    when( path174\n"
      "      axlMsgPut(\"第二跳: 17.4 对话框存 S019(免补丁转换器只认此血统)...\")\n"
      "      path174 = _DR17_RunMidHop174(dir name path174)\n"
      "    )\n"
      "    when( path174\n"
      "      axlMsgPut(\"第三跳: 17.4 -> 16.6 转换中...\")\n"
      "      return( _DR17_RunExe(exe dir name path174) )\n"
      "    )\n"),
))

# ---- 5. X2Hop 会话内回放分支插中间跳 ----
edits.append((
    E("    axlMsgPut(\"第一跳完成, 第二跳: 17.4 -> 16.6 转换中...\")\n"
      "    return( _DR17_RunExe(exe dir name path174) )\n"),
    E("    axlMsgPut(\"第一跳完成, 第二跳: 17.4 对话框存 S019...\")\n"
      "    path174 = _DR17_RunMidHop174(dir name path174)\n"
      "    unless( path174 return(nil) )\n"
      "    axlMsgPut(\"第三跳: 17.4 -> 16.6 转换中...\")\n"
      "    return( _DR17_RunExe(exe dir name path174) )\n"),
))

# ---- 6. 新增两个过程(插在 X2Hop 定义前) ----
NEW_PROCS = E(
    ";------------------------------------------------------------------------\n"
    "; 函数名  : _DR17_Find174Allegro\n"
    "; 功能    : 定位 17.4 安装的 allegro.exe(中间跳要起 17.4 实例跑对话框)\n"
    "; 返回值  : exe 路径 / nil\n"
    "; 优先级  : CDSROOT 版本替换(2x.x/25.1 -> 17.4) > 常见安装位\n"
    ";------------------------------------------------------------------------\n"
    "procedure( _DR17_Find174Allegro()\n"
    "  prog((roots cdsroot alt found r c exe)\n"
    "    cdsroot = getShellEnvVar(\"CDSROOT\")\n"
    "    roots = nil\n"
    "    when( cdsroot\n"
    "      cdsroot = axlOSSlash(cdsroot)\n"
    "      roots = cons(cdsroot roots)\n"
    "      foreach( v '(\"24.1\" \"23.1\" \"22.1\" \"25.1\")\n"
    "        when( rexMatchp(v cdsroot)\n"
    "          alt = rexReplace(cdsroot v 1 \"17.4\")\n"
    "          unless( member(alt roots) roots = cons(alt roots) )\n"
    "        )\n"
    "      )\n"
    "    )\n"
    "    foreach( r '(\"D:/Cadence/SPB_17.4\" \"C:/Cadence/SPB_17.4\")\n"
    "      unless( member(r roots) roots = cons(r roots) )\n"
    "    )\n"
    "    found = nil\n"
    "    foreach( r roots\n"
    "      foreach( c '(\"/tools/bin/allegro.exe\" \"/tools/pcb/bin/allegro.exe\")\n"
    "        exe = strcat(r c)\n"
    "        when( and(null(found) isFile(exe)) found = exe )\n"
    "      )\n"
    "    )\n"
    "    return(found)\n"
    "  )\n"
    ")\n"
    "\n"
    ";------------------------------------------------------------------------\n"
    "; 函数名  : _DR17_RunMidHop174\n"
    "; 功能    : 中间跳: 起 17.4 实例回放原生 Downrev 对话框, 把 22.1 血统\n"
    ";           的 174 文件另存为 S019(QIR3)血统(v3.2 实锤: 免补丁 exe 只认\n"
    ";           对话框 S019 血统; 22.1 血统报 32000016, 编辑器重存无效)\n"
    "; 参数    : dir/name - 工作目录/设计名; path174 - 第一跳产物\n"
    "; 返回值  : S019 中间文件路径 / nil(失败已提示)\n"
    ";------------------------------------------------------------------------\n"
    "procedure( _DR17_RunMidHop174(dir name path174)\n"
    "  prog((exe midRoot midBin tmpIn tmpMid pathMid scrPath batPath port n ok)\n"
    "    exe = _DR17_Find174Allegro()\n"
    "    unless( exe\n"
    "      axlUIConfirm(\"第二跳找不到 17.4 安装(allegro.exe)。\\n请装 17.4, 或手工: 用 17.4 打开 *_174.brd,\\nDownrev 对话框选 \\\"Save design to 17.4 S019 (QIR3)\\\" 另存后再执行本命令。\")\n"
    "      return(nil)\n"
    "    )\n"
    "    ;; exe 所在根与 bin 目录(bat 里 CDSROOT/PATH 指向 17.4 自身)\n"
    "    midRoot = nil\n"
    "    midBin = nil\n"
    "    when( rexMatchp(\"/tools/bin/allegro.exe$\" exe)\n"
    "      midRoot = substring(exe 1 strlen(exe) - 21)\n"
    "      midBin = strcat(midRoot \"/tools/bin\")\n"
    "    )\n"
    "    when( rexMatchp(\"/tools/pcb/bin/allegro.exe$\" exe)\n"
    "      midRoot = substring(exe 1 strlen(exe) - 25)\n"
    "      midBin = strcat(midRoot \"/tools/pcb/bin\")\n"
    "    )\n"
    "    tmpIn = strcat(axlTempDirectory() \"/\" name \"_midin.brd\")\n"
    "    tmpMid = strcat(axlTempDirectory() \"/\" name \"_s019.brd\")\n"
    "    pathMid = _DR17_OutputPath(dir name \"s019\")\n"
    "    foreach( f list(tmpIn tmpMid)\n"
    "      when( isFile(f) errset(deleteFile(f) t) )\n"
    "    )\n"
    "    ok = errset(axlOSFileCopy(path174 tmpIn nil) t)\n"
    "    unless( and(ok car(ok))\n"
    "      axlUIConfirm(\"中间跳输入复制失败: \" tmpIn)\n"
    "      return(nil)\n"
    "    )\n"
    "    ;; 回放脚本: 17.4 对话框 save6=S019(QIR3), fillin 喂输出路径\n"
    "    scrPath = strcat(axlTempDirectory() \"/dr174_mid.scr\")\n"
    "    port = outfile(scrPath \"w\")\n"
    "    unless( port\n"
    "      axlUIConfirm(\"无法创建临时脚本文件\")\n"
    "      return(nil)\n"
    "    )\n"
    "    fprintf(port \"scriptmode +i\\n\")\n"
    "    fprintf(port \"downrev\\n\")\n"
    "    fprintf(port \"setwindow form.downrev\\n\")\n"
    "    fprintf(port \"FORM downrev save6\\n\")\n"
    "    fprintf(port \"FORM downrev save\\n\")\n"
    "    fprintf(port \"fillin \\\"%s\\\"\\n\" tmpMid)\n"
    "    fprintf(port \"exit\\n\")\n"
    "    close(port)\n"
    "    batPath = strcat(axlTempDirectory() \"/dr174_mid.bat\")\n"
    "    port = outfile(batPath \"w\")\n"
    "    unless( port\n"
    "      axlUIConfirm(\"无法创建临时 bat 文件\")\n"
    "      return(nil)\n"
    "    )\n"
    "    fprintf(port \"@echo off\\r\\n\")\n"
    "    fprintf(port \"set \\\"CDSROOT=%s\\\"\\r\\n\" midRoot)\n"
    "    fprintf(port \"set \\\"PATH=%s;%%PATH%%\\\"\\r\\n\" midBin)\n"
    "    fprintf(port \"\\\"%s\\\" -s \\\"%s\\\" \\\"%s\\\"\\r\\n\" exe scrPath tmpIn)\n"
    "    close(port)\n"
    "    axlMsgPut(\"中间跳: 起 17.4 实例存 S019(约 1 分钟, 请稍候)...\")\n"
    "    ASTB_DebugLog(strcat(\"Downrev166: midhop exe=\" exe \" in=\" tmpIn))\n"
    "    system(strcat(\"cmd /c start \\\"\\\" \\\"\" batPath \"\\\"\"))\n"
    "    n = 0\n"
    "    while( and(null(isFile(tmpMid)) n < 120)\n"
    "      sleep(1)\n"
    "      n = n+1\n"
    "    )\n"
    "    unless( isFile(tmpMid)\n"
    "      axlUIConfirm(\"中间跳超时(120s 未出 S019 文件)。\\n若新开的 17.4 停在产品选择/Downrev 对话框,\\n请手动: 选 \\\"Save design to 17.4 S019 (QIR3)\\\" 存出后再执行本命令。\")\n"
    "      return(nil)\n"
    "    )\n"
    "    ok = errset(axlOSFileCopy(tmpMid pathMid nil) t)\n"
    "    unless( and(ok car(ok))\n"
    "      axlUIConfirm(\"S019 中间文件拷回失败: \" pathMid)\n"
    "      return(nil)\n"
    "    )\n"
    "    foreach( f list(tmpIn tmpMid scrPath batPath)\n"
    "      errset(deleteFile(f) t)\n"
    "    )\n"
    "    axlMsgPut(\"中间跳完成(S019 血统)。\")\n"
    "    return(pathMid)\n"
    "  )\n"
    ")\n"
    "\n"
)

edits.append((
    E(";------------------------------------------------------------------------\n"
      "procedure( _DR17_RunX2Hop(exe dir name brd)\n"),
    E(";------------------------------------------------------------------------\n") + NEW_PROCS +
    E("procedure( _DR17_RunX2Hop(exe dir name brd)\n"),
))

for i, (old, new) in enumerate(edits, 1):
    n = src.count(old)
    if n != 1:
        print("EDIT %d: anchor found %d times, ABORT" % (i, n))
        sys.exit(1)
    src = src.replace(old, new, 1)

depth = 0
in_str = False
in_comment = False
esc = False
for ch in src:
    if in_comment:
        if ch == "\n":
            in_comment = False
        continue
    if in_str:
        if esc:
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == '"':
            in_str = False
        continue
    if ch == '"':
        in_str = True
    elif ch == ";":
        in_comment = True
    elif ch == "(":
        depth += 1
    elif ch == ")":
        depth -= 1
        if depth < 0:
            print("PAREN NEGATIVE, ABORT")
            sys.exit(1)
if depth != 0 or in_str:
    print("UNBALANCED (depth=%d in_str=%s), ABORT" % (depth, in_str))
    sys.exit(1)

codecs.open(PATH, "w", "gbk").write(src)
back = codecs.open(PATH, "r", "gbk").read()
assert back == src
print("OK: %d edits applied, paren OK, GBK roundtrip OK" % len(edits))
