;========================================================================
; 文件名    : utf8_loader.il
; 作者      : SkillGroup / ASTB 项目组(整合)
; 创建日期  : 2026-07-18
; 版本      : 2.0
; 功能描述  : UTF-8 到 GBK 自动转码加载器
;             允许模块作者用 UTF-8 编写 .il 文件(现代编辑器),
;             ASTB_LoadDir 加载时自动检测(UTF-8 BOM 或 *_utf8.il 命名)
;             并转码为 GBK 缓存(<install>/_gbk_cache/)后再加载
;             配置开关: ASTB_SetConfig("utf8_autoconv" "off") 关闭(默认 on)
; 依赖模块  : tools/utf8_to_gbk.py (Windows) 或 iconv (Linux)
; 使用      :
;   手动    : ASTB_LoadUTF8Skill("G:/allegro/allegro_skill/modules/xxx.il")
;   批量    : ASTB_BatchLoadUTF8Skill(list("a.il" "b.il"))
;   自动    : ASTB_LoadDir 内部调用 ASTB_UTF8_NeedConvert + ASTB_UTF8_ToGbk
; 修改记录  :
;   2026-07-17 v1.0 SkillGroup 初始创建(独立项目, 纯 ASCII)
;   2026-07-18 v2.0 ASTB 项目组 整合入 core/, API 加 ASTB_ 前缀;
;                缓存目录移到安装根 _gbk_cache/; 增加 BOM 检测与配置开关
;   2026-07-19 v2.0.1 ASTB 文件头中文化并转 GBK, 符合工具箱核心文件约定
;   2026-08-01 v2.0.2 ASTB 项目组 NeedConvert 内包 errset 防抛错(根除每文件
;                ERROR 噪音); Enabled/EndsWith 字符串比较由 ==/!= 改 equal
;   2026-08-01 v2.0.3 ASTB 项目组 ASTB_UTF8_ToGbk 的 let 改 prog（体内 return
;                需 prog 环境，冒烟审计命中）；平台判断 == 改 equal（字符串
;                身份比较恒假，Windows/python 分支此前从未命中）
; 编码      : GBK (文件头中文; 函数体与字符串保持纯英文, 跨编码安全)
;========================================================================

;------------------------------------------------------------------------
; Global variables initialization
;------------------------------------------------------------------------
unless(boundp('g_utf8LoaderVersion)
    g_utf8LoaderVersion = "2.0"
)

;------------------------------------------------------------------------
; Module constants
;------------------------------------------------------------------------
C_UTF8_LOADER_MODULE = "ASTB_UTF8Loader"

;------------------------------------------------------------------------
; Function  : _ASTB_UTF8_EndsWith
; Purpose   : Check if string str ends with suffix (local copy to avoid
;             load-order dependency on core/utils.il)
; Params    :
;   @param str    - source string
;   @param suffix - suffix string
; Returns   : t/nil
;------------------------------------------------------------------------
procedure( _ASTB_UTF8_EndsWith(str suffix)
    let((ls lz)
        ls = strlen(str)
        lz = strlen(suffix)
        and( ls >= lz equal(substring(str ls - lz + 1 lz) suffix) )
    )
)

;------------------------------------------------------------------------
; Function  : ASTB_UTF8_Enabled
; Purpose   : Check config gate "utf8_autoconv" (default on). When the
;             config module is not available, defaults to enabled.
; Params    : none
; Returns   : t - auto transcode enabled, nil - disabled
;------------------------------------------------------------------------
procedure( ASTB_UTF8_Enabled()
    if( fboundp('ASTB_GetConfig) then
        not(equal(ASTB_GetConfig("utf8_autoconv" "on") "off"))
    else
        t
    )
)

;------------------------------------------------------------------------
; Function  : ASTB_UTF8_HasBOM
; Purpose   : Detect UTF-8 BOM (EF BB BF) at file start
; Params    :
;   @param filePath - file to check
; Returns   : t - BOM present, nil - no BOM or unreadable
;------------------------------------------------------------------------
procedure( ASTB_UTF8_HasBOM(filePath)
    let((port b1 b2 b3 result)
        result = nil
        port = infile(filePath)
        when( port
            b1 = getc(port)
            b2 = getc(port)
            b3 = getc(port)
            close(port)
            when( and( b1 b2 b3
                       charToInt(b1) == 239
                       charToInt(b2) == 187
                       charToInt(b3) == 191 )
                result = t
            )
        )
        result
    )
)

;------------------------------------------------------------------------
; Function  : ASTB_UTF8_NeedConvert
; Purpose   : Decide whether a module file should be transcoded before
;             loading: config enabled AND (UTF-8 BOM present OR file
;             name ends with "_utf8.il")
; Params    :
;   @param filePath - full path of the .il file
; Returns   : t/nil
;------------------------------------------------------------------------
procedure( ASTB_UTF8_NeedConvert(filePath)
    ;; v2.0.2: 内部 errset 兜底--上游配置/读取异常时按"不转码"返回 nil,
    ;; 不再向外抛错（外层每文件刷 ERROR 日志的噪音根因）；car 解包 errset
    car(errset(
        and( ASTB_UTF8_Enabled()
             or( ASTB_UTF8_HasBOM(filePath)
                 _ASTB_UTF8_EndsWith(filePath "_utf8.il") ) )
    t))
)

;------------------------------------------------------------------------
; Function  : _ASTB_UTF8_InstallDir
; Purpose   : Best-effort install dir detection (ASTB_GLOBAL first,
;             then nil when unknown)
; Params    : none
; Returns   : string - install dir path, or nil
;------------------------------------------------------------------------
procedure( _ASTB_UTF8_InstallDir()
    if( and(boundp('ASTB_GLOBAL) ASTB_GLOBAL) then
        ASTB_GLOBAL->InstallDir
    else
        nil
    )
)

;------------------------------------------------------------------------
; Function  : ASTB_UTF8_FindHelper
; Purpose   : Locate utf8_to_gbk.py: <install>/tools first, then every
;             skill path directory
; Params    : none
; Returns   : string - full path of utf8_to_gbk.py, nil if not found
;------------------------------------------------------------------------
procedure( ASTB_UTF8_FindHelper()
    let((installDir candidate fullPath found)
        found = nil
        installDir = _ASTB_UTF8_InstallDir()
        when( installDir
            candidate = strcat(installDir "/tools/utf8_to_gbk.py")
            when( infile(candidate)
                close(infile(candidate))
                found = candidate
            )
        )
        unless( found
            foreach( dir getSkillPath()
                unless( found
                    fullPath = strcat(dir "/utf8_to_gbk.py")
                    when( infile(fullPath)
                        close(infile(fullPath))
                        found = fullPath
                    )
                )
            )
        )
        found
    )
)

;------------------------------------------------------------------------
; Function  : ASTB_UTF8_GetCacheDir
; Purpose   : Return (and create if needed) the GBK cache directory:
;             <install>/_gbk_cache ; falls back to nil when unknown so
;             caller can use the source file's own directory
; Params    : none
; Returns   : string - cache dir path, or nil
;------------------------------------------------------------------------
procedure( ASTB_UTF8_GetCacheDir()
    let((installDir cacheDir)
        cacheDir = nil
        installDir = _ASTB_UTF8_InstallDir()
        when( installDir
            cacheDir = strcat(installDir "/_gbk_cache")
            unless( isDir(cacheDir)
                errset(createDir(cacheDir) t)
            )
            unless( isDir(cacheDir)
                cacheDir = nil
            )
        )
        cacheDir
    )
)

;------------------------------------------------------------------------
; Function  : ASTB_UTF8_GetGbkPath
; Purpose   : Build the GBK output path for a UTF-8 source file:
;             <cacheDir>/<basename_without_il>_gbk.il
;             Falls back to <source_dir>/<name>_gbk.il when no cache dir
; Params    :
;   @param filePath - UTF-8 source file path
; Returns   : string - GBK output path
;------------------------------------------------------------------------
procedure( ASTB_UTF8_GetGbkPath(filePath)
    let((parts base cacheDir outDir)
        parts = parseString(filePath "/")
        base = car(last(parts))
        when( _ASTB_UTF8_EndsWith(base ".il")
            base = substring(base 1 strlen(base) - 3)
        )
        cacheDir = ASTB_UTF8_GetCacheDir()
        if( cacheDir then
            outDir = cacheDir
        else
            ; fallback: same directory as the source file
            parts = parseString(filePath "/")
            outDir = buildString(reverse(cdr(reverse(parts))) "/")
        )
        strcat(outDir "/" base "_gbk.il")
    )
)

;------------------------------------------------------------------------
; Function  : ASTB_UTF8_ToGbk
; Purpose   : Convert a UTF-8 .il file to GBK (cache location).
;             Windows: python tools/utf8_to_gbk.py ; Linux: iconv
; Params    :
;   @param filePath - full path to the UTF-8 .il file
; Returns   : string - GBK file path on success
;             nil    - conversion failed
; Example   : ASTB_UTF8_ToGbk("G:/skill/modules/foo_utf8.il")
;------------------------------------------------------------------------
procedure( ASTB_UTF8_ToGbk(filePath)
    ;; v2.0.3: let 改 prog（体内 return 需 prog 环境）
    prog((gbkPath platform scriptPath cmd result osVar)
        gbkPath = ASTB_UTF8_GetGbkPath(filePath)

        ; Detect platform
        osVar = getShellEnvVar("OS")
        platform = if( equal(osVar "Windows_NT") then "windows" else "linux" )

        if( equal(platform "windows") then
            ; ---- Windows: use Python helper script ----
            scriptPath = ASTB_UTF8_FindHelper()
            if( null(scriptPath) then
                printf("[%s][ERROR] utf8_to_gbk.py not found (checked <install>/tools and skill path)\n"
                       C_UTF8_LOADER_MODULE)
                return(nil)
            )
            cmd = sprintf(nil "python \"%s\" \"%s\" \"%s\""
                          scriptPath filePath gbkPath)
        else
            ; ---- Linux: use iconv directly ----
            cmd = sprintf(nil "iconv -f UTF-8 -t GBK '%s' > '%s'"
                          filePath gbkPath)
        )

        result = system(cmd)
        if( result != 0 then
            printf("[%s][ERROR] UTF8->GBK conversion failed for: %s (exit code: %d)\n"
                   C_UTF8_LOADER_MODULE filePath result)
            return(nil)
        )

        printf("[%s] Converted UTF8->GBK: %s -> %s\n"
               C_UTF8_LOADER_MODULE filePath gbkPath)
        gbkPath
    )
)

;------------------------------------------------------------------------
; Function  : ASTB_LoadUTF8Skill
; Purpose   : Convert a UTF-8 encoded SKILL file to GBK and load it
; Params    :
;   @param filePath - full path to the UTF-8 .il file
; Returns   : t   - loaded successfully
;             nil - conversion or loading failed
; Example   : ASTB_LoadUTF8Skill("G:/skill/modules/foo_utf8.il")
;------------------------------------------------------------------------
procedure( ASTB_LoadUTF8Skill(filePath)
    let((gbkPath)
        gbkPath = ASTB_UTF8_ToGbk(filePath)
        when( gbkPath
            printf("[%s] Loading GBK file: %s\n"
                   C_UTF8_LOADER_MODULE gbkPath)
            load(gbkPath)
        )
    )
)

;------------------------------------------------------------------------
; Function  : ASTB_BatchLoadUTF8Skill
; Purpose   : Batch load multiple UTF-8 SKILL files
; Params    :
;   @param fileList - list of UTF-8 .il file paths
; Returns   : list of t/nil results for each file
; Example   : ASTB_BatchLoadUTF8Skill(list("a.il" "b.il" "c.il"))
;------------------------------------------------------------------------
procedure( ASTB_BatchLoadUTF8Skill(fileList)
    let((results)
        results = nil
        foreach( filePath fileList
            results = append1(results ASTB_LoadUTF8Skill(filePath))
        )
        results
    )
)

;------------------------------------------------------------------------
; Module initialization
;------------------------------------------------------------------------
printf("[%s] UTF-8 auto-transcoding loader ready, version %s\n"
       C_UTF8_LOADER_MODULE g_utf8LoaderVersion)
printf("[%s] Manual: ASTB_LoadUTF8Skill(\"your_utf8_file.il\") ; auto: BOM or *_utf8.il via ASTB_LoadDir\n"
       C_UTF8_LOADER_MODULE)
