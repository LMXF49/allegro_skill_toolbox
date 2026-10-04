;========================================================================
; 文件名    : place_movescreen.il
; 作者      : deargds
; 创建日期  : 2026-07-16
; 版本      : 1.0
; 功能描述  : 屏幕视图移动控制，支持上下左右方向移动及步长设置
; 依赖模块  : 无
; 修改记录  :
;   2026-07-16 v1.0 Toolbox 初始创建并添加规范文件头
;   2026-07-17 v1.1 Toolbox 步长输入增加数字校验；方向键绑定改 axlSetAlias
;              （会话级，不写用户 env）；x_move_screen_step 加 boundp 保护
;========================================================================

;; ============================================================
;; File: place_movescreen.il
;; Purpose: Move Screen
;; Encoding: GBK
;; Source: 02-布局与对齐/place_movescreen.il
;; ============================================================

;write by deargds

; 方向键绑定为会话级别名（axlSetAlias 仅当前会话有效，不写入用户 env）。
; 注意：加载本模块后方向键被用于视图移动，覆盖 Allegro 默认方向键行为；
; 执行 x_restore_arrow_keys() 或重启 Allegro 可恢复默认。
axlSetAlias( "Up"    "skill x_up")

axlSetAlias( "Down"  "skill x_down")

axlSetAlias( "Left"  "skill x_left")

axlSetAlias( "Right" "skill x_right")

axlShell("alias set move grid 'skill set_x_move_screen_step'")

unless(boundp('x_move_screen_step)
    x_move_screen_step = 1
)



defun( x_restore_arrow_keys ()
    axlSetAlias( "Up" nil)
    axlSetAlias( "Down" nil)
    axlSetAlias( "Left" nil)
    axlSetAlias( "Right" nil)
    axlMsgPut("Arrow keys restored to default.")
)

defun( set_x_move_screen_step ()

prog(( gp gpv)

    gp = axlUIPrompt("Please input screen move grid:")

    when( gp == nil return(nil))

    ; atof 对非法输入返回 0.0 而非 nil，必须校验数值范围
    gpv = errset(atof(gp))

    if( gpv == nil || car(gpv) <= 0 then

        axlUIConfirm("\312\344\310\353\316\336\320\247\243\254\307\353\312\344\310\353\264\363\323\332 0 \265\304\312\375\327\326")

    else

        x_move_screen_step = car(gpv)

    )

))



defun( x_up ()

let((x y box)

x = 0

y = x_move_screen_step

box = axlWindowBoxGet()

axlWindowBoxSet(list(list(xCoord(lowerLeft(box)) + x yCoord(lowerLeft(box)) + y) list( xCoord(upperRight(box)) + x yCoord(upperRight(box)) + y)))

))



defun( x_down ()

let((x y box)

x = 0

y = minus(x_move_screen_step)

box = axlWindowBoxGet()

axlWindowBoxSet(list(list(xCoord(lowerLeft(box)) + x yCoord(lowerLeft(box)) + y) list( xCoord(upperRight(box)) + x yCoord(upperRight(box)) + y)))

))



defun( x_left ()

let((x y box)

x = minus(x_move_screen_step)

y = 0

box = axlWindowBoxGet()

axlWindowBoxSet(list(list(xCoord(lowerLeft(box)) + x yCoord(lowerLeft(box)) + y) list( xCoord(upperRight(box)) + x yCoord(upperRight(box)) + y)))

))



defun( x_right ()

let((x y box)

x = x_move_screen_step

y = 0

box = axlWindowBoxGet()

axlWindowBoxSet(list(list(xCoord(lowerLeft(box)) + x yCoord(lowerLeft(box)) + y) list( xCoord(upperRight(box)) + x yCoord(upperRight(box)) + y)))

))
;; ============================================================
;; Toolbox wrapper
;; ============================================================

procedure( ASTB_Place_MoveScreen()
  x_right()
)

ASTB_RegisterCommand("ASTB_Place_MoveScreen" "ASTB_Place_MoveScreen" ?cmdType "interactive")

printf("[ASTB] place_movescreen.il loaded.\n")