;========================================================================
; 文件名    : core/utils.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-06-06
; 版本      : 1.3
; 功能描述  : 通用工具函数库（字符串处理、单位换算、日志、目录与配置行解析）
; 依赖模块  : 无（本文件须最先加载）
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-06-06 v1.0 allegro_skill 项目组 初始创建
;   2026-07-17 v1.1 修复组_框架核心 修复臆造 API：axlOSCreateDir 改为核心
;                   函数 createDir；ASTB_StringSplit 补声明局部变量 ch（原会
;                   隐式污染全局）；单位换算函数补 numberp 校验与函数注释
;   2026-07-26 v1.2 ASTB 项目组 StringInList/StrListHas 字符串比较由
;                   strcmp 改内建 equal：0726 实机证实 strcmp 在本环境
;                   失效（相同内容不返回 0，疑被第三方加载物重定义），
;                   致 ASTB_CONFIG_KEYS 重复登记、astb.cfg 重复行堆积；
;                   UTL-STAMP 升级 0726
;   2026-07-26 v1.3 ASTB 项目组 修复 ASTB_StringTrim 用 ==（eq 同一性）
;                   比较字符致 trim 完全失效：全部改 equal；此 bug 使
;                   CRLF 配置行 \r 残留进 value，SetConfig 替换成空格后
;                   槽值变 "en "，IsLanguageEnglish 永假（重启后菜单
;                   永远中文的根因）；UTL-STAMP 升级 0726B
;========================================================================

;------------------------------------------------------------------------
; 函数名  : ASTB_StringTrim
; 功能    : 去除字符串首尾空白（空格 / Tab / LF / CR）
; 参数    : str - 输入字符串
; 返回值  : 去除首尾空白后的字符串
;------------------------------------------------------------------------
procedure( ASTB_StringTrim(str)
  prog((start end len ch)
    len = strlen(str)
    start = 0
    end = len
    when( start < len
      ch = substring(str start + 1 1)
      while( and(start < len or(equal(ch " ") equal(ch "\t") equal(ch "\n") equal(ch "\r")))
        start = start + 1
        when( start < len
          ch = substring(str start + 1 1)
        )
      )
    )
    when( end > start
      ch = substring(str end 1)
      while( and(end > start or(equal(ch " ") equal(ch "\t") equal(ch "\n") equal(ch "\r")))
        end = end - 1
        when( end > start
          ch = substring(str end 1)
        )
      )
    )
    return(substring(str start + 1 end - start))
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_StringSplit
; 功能    : 按单字符分隔符拆分字符串，各段自动 Trim
; 参数    : str - 输入字符串；sep - 分隔字符（nil 时默认逗号）
; 返回值  : 字符串列表；str 为 nil 时返回 nil
;------------------------------------------------------------------------
procedure( ASTB_StringSplit(str sep)
  prog((result pos len token ch)
    result = nil
    when( null(str) return(nil) )
    when( null(sep) sep = "," )
    len = strlen(str)
    pos = 0
    token = ""
    while( pos < len
      ch = substring(str pos + 1 1)
      if( ch == sep
      then
        result = cons(ASTB_StringTrim(token) result)
        token = ""
      else
        token = strcat(token ch)
      )
      pos = pos + 1
    )
    result = cons(ASTB_StringTrim(token) result)
    return(reverse(result))
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_StringStartsWith
; 功能    : 判断字符串是否以指定前缀开头
; 参数    : str - 输入字符串；prefix - 前缀
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( ASTB_StringStartsWith(str prefix)
  prog((lenPrefix lenStr)
    lenPrefix = strlen(prefix)
    lenStr = strlen(str)
    if( lenStr < lenPrefix
    then
      return(nil)
    else
      return(substring(str 1 lenPrefix) == prefix)
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_StringEndsWith
; 功能    : 判断字符串是否以指定后缀结尾
; 参数    : str - 输入字符串；suffix - 后缀
; 返回值  : t / nil
; 备注    : 本函数是后缀判断的唯一实现；loader.il 的 ASTB_HasSuffix
;           已改为调用本函数，禁止再复制实现
;------------------------------------------------------------------------
procedure( ASTB_StringEndsWith(str suffix)
  prog((lenSuffix lenStr start)
    lenSuffix = strlen(suffix)
    lenStr = strlen(str)
    if( lenStr < lenSuffix
    then
      return(nil)
    else
      start = lenStr - lenSuffix + 1
      return(substring(str start lenSuffix) == suffix)
    )
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_BBoxCenter
; 功能    : 计算边界框中心点坐标
; 参数    : bBox - 边界框 ((x1 y1) (x2 y2))
; 返回值  : (x y) 浮点坐标
;------------------------------------------------------------------------
procedure( ASTB_BBoxCenter(bBox)
  prog((x y)
    x = (caar(bBox) + caadr(bBox)) / 2.0
    y = (cadar(bBox) + cadadr(bBox)) / 2.0
    return(list(x y))
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MilToMm / ASTB_MmToMil / ASTB_InchToMm / ASTB_MmToInch
; 功能    : 长度单位换算（mil / mm / inch）
; 参数    : 数值（非数值输入返回 nil，避免隐式报错）
; 返回值  : 换算后的浮点数；输入非数值时返回 nil
;------------------------------------------------------------------------
procedure( ASTB_MilToMm(mil)
  if( numberp(mil) then mil * 0.0254 else nil )
)

procedure( ASTB_MmToMil(mm)
  if( numberp(mm) then mm / 0.0254 else nil )
)

procedure( ASTB_InchToMm(inch)
  if( numberp(inch) then inch * 25.4 else nil )
)

procedure( ASTB_MmToInch(mm)
  if( numberp(mm) then mm / 25.4 else nil )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_LogInfo / ASTB_LogWarn / ASTB_LogError
; 功能    : 统一日志输出（INFO / WARN / ERROR 三级）
; 参数    : msg - 日志文本
; 返回值  : 无
;------------------------------------------------------------------------
procedure( ASTB_LogInfo(msg)
  printf("[ASTB][INFO] %s\n" msg)
)

procedure( ASTB_LogWarn(msg)
  printf("[ASTB][WARN] %s\n" msg)
)

procedure( ASTB_LogError(msg)
  printf("[ASTB][ERROR] %s\n" msg)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_MsgBox / ASTB_MsgError
; 功能    : 弹出提示 / 错误对话框
; 参数    : msg - 显示文本
; 返回值  : axlUIConfirm 的返回值
;------------------------------------------------------------------------
procedure( ASTB_MsgBox(msg)
  axlUIConfirm(msg)
)

procedure( ASTB_MsgError(msg)
  axlUIConfirm(strcat("ERROR:\n" msg))
)

;------------------------------------------------------------------------
; 函数名  : ASTB_FileExists / ASTB_DirExists
; 功能    : 判断文件 / 目录是否存在
; 参数    : path - 路径
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( ASTB_FileExists(path)
  isFile(path)
)

procedure( ASTB_DirExists(path)
  isDir(path)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_EnsureDir
; 功能    : 确保目录存在，不存在则创建
; 参数    : path - 目录路径
; 返回值  : t - 目录已存在或创建成功；nil - 创建失败
; 备注    : 使用核心 SKILL 函数 createDir（AXL 手册中不存在
;           axlOSCreateDir，臆造 API 会在目录缺失时直接崩溃）
;------------------------------------------------------------------------
procedure( ASTB_EnsureDir(path)
  prog((ret)
    ;; isDir 对部分路径形式（如无尾斜杠）可能误判，两种形式都查
    when( or(isDir(path) isDir(strcat(path "/")))
      return(t)
    )
    ret = errset(createDir(path) t)
    unless( ret
      ASTB_LogError(sprintf(nil "ASTB_EnsureDir: createDir failed: %s" path))
    )
    or(isDir(path) isDir(strcat(path "/")))
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_ParseCfgLine
; 功能    : 解析配置行 "key=value"（忽略空行与 # 注释行）
; 参数    : line - 配置文件的某一行
; 返回值  : (key value) 列表；无效行返回 nil
; 备注    : 以第一个 = 为分隔，value 中允许出现 =
;------------------------------------------------------------------------
procedure( ASTB_ParseCfgLine(line)
  prog((trimmed pos key value len i)
    trimmed = ASTB_StringTrim(line)
    when( or(null(trimmed) eq(trimmed "") substring(trimmed 1 1) == "#")
      return(nil)
    )
    pos = nil
    len = strlen(trimmed)
    i = 1
    while( i <= len
      prog(()
        when( strcmp(substring(trimmed i 1) "=") == 0
          pos = i
          i = len + 1
        )
        i = i + 1
      )
    )
    when( pos && pos > 0
      key = ASTB_StringTrim(substring(trimmed 1 pos - 1))
      value = ASTB_StringTrim(substring(trimmed pos + 1 len))
      return(list(key value))
    )
    return(nil)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_StringInList
; 功能    : 判断字符串是否存在于字符串列表中
; 参数    : item - 目标字符串；strList - 字符串列表
; 返回值  : t / nil
; 备注    : 本函数是全工程唯一实现（原 config.il 中的重复副本已删除，
;           禁止再复制；utils.il 由加载器最先加载，调用方可直接使用）
;------------------------------------------------------------------------
procedure( ASTB_StringInList(item strList)
  prog((found)
    found = nil
    foreach( s strList
      ;; equal 内容比较（0726 改：strcmp 在本环境疑似被第三方加载物
      ;; 重定义污染，相同内容不返回 0，致 KEYS 重复登记/cfg 堆积）
      when( and(stringp(s) stringp(item) equal(s item))
        found = t
      )
    )
    found
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_StrListHas
; 功能    : 判断字符串是否在字符串列表中（全新命名，规避内存中可能
;           滞留的签名颠倒旧版 ASTB_StringInList）
; 参数    : l - 字符串列表；item - 目标字符串
; 返回值  : t / nil
;------------------------------------------------------------------------
procedure( ASTB_StrListHas(l item)
  ;; member 做内容相等查找（equal 语义）：避免 prog 局部变量 +
  ;; foreach 的组合——在 bridge eval(readstring) 上下文里 foreach
  ;; 无法修改 prog 局部变量（实测恒 nil），导致 SetConfig 的
  ;; unless 防重复失效、astb.cfg 键无限累积。member 是原语，无此坑。
  if( and(listp(l) stringp(item) member(item l) )
  then t
  else nil
  )
)

printf("UTL-STAMP-0726B\n")
printf("[ASTB] core/utils.il loaded.\n")
