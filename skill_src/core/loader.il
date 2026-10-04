;========================================================================
; 文件名    : core/loader.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-06-06
; 版本      : 1.7
; 功能描述  : 模块自动加载器（核心库按序加载、modules 目录递归加载，
;             逐文件 errset 保护并记录失败）
; 依赖模块  : core/utils.il（ASTB_StringEndsWith，运行时调用）
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-06-06 v1.0 allegro_skill 项目组 初始创建
;   2026-07-17 v1.1 修复组_框架核心 ASTB_HasSuffix 改为调用 utils.il 的
;                   ASTB_StringEndsWith（原实现与 utils 完全重复，且
;                   substring 第三参误用 lenStr 属脆弱写法）
;   2026-07-18 v1.2 ASTB 项目组 ASTB_LoadDir 接入 UTF-8 自动转码分支(配套 core/utf8_loader.il)
;   2026-07-25 v1.3 ASTB 项目组 单文件处理全程纳入 errset 并点名
;                   记录（此前 UTF8 检测/递归路径出错会中断整个
;                   LoadModules）
;   2026-08-01 v1.4 ASTB 项目组 load 失败经 errsetstring 带回错误原文
;                   写日志；UTF8 转码失败回退原文件加载不再中断；
;                   NeedConvert 失败日志降级为 DebugLog（CIW 降噪）
;   2026-08-01 v1.5 ASTB 项目组 修复 v1.4 errsetstring 误用：第一参
;                   误传 load(loadPath) 表达式（先执行 load 返回 t，
;                   errsetstring(t t) 报 argument #1 should be a
;                   string），导致启动时每个模块一条 *Error* +
;                   误报 ASTB_LoadDir error；改为表达式字符串，
;                   成功判定加 listp 防御
;   2026-08-01 v1.6 ASTB 项目组 ASTB_LoadModules 结束打印
;                   成功/失败汇总与失败清单（ASTB_LOAD_OK /
;                   ASTB_LOAD_FAILED 计数），真错误不再淹没在
;                   逐文件日志里
;   2026-09-29 v1.7 ASTB Team ASTB_LoadCore 扫描排除 ilinit_block.il:
;                   该文件是安装器/Studio 注入 allegro.ilinit 用的模板
;                   (含 @INSTALL_DIR@ 占位符), 被目录扫描当代码加载
;                   会报 load @INSTALL_DIR@/main.il 错
;========================================================================

;------------------------------------------------------------------------
; 加载计数（ASTB_LoadModules 汇总用，boundp 保护防 Reload 告警）
;------------------------------------------------------------------------
unless( boundp('ASTB_LOAD_OK)     ASTB_LOAD_OK     = 0 )
unless( boundp('ASTB_LOAD_FAILED) ASTB_LOAD_FAILED = nil )

;------------------------------------------------------------------------
; 函数名  : ASTB_HasSuffix
; 功能    : 判断字符串是否以指定后缀结尾
; 参数    : str - 输入字符串；suffix - 后缀
; 返回值  : t / nil
; 备注    : 唯一实现位于 core/utils.il 的 ASTB_StringEndsWith，此处仅
;           作转发以保持向后兼容。本函数首次被调用时（ASTB_LoadCore 内）
;           utils.il 已加载完毕；若 utils.il 加载失败，外层 errset 会
;           捕获本函数的未绑定错误并记录日志。
;------------------------------------------------------------------------
procedure( ASTB_HasSuffix(str suffix)
  ASTB_StringEndsWith(str suffix)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_LoadDir
; 功能    : 加载指定目录下全部 .il 文件（可选递归子目录），按字母序，
;           逐文件 errset 保护，失败记录日志后继续
; 参数    : dirPath - 目录路径；recursive - 是否递归（默认 nil）
; 返回值  : 无
;------------------------------------------------------------------------
procedure( ASTB_LoadDir(dirPath @optional (recursive nil))
  prog((files f fullPath result loadPath convPath fresult nc ncNeed)
    when( isDir(dirPath)
      ASTB_DebugLog(strcat("ASTB_LoadDir: scanning " dirPath))
      files = sort(getDirFiles(dirPath) 'alphalessp)
      foreach( f files
        unless( or(f == "." f == "..")
          fullPath = strcat(dirPath "/" f)
          ;; 整个单文件处理过程纳入 errset 并点名记录：此前仅 load 步
          ;; 有保护，UTF8 检测/转码/子目录递归等路径出错会中断整个
          ;; 模块加载（Init 步骤 LoadModules 失败的根因区）
          fresult = errset(
            prog(()
              when( isDir(fullPath) && recursive
                ASTB_LoadDir(fullPath recursive)
              )
              when( ASTB_HasSuffix(f ".il") && isFile(fullPath)
                loadPath = fullPath
                ;; UTF-8 auto-transcode (core/utf8_loader.il, config: utf8_autoconv)
                ;; NeedConvert 独立 errset：定位"每文件必炸"的公共嫌疑点，
                ;; 失败按"不转码"处理，不再阻断 load
                nc = errset(ncNeed = and(fboundp('ASTB_UTF8_NeedConvert)
                                             ASTB_UTF8_NeedConvert(fullPath)) t)
                unless( nc
                  ASTB_DebugLog(sprintf(nil "UTF8 NeedConvert failed: %s" fullPath))
                  ncNeed = nil
                )
                when( ncNeed
                  ;; v1.4: 转码失败回退加载原文件，不再中断本文件
                  convPath = car(errset(ASTB_UTF8_ToGbk(fullPath) t))
                  when( convPath
                    ASTB_LogInfo(sprintf(nil "UTF-8 module transcoded: %s" f))
                    loadPath = convPath
                  )
                )
                ASTB_DebugLog(strcat("ASTB_LoadDir: loading file " loadPath))
                ;; v1.5: errsetstring 第一参必须是"表达式字符串"。v1.4 误传
                ;; load(loadPath) ——load 先执行返回 t，errsetstring(t t)
                ;; 报 *Error* argument #1 should be a string，被外层 errset
                ;; 捕获后每模块误报一条 LoadDir error。改为拼接表达式字符串；
                ;; 加载错误的原文由第二参 t 直接打印到命令行。
                if( fboundp('errsetstring) then
                  result = errsetstring(sprintf(nil "load(\"%s\")" loadPath) t)
                  if( and(result listp(result) eq(car(result) t)) then
                    ASTB_LOAD_OK = ASTB_LOAD_OK + 1
                  else
                    ASTB_LOAD_FAILED = cons(loadPath ASTB_LOAD_FAILED)
                    ASTB_LogError(sprintf(nil "Failed to load %s" loadPath))
                  )
                else
                  result = errset(load(loadPath) t)
                  if( result then
                    ASTB_LOAD_OK = ASTB_LOAD_OK + 1
                  else
                    ASTB_LOAD_FAILED = cons(loadPath ASTB_LOAD_FAILED)
                    ASTB_LogError(sprintf(nil "Failed to load %s" loadPath))
                  )
                )
              )
            )
            t
          )
          unless( fresult
            ASTB_LOAD_FAILED = cons(fullPath ASTB_LOAD_FAILED)
            ASTB_LogError(sprintf(nil "ASTB_LoadDir: error while processing %s" fullPath))
            ASTB_DebugLog(sprintf(nil "ASTB_LoadDir: ERROR at %s" fullPath))
          )
        )
      )
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_LoadCore
; 功能    : 加载核心库：先显式加载 utils.il 与 version_adapter.il
;          （其余核心文件依赖其中的函数），再按字母序加载剩余 .il
; 返回值  : 无（单文件失败仅记录日志，不中断整体加载）
;------------------------------------------------------------------------
procedure( ASTB_LoadCore()
  prog((coreFiles f result)
    result = errset(load(strcat(ASTB_GLOBAL->CorePath "/utils.il")) t)
    unless( result
      ASTB_LogError("Failed to load core/utils.il")
    )
    result = errset(load(strcat(ASTB_GLOBAL->CorePath "/version_adapter.il")) t)
    unless( result
      ASTB_LogError("Failed to load core/version_adapter.il")
    )
    coreFiles = sort(getDirFiles(ASTB_GLOBAL->CorePath) 'alphalessp)
    foreach( f coreFiles
      when( and(ASTB_HasSuffix(f ".il")
                f != "utils.il"
                f != "version_adapter.il"
                f != "loader.il"
                f != "_stubs.il"
                f != "ilinit_block.il")
        result = errset(load(strcat(ASTB_GLOBAL->CorePath "/" f)) t)
        unless( result
          ASTB_LogError(sprintf(nil "Failed to load core/%s" f))
        )
      )
    )
    ASTB_LogInfo("Core libraries loaded.")
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_LoadModules
; 功能    : 递归加载 modules 目录下全部 .il 模块，结束打印
;           成功/失败汇总与失败清单（v1.6）
; 返回值  : 无
;------------------------------------------------------------------------
procedure( ASTB_LoadModules()
  prog((failedPath)
    ASTB_LOAD_OK = 0
    ASTB_LOAD_FAILED = nil
    ASTB_DebugLog("ASTB_LoadModules: start")
    ASTB_LoadDir(ASTB_GLOBAL->ModulePath t)
    if( ASTB_LOAD_FAILED then
      ASTB_LogError(sprintf(nil "Modules loaded: 成功 %d / 失败 %d"
          ASTB_LOAD_OK length(ASTB_LOAD_FAILED)))
      foreach( failedPath reverse(ASTB_LOAD_FAILED)
        ASTB_LogError(sprintf(nil "  失败: %s" failedPath))
      )
    else
      ASTB_LogInfo(sprintf(nil "Modules loaded: 全部成功 (%d 个文件)" ASTB_LOAD_OK))
    )
    ASTB_DebugLog("ASTB_LoadModules: done")
  )
)

printf("[ASTB] core/loader.il loaded.\n")
