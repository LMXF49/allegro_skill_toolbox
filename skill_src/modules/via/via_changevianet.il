;========================================================================
; 文件名    : via_changevianet.il
; 作者      : deargds / ASTB Team
; 创建日期  : 2026-07-16
; 版本      : 1.6
; 功能描述  : 修改选中过孔的网络（先建新孔再删原孔，带错误保护可 Undo）
; 依赖模块  : core/trans.il (ASTB_RegisterCommand, ASTB_DBTransactionMark)
; 修改记录  :
;   2026-07-16 v1.0 ASTB Team 初始创建
;   2026-07-16 v1.1 ASTB Team 事务保护 (ASTB_DBTransactionMark)
;   2026-07-17 v1.2 ASTB Team 整改：修复文件头中文乱码；命令注册改走
;                     ASTB_RegisterCommand 并移至函数定义之后；新孔创建
;                     成功后才删除原孔；net 参数显式传网络名字符串；入口
;                     补 axlClearSelSet；errset 失败时给用户可见提示
;   2026-07-19 v1.3 ASTB Team 改交互: 目标网络由 axlUIDataBrowse
;                     列表选择改为点选带网络参考对象(管脚/过孔/走线/
;                     铜皮)取其网络; doChange 的 vnet 参数语义同步
;                     改为网络名字符串
;   2026-08-17 v1.4 ASTB Team 选择阶段右键菜单补 Done/Oops/Cancel：
;                     原 while(axlSelect()) 裸调用默认右键只有
;                     snap pick to，无法 Done 结束选择；改 rvia 实证
;                     模式（groupMode t + popup 命名函数串回调），
;                     Oops=清空重选，Cancel 改置标志位判断
;                     （不再读 doneState）
;   2026-08-20 v1.5 ASTB Team 修 16.6 语法错误：case 测试里的 if 补
;                     显式 then（Allegro SKILL 带 else 必须有 then）
;   2026-09-04 v1.6 ASTB Team 修 17.4 失败：17.4 S039 跨选择轮旧 dbid
;                     必死（place_align 落盘探针实证），过孔改为按
;                     (xy 焊盘名) 现场解析即用即弃（same_via 模式）；
;                     提示弹窗 axlUIConfirm 全部改走命令行 axlUIWPrint
;========================================================================

/*
################################################################################
#                               by deargds                                     #
#                            deargds@163.com                                   #
################################################################################
*/

;------------------------------------------------------------------------
; 函数名  : _x_change_via_net_doChange
; 功能    : 内部执行函数：对选中过孔逐个在新网络上建新孔，成功后删除原孔
; 参数    :
;   @param viaSpecs       - 选中过孔身份信息列表 (xy 焊盘名 FIXED) ——
;                     v1.6 起不再传 dbid（17.4 跨选择轮必失效）
;   @param vnet           - 目标网络名字符串(v1.3 起)
;   @param ch_via_logport - 日志输出端口
;   @param flag           - 兼容保留参数（未使用）
; 返回值  : t - 存在被跳过的 FIXED 过孔；nil - 无
; 副作用  : 修改设计数据库（由调用方 ASTB_DBTransactionMark 包裹，可 Undo）
;------------------------------------------------------------------------
procedure( _x_change_via_net_doChange(viaSpecs vnet ch_via_logport flag)
    prog((spec xy pad fixed old v rr)
        ; v1.6: 17.4 S039 下第二轮 axlSingleSelectPoint 之后，第一轮选中
        ; 过孔的 dbid 全部失效（removed）。逐条按 (xy 焊盘名) 现场解析
        ; 旧孔、即用即弃——same_via.il 在 17.4 实证可行的模式。
        axlSetFindFilter(?enabled '("noall" "vias") ?onButtons '("noall" "vias"))
        foreach( spec viaSpecs
            xy    = car(spec)
            pad   = cadr(spec)
            fixed = caddr(spec)
            if( fixed then
                fprintf(ch_via_logport "Ignore Change FIXED VIA @ %L\n" xy)
                flag = t
            else
                axlClearSelSet()
                old = nil
                when( axlSingleSelectPoint(xy)
                    foreach( v axlGetSelSet()
                        when( and(null(old) equal(v->name pad))
                            old = v
                        )
                    )
                )
                if( null(old) then
                    fprintf(ch_via_logport "Via not found @ %L\n" xy)
                    flag = t
                else
                    ; 先建新孔，确认成功后再删原孔，避免数据丢失
                    rr = errset( axlDBCreateVia(pad xy vnet) t )
                    if( and(rr car(rr) car(car(rr))) then
                        errset( axlDeleteObject(old) t )
                    else
                        fprintf(ch_via_logport "Create via failed @ %L\n" xy)
                        flag = t
                    )
                )
            )
        )
        axlClearSelSet()
        return(flag)
    )
)


;------------------------------------------------------------------------
; 函数名  : _CVN_PickDone / _CVN_PickOops / _CVN_PickCancel
; 功能    : 拾取右键菜单回调（命名函数串模式）：Done 结束选择；
;           Oops 清空当前选择重新框选；Cancel 置取消标志并退出
;------------------------------------------------------------------------
unless( boundp('_CVN_pickCancel) defvar(_CVN_pickCancel nil))

procedure( _CVN_PickDone()
    axlUIPopupSet(nil)
    axlFinishEnterFun()
)

procedure( _CVN_PickOops()
    axlClearSelSet()
    axlMsgPut("已清空选择, 请重新点选/框选")
)

procedure( _CVN_PickCancel()
    _CVN_pickCancel = t
    axlClearSelSet()
    axlUIPopupSet(nil)
    axlCancelEnterFun()
)

;------------------------------------------------------------------------
; 函数名  : x_change_via_net
; 功能    : 交互式修改选中过孔的网络（cvia 命令入口）
; 参数    : 无（交互选择）
; 返回值  : t - 完成；nil - 用户取消或未选择对象
; 副作用  : 修改设计数据库；数据库修改经 ASTB_DBTransactionMark 保护，
;           支持 Allegro 原生 Undo (Ctrl+Z)
;------------------------------------------------------------------------
procedure( x_change_via_net()
    prog((all vnet ch_via_logfile ch_via_logport flag errBox refObj viaSpecs)
        unless( axlOKToProceed()
            axlUIWPrint(nil "ERROR: 当前环境不允许执行该操作")
            return(nil)
        )
        axlClearSelSet()
        axlSetFindFilter(?enabled list("noall" "vias") ?onButtons list("vias"))

        ; v1.4: 右键菜单补 Done/Oops/Cancel（rvia 实证模式：
        ; groupMode t 点选/框选直接生效并累积，Done/Cancel 才返回；
        ; 原默认右键只有 snap pick to，无法 Done 结束选择）
        _CVN_pickCancel = nil
        axlUIPopupSet(axlUIPopupDefine(nil
            list(
                list("Done"   "_CVN_PickDone()")
                list("Oops"   "_CVN_PickOops()")
                list("Cancel" "_CVN_PickCancel()")
            )))
        axlSelect(?groupMode t
                  ?prompt "点选或框选要改网络的过孔, 右键 Done 完成")
        axlUIPopupSet(nil)
        all = axlGetSelSet()
        when( and(all listp(all))
            axlHighlightObject(all)
        )
        ; v1.6: 趁本轮 dbid 还活着，立即提取身份信息 (xy 焊盘名 FIXED)。
        ; 17.4 下第二轮 axlSingleSelectPoint(取参考网络) 之后旧 dbid
        ; 全部失效，doChange 只能凭坐标现场解析
        viaSpecs = nil
        foreach( p all
            viaSpecs = cons(list(p->xy p->name axlDBIsFixed(p)) viaSpecs)
        )
        viaSpecs = reverse(viaSpecs)

        case( if( _CVN_pickCancel then 'cancel else 'done)
            (done
                when( all == nil
                    axlUIWPrint(nil "未选择任何过孔, 命令结束")
                    return(nil)
                )

                ;--- v1.3: 点选带网络参考对象取网络(原列表选择) ---
                axlMsgPut("请点击带网络的参考对象(管脚/过孔/走线/铜皮)")
                axlClearSelSet()
                axlSetFindFilter(?enabled
                    list("noall" "pins" "vias" "clines"
                         "clinesegs" "shapes")
                    ?onButtons
                    list("pins" "vias" "clines"
                         "clinesegs" "shapes"))
                refObj = nil
                when( axlSingleSelectPoint()
                    refObj = car(axlGetSelSet())
                )
                if( refObj && refObj->net && refObj->net->name
                    && refObj->net->name != "" then
                    vnet = refObj->net->name
                else
                    axlUIWPrint(nil "未获取到网络(对象无网络或操作已取消), 命令结束")
                    return(nil)
                )

                ch_via_logfile = axlTempFile()
                ch_via_logport = outfile(ch_via_logfile)
                unless( ch_via_logport
                    axlUIWPrint(nil "ERROR: 无法打开临时日志文件")
                    return(nil)
                )
                flag = nil

                ; 使用 ASTB_DBTransactionMark，数据库修改可 Undo，出错自动捕获
                errBox = ncons(nil)
                flag = ASTB_DBTransactionMark('_x_change_via_net_doChange
                    list(viaSpecs vnet ch_via_logport flag) errBox)
                when( errBox->value
                    axlUIWPrint(nil "ERROR: Change Via Net failed: %s" errBox->value)
                )

                close(ch_via_logport)
                when( flag
                    axlUIWExpose(axlUIViewFileCreate(ch_via_logfile "Change Via Net Log" nil))
                )
            )
            (cancel
                axlUIWPrint(nil "cancel")
            )
        )
        return(t)
    )
)

; 命令注册须在函数定义之后（ASTB_RegisterCommand 会检查 fboundp）
ASTB_RegisterCommand("cvia" "x_change_via_net" ?cmdType "interactive" ?undo t)

printf("[ASTB] via_changevianet.il loaded.\n")
