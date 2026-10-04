;========================================================================
; 文件名    : text_textcenterout.il
; 作者      : kevin wong（原作）；ASTB（工具箱集成整改）
; 创建日期  : 2013-12-11
; 版本      : 1.2
; 功能描述  : 快速重排元件值(COMPONENT VALUE)文本：按元件方向重算文本方向
;             （90/270 度取 90 度，否则取 0 度）并按元件原点偏移重放文本位置。
;             提供 val_c（全部重排）与 val_o（仅处理方向不正确的）两个命令。
; 依赖模块  : core（ASTB_DBTransactionMark）
; 修改记录  :
;   2013-12-11 v1.0 kevin wong 初始创建（原文件头中文已乱码，按代码语义重写）
;   2026-07-17 v1.1 ASTB 事务保护(ASTB_DBTransactionMark)
;   2026-07-18 v1.2 ASTB 整改：jfh* 函数统一加 qtc_ 前缀，消除与 09 号文件的
;             同名覆盖冲突；顶层 axlVisibleDesign/axlVisibleLayer 加载期副作用
;             移入命令函数内、退出时恢复；删除写 CWD 的 out.txt 调试残留；
;             函数变量收进 let 绑定；文件转 GBK 编码
;========================================================================

;------------------------------------------------------------------------
; 函数名  : qtc_SetRotateVis
; 功能    : 关闭整板显示，仅打开重排文本所需的层
; 参数    : 无
; 返回值  : 调用前的可见性状态（供 axlVisibleSet 恢复）
; 副作用  : 修改当前显示可见性，调用方退出前必须用 axlVisibleSet 恢复
;------------------------------------------------------------------------
procedure( qtc_SetRotateVis()
    let((savedVis)
        savedVis = axlVisibleGet()
        axlVisibleDesign(nil)
        axlVisibleLayer( "BOARD GEOMETRY/OUTLINE" t )
        axlVisibleLayer( "PIN/TOP" t )
        axlVisibleLayer( "PIN/BOTTOM" t )
        axlVisibleLayer( "REF DES/SILKSCREEN_TOP" t )
        axlVisibleLayer( "REF DES/SILKSCREEN_BOTTOM" t )
        axlVisibleLayer( "PACKAGE GEOMETRY/SILKSCREEN_TOP" t )
        axlVisibleLayer( "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM" t )
        savedVis
    )
)

;------------------------------------------------------------------------
; 函数名  : qtc_GetRefIDComDir
; 功能    : 收集重排所需的标准信息：顶层/底层元件方向列表、
;           顶层/底层 COMPONENT VALUE 文本 dbid 列表
; 参数    : 无
; 返回值  : list(l_nTopCompDir l_nBtmCompDir l_dbTopRefDbid l_dbBtmRefDbid)
;------------------------------------------------------------------------
procedure( qtc_GetRefIDComDir()
    let((dbCurrentDesign l_dbAllSyms l_dbAttachedTxt
         l_nTopCompDir l_nBtmCompDir l_dbTopRefDbid l_dbBtmRefDbid)
        dbCurrentDesign = axlDBGetDesign()
        l_dbAllSyms = dbCurrentDesign->symbols

        ;--- 遍历全部元件，按所在面分别记录方向与 COMPONENT VALUE 文本 dbid ---
        foreach(symb l_dbAllSyms
            if( stringp(symb->refdes) then ;读到异常对象则跳过
                if( symb->isMirrored != t then ;顶层
                    l_nTopCompDir = cons(round(symb->rotation) l_nTopCompDir)
                    l_dbAttachedTxt = axlDBGetAttachedText(symb)
                    foreach(txt l_dbAttachedTxt
                        when( txt->layer == "COMPONENT VALUE/SILKSCREEN_TOP"
                            l_dbTopRefDbid = cons(txt l_dbTopRefDbid)
                        )
                    )
                else ;底层
                    l_nBtmCompDir = cons(round(symb->rotation) l_nBtmCompDir)
                    l_dbAttachedTxt = axlDBGetAttachedText(symb)
                    foreach(txt l_dbAttachedTxt
                        when( txt->layer == "COMPONENT VALUE/SILKSCREEN_BOTTOM"
                            l_dbBtmRefDbid = cons(txt l_dbBtmRefDbid)
                        )
                    )
                )
            )
        )
        list(l_nTopCompDir l_nBtmCompDir l_dbTopRefDbid l_dbBtmRefDbid)
    )
)

;------------------------------------------------------------------------
; 函数名  : qtc_RotateTopRef
; 功能    : 重排顶层 COMPONENT VALUE 文本：按元件方向重算方向并偏移到元件附近
; 参数    : ll_dbTopRef - 顶层文本 dbid 列表
;           ll_nTopComDir - 对应的元件方向列表
; 返回值  : 无
; 副作用  : 修改数据库（删除原文本并新建），调用方需包事务
;------------------------------------------------------------------------
procedure( qtc_RotateTopRef(ll_dbTopRef ll_nTopComDir)
    let((sRefContent dbParent xy ptRefxy sRefLayer bMirror sJustify sTxtBlock
         nRefDir stTxtOri isCreation)
        foreach((dbTopRef nTopComDir) ll_dbTopRef ll_nTopComDir
            ;--- 读取不需要修改的属性 ---
            sRefContent = dbTopRef->text
            dbParent    = dbTopRef->parent
            xy          = dbTopRef->parent->xy
            sRefLayer   = dbTopRef->layer
            bMirror     = dbTopRef->isMirrored
            sJustify    = dbTopRef->justify
            sTxtBlock   = dbTopRef->textBlock
            nTopComDir  = round(dbParent->rotation)

            ;--- 元件方向为 90/270 度时文本取 90 度，否则取 0 度；位置随方向偏移 ---
            if( (nTopComDir > 75 && nTopComDir < 105) || (nTopComDir > 255 && nTopComDir < 285) then
                nRefDir = 90
                ptRefxy = list(nth(0 xy) + 10 nth(1 xy) - 30)
            else
                nRefDir = 0
                ptRefxy = list(nth(0 xy) - 30 nth(1 xy) - 10)
            )

            stTxtOri = make_axlTextOrientation(
                ?textBlock sTxtBlock
                ?rotation  nRefDir
                ?mirrored  bMirror
                ?justify   sJustify
            )

            isCreation = axlDBCreateText(
                sRefContent
                ptRefxy
                stTxtOri
                sRefLayer
                dbParent
            )

            when( car(isCreation)
                axlDeleteObject(dbTopRef)
            )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : qtc_RotateBtmRef
; 功能    : 重排底层 COMPONENT VALUE 文本：按元件方向重算方向并偏移到元件附近
; 参数    : ll_dbBtmRef - 底层文本 dbid 列表
;           ll_nBtmComDir - 对应的元件方向列表
; 返回值  : 无
; 副作用  : 修改数据库，调用方需包事务
;------------------------------------------------------------------------
procedure( qtc_RotateBtmRef(ll_dbBtmRef ll_nBtmComDir)
    let((sRefContent dbParent xy ptRefxy sRefLayer bMirror sJustify sTxtBlock
         nRefDir stTxtOri isCreation)
        foreach((dbBtmRef nBtmComDir) ll_dbBtmRef ll_nBtmComDir
            sRefContent = dbBtmRef->text
            dbParent    = dbBtmRef->parent
            xy          = dbBtmRef->parent->xy
            sRefLayer   = dbBtmRef->layer
            bMirror     = dbBtmRef->isMirrored
            sJustify    = dbBtmRef->justify
            sTxtBlock   = dbBtmRef->textBlock
            nBtmComDir  = round(dbParent->rotation)

            if( (nBtmComDir > 85 && nBtmComDir < 95) || (nBtmComDir > 265 && nBtmComDir < 275) then
                nRefDir = 270
                ptRefxy = list(nth(0 xy) - 10 nth(1 xy) - 30)
            else
                nRefDir = 0
                ptRefxy = list(nth(0 xy) + 30 nth(1 xy) - 10)
            )

            stTxtOri = make_axlTextOrientation(
                ?textBlock sTxtBlock
                ?rotation  nRefDir
                ?mirrored  bMirror
                ?justify   sJustify
            )

            isCreation = axlDBCreateText(
                sRefContent
                ptRefxy
                stTxtOri
                sRefLayer
                dbParent
            )

            when( car(isCreation)
                axlDeleteObject(dbBtmRef)
            )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : qtc_RotateTopRefIr
; 功能    : 仅重排方向不正确的顶层 COMPONENT VALUE 文本（保持原位置）
; 参数    : ll_dbTopRef - 顶层文本 dbid 列表
;           ll_nTopComDir - 对应的元件方向列表
; 返回值  : 无
; 副作用  : 修改数据库，调用方需包事务
;------------------------------------------------------------------------
procedure( qtc_RotateTopRefIr(ll_dbTopRef ll_nTopComDir)
    let((sRefContent dbParent ptRefxy sRefLayer bMirror sJustify sTxtBlock
         nRefOri nRefDir stTxtOri isCreation)
        foreach((dbTopRef nTopComDir) ll_dbTopRef ll_nTopComDir
            sRefContent = dbTopRef->text
            dbParent    = dbTopRef->parent
            ptRefxy     = dbTopRef->parent->xy
            sRefLayer   = dbTopRef->layer
            bMirror     = dbTopRef->isMirrored
            sJustify    = dbTopRef->justify
            sTxtBlock   = dbTopRef->textBlock
            nRefOri     = round(dbTopRef->rotation)

            ;--- 原方向已正确则保持，否则按元件方向重算 ---
            if( nRefOri != 90 && nRefOri != 0 then
                if( (nTopComDir > 85 && nTopComDir < 95) || (nTopComDir > 265 && nTopComDir < 275) then
                    nRefDir = 90
                else
                    nRefDir = 0
                )
            else
                nRefDir = nRefOri
            )

            stTxtOri = make_axlTextOrientation(
                ?textBlock sTxtBlock
                ?rotation  nRefDir
                ?mirrored  bMirror
                ?justify   sJustify
            )

            isCreation = axlDBCreateText(
                sRefContent
                ptRefxy
                stTxtOri
                sRefLayer
                dbParent
            )

            when( car(isCreation)
                axlDeleteObject(dbTopRef)
            )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : qtc_RotateBtmRefIr
; 功能    : 仅重排方向不正确的底层 COMPONENT VALUE 文本（保持原位置）
; 参数    : ll_dbBtmRef - 底层文本 dbid 列表
;           ll_nBtmComDir - 对应的元件方向列表
; 返回值  : 无
; 副作用  : 修改数据库，调用方需包事务
;------------------------------------------------------------------------
procedure( qtc_RotateBtmRefIr(ll_dbBtmRef ll_nBtmComDir)
    let((sRefContent dbParent ptRefxy sRefLayer bMirror sJustify sTxtBlock
         nRefOri nRefDir stTxtOri isCreation)
        foreach((dbBtmRef nBtmComDir) ll_dbBtmRef ll_nBtmComDir
            sRefContent = dbBtmRef->text
            dbParent    = dbBtmRef->parent
            ptRefxy     = dbBtmRef->parent->xy
            sRefLayer   = dbBtmRef->layer
            bMirror     = dbBtmRef->isMirrored
            sJustify    = dbBtmRef->justify
            sTxtBlock   = dbBtmRef->textBlock
            nRefOri     = round(dbBtmRef->rotation)

            if( nRefOri != 270 && nRefOri != 0 then
                if( (nBtmComDir > 85 && nBtmComDir < 95) || (nBtmComDir > 265 && nBtmComDir < 275) then
                    nRefDir = 270
                else
                    nRefDir = 0
                )
            else
                nRefDir = nRefOri
            )

            stTxtOri = make_axlTextOrientation(
                ?textBlock sTxtBlock
                ?rotation  nRefDir
                ?mirrored  bMirror
                ?justify   sJustify
            )

            isCreation = axlDBCreateText(
                sRefContent
                ptRefxy
                stTxtOri
                sRefLayer
                dbParent
            )

            when( car(isCreation)
                axlDeleteObject(dbBtmRef)
            )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ref
; 功能    : 命令入口：重排全部 COMPONENT VALUE 文本（val_c）
; 参数    : 无
; 返回值  : 无
; 副作用  : 修改数据库与显示可见性（退出前恢复可见性）
;------------------------------------------------------------------------
procedure( ref()
    let((savedVis info l_nTopCompDir l_nBtmCompDir l_dbTopRefDbid l_dbBtmRefDbid)
        if( axlOKToProceed() != t then
            axlMsgPut("Finish current command first")
        else
            savedVis = qtc_SetRotateVis()
            info = qtc_GetRefIDComDir()
            l_nTopCompDir  = nth(0 info)
            l_nBtmCompDir  = nth(1 info)
            l_dbTopRefDbid = nth(2 info)
            l_dbBtmRefDbid = nth(3 info)
            ASTB_DBTransactionMark('qtc_RotateTopRef list(l_dbTopRefDbid l_nTopCompDir))
            ASTB_DBTransactionMark('qtc_RotateBtmRef list(l_dbBtmRefDbid l_nBtmCompDir))
            axlVisibleSet(savedVis)
            axlMsgPut("OK")
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : qtc_rotaterefIr
; 功能    : 命令入口：仅重排方向不正确的 COMPONENT VALUE 文本（val_o）
; 参数    : 无
; 返回值  : 无
; 副作用  : 修改数据库与显示可见性（退出前恢复可见性）
;------------------------------------------------------------------------
procedure( qtc_rotaterefIr()
    let((savedVis info l_nTopCompDir l_nBtmCompDir l_dbTopRefDbid l_dbBtmRefDbid)
        if( axlOKToProceed() != t then
            axlMsgPut("Finish current command first")
        else
            savedVis = qtc_SetRotateVis()
            info = qtc_GetRefIDComDir()
            l_nTopCompDir  = nth(0 info)
            l_nBtmCompDir  = nth(1 info)
            l_dbTopRefDbid = nth(2 info)
            l_dbBtmRefDbid = nth(3 info)
            ASTB_DBTransactionMark('qtc_RotateTopRefIr list(l_dbTopRefDbid l_nTopCompDir))
            ASTB_DBTransactionMark('qtc_RotateBtmRefIr list(l_dbBtmRefDbid l_nBtmCompDir))
            axlVisibleSet(savedVis)
            axlMsgPut("OK")
        )
    )
)

;-------- 注册命令 --------------------------------------------------------
axlCmdRegister( "val_c" 'ref)
axlCmdRegister( "val_o" 'qtc_rotaterefIr)
