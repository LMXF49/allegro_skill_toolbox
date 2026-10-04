;========================================================================
; 文件名    : util_unitconvert.il
; 作者      : Wanghh (https://github.com/whh5118/GTOpen) / Toolbox
; 创建日期  : 2025
; 版本      : 2.1
; 功能描述  : 单位转换计算器 (mils/mm 互转)
; 依赖模块  : core/trans.il (ASTB_RegisterCommand)
; 修改记录  :
;   2025 v1.0 Toolbox 整合到工具箱
;   2026 v1.1 修复组 合并双文件头、删除虚假依赖声明、form 路径改从
;             ASTB_GLOBAL->FormPath 查找并判空、evalstring 加 errset
;             保护、输入改严格数字校验、魔数改命名常量、命令注册
;             ?cmdType 符号改字符串
;   2026-07-17 v1.2 整合工程师：Calculator.form 已删除（与
;             gtopen_calculator.form 重复），find_formfile 改为优先
;             gtopen_calculator.form、旧名兜底
;   2026-07-17 v1.3 修复输入回车不换算：gtopen_calculator.form
;             两个 STRFILLIN 字段补 OPTIONS disp（无此选项字段
;             不派发回调）；清空输入时静默清两侧不报错；回调刷新
;             不再重复 axlFormDisplay，避免焦点跳动
;   2026-07-17 v1.4 修复回车清空：OPTIONS disp 派发时 form->curValue
;             不可靠（实测为空串），改用 axlFormGetField 读取字段
;             当前内容；只刷新对侧字段，不改写正在输入的字段；
;             非法输入静默跳过，等待继续输入
;   2026-07-17 v1.5 按官方 BNF 重正：OPTIONS disp 为非文档选项，
;             派发时字段值未提交导致取值为空，已移除；字段改用
;             REALFILLIN（自带 [0-9.+-] 输入校验，回车/离场提交
;             并派发）；回调恢复读取 form->curValue（提交后派发
;             的官方取值通道），仍只刷新对侧字段
;   2026-07-17 v1.6 修复 strlen 报错：REALFILLIN 提交后 curValue
;             直接是浮点数（非字符串），移除 _gt_valid_number/
;             evalstring 字符串校验链路，改为数值比较；表单补
;             DECIMAL 精度（官方 axlform.form 示例用法）
;   2026-08-23 v1.7 修复 16.6 表单创建失败（axlFormCreate 返回 nil）：
;             a) forms/gtopen_calculator.form 由 CRLF 转 LF——16.6
;             表单解析器对 # 注释行 + CRLF 组合致命（纯 CRLF 或
;             纯注释 LF 均正常，axlFormTest 却都通过，实机二分定位）；
;             b) 表单变量名 'calculator_form 改 'astb_calculator_form——
;             该名字在失败创建后会在 16.6 表单注册表残留污染，同名
;             再创建恒 nil（换名即建成功），改名杜绝一切同名冲突
;   2026-08-23 v1.8 变量名再改 'astb_unitcv_form：v1.7 选用的
;             'astb_calculator_form 在本机 16.6 实测仍为"被诅咒名"
;             （创建即绑僵尸句柄但返回 nil；'astb_unitcv_form 等新名
;             秒建成功），详见 pitfalls §8.5
;   2026-08-23 v1.9 变量名回退 'calculator_form（新会话实测该名可建，
;             失败创建才诅咒名字）；失败提示 axlUIConfirm 改
;             axlUIWPrint（模态弹窗会卡死桥/定时器线程）
;   2026-08-23 v2.0 根治：表单变量名改为每次调用全新生成
;             （astb_ucf_<序号>，不再绑定固定全局名）——实机归纳
;             铁律：axlFormCreate 的变量名只要被绑定过（nil/僵尸
;             句柄/其他包占用）再创建恒 nil，未绑定的新名必成功
;             （3 会话 2 版本 25+ 探针零例外）；旧表单关闭改走
;             缓存句柄 _GT_UCF_LAST，不再依赖固定变量名
;   2026-08-23 v2.1 终极根因修复：prog 体内一旦写了 return(...)，
;             16.6 的隐式落尾返回值就丢（bare tail 的 form 返回 nil），
;             必须显式 return(form)——此前表单其实每次都创建成功，
;             是返回值 nil 让调用方放弃 axlFormDisplay（实机对照：
;             同函数体仅差结尾 return(form)，成败立分）
;========================================================================

/*
#############################################################################
#  历史信息（原始 FanySkill 头，仅作来源说明保留）
#  Command    : FYCA
#  Skill File : FanySkill_Calculator.il
#  Write by   : Wanghh   Download: https://github.com/whh5118/GTOpen
#############################################################################
*/

; --- 输入上限常量（防止 axlMKSConvert 换算溢出） ---
; 393700787 mil * 0.0254 ≈ 10^7 mm
unless(boundp('C_GT_MAX_MILS) C_GT_MAX_MILS = 393700787)
; 2539999 mm / 0.0254 ≈ 10^8 mil
unless(boundp('C_GT_MAX_MM)   C_GT_MAX_MM   = 2539999)

;------------------------------------------------------------------------
; 函数名  : ASTB_Util_UnitConvert
; 功能    : 单位转换计算器命令入口
; 返回值  : t 成功 / nil 失败
;------------------------------------------------------------------------
procedure( ASTB_Util_UnitConvert()
    prog((form)
        form = gt_calculator_createform()
        unless( form
            return(nil)
        )
        gt_calculator_int_var(form)
        gt_calculator_update_form(form)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : gt_calculator_find_formfile
; 功能    : 定位计算器表单（优先 gtopen_calculator.form，旧名
;           Calculator.form 兜底；先查工具箱 forms 目录，再查 SKILL 路径）
; 返回值  : 表单文件完整路径 / nil 未找到
;------------------------------------------------------------------------
procedure( gt_calculator_find_formfile()
    prog((cand names nm)
        ; 2026-07-17：Calculator.form 已删除（与 gtopen_calculator.form
        ; 内容重复），优先使用 gtopen_calculator.form，旧名兜底
        names = list("gtopen_calculator.form" "Calculator.form")
        when( and(boundp('ASTB_GLOBAL) ASTB_GLOBAL->FormPath)
            foreach( nm names
                cand = strcat(ASTB_GLOBAL->FormPath "/" nm)
                when( isFile(cand)
                    return(cand)
                )
            )
        )
        foreach( dir getSkillPath()
            foreach( nm names
                cand = strcat(dir "/" nm)
                when( isFile(cand)
                    return(cand)
                )
            )
        )
        return(nil)
    )
)

; 表单句柄缓存与命名序号（v2.0：变量名每次全新，规避绑定名诅咒）
unless(boundp('_GT_UCF_SEQ)  _GT_UCF_SEQ  = 0)
unless(boundp('_GT_UCF_LAST) _GT_UCF_LAST = nil)

;------------------------------------------------------------------------
; 函数名  : gt_calculator_createform
; 功能    : 创建计算器表单（重复调用时先关闭旧表单）
; 返回值  : 表单句柄 / nil 失败
; 注意    : via_stitching.il 中的同名死定义已于 2026-07-17 删除，
;           本文件为 gt_calculator_* 系列函数唯一实现
;------------------------------------------------------------------------
procedure( gt_calculator_createform()
    prog((file form vname)
        ; 关闭上次未关闭的旧表单，避免句柄泄漏（走缓存句柄，
        ; 不依赖固定变量名——绑定过的名字再创建恒 nil，见 v2.0 注）
        when( and(boundp('_GT_UCF_LAST) _GT_UCF_LAST axlIsFormType(_GT_UCF_LAST))
            errset(axlFormClose(_GT_UCF_LAST) nil)
            _GT_UCF_LAST = nil
        )
        file = gt_calculator_find_formfile()
        unless( file
            axlUIWPrint(nil "\316\264\325\322\265\275 gtopen_calculator.form\243\254\307\353\274\354\262\351\271\244\276\337\317\344 forms \304\277\302\274\241\243")
            return(nil)
        )
        ; 变量名每次全新生成（concat 产生符号），确保从未被绑定
        _GT_UCF_SEQ = _GT_UCF_SEQ + 1
        vname = concat("astb_ucf_" _GT_UCF_SEQ)
        form = axlFormCreate(vname file nil 'gt_calculator_CB t)
        unless( form
            axlUIWPrint(nil strcat("\261\355\265\245\264\264\275\250\312\247\260\334: " file))
            return(nil)
        )
        _GT_UCF_LAST = form
        return(form)
    )
)

;------------------------------------------------------------------------
; 函数名  : gt_calculator_int_var
; 功能    : 初始化表单私有数据（两个输入框内容）
;------------------------------------------------------------------------
procedure( gt_calculator_int_var(form)
    let(()
        form->var = ncons(nil)
        form->var->mils_input = nil
        form->var->mm_input = nil
    )
)

;------------------------------------------------------------------------
; 函数名  : gt_calculator_update_form
; 功能    : 将私有数据回写两个输入框并显示表单
;------------------------------------------------------------------------
procedure( gt_calculator_update_form(form)
    let((val)
        val = form->var->mils_input
        axlFormSetField(form "mils_input" if(val then val else ""))
        val = form->var->mm_input
        axlFormSetField(form "mm_input" if(val then val else ""))
        axlFormAutoResize(form)
        axlFormDisplay(form)
    )
)

;------------------------------------------------------------------------
; 函数名  : _gt_valid_number
; 功能    : 严格校验数字格式（整数/小数，拒绝多空格、多小数点、字母）
;------------------------------------------------------------------------
procedure( _gt_valid_number(str)
    and( str
         strlen(str) > 0
         str != "."
         rexMatchp("^[0-9]*\\.?[0-9]*$" str) )
)

;------------------------------------------------------------------------
; 函数名  : gt_calculator_CB
; 功能    : 表单回调：按输入框字段做单位互转
;------------------------------------------------------------------------
procedure( gt_calculator_CB(form)
    let((val)
        case( form->curField
            ("mils_input"
                ; REALFILLIN 提交后 curValue 直接是浮点数（v1.6）
                val = form->curValue
                when( val && val >= 0 && val <= C_GT_MAX_MILS
                    axlFormSetField(form "mm_input"
                        axlMKSConvert(val "MILS" "MM"))
                )
            )
            ("mm_input"
                val = form->curValue
                when( val && val >= 0 && val <= C_GT_MAX_MM
                    axlFormSetField(form "mils_input"
                        axlMKSConvert(val "MM" "MILS"))
                )
            )
            (t
                nil
            )
        )
    )
)

ASTB_RegisterCommand("ASTB_Util_UnitConvert" "ASTB_Util_UnitConvert" ?cmdType "interactive")

printf("[ASTB] util_unitconvert.il loaded.\n")
