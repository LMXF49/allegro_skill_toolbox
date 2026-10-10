;========================================================================
; 文件名    : core/zz_smoke.il
; 作者      : ASTB Team
; 创建日期  : 2026-08-01
; 版本      : 1.1
; 功能描述  : 整改后一键冒烟检查（ASTB_SmokeTest 命令）：
;             1) 核心函数 fboundp 抽查（防同名覆盖/加载链断裂）
;             2) 菜单结构内嵌中文标签完整性检查（v4.3 起标签内嵌）
;             3) forms/*.form 全部解析试创建（抓 LIST "" 类语法坑）
;             配合 tools/astb_smoke.py（静态检查）使用：python 跑静态，
;             本命令跑运行时。只读，不修改任何文件与设计数据。
; 依赖模块  : core/menu.il (ASTB_GetMenuStructure / ASTB_MenuIsCommand /
;             ASTB_MenuGetCommand)、core/trans.il
; 编码      : GBK（含中文，必须 GBK 保存）
; 修改记录  :
;   2026-10-11 v1.1 ASTB Team 标签检查适配 menu.il v4.3 内嵌双语
;   2026-08-01 v1.0 ASTB Team 初始创建
;========================================================================

;------------------------------------------------------------------------
; 函数    : ASTB_SmokeCheckFns
; 功能    : 核心函数存在性抽查（fboundp），防同名覆盖与加载失败
; 返回    : 缺失函数名列表（nil = 全部存在）
;------------------------------------------------------------------------
procedure( ASTB_SmokeCheckFns()
    prog( (names f missing)
        names = '("ASTB_StringTrim" "ASTB_StringEndsWith" "ASTB_GetConfig"
                  "ASTB_SetConfig" "ASTB_RegisterCommand" "ASTB_DBTransactionMark"
                  "ASTB_LoadChineseLabels" "ASTB_GetMenuStructure"
                  "ASTB_MenuIsCommand" "ASTB_MenuGetCommand"
                  "ASTB_InjectMenu" "ASTB_UTF8_NeedConvert")
        missing = nil
        foreach( f names
            unless( fboundp(concat(f))
                missing = cons(f missing)
                axlUIWPrint(nil "  [FAIL] \272\257\312\375\310\261\312\247: %s" f)
            )
        )
        unless( missing
            axlUIWPrint(nil "  [OK] \272\313\320\304\272\257\312\375 %d \270\366\310\253\262\277\264\346\324\332" length(names))
        )
        return( reverse(missing) )
    )
)

;------------------------------------------------------------------------
; 函数    : ASTB_SmokeCheckLabels
; 功能    : 菜单结构内嵌中文标签完整性检查（v4.3 起标签内嵌结构行，
;           cadr 即中文标签）；标签非空且不同于英文键才算有效
; 返回    : 标签异常的英文键列表（nil = 全部通过）
;------------------------------------------------------------------------
procedure( ASTB_SmokeCheckLabels()
    prog( (menuList item key zh missing total)
        missing = nil
        total = 0
        menuList = ASTB_GetMenuStructure()
        foreach( item menuList
            when( ASTB_MenuIsCommand(item)
                total = total + 1
                key = car(item)
                zh = cadr(item)
                when( or(null(zh) not(stringp(zh)) equal(zh "") equal(zh key))
                    missing = cons(key missing)
                    axlUIWPrint(nil "  [WARN] \262\313\265\245\317\356\326\320\316\304\261\352\307\251\310\261\312\247/\316\336\320\247: %s" key)
                )
            )
        )
        if( missing then
            axlUIWPrint(nil "  [WARN] \304\332\307\266\261\352\307\251: %d / %d \270\366\303\374\301\356\317\356\261\352\307\251\322\354\263\243"
                length(missing) total)
        else
            axlUIWPrint(nil "  [OK] \304\332\307\266\261\352\307\251: %d \270\366\303\374\301\356\317\356\310\253\262\277\264\370\326\320\316\304\261\352\307\251" total)
        )
        return( reverse(missing) )
    )
)

;------------------------------------------------------------------------
; 函数    : ASTB_SmokeCheckForms
; 功能    : forms/*.form 全部试解析（创建即关闭，不显示），
;           抓 LIST "" / ENUMSET 参数类语法坑
; 返回    : 解析失败的文件名列表（nil = 全部通过）
;------------------------------------------------------------------------
procedure( ASTB_SmokeCheckForms()
    prog( (files f path fw failed total)
        failed = nil
        total = 0
        files = errset( getDirFiles(ASTB_GLOBAL->FormPath) nil )
        files = and(files car(files))
        foreach( f files
            when( and(f ASTB_HasSuffix(f ".form"))
                total = total + 1
                path = strcat(ASTB_GLOBAL->FormPath "/" f)
                fw = errset( axlFormCreate((gensym) path nil nil t) nil )
                fw = and(fw car(fw))
                if( fw then
                    errset( axlFormClose(fw) nil )
                else
                    failed = cons(f failed)
                    axlUIWPrint(nil "  [FAIL] \261\355\265\245\275\342\316\366\312\247\260\334: %s" f)
                )
            )
        )
        unless( failed
            axlUIWPrint(nil "  [OK] \261\355\265\245\275\342\316\366: %d \270\366 .form \310\253\262\277\315\250\271\375" total)
        )
        return( reverse(failed) )
    )
)

;------------------------------------------------------------------------
; 函数    : ASTB_SmokeTest
; 功能    : 冒烟入口：依次跑 函数抽查 / 标签对齐 / 表单解析，
;           结束打印 PASS/FAIL 汇总
;------------------------------------------------------------------------
procedure( ASTB_SmokeTest()
    prog( (missFn missLbl failForm problems)
        axlUIWPrint(nil "==== ASTB SmokeTest \277\252\312\274 ====")
        axlUIWPrint(nil "[1/3] \272\313\320\304\272\257\312\375\263\351\262\351")
        missFn = ASTB_SmokeCheckFns()
        axlUIWPrint(nil "[2/3] \262\313\265\245\261\352\307\251\266\324\306\353")
        missLbl = ASTB_SmokeCheckLabels()
        axlUIWPrint(nil "[3/3] \261\355\265\245\275\342\316\366")
        failForm = ASTB_SmokeCheckForms()
        problems = length(missFn) + length(failForm)
        if( problems > 0 then
            axlUIWPrint(nil "==== SmokeTest FAIL: \272\257\312\375\310\261\312\247 %d, \261\355\265\245\312\247\260\334 %d, \261\352\307\251\310\261\312\247 %d (\261\352\307\251\316\252 WARN) ===="
                length(missFn) length(failForm) length(missLbl))
        else
            when( missLbl
                axlUIWPrint(nil "==== SmokeTest PASS\243\250%d \270\366\274\374\310\261\326\320\316\304\261\352\307\251, WARN\243\251====" length(missLbl))
            )
            unless( missLbl
                axlUIWPrint(nil "==== SmokeTest PASS ====")
            )
        )
        return( problems == 0 )
    )
)

ASTB_RegisterCommand("ASTB_SmokeTest" 'ASTB_SmokeTest ?cmdType "general" ?undo nil)

printf("[ASTB] core/zz_smoke.il loaded, command: ASTB_SmokeTest\n")
