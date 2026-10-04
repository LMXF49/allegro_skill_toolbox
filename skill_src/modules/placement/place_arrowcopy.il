;========================================================================
; 文件名    : modules/placement/place_arrowcopy.il
; 作者      : allegro_skill 项目组
; 创建日期  : 2026-07-21
; 版本      : 2.5
; 功能描述  : 方向键等距复制（仿 FanySkill "Direction Key V1.1"）：
;             表单选择间距（MIL 预设单选 或 NEW 自定义）与修饰键
;             （Ctrl/Shift/Alt 复选），点 Set 后把四个方向键绑定为
;             Allegro 内建命令 `ipick ±D 0 / 0 ±D`（相对上一点的增量
;             拾取）。随后启动 Allegro 标准 copy 命令拾取对象，每按
;             一次方向键即在距上一点 D 处放置一个副本，实现等距阵列；
;             不挟持任何 AXL 克隆逻辑，元件 refdes/网络由原生 copy
;             命令保证。方向键恢复默认用 hotkey_reset 或手工改 env
;             （v2.4 起表单不再带模式下拉）。
; 依赖模块  : core/utils.il、core/trans.il
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-07-21 v1.0 allegro_skill 项目组 初始创建（axlCopyObject 方案）
;   2026-07-22 v2.0 allegro_skill 项目组 按用户提供的 FanySkill
;                     Direction Key V1.1 截图重做：弃用 axlCopyObject
;                     链式克隆方案，改为 ipick 增量拾取 + copy 命令
;                     的原生工作流；表单改为 MIL 预设单选/NEW 自定义 +
;                     Ctrl/Shift/Alt 修饰键 + View.../Set
;   2026-07-22 v2.1 allegro_skill 项目组 修复表单关闭后无法重开
;   2026-09-10 v2.2 ASTB Team 表单高度收敛：PORT 73 6 -> 73 5，
;                     内容行整体上移一行（去顶部空白行），底部留白消除
;   2026-09-10 v2.3 ASTB Team 表单高度再收敛：PORT 高 5 -> 4
;   2026-09-10 v2.4 ASTB Team 拆掉无用的模式下拉（其 ENUMSET 14 14
;                     高度 14 行正是底部大空白的根源）；View/Set 左移；
;                     恢复方向键默认改走 hotkey_reset 或手工 env
;                     （旧句柄失效但 axlIsFormType 误判，改为一律先
;                     关闭旧句柄再重建）；表单宽度 78 -> 73 收紧布局
;   2026-09-29 v2.5 ASTB Team Set 旁新增"取消设置"按钮(unset_btn):
;                     一键解除本工具已绑定的方向键(走 _ACB_UnbindAll),
;                     表单标题同步 V2.5
; 实机待验证:
;   1) 修饰键组合名（"CLeft"/"CSUp"/"ARight" 等）axlSetFunckey 是否
;      全部接受；不接受时退化方案为写 env（参照 util_hotkeysetup.il）
;   2) axlSetFunckey(key nil) 解绑修饰键组合的返回值语义
;========================================================================

;; ------------------------------------------------------------------
;; 模块级全局状态（boundp 保护，Reload 后保留用户设置与绑定登记）
;; ------------------------------------------------------------------
unless(boundp('_acbDist)     _acbDist     = 39.37)  ;; 当前间距（设计单位）
unless(boundp('_acbForm)     _acbForm     = nil)
unless(boundp('_acbBindings) _acbBindings = nil)    ;; ((keyName cmd) ...)
unless(boundp('_acbUnits)    _acbUnits    = "mils")

;; MIL 基准预设值（显示时按单位换算）
unless(boundp('_acbPresets)  _acbPresets  = '(19.69 31.49 39.37 25 50 150))

;------------------------------------------------------------------------
; 函数名  : _ACB_UnitInfo
; 功能    : 取当前设计单位的换算系数（相对 mil）与显示名
; 返回值  : (factor unitName distLabel)
;------------------------------------------------------------------------
procedure( _ACB_UnitInfo()
    prog((units)
        units = car(axlDBGetDesignUnits())
        unless( units units = "mils" )
        _acbUnits = units
        cond(
            ( equal(units "mils")        return( list(1.0     "MILS" "MIL:") ) )
            ( equal(units "millimeters") return( list(0.0254  "MM"   "MM:") ) )
            ( equal(units "microns")     return( list(25.4    "UM"   "UM:") ) )
            ( equal(units "inches")      return( list(0.001   "INCH" "INCH:") ) )
            ( equal(units "centimeters") return( list(0.00254 "CM"   "CM:") ) )
            ( t                          return( list(1.0     "MILS" "MIL:") ) )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : _ACB_CreateFormFile
; 功能    : 动态生成 Direction Key 表单文件（写入临时目录，用完即删）
; 参数    : factor - 单位换算系数；unitName - 标题单位名；
;           distLabel - 距离行标签（MIL:/MM: 等）
; 返回值  : 表单文件路径 / nil
;------------------------------------------------------------------------
procedure( _ACB_CreateFormFile(factor unitName distLabel)
    prog((formFile p title i xpos val lab)
        formFile = axlTempFile()
        p = outfile(formFile "w")
        unless( p
            axlUIConfirm(strcat("无法创建临时表单文件: " formFile))
            return(nil)
        )
        sprintf(title "Direction Key V2.5   Units: %s" unitName)
        fprintf(p "FILE_TYPE=FORM_DEFN VERSION=2\n")
        fprintf(p "FORM\n")
        fprintf(p "FIXED\n")
        fprintf(p "PORT 73 4\n")
        fprintf(p "HEADER \"%s\"\n" title)
        fprintf(p "TILE\n")
        ;; ---- 距离行：预设单选（同组 CHECKLIST = 收音机互斥）+ NEW 自定义
        fprintf(p "TEXT \"%s\"\n" distLabel)
        fprintf(p "TLOC 1 0\nENDTEXT\n")
        xpos = 6
        for( i 0 length(_acbPresets)-1
            val = nth(i _acbPresets)*factor
            sprintf(lab "%g" val)
            fprintf(p "FIELD d%d\n" i+1)
            fprintf(p "FLOC %d 0\n" xpos)
            fprintf(p "CHECKLIST \"%s\" \"acb_d\"\n" lab)
            fprintf(p "ENDFIELD\n")
            xpos = xpos+strlen(lab)+2
        )
        fprintf(p "TEXT \"NEW:\"\n")
        fprintf(p "TLOC %d 0\nENDTEXT\n" xpos+1)
        fprintf(p "FIELD new_val\n")
        fprintf(p "FLOC %d 0\n" xpos+6)
        fprintf(p "REALFILLIN 8 8\n")
        fprintf(p "DECIMAL 3\n")
        fprintf(p "ENDFIELD\n")
        ;; ---- 按键行：修饰键复选（无组 CHECKLIST = 独立复选）+ 模式 + 按钮
        fprintf(p "TEXT \"KEY:\"\n")
        fprintf(p "TLOC 1 2\nENDTEXT\n")
        fprintf(p "FIELD mod_c\n")
        fprintf(p "FLOC 6 2\n")
        fprintf(p "CHECKLIST \"Ctrl (C) +\"\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "FIELD mod_s\n")
        fprintf(p "FLOC 19 2\n")
        fprintf(p "CHECKLIST \"Shift (S) +\"\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "FIELD mod_a\n")
        fprintf(p "FLOC 32 2\n")
        fprintf(p "CHECKLIST \"Alt (A) +\"\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "FIELD view_btn\n")
        fprintf(p "FLOC 46 2\n")
        fprintf(p "MENUBUTTON \"View...\" 7 3\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "FIELD set_btn\n")
        fprintf(p "FLOC 55 2\n")
        fprintf(p "MENUBUTTON \"Set\" 5 3\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "FIELD unset_btn\n")
        fprintf(p "FLOC 61 2\n")
        fprintf(p "MENUBUTTON \"取消设置\" 9 3\n")
        fprintf(p "ENDFIELD\n")
        fprintf(p "ENDTILE\n")
        fprintf(p "ENDFORM\n")
        close(p)
        return(formFile)
    )
)

;------------------------------------------------------------------------
; 函数名  : _ACB_ParseNum
; 功能    : 解析数值输入：接受数字或字符串，校验 > 0
; 返回值  : 正浮点数 / nil（非法输入）
;------------------------------------------------------------------------
procedure( _ACB_ParseNum(v)
    prog((r)
        cond(
            ( numberp(v)  r = v )
            ( stringp(v)  r = atof(v) )
            ( t           r = 0.0 )
        )
        if( r > 0 then return(r) else return(nil) )
    )
)

;------------------------------------------------------------------------
; 函数名  : _ACB_ComposePrefix
; 功能    : 按修饰键复选状态组合键名前缀（固定 C/S/A 顺序）
; 参数    : form - 表单句柄
; 返回值  : "" / "C" / "S" / "A" / "CS" / "CA" / "SA" / "CSA"
;------------------------------------------------------------------------
procedure( _ACB_ComposePrefix(form)
    prog((pre)
        pre = ""
        when( axlFormGetField(form "mod_c") pre = strcat(pre "C") )
        when( axlFormGetField(form "mod_s") pre = strcat(pre "S") )
        when( axlFormGetField(form "mod_a") pre = strcat(pre "A") )
        return(pre)
    )
)

;------------------------------------------------------------------------
; 函数名  : _ACB_UnbindAll
; 功能    : 解绑登记表中的全部按键（alias/funckey 置 nil）
;------------------------------------------------------------------------
procedure( _ACB_UnbindAll()
    prog((b)
        foreach( b _acbBindings
            errset( axlSetAlias(car(b) nil) t )
            errset( axlSetFunckey(car(b) nil) t )
        )
        _acbBindings = nil
    )
)

;------------------------------------------------------------------------
; 函数名  : _ACB_RestoreArrows
; 功能    : 恢复方向键：优先还原 x_move_screen 的视图平移绑定
;           （本工具箱加载后的既有方向键语义），未加载则解绑回默认
;------------------------------------------------------------------------
procedure( _ACB_RestoreArrows()
    _ACB_UnbindAll()
    if( fboundp('x_up) then
        axlSetAlias("Up"    "skill x_up")
        axlSetAlias("Down"  "skill x_down")
        axlSetAlias("Left"  "skill x_left")
        axlSetAlias("Right" "skill x_right")
    else
        axlSetAlias("Up" nil)
        axlSetAlias("Down" nil)
        axlSetAlias("Left" nil)
        axlSetAlias("Right" nil)
    )
)

;------------------------------------------------------------------------
; 函数名  : _ACB_SetBindings
; 功能    : Set 按钮主逻辑：读取间距/修饰键/模式并绑定四个方向键
; 参数    : form - 表单句柄
; 返回值  : t / nil
; 备注    : 绑定命令为 Allegro 内建 `ipick dx dy`（相对上一点增量
;           拾取），仅在 copy 等交互命令激活期间起作用；无修饰键时
;           走 axlSetAlias（x_move_screen 实证），有修饰键走
;           axlSetFunckey（组合名 C/S/A 前缀，实机待验证）
;------------------------------------------------------------------------
procedure( _ACB_SetBindings(form)
    prog((pre d cmd dirs dir key nv)
        ;; 间距：NEW 框有有效值优先，否则用当前单选值
        d = _acbDist
        nv = axlFormGetField(form "new_val")
        when( and(nv stringp(nv) nv != "")
            nv = _ACB_ParseNum(nv)
            if( nv then d = nv else
                axlUIConfirm("NEW 间距无效: 请输入大于 0 的数字")
                return(nil)
            )
        )
        _acbDist = d
        pre = _ACB_ComposePrefix(form)
        _ACB_UnbindAll()
        dirs = list( list("Left"  sprintf(nil "ipick -%g 0" d))
                     list("Right" sprintf(nil "ipick %g 0" d))
                     list("Up"    sprintf(nil "ipick 0 %g" d))
                     list("Down"  sprintf(nil "ipick 0 -%g" d)) )
        foreach( dir dirs
            key = strcat(pre car(dir))
            cmd = cadr(dir)
            if( strcmp(pre "") == 0 then
                axlSetAlias(key cmd)
            else
                axlSetFunckey(key cmd)
            )
            _acbBindings = cons( list(key cmd) _acbBindings )
        )
        axlUIWPrint(form sprintf(nil
            "已绑定 %s方向键 = 间距 %g: 启动 copy 命令拾取对象后按方向键等距放置"
            pre d))
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _ACB_ViewBindings
; 功能    : View... 按钮：弹出当前绑定清单与使用说明
;------------------------------------------------------------------------
; 函数名  : _ACB_UnsetBindings
; 功能    : 取消设置按钮: 解除本工具已绑定的全部方向键(登记簿清空)
; 参数    : form - 表单句柄
; 返回值  : t
;------------------------------------------------------------------------
procedure( _ACB_UnsetBindings(form)
    _ACB_UnbindAll()
    axlUIWPrint(form "已取消设置: 本工具绑定的方向键已全部解除")
    t
)

;------------------------------------------------------------------------
procedure( _ACB_ViewBindings()
    prog((f p b)
        f = axlTempFile()
        p = outfile(f "w")
        unless( p return(nil) )
        fprintf(p "Direction Key 当前绑定\n")
        fprintf(p "====================================\n")
        if( null(_acbBindings) then
            fprintf(p "(无绑定)\n")
        else
            foreach( b _acbBindings
                fprintf(p "%-10s -> %s\n" car(b) cadr(b))
            )
        )
        fprintf(p "\n使用步骤:\n")
        fprintf(p "1. 表单选间距(预设或 NEW)与修饰键\n")
        fprintf(p "2. 点 Set 完成绑定\n")
        fprintf(p "3. 启动 Allegro copy 命令并拾取源对象\n")
        fprintf(p "4. 每按一次方向键, 在距上一点一个间距处放置副本\n")
        fprintf(p "\n恢复: hotkey_reset 恢复默认方向键\n")
        close(p)
        axlUIViewFileCreate(f "Direction Key Bindings" t)
        deleteFile(f)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : _ACB_Callback
; 功能    : 表单回调分发：单选/NEW 维护 _acbDist，按钮执行绑定
; 参数    : form - 表单句柄
; 返回值  : t
;------------------------------------------------------------------------
procedure( _ACB_Callback(form)
    prog((field val i)
        field = form->curField
        case( field
            ("set_btn"
                _ACB_SetBindings(form)
            )
            ("unset_btn"
                _ACB_UnsetBindings(form)
            )
            ("view_btn"
                _ACB_ViewBindings()
            )
            ("new_val"
                val = _ACB_ParseNum(form->curValue)
                when( val
                    _acbDist = val
                    ;; 自定义生效时清掉预设单选，避免两处不一致
                    for( i 1 length(_acbPresets)
                        axlFormSetField(form sprintf(nil "d%d" i) nil)
                    )
                )
            )
            ("mod_c" t)
            ("mod_s" t)
            ("mod_a" t)
            (t
                ;; d1..d6 预设单选：读取选中值并清空 NEW 显示
                when( and(field strlen(field) == 2 substring(field 1 1) == "d")
                    i = atoi(substring(field 2 1))
                    when( and(i >= 1 i <= length(_acbPresets) form->curValue)
                        _acbDist = nth(i-1 _acbPresets) * car(_ACB_UnitInfo())
                        axlFormSetField(form "new_val" "")
                    )
                )
            )
        )
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Place_ArrowCopy
; 功能    : 命令入口：创建并显示 Direction Key 表单
; 参数    : 无
; 返回值  : t 成功 / nil 失败
; 备注    : 本命令只负责键绑定（会话级），不触碰数据库；实际的
;           等距放置由 Allegro 原生 copy 命令 + ipick 完成
;------------------------------------------------------------------------
procedure( ASTB_Place_ArrowCopy()
    prog((formFile info factor unitName distLabel)
        ;; 窗口 X 关闭后句柄失效但 axlIsFormType 可能仍判真，
        ;; 一律先尝试关闭旧句柄再重建，保证可重复打开
        when( _acbForm
            errset(axlFormClose(_acbForm) t)
            _acbForm = nil
        )
        info = _ACB_UnitInfo()
        factor = car(info)
        unitName = cadr(info)
        distLabel = caddr(info)
        _acbDist = 39.37*factor
        formFile = _ACB_CreateFormFile(factor unitName distLabel)
        unless( formFile
            return(nil)
        )
        ; 手册签名 axlFormCreate(g_var t_file l_placement g_callback t_mapButton)，共 5 个实参
        _acbForm = axlFormCreate((gensym) formFile '("NE" "msglines" 0) '_ACB_Callback t)
        unless( _acbForm
            axlUIConfirm("Direction Key 表单创建失败")
            deleteFile(formFile)
            return(nil)
        )
        ;; 默认选中 39.37（换算后）所在档位 d3
        axlFormSetField(_acbForm "d3" t)
        axlUIWPerm(_acbForm t)
        axlFormDisplay(_acbForm)
        deleteFile(formFile)
        return(t)
    )
)

ASTB_RegisterCommand("ASTB_Place_ArrowCopy" "ASTB_Place_ArrowCopy" ?cmdType "interactive")

printf("[ASTB] place_arrowcopy.il loaded.\n")
