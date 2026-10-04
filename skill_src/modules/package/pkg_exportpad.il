;========================================================================
; 文件名    : pkg_exportpad.il
; 作者      : FanySkill / ASTB 整改组
; 创建日期  : 2026-07-16
; 版本      : 1.1
; 功能描述  : 交互式选择 symbols 并导出封装文件到用户指定目录。
;             本模块已合并原 pkg_exportfootprint.il，统一提供
;             ASTB_Pkg_ExportPad 与 ASTB_Pkg_ExportFootprint 两个入口
; 依赖模块  : core
; 修改记录  :
;   2026-07-16 v1.0 FanySkill 初始创建
;   2026-07-17 v1.1 ASTB 整改：合并 pkg_exportfootprint.il（消除 4 个重复定义
;                    的全局函数 axlDPDone/axlDPCancel/DumpPadstack/axlPadDone）；
;                    删除 DumpPadstack/axlPadDone/package_out 死代码；
;                    导出目录改为用户自选（原硬编码 ./Package）；空选择补提示；
;                    公共函数加 ASTB_Pkg_ 前缀；统一 cmdType 为字符串
;========================================================================

;------------------------------------------------------------------------
; 函数名  : ASTB_Pkg_ExportCancel
; 功能    : 取消选择并退出交互
;------------------------------------------------------------------------
procedure( ASTB_Pkg_ExportCancel()
    axlClearSelSet()
    axlCancelEnterFun()
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Pkg_ExportDone
; 功能    : 将所选 symbols 的封装定义导出到用户选择的目录
; 参数    : 无
; 返回值  : 无
; 副作用  : 在目标目录写封装文件（只读导出，不修改设计数据库）
;------------------------------------------------------------------------
procedure( ASTB_Pkg_ExportDone()
    let((lid outdir)
        lid = axlGetSelSet()
        if( lid == nil
        then
            axlUIConfirm("未选择任何 symbol，导出取消")
        else
            outdir = axlDMDirectoryBrowse("." t)
            when( stringp(outdir)
                foreach( pid lid
                    if( axlWritePackageFile(pid->definition outdir)
                    then
                        printf(strcat("\nExport package: " pid->name " Successful!"))
                    else
                        printf(strcat("fail to export package: " pid->name "\n"))
                        printf(strcat("incorrect dbid or directory " simplifyFilename(outdir)))
                    )
                )
            )
        )
        axlClearSelSet()
        axlFinishEnterFun()
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Pkg_ExportSymbols
; 功能    : 公共交互入口：过滤 symbols 并等待用户选择，Done 后导出
;------------------------------------------------------------------------
procedure( ASTB_Pkg_ExportSymbols()
    let((mypopup)
        mypopup = axlUIPopupDefine(nil (list
            (list "Done" 'ASTB_Pkg_ExportDone)
            (list "Undo" 'ASTB_SystemUndo)
            (list "Cancel" 'ASTB_Pkg_ExportCancel)
        ))
        axlUIPopupSet(mypopup)
        axlClearSelSet()
        axlSetFindFilter(?enabled '("noall" "symbols") ?onButtons '("symbols"))
        while( axlSelect(?prompt "please select symbols!") t)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Pkg_ExportPad / ASTB_Pkg_ExportFootprint
; 功能    : ASTB 框架入口（同一导出逻辑，保留两个命令名以兼容菜单）
;------------------------------------------------------------------------
procedure( ASTB_Pkg_ExportPad()
    ASTB_Pkg_ExportSymbols()
)

procedure( ASTB_Pkg_ExportFootprint()
    ASTB_Pkg_ExportSymbols()
)

ASTB_RegisterCommand("ASTB_Pkg_ExportPad" "ASTB_Pkg_ExportPad" ?cmdType "interactive" ?undo nil)
ASTB_RegisterCommand("ASTB_Pkg_ExportFootprint" "ASTB_Pkg_ExportFootprint"
    ?cmdType "interactive" ?undo nil)

printf("[ASTB] pkg_exportpad.il loaded.\n")
