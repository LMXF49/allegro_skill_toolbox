;========================================================================
; 文件名    : modules/utilities/util_openstudio.il
; 作者      : ASTB Team
; 创建日期  : 2026-09-29
; 版本      : 1.5
; 功能描述  : 打开外置软件 ASTB Studio：从 Allegro 内一键启动外置桌面
;             程序（项目列表/命令面板/快捷键表格），start 后台拉起不
;             阻塞 Allegro；按安装布局自动定位 ASTBStudio.exe
; 依赖模块  : core/trans.il（ASTB_RegisterCommand）
; 修改记录  :
;   2026-09-29 v1.0 ASTB Team 初始创建：候选路径 = 安装根目录\studio\
;                ASTBStudio.exe（安装版布局 <dir>\skill + <dir>\studio）
;                → 开发环境 tools\dist\ASTBStudio\；找不到时命令行
;                提示期望路径，不弹窗
;   2026-09-29 v1.1 ASTB Team 修加载 syntax error: axlShell 行避开
;                紧邻闭引号的 \" 组合, 双引号字符改由
;                substring("a\"b" 2 1) 从串中部取(arrowcopy 实证
;                串中 \" 全版本可读)
;   2026-09-29 v1.2 ASTB Team axlShell 换 ipcBeginProcess: axlShell
;                喂的是 Allegro 命令行("start ..." 被当 Allegro
;                命令报 Command not found), 起 OS 程序走手册 §6.1
;                ipcBeginProcess 直起进程, 不 ipcWait 不阻塞
;   2026-09-29 v1.3 ASTB Team ipcBeginProcess 第6参(logFile)必须是
;                字符串(template "ttgggt"), nil 改传 ""
;   2026-09-30 v1.4 ASTB Team 候选路径加入 C++ 原生版并优先:
;                安装根\studio\ASTBStudio.exe → 开发环境
;                cpp\dist\ASTBStudioCpp.exe → 开发环境旧 Python
;                tools\dist(回退)
;   2026-09-30 v1.5 ASTB Team 候选加入 Java 版并优先: 安装根\studio\
;                ASTBStudio.exe -> java\dist\ASTBStudio.jar(Java 版,
;                .jar 走 ipcBeginProcess("java" "-jar ...") 直起) ->
;                cpp\dist(C++ 归档) -> tools\dist(旧 Python 回退)
;========================================================================

;------------------------------------------------------------------------
; 函数名  : _OST_ParentDir
; 功能    : 取路径的上一级目录（"/" 分隔；无上一级返回 ""）
;------------------------------------------------------------------------
procedure( _OST_ParentDir(p)
    prog((parts out)
        parts = parseString(p "/")
        unless( and(parts cdr(parts)) return("") )
        out = car(parts)
        parts = cdr(parts)
        while( cdr(parts)
            out = strcat(out "/" car(parts))
            parts = cdr(parts)
        )
        return(out)
    )
)

;------------------------------------------------------------------------
; 函数名  : _OST_WinPath
; 功能    : "/" 路径转 "\\" Windows 反斜杠路径（供 cmd start 使用）
;------------------------------------------------------------------------
procedure( _OST_WinPath(p)
    prog((out x parts)
        parts = parseString(p "/")
        out = car(parts)
        foreach( x cdr(parts)
            out = strcat(out "\\" x)
        )
        return(out)
    )
)

;------------------------------------------------------------------------
; 函数名  : _OST_FindStudio
; 功能    : 按候选路径找 ASTBStudio.exe；找到返回全路径，否则 nil
; 候选    : 1. 安装根目录\studio\ASTBStudio.exe（安装版布局）
;           2. 安装根目录\tools\dist\ASTBStudio\ASTBStudio.exe（开发环境）
;------------------------------------------------------------------------
; 函数名  : _OST_HasSuffix
; 功能    : 判断字符串是否以给定后缀结尾(大小写不敏感)
;------------------------------------------------------------------------
procedure( _OST_HasSuffix(str suffix)
    prog((n m)
        n = strlen(str)
        m = strlen(suffix)
        if( n < m then return(nil) )
        return( equal(lowerCase(substring(str n - m + 1 m)) lowerCase(suffix)) )
    )
)

;------------------------------------------------------------------------
procedure( _OST_FindStudio()
    prog((root cands c exe)
        root = _OST_ParentDir(ASTB_GLOBAL->InstallPath)
        cands = list(
            strcat(root "/studio/ASTBStudio.exe")
            strcat(root "/java/dist/ASTBStudio.jar")
            strcat(root "/cpp/dist/ASTBStudioCpp.exe")
            strcat(root "/tools/dist/ASTBStudio/ASTBStudio.exe")
        )
        exe = nil
        foreach( c cands
            when( and(null(exe) isFile(c))
                exe = c
            )
        )
        return(exe)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_OpenStudio
; 功能    : 命令入口（菜单 System -> Open Studio / 命令行 studio）
;------------------------------------------------------------------------
procedure( ASTB_OpenStudio()
    prog((exe win cid args q)
        exe = _OST_FindStudio()
        if( exe then
            win = _OST_WinPath(exe)
            ; v1.2: ipcBeginProcess 直起进程(§6.1), 不经 cmd/start 不阻塞;
            ;       axlShell 是喂 Allegro 命令行的, 起不了 OS 程序
            ; v1.5: .jar 候选走 java -jar(java 在 PATH), exe 候选直起;
            ;       引号字符从串中部取(pitfalls 4.18, 紧邻闭引号的转义
            ;       个别版本 reader 不吃)
            q = substring("a\"b" 2 1)
            if( _OST_HasSuffix(exe ".jar") then
                args = strcat("-jar " q win q)
                cid = ipcBeginProcess("java" args nil nil nil "")
            else
                cid = ipcBeginProcess(win "" nil nil nil "")
            )
            axlUIWPrint(nil "\322\321\306\364\266\257\315\342\326\303\310\355\274\376: %s" exe)
        else
            axlUIWPrint(nil "\316\264\325\322\265\275 ASTBStudio.exe\243\250\306\332\315\373\324\332\260\262\327\260\270\371\304\277\302\274 studio\\ \317\302\243\251\243\254\307\353\317\310\260\262\327\260\315\342\326\303\310\355\274\376")
        )
        return(t)
    )
)

ASTB_RegisterCommand("ASTB_OpenStudio" "ASTB_OpenStudio" ?cmdType "general" ?undo nil)
ASTB_RegisterCommand("studio" "ASTB_OpenStudio" ?cmdType "general" ?undo nil)

printf("[ASTB] util_openstudio.il v1.5 loaded, command: studio\n")
