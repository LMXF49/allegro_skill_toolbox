;========================================================================
; 文件名    : pkg_changeorigin.il
; 作者      : FanySkill / ASTB 整改组
; 创建日期  : 2026-07-16
; 版本      : 1.1
; 功能描述  : 通过依次选择两个 Pin，自动计算连线中点并将封装设计原点平移到该中点
; 依赖模块  : core
; 修改记录  :
;   2026-07-16 v1.0 FanySkill 初始创建
;   2026-07-17 v1.1 ASTB 整改：重写损坏文件头；删除裸 axlCmdRegister(FYCH)，
;                    统一走 ASTB 事务入口；局部变量补 let 绑定；删除无效
;                    axlDBRefreshId 调用与调试死注释；交互补提示语
;========================================================================

;------------------------------------------------------------------------
; 函数名  : FanySkill_Change_Origin
; 功能    : 选两个 Pin，把设计原点改为两 Pin 连线的中点
; 参数    : 无
; 返回值  : 无
; 副作用  : 修改当前设计数据库（由 ASTB 入口经 ASTB_DBTransactionMark 保护）
;------------------------------------------------------------------------
procedure( FanySkill_Change_Origin()
    let((points1 points2 p_s1 p_s2 pins apin xpos1 ypos1 xpos2 ypos2 x_o y_o)
        axlClearSelSet()
        axlSetFindFilter(?enabled '("PINS") ?onButtons '("PINS"))
        points1 = axlEnterPoint(?prompts '("请选择第一个 Pin"))
        p_s1 = axlSingleSelectPoint(points1)
        when( p_s1
            pins = axlGetSelSet()
            apin = car(pins)
            xpos1 = car(apin->xy)
            ypos1 = cadr(apin->xy)
            axlSetFindFilter(?enabled '("PINS") ?onButtons '("PINS"))
            points2 = axlEnterPoint(?prompts '("请选择第二个 Pin"))
            p_s2 = axlSingleSelectPoint(points2)
            when( p_s2
                pins = axlGetSelSet()
                apin = car(pins)
                xpos2 = car(apin->xy)
                ypos2 = cadr(apin->xy)
                x_o = (xpos1 + xpos2) / 2
                y_o = (ypos1 + ypos2) / 2
                axlDBChangeDesignOrigin(-x_o:-y_o)
            )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Pkg_ChangeOrigin
; 功能    : ASTB 框架入口，带错误捕获保护
;------------------------------------------------------------------------
procedure( ASTB_Pkg_ChangeOrigin()
    ASTB_DBTransactionMark('FanySkill_Change_Origin nil)
)

ASTB_RegisterCommand("ASTB_Pkg_ChangeOrigin" "ASTB_Pkg_ChangeOrigin" ?cmdType "interactive")

printf("[ASTB] pkg_changeorigin.il loaded.\n")
