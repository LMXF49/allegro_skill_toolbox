;========================================================================
; 文件名    : route_shortseg.il
; 作者      : Allegro SKILL Toolbox
; 创建日期  : 2026-07-16
; 版本      : 1.1
; 功能描述  : 检查并高亮长度小于设定最小值的 cline segment
;             （端点未连接 pin/via/shape 的孤立短线段），生成检查报告
; 依赖模块  : core/menu.il, core/utils.il
; 修改记录  :
;   2026-07-16 v1.0 Allegro SKILL Toolbox 初始创建
;   2026-07-17 v1.1 Allegro SKILL Toolbox 整改：
;                   1) 删除与 ASTB_RegisterCommand 重复的 axlCmdRegister("seg")
;                   2) 补 let 绑定；用户取消分支补 close(port) 修复句柄泄漏
;                   3) 输入校验改为 minLen<=0（原 minLen==nil 永不成立）
;                   4) 报告文案与功能对齐；入口清理旧高亮
;========================================================================

;------------------------------------------------------------------------
; 函数名  : short_seg
; 功能    : 高亮长度小于最小线长且端点未连接对象的走线段，输出报告
; 副作用  : 仅高亮与生成临时报告文件，不修改数据库
;------------------------------------------------------------------------
procedure( short_seg()
    prog( (file port flag minLen stmp all strt endt distance)
        file = axlTempFile()
        port = outfile(file "w")
        unless( port
            axlUIConfirm("无法创建临时报告文件")
            return(nil)
        )
        flag = 0
        minLen = 2.00

        stmp = axlUIPrompt("请输入最小线长" "2.00")
        if( stmp != nil then
            minLen = atof(stmp)
            when( minLen <= 0
                axlUIConfirm("输入无效，采用默认值。(2.0)")
                minLen = 2.00
            )

            axlDehighlightObject(nil)   ; 清旧高亮，避免多次运行叠加
            axlSetFindFilter(
                ?enabled list("noall" "clinesegs" "pins" "vias" "shapes")
                ?onButtons list("noall" "clinesegs")
            )
            axlAddSelectAll()
            all = axlGetSelSet()
            axlClearSelSet()

            ; 端点探测阶段只允许选中 pin/via/shape
            axlSetFindFilter(
                ?onButtons list("noall" "pins" "vias" "shapes")
            )

            foreach( i all
                strt = car(i->startEnd)
                endt = cadr(i->startEnd)
                distance = axlDistance(strt endt)
                if( distance < minLen then
                    if( axlSingleSelectPoint(strt) then
                        axlClearSelSet()    ; 端点处有连接对象，非孤立短线
                    else
                        if( flag == 0 then flag = 1 )
                        axlHighlightObject(i)
                        fprintf(port "Segment @ %L\n" strt)
                    )
                )
            )

            if( flag == 0 then fprintf(port "\n未发现小于最小线长的线段。\n") )

            close(port)
            axlUIWExpose(axlUIViewFileCreate(file "检查报告" nil))
        else
            close(port)                 ; 用户取消同样关闭句柄
            printf("Cancelled\n")
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Route_ShortSeg
; 功能    : 命令入口（纯查询/高亮工具，不修改数据库，不挂 undo）
;------------------------------------------------------------------------
procedure( ASTB_Route_ShortSeg()
    short_seg()
)

ASTB_RegisterCommand("ASTB_Route_ShortSeg" "ASTB_Route_ShortSeg" ?cmdType "interactive" ?undo nil)

printf("[ASTB] route_shortseg.il loaded.\n")
