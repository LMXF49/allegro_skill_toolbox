# -*- coding: utf-8 -*-
"""
patch_20261004_downrev_revert_midhop.py — util_downrev17.il v3.2 -> v3.3
按用户决策回退 S019 中间跳, 恢复两跳直通:
  第一跳 24.x 原生对话框存 17.4(save7) -> 第二跳免补丁 exe 直转 16.6。
回退原因(v3.2 实验结论, 实测):
  - exe 读 24.x 对话框产物报 32000016 仅发生在含底面镜像器件
    (mirrored_layers)的板; 干净板可直通(用户小板"2"实证)
  - S019 中间跳对这类板同样被拒(17.4 对话框报 mirrored_layers)
  - 17.4 编辑器打开+弄脏+另存也洗不掉(实测), 自动化无解, 回退
改动:
  1. 版本 3.3, 功能描述改写已知限制, 修改记录加 v3.3
  2. 删 _DR17_Find174Allegro/_DR17_RunMidHop174(整段)
  3. X2Hop 两分支恢复 v3.1 直通
  4. 失败提示补充 mirrored_layers/32000016 场景
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
    E("; 版本      : 3.2\n"),
    E("; 版本      : 3.3\n"),
))

# ---- 2. 功能描述: v3.2 三跳说明 -> 已知限制 ----
edits.append((
    E(";             24.x 会话三跳：原生对话框存 17.4(22.1 血统) -> 17.4\n"
      ";             对话框存 S019(QIR3 血统，免补丁 exe 只认这种) -> exe\n"
      ";             转 16.6。对话框血统的文件 exe 直读报 32000016(实测)，\n"
      ";             17.4 编辑器重存也洗不掉(实测)。\n"),
    E(";             已知限制(2026-10-04 实测)：含底面镜像器件\n"
      ";             (mirrored_layers)的板，24.x 对话框产物 exe 直读报\n"
      ";             32000016；干净板(无底面镜像器件)可直通。S019 中间跳\n"
      ";             方案(v3.2)对话框同样拒 mirrored_layers，已回退。\n"),
))

# ---- 3. 修改记录加 v3.3 ----
edits.append((
    E(";                     _DR17_Find174Allegro/_DR17_RunMidHop174\n"),
    E(";                     _DR17_Find174Allegro/_DR17_RunMidHop174\n"
      ";   2026-10-04 v3.3 ASTB Team 按用户决策回退 v3.2 中间跳，恢复两跳\n"
      ";                     (24.x 对话框存 17.4 -> 免补丁 exe 直转)；删\n"
      ";                     中间跳两函数；失败提示补 mirrored_layers/\n"
      ";                     32000016 场景说明\n"),
))

# ---- 4. 删两个中间跳过程(整段, 与 v3.2 插入文本逐字对应) ----
MIDHOP_BLOCK = E(
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
edits.append((MIDHOP_BLOCK, E("")))

# ---- 5. X2Hop 批处理分支恢复直通 ----
edits.append((
    E("    path174 = _DR17_RunX2HopBatch(dir name brd)\n"
      "    when( path174\n"
      "      axlMsgPut(\"第二跳: 17.4 对话框存 S019(免补丁转换器只认此血统)...\")\n"
      "      path174 = _DR17_RunMidHop174(dir name path174)\n"
      "    )\n"
      "    when( path174\n"
      "      axlMsgPut(\"第三跳: 17.4 -> 16.6 转换中...\")\n"
      "      return( _DR17_RunExe(exe dir name path174) )\n"
      "    )\n"),
    E("    path174 = _DR17_RunX2HopBatch(dir name brd)\n"
      "    when( path174\n"
      "      axlMsgPut(\"第二跳: 17.4 -> 16.6 转换中...\")\n"
      "      return( _DR17_RunExe(exe dir name path174) )\n"
      "    )\n"),
))

# ---- 6. X2Hop 会话内回放分支恢复直通 ----
edits.append((
    E("    axlMsgPut(\"第一跳完成, 第二跳: 17.4 对话框存 S019...\")\n"
      "    path174 = _DR17_RunMidHop174(dir name path174)\n"
      "    unless( path174 return(nil) )\n"
      "    axlMsgPut(\"第三跳: 17.4 -> 16.6 转换中...\")\n"
      "    return( _DR17_RunExe(exe dir name path174) )\n"),
    E("    axlMsgPut(\"第一跳完成, 第二跳: 17.4 -> 16.6 转换中...\")\n"
      "    return( _DR17_RunExe(exe dir name path174) )\n"),
))

# ---- 7. 失败提示补 mirrored_layers 场景 ----
edits.append((
    E("            axlUIConfirm(\"降版本失败: 设计含 16.6 不支持的特性(详见弹出日志)。\\n多叠层/多 Zone/新焊盘形状/POLY_VIA/BACKDRILL 等\\n需先在 17.4 中移除后再试\")\n"),
    E("            axlUIConfirm(\"降版本失败: 设计含 16.6 不支持的特性(详见弹出日志)。\\n多叠层/多 Zone/新焊盘形状/POLY_VIA/BACKDRILL 等\\n需先在 17.4 中移除后再试。\\n\\n若日志报 mirrored_layers/32000016: 该板含底面镜像\\n器件, 免补丁转换器暂不支持自动转换(中间跳方案已回退)。\")\n"),
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
