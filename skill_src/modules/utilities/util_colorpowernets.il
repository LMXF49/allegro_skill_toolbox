;========================================================================
; 文件名    : util_colorpowernets.il
; 作者      : Toolbox
; 创建日期  : 2025
; 版本      : 1.6
; 功能描述  : 自动为电源和地网络分配颜色
; 依赖模块  : core/trans.il (ASTB_RegisterCommand)
; 修改记录  :
;   2025 v1.0 Toolbox 初始创建
;   2026 v1.1 修复组 配置表 defvar 加 boundp 保护、颜色魔数改命名
;             常量、axlShell 网络名加引号并检查返回值、入口加无设计
;             判空、数字判断改 rexMatchp、?cmdType 符号改字符串
;   2026-08-01 v1.2 ASTB Team 实机修复：电压解析函数用了 C 的 break
;             （SKILL 无此关键字，运行报 unbound variable - break，
;             功能整体不可用）——内层扫描改标志位退出；同函数
;             两处 == 字符串比较改 equal
;   2026-08-01 v1.2.1 ASTB Team 实机修复：axlUIWRedraw() 0 参报错
;             （至少 1 参）——改 axlVisibleUpdate(t)（pitfalls 1.3）
;   2026-08-01 v1.3 ASTB Team 实机修复：axlShell assign color 假成功
;             实不刷色——改 axlCustomColorObject(netDbid) 直接 API，
;             并先开 customColorEnabled 显示开关（手册实证要求）
;   2026-08-01 v1.4 ASTB Team 用户要求：电源网络不再按电压定色——
;             调色板逐网分配不同颜色，每次刷色起点 +7 轮转（颜色
;             次次不同）；地网络保持固定灰色
;   2026-08-01 v1.5 ASTB Team 用户要求：地网络灰色/灰棕色随刷色
;             次数交替（C_ASTB_PWRGND_GND_COLOR2=24 灰棕，可按本机
;             调色板改），电源网轮转不变
;   2026-08-01 v1.6 ASTB Team 用户定稿配色：灰=18、灰棕=3；不同
;             地网络按 基3+16 步进（3/19/35/51 循环，mod 64 回绕）
;========================================================================

;; ============================================================
;; File: modules/utilities/util_colorpowernets.il
;; Purpose: Auto-color power and ground nets
;; ============================================================

; --- 颜色常量（对应 Allegro 调色板索引） ---
; 1=Red 2=Green 3=Blue 4=Yellow 5=Orange 6=Purple 7=Cyan 8=White 9=Gray 10=Pink
unless(boundp('C_ASTB_PWRGND_NO_VOLT_COLOR)
    C_ASTB_PWRGND_NO_VOLT_COLOR = 1)      ; VCC/VDD 无电压后缀 -> 红
unless(boundp('C_ASTB_PWRGND_UNKNOWN_VOLT_COLOR)
    C_ASTB_PWRGND_UNKNOWN_VOLT_COLOR = 9) ; 未登记的电压值 -> 灰
unless(boundp('C_ASTB_PWRGND_GND_COLOR)
    C_ASTB_PWRGND_GND_COLOR = 18)         ; 地网络 -> 灰（本机调色板实测索引）
unless(boundp('C_ASTB_PWRGND_GND_BASE)
    C_ASTB_PWRGND_GND_BASE = 3)           ; 地网络步进起点 -> 灰棕（实测索引 3）
unless(boundp('C_ASTB_PWRGND_GND_STEP)
    C_ASTB_PWRGND_GND_STEP = 16)          ; 不同地网络 +16 步进（3/19/35/51 循环）

;; --- Ground net prefixes (case-sensitive, exact start match) ---
;; boundp 保护：重复加载不覆盖用户自定义
unless(boundp('_ASTB_PWRGND_GND_LIST)
    defvar(_ASTB_PWRGND_GND_LIST '("GND" "AGND" "DGND" "SGND" "EGND" "VSS"))
)

;; --- Power net prefix patterns ---
unless(boundp('_ASTB_PWRGND_PWR_PREFIXES)
    defvar(_ASTB_PWRGND_PWR_PREFIXES '("VCC" "VDD" "VIO" "VIN" "VOUT" "VPP" "VEE"))
)

;; --- Voltage -> Color mapping ---
unless(boundp('_ASTB_PWRGND_VOLT_COLOR)
    defvar(_ASTB_PWRGND_VOLT_COLOR '(
      ("3.3" 3)   ;; Blue
      ("5"   5)   ;; Orange
      ("1.8" 6)   ;; Purple
      ("1.2" 7)   ;; Cyan
      ("12"  8)   ;; White
      ("1"   10)  ;; Pink
      ("2.5" 4)   ;; Yellow
      ("0.9" 9)   ;; Gray
      ("1.5" 6)   ;; Purple
      ("2"   4)   ;; Yellow
      ("3"   3)   ;; Blue
      ("6"   5)   ;; Orange
      ("9"   9)   ;; Gray
      ("15"  8)   ;; White
      ("24"  8)   ;; White
      ("48"  8)   ;; White
    ))
)

;; Check if string starts with exact prefix (case-sensitive)
procedure( _ASTB_PwrGndStartsWith(str prefix)
  prog((slen plen)
    slen = strlen(str)
    plen = strlen(prefix)
    when( plen <= slen
      return( substring(str 1 plen) == prefix )
    )
    return(nil)
  )
)

;; Check if net is ground
procedure( _ASTB_PwrGndIsGnd(netName)
  prog((prefix)
    foreach( prefix _ASTB_PWRGND_GND_LIST
      when( _ASTB_PwrGndStartsWith(netName prefix)
        return(t)
      )
    )
    return(nil)
  )
)

;; Parse voltage value from net name (e.g. "VCC_3.3V" -> "3.3", "5V" -> "5")
;; v1.2: SKILL 无 break（C 臆造语法，运行报 unbound variable - break）——
;;       内层扫描改 scanning 标志退出；字符串比较 == 改 equal（pitfalls 4.8）
procedure( _ASTB_PwrGndParseVoltage(netName)
  prog((len i ch valStr dotFound scanning)
    len = strlen(netName)
    i = 1
    while( i <= len
      ch = substring(netName i 1)
      ;; Look for digit start
      when( rexMatchp("^[0-9]$" ch)
        valStr = ""
        dotFound = nil
        scanning = t
        while( and(scanning i <= len)
          ch = substring(netName i 1)
          if( rexMatchp("^[0-9]$" ch)
          then
            valStr = strcat(valStr ch)
            i = i + 1
          else
            if( equal(ch ".") && !dotFound
            then
              dotFound = t
              valStr = strcat(valStr ch)
              i = i + 1
            else
              ;; 非数字非点：退出内层扫描，i 停在未消费字符上
              scanning = nil
            )
          )
        )
        ;; Check if current char is V
        when( i <= len && equal(substring(netName i 1) "V")
          return(valStr)
        )
        ;; Continue searching from next position
      )
      i = i + 1
    )
    return(nil)
  )
)

;; Determine color for a power net (nil if not power)
procedure( _ASTB_PwrGndGetColor(netName)
  prog((prefix voltStr entry)
    ;; Check known prefixes first
    foreach( prefix _ASTB_PWRGND_PWR_PREFIXES
      when( _ASTB_PwrGndStartsWith(netName prefix)
        ;; Try to extract voltage after prefix
        voltStr = _ASTB_PwrGndParseVoltage(netName)
        when( voltStr
          foreach( entry _ASTB_PWRGND_VOLT_COLOR
            when( voltStr == car(entry)
              return(cadr(entry))
            )
          )
          return(C_ASTB_PWRGND_UNKNOWN_VOLT_COLOR) ;; Generic voltage -> Gray
        )
        return(C_ASTB_PWRGND_NO_VOLT_COLOR) ;; VCC/VDD without voltage -> Red
      )
    )
    ;; Try generic voltage pattern
    voltStr = _ASTB_PwrGndParseVoltage(netName)
    when( voltStr
      foreach( entry _ASTB_PWRGND_VOLT_COLOR
        when( voltStr == car(entry)
          return(cadr(entry))
        )
      )
      return(C_ASTB_PWRGND_UNKNOWN_VOLT_COLOR) ;; Generic voltage -> Gray
    )
    return(nil)
  )
)

;; Scan all nets in design
procedure( _ASTB_PwrGndScan()
  prog((db nets gndList pwrList otherList name)
    db = axlDBGetDesign()
    unless( db
      return(nil)
    )
    nets = db->nets
    gndList = nil
    pwrList = nil
    otherList = nil

    foreach( net nets
      name = net->name
      if( _ASTB_PwrGndIsGnd(name)
      then
        gndList = cons(name gndList)
      else
        prog((color)
          color = _ASTB_PwrGndGetColor(name)
          if( color
          then
            pwrList = cons(name pwrList)
          else
            otherList = cons(name otherList)
          )
        )
      )
    )

    return(list(gndList pwrList otherList))
  )
)

;; Apply color to a single net via axlCustomColorObject（直接 API）
;; 返回值: t 成功 / nil 失败
;; v1.3: 弃用 axlShell("assign color ...")——假成功实不刷色并残留
;;       "Cannot exit current application"（命令未正常退出）
procedure( _ASTB_PwrGndApplyColor(netName colorIdx)
  prog((n netDbid rr)
    netDbid = nil
    foreach( n axlDBGetDesign()->nets
      when( equal(n->name netName)
        netDbid = n
      )
    )
    unless( netDbid
      return(nil)
    )
    rr = errset( axlCustomColorObject(netDbid colorIdx) t )
    return( and(rr car(rr)) )
  )
)

;; 调色板（视觉区分优先：先奇数跨步后偶数跨步，覆盖 1-63）
;; v1.4: 每个电源网络分配不同颜色，每次刷色起点轮转（颜色次次不同）
unless(boundp('_pwrPalette)
    _pwrPalette = '(3 5 9 13 17 21 25 29 33 37 41 45 49 53 57 61
                   2 6 10 14 18 22 26 30 34 38 42 46 50 54 58 62
                   4 7 11 15 19 23 27 31 35 39 43 47 51 55 59 63
                   8 12 16 20 24 28 32 36 40 44 48 52 56 60))
unless(boundp('_pwrColorSeed)
    _pwrColorSeed = 0)

;; Apply colors to all detected nets
procedure( _ASTB_PwrGndApplyAll(gndList pwrList)
  prog((count failCount name color pal palLen idx)
    count = 0
    failCount = 0

    ;; v1.3: 自定义颜色需先开启显示开关（color192 "Enable Custom Colors"）
    errset( axlDBControl('customColorEnabled t) nil )

    ;; Ground nets：v1.6 不同地网络按 基3+16 步进（3/19/35/51 循环）
    idx = 0
    foreach( name gndList
      color = 1 + mod(C_ASTB_PWRGND_GND_BASE - 1
                      + C_ASTB_PWRGND_GND_STEP * idx 64)
      idx = idx + 1
      if( _ASTB_PwrGndApplyColor(name color)
      then
        count = count + 1
      else
        failCount = failCount + 1
      )
    )

    ;; Power nets：v1.4 调色板轮转分配（每网不同色，每次刷色起点后移）
    pal = _pwrPalette
    palLen = length(pal)
    idx = _pwrColorSeed
    foreach( name pwrList
      color = nth(mod(idx palLen) pal)
      idx = idx + 1
      if( _ASTB_PwrGndApplyColor(name color)
      then
        count = count + 1
      else
        failCount = failCount + 1
      )
    )
    _pwrColorSeed = mod(_pwrColorSeed + 7 palLen)

    printf("[ASTB] Colored %d nets (%d failed).\n" count failCount)
    ; v1.2.1: axlUIWRedraw 至少要 1 参（0 参报错）；统一用项目实证的
    ; axlVisibleUpdate(t) 刷新显示（pitfalls 1.3）
    axlVisibleUpdate(t)
    return(count)
  )
)

;; Main entry point
procedure( ASTB_Util_ColorPowerNets()
  prog((result gndList pwrList otherList msg)
    unless( axlDBGetDesign()
      axlUIConfirm("No design open.")
      return(nil)
    )

    result = _ASTB_PwrGndScan()
    unless( result
      axlUIConfirm("No design open.")
      return(nil)
    )
    gndList = car(result)
    pwrList = cadr(result)
    otherList = caddr(result)

    unless( or(gndList pwrList)
      axlUIConfirm("No power or ground nets detected in current design.")
      return(nil)
    )

    msg = sprintf(nil
      "Detected:\nGND: %d nets\nPower: %d nets\nOther: %d nets\n\nApply colors?"
      length(gndList) length(pwrList) length(otherList))

    when( axlUIConfirm(msg)
      _ASTB_PwrGndApplyAll(gndList pwrList)
      axlUIConfirm("Color applied successfully.")
    )

    return(t)
  )
)

ASTB_RegisterCommand("ASTB_Util_ColorPowerNets" "ASTB_Util_ColorPowerNets" ?cmdType "interactive")
printf("[ASTB] util_colorpowernets.il loaded.\n")
