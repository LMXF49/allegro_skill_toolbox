;========================================================================
; 文件名    : text_refdesrotate.il
; 作者      : Jingfenghua/24245（原作）；ASTB（工具箱集成整改）
; 创建日期  : 2002-05-15
; 版本      : 1.3
; 功能描述  : 批量旋转元件位号(RefDes)方向，使顶层/底层位号方向与元件方向一致。
;             提供 ch_ref（全部重排）与 ch_refskip（仅处理方向不正确的位号）两个命令。
; 依赖模块  : core（ASTB_DBTransactionMark）
; 修改记录  :
;   2002-05-15 v1.0 Jingfenghua 初始创建（原文件头中文已乱码，按代码语义重写）
;   2026-07-16 v1.1 ASTB 补规范文件头
;   2026-07-17 v1.2 ASTB 事务保护(ASTB_DBTransactionMark)
;   2026-07-18 v1.3 ASTB 整改：jfh* 函数统一加 jfhR_ 前缀，消除与 12 号文件的
;             同名覆盖冲突；删除 jfhrotateref/jfhrotaterefIr 同文件内重复定义；
;             顶层 axlVisibleDesign/axlVisibleLayer 加载期副作用移入命令函数内、
;             退出时恢复；函数变量收进 let 绑定；文件转 GBK 编码
;========================================================================

;------------------------------------------------------------------------
; 函数名  : jfhR_SetRotateVis
; 功能    : 关闭整板显示，仅打开旋转位号所需的层
; 参数    : 无
; 返回值  : 调用前的可见性状态（供 axlVisibleSet 恢复）
; 副作用  : 修改当前显示可见性，调用方退出前必须用 axlVisibleSet 恢复
;------------------------------------------------------------------------
procedure( jfhR_SetRotateVis()
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
; 函数名  : jfhR_GetRefIDComDir
; 功能    : 收集旋转位号所需的标准信息：顶层/底层元件方向列表、
;           顶层/底层位号文本 dbid 列表
; 参数    : 无
; 返回值  : list(l_nTopCompDir l_nBtmCompDir l_dbTopRefDbid l_dbBtmRefDbid)
;------------------------------------------------------------------------
procedure( jfhR_GetRefIDComDir()
    let((dbCurrentDesign l_dbAllSyms l_dbAttachedTxt
         l_nTopCompDir l_nBtmCompDir l_dbTopRefDbid l_dbBtmRefDbid)
        dbCurrentDesign = axlDBGetDesign()
        l_dbAllSyms = dbCurrentDesign->symbols

        ;--- 遍历全部元件，按所在面分别记录方向与位号 dbid ---
        foreach(sym l_dbAllSyms
            if( stringp(sym->refdes) then ;读到异常对象则跳过
                if( sym->isMirrored != t then ;顶层
                    l_nTopCompDir = cons(round(sym->rotation) l_nTopCompDir)
                    l_dbAttachedTxt = axlDBGetAttachedText(sym)
                    foreach(txt l_dbAttachedTxt
                        when( txt->layer == "REF DES/SILKSCREEN_TOP"
                            l_dbTopRefDbid = cons(txt l_dbTopRefDbid)
                        )
                    )
                else ;底层
                    l_nBtmCompDir = cons(round(sym->rotation) l_nBtmCompDir)
                    l_dbAttachedTxt = axlDBGetAttachedText(sym)
                    foreach(txt l_dbAttachedTxt
                        when( txt->layer == "REF DES/SILKSCREEN_BOTTOM"
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
; 函数名  : jfhR_RotateTopRef
; 功能    : 重排顶层位号方向：元件方向为 90/270 度时位号取 90 度，否则取 0 度
; 参数    : ll_dbTopRef - 顶层位号文本 dbid 列表
;           ll_nTopComDir - 对应的元件方向列表
; 返回值  : 无
; 副作用  : 修改数据库（删除原位号文本并新建），调用方需包事务
;------------------------------------------------------------------------
procedure( jfhR_RotateTopRef(ll_dbTopRef ll_nTopComDir)
    let((sRefContent dbParent ptRefxy sRefLayer bMirror sJustify sTxtBlock
         nRefDir stTxtOri isCreation)
        foreach((dbTopRef nTopComDir) ll_dbTopRef ll_nTopComDir
            ;--- 读取不需要修改的属性 ---
            sRefContent = dbTopRef->text
            dbParent    = dbTopRef->parent
            ptRefxy     = dbTopRef->xy
            sRefLayer   = dbTopRef->layer
            bMirror     = dbTopRef->isMirrored
            sJustify    = dbTopRef->justify
            sTxtBlock   = dbTopRef->textBlock

            ;--- 元件方向非 90/270 度时位号取 0 度，否则取 90 度 ---
            if( (nTopComDir > 85 && nTopComDir < 95) || (nTopComDir > 265 && nTopComDir < 275) then
                nRefDir = 90
            else
                nRefDir = 0
            )

            ;--- 填充文本方向结构 r_textOrientation ---
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
; 函数名  : jfhR_RotateBtmRef
; 功能    : 重排底层位号方向：元件方向为 90/270 度时位号取 270 度，否则取 0 度
; 参数    : ll_dbBtmRef - 底层位号文本 dbid 列表
;           ll_nBtmComDir - 对应的元件方向列表
; 返回值  : 无
; 副作用  : 修改数据库（删除原位号文本并新建），调用方需包事务
;------------------------------------------------------------------------
procedure( jfhR_RotateBtmRef(ll_dbBtmRef ll_nBtmComDir)
    let((sRefContent dbParent ptRefxy sRefLayer bMirror sJustify sTxtBlock
         nRefDir stTxtOri isCreation)
        foreach((dbBtmRef nBtmComDir) ll_dbBtmRef ll_nBtmComDir
            sRefContent = dbBtmRef->text
            dbParent    = dbBtmRef->parent
            ptRefxy     = dbBtmRef->xy
            sRefLayer   = dbBtmRef->layer
            bMirror     = dbBtmRef->isMirrored
            sJustify    = dbBtmRef->justify
            sTxtBlock   = dbBtmRef->textBlock

            if( (nBtmComDir > 85 && nBtmComDir < 95) || (nBtmComDir > 265 && nBtmComDir < 275) then
                nRefDir = 270
            else
                nRefDir = 0
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
; 函数名  : jfhR_RotateTopRefIr
; 功能    : 仅重排方向不正确的顶层位号（已正确的保持原方向）
; 参数    : ll_dbTopRef - 顶层位号文本 dbid 列表
;           ll_nTopComDir - 对应的元件方向列表
; 返回值  : 无
; 副作用  : 修改数据库，调用方需包事务
;------------------------------------------------------------------------
procedure( jfhR_RotateTopRefIr(ll_dbTopRef ll_nTopComDir)
    let((sRefContent dbParent ptRefxy sRefLayer bMirror sJustify sTxtBlock
         nRefOri nRefDir stTxtOri isCreation)
        foreach((dbTopRef nTopComDir) ll_dbTopRef ll_nTopComDir
            sRefContent = dbTopRef->text
            dbParent    = dbTopRef->parent
            ptRefxy     = dbTopRef->xy
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
; 函数名  : jfhR_RotateBtmRefIr
; 功能    : 仅重排方向不正确的底层位号（已正确的保持原方向）
; 参数    : ll_dbBtmRef - 底层位号文本 dbid 列表
;           ll_nBtmComDir - 对应的元件方向列表
; 返回值  : 无
; 副作用  : 修改数据库，调用方需包事务
;------------------------------------------------------------------------
procedure( jfhR_RotateBtmRefIr(ll_dbBtmRef ll_nBtmComDir)
    let((sRefContent dbParent ptRefxy sRefLayer bMirror sJustify sTxtBlock
         nRefOri nRefDir stTxtOri isCreation)
        foreach((dbBtmRef nBtmComDir) ll_dbBtmRef ll_nBtmComDir
            sRefContent = dbBtmRef->text
            dbParent    = dbBtmRef->parent
            ptRefxy     = dbBtmRef->xy
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
; 函数名  : jfhR_rotateref
; 功能    : 命令入口：重排全部元件位号方向（ch_ref）
; 参数    : 无
; 返回值  : 无
; 副作用  : 修改数据库与显示可见性（退出前恢复可见性）
;------------------------------------------------------------------------
procedure( jfhR_rotateref()
    let((savedVis info l_nTopCompDir l_nBtmCompDir l_dbTopRefDbid l_dbBtmRefDbid)
        if( axlOKToProceed() != t then
            axlMsgPut("Finish current command first")
        else
            savedVis = jfhR_SetRotateVis()
            info = jfhR_GetRefIDComDir()
            l_nTopCompDir  = nth(0 info)
            l_nBtmCompDir  = nth(1 info)
            l_dbTopRefDbid = nth(2 info)
            l_dbBtmRefDbid = nth(3 info)
            ASTB_DBTransactionMark('jfhR_RotateTopRef list(l_dbTopRefDbid l_nTopCompDir))
            ASTB_DBTransactionMark('jfhR_RotateBtmRef list(l_dbBtmRefDbid l_nBtmCompDir))
            axlVisibleSet(savedVis)
            axlMsgPut("OK")
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : jfhR_rotaterefIr
; 功能    : 命令入口：仅重排方向不正确的元件位号（ch_refskip）
; 参数    : 无
; 返回值  : 无
; 副作用  : 修改数据库与显示可见性（退出前恢复可见性）
;------------------------------------------------------------------------
procedure( jfhR_rotaterefIr()
    let((savedVis info l_nTopCompDir l_nBtmCompDir l_dbTopRefDbid l_dbBtmRefDbid)
        if( axlOKToProceed() != t then
            axlMsgPut("Finish current command first")
        else
            savedVis = jfhR_SetRotateVis()
            info = jfhR_GetRefIDComDir()
            l_nTopCompDir  = nth(0 info)
            l_nBtmCompDir  = nth(1 info)
            l_dbTopRefDbid = nth(2 info)
            l_dbBtmRefDbid = nth(3 info)
            ASTB_DBTransactionMark('jfhR_RotateTopRefIr list(l_dbTopRefDbid l_nTopCompDir))
            ASTB_DBTransactionMark('jfhR_RotateBtmRefIr list(l_dbBtmRefDbid l_nBtmCompDir))
            axlVisibleSet(savedVis)
            axlMsgPut("OK")
        )
    )
)

;-------- 注册命令 --------------------------------------------------------
axlCmdRegister( "ch_ref"     'jfhR_rotateref)
axlCmdRegister( "ch_refskip" 'jfhR_rotaterefIr)
