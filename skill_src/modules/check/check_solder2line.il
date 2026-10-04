;========================================================================
; 文件名    : check_solder2line.il
; 作者      : LiGuangsheng/24445 (HUAWEI)
; 创建日期  : 2002-06-01
; 版本      : 1.3
; 功能描述  : 检查Solder Mask到Line间距
; 依赖模块  : axlFormCreate, axlSetFindFilter, axlSingleSelectBox
; 修改记录  :
;   2002-06-01 v1.0 LiGuangsheng/24445 (HUAWEI) 初始创建
;   2026-07 v1.1 ASTB 第三方原样集成，仅修确定性bug：
;             mod(…,45)==90永假死分支改mod(…,90)==45（45°旋转pin漏检）；
;             第40行粘连语句拆开；已关闭表单上的axlUIWPrint改向主表单；
;             除零保护；帮助文本1.1412改1.4142；临时表单改写临时目录；
;             废弃含空格的"solder2line check"命令，入口统一ASTB_Check_Solder2Line
;   2026-07-18 v1.2 ASTB 修复组 表单界面汉化：标题/按钮/选项/提示信息改中文
;   2026-09-09 v1.3 ASTB 修复组 修 17.4 跨轮 dbid 失效（17.4 S039：跨
;             axlSingleSelectBox 轮次后旧 dbid 全部 dbid:removed）：跨轮
;             累积/比较的 net dbid 改为当轮提取网络名字符串(->net->name)
;             再比较；同网络分支改为比较两次选集当轮提取的网络名
;             （对象数量+名字集合）；_lgs_check_list_same 比较改 nequal
;========================================================================

;            CHECK SOLDER MASK TO LINE
;        ------------------------------------------------
;
;
;File name: lgs_check_solder_to_line_V1_0.il
;Revision:1.0
;Date:June 1,2002
;Writen by:
;LiGuangsheng/24445
;Tel: 6540574
;E_mail: liguangsheng@huawei.com
;CAD Group Fundamental Dept R&D Engineer
;HUAWEI TECHNOLOGIES CO., LTD.




;***************************************************************************************************************************
;        Register Main Function
;***************************************************************************************************************************

; 入口统一为 ASTB_Check_Solder2Line（见 zz_wrappers.il）；
; 原 "solder2line check" 命令名含空格，已废弃
; --- 异步表单共享状态（回调在主函数返回后触发，必须为全局，boundp保护） ---
unless( boundp('lgs_hilight_bBox) lgs_hilight_bBox = nil )
unless( boundp('lgs_view_number) lgs_view_number = 0 )
unless( boundp('lgs_zoom_i) lgs_zoom_i = 70 )
unless( boundp('lgs_zoom) lgs_zoom = 0 )
unless( boundp('lgs_bBox_win) lgs_bBox_win = nil )
unless( boundp('lgs_stol_checksamenet) lgs_stol_checksamenet = nil )
unless( boundp('lgs_layer) lgs_layer = nil )
unless( boundp('lgs_soder_adder) lgs_soder_adder = 2 )
unless( boundp('lgs_info) lgs_info = nil )
unless( boundp('lgs_stol_main_form) lgs_stol_main_form = nil )
unless( boundp('lgs_progress_form) lgs_progress_form = nil )
unless( boundp('lgsfindcompshelpform) lgsfindcompshelpform = nil )
unless( boundp('lgs31_main_form_path) lgs31_main_form_path = nil )
unless( boundp('lgs31_progress_form_path) lgs31_progress_form_path = nil )

;***************************************************************************************************************************
;        Main Function       _lgs_check_solder_to_line ()
;***************************************************************************************************************************
(defun _lgs_check_solder_to_line ()

lgs_area_list = nil   ; v1.1修复：原语句函数名与变量名粘连（_lgs_check_solder_to_line_main_formlgs_area_list）
lgs_hilight_bBox = nil
lgs_view_number = 0
lgs_soder_adder = 2
lgs_zoom_i = 70
lgs_bBox_win = nil
lgs_stol_checksamenet = nil
lgs_layer = nil
_lgs_check_solder_to_line_main_form()
axlFormSetField( lgs_stol_main_form "lgs_distance_D" lgs_soder_adder)
axlFormSetField( lgs_stol_main_form "lgs_distance_O" lgs_soder_adder*1.4142)
axlFormSetField( lgs_stol_main_form "stol_checksamenet" lgs_stol_checksamenet)
);end defun _lgs_check_solder_to_line ()

;***************************************************************************************************************************
;        _lgs_solder_to_line_check ( lgs_layer lgs_soder_adder)
;***************************************************************************************************************************
(defun _lgs_solder_to_line_check ( lgs_layer lgs_soder_adder)
let( ( lgs_area_list lgs_area_list_small lgs_area_list45 lgs_times lgs_temp
        lgs_all_pins_list lgs_all_pads_list lgs_item_bBox lgs_item_bBox_list
        lgs_item_1x lgs_item_1y lgs_item_2x lgs_item_2y
        lgs_item_1x_n lgs_item_1y_n lgs_item_2x_n lgs_item_2y_n
        lgs_item_1x_n_samll lgs_item_1y_n_samll lgs_item_2x_n_samll lgs_item_2y_n_samll
        ya yb yc yd pin_x pin_y pax pay pbx pby pcx pcy pdx pdy
        lgs_temp_select_list lgs_temp1 lgs_temp2 )

_lgs_creat_progress_form()
lgs_area_list = nil
lgs_area_list_small = nil
lgs_area_list45 = nil
lgs_hilight_bBox = nil
lgs_bBox_win = nil
lgs_view_number = 0
lgs_times = 0

axlSetFindFilter(?enabled '(noall pins) ?onButtons '(noall pins))
axlAddSelectAll()
lgs_all_pins_list = axlGetSelSet()
axlClearSelSet()

foreach(lgs_item_pins lgs_all_pins_list

    lgs_times++
    lgs_all_pads_list = lgs_item_pins->pads

    foreach(lgs_item_pads lgs_all_pads_list

        if(((lgs_item_pads->layer == lgs_layer) && (lgs_item_pads->figureName == "RECTANGLE") && (lgs_item_pads->type == "REGULAR"))
           ||((lgs_item_pads->layer == lgs_layer) && (lgs_item_pads->figureName == "SQUARE") && (lgs_item_pads->type == "REGULAR"))
        then
            ;================================================================================================
            if(mod( round( lgs_item_pins->rotation) 90) == 0
            then
                ;----------------------------------------------------------------------------------------    
                lgs_item_bBox = lgs_item_pads->bBox
                    
                if(_lgs_bBox_check_0( lgs_item_bBox)        ;bBox ?!= 0
                then
                    lgs_item_1x = car( car( lgs_item_bBox))
                    lgs_item_1y = nthelem( 2 car( lgs_item_bBox))
                    lgs_item_2x = car( nthelem( 2 lgs_item_bBox))
                    lgs_item_2y = nthelem( 2 nthelem( 2 lgs_item_bBox))
                    
                    if(lgs_item_1x < lgs_item_2x
                    then
                        lgs_item_1x_n = lgs_item_1x - lgs_soder_adder + car( lgs_item_pins->xy)
                        lgs_item_2x_n = lgs_item_2x + lgs_soder_adder + car( lgs_item_pins->xy)
                    
                    else
                        lgs_item_1x_n = lgs_item_1x + lgs_soder_adder + car( lgs_item_pins->xy)
                        lgs_item_2x_n = lgs_item_2x - lgs_soder_adder + car( lgs_item_pins->xy)
                    
                      );end if
                    
                    if(lgs_item_1y < lgs_item_2y
                    then
                        lgs_item_1y_n = lgs_item_1y - lgs_soder_adder + cadr( lgs_item_pins->xy)
                        lgs_item_2y_n = lgs_item_2y + lgs_soder_adder + cadr( lgs_item_pins->xy)
                    else
                        lgs_item_1y_n = lgs_item_1y + lgs_soder_adder + cadr( lgs_item_pins->xy)
                        lgs_item_2y_n = lgs_item_2y - lgs_soder_adder + cadr( lgs_item_pins->xy)
                    
                      );end if
                    
                    lgs_item_bBox = list( list( lgs_item_1x_n lgs_item_1y_n) list( lgs_item_2x_n lgs_item_2y_n))
                    
                    lgs_area_list = cons( list( lgs_item_bBox) lgs_area_list)        ;add to list
                    
                    lgs_item_1x_n_samll = lgs_item_1x + car( lgs_item_pins->xy)
                    lgs_item_2x_n_samll = lgs_item_2x + car( lgs_item_pins->xy)
                                        
                    lgs_item_1y_n_samll = lgs_item_1y + cadr( lgs_item_pins->xy)
                    lgs_item_2y_n_samll = lgs_item_2y + cadr( lgs_item_pins->xy)
                    
                    lgs_item_bBox = list( list( lgs_item_1x_n_samll lgs_item_1y_n_samll) list( lgs_item_2x_n_samll lgs_item_2y_n_samll))
                    
                    lgs_area_list_small = cons( list( lgs_item_bBox) lgs_area_list_small)
                        
                        
                    );end if(_lgs_bBox_check_0( lgs_item_bBox)
                ;----------------------------------------------------------------------------------------    
            ;place n*45
            else if(mod( round( lgs_item_pins->rotation) 90) == 45            ;45度旋转pin分支（v1.1修复：原mod(…,45)==90值域[0,45)永假）
                then
                    lgs_item_bBox = lgs_item_pads->parent->bBox
                    
                    ya = (caar( lgs_item_bBox) + cadadr( lgs_item_bBox))/1.4142
                    yb = (caar( lgs_item_bBox) + cadar( lgs_item_bBox))/1.4142
                    yc = (caadr( lgs_item_bBox) + cadar( lgs_item_bBox))/1.4142
                    yd = (caadr( lgs_item_bBox) + cadadr( lgs_item_bBox))/1.4142
                    
                    pin_x = car( lgs_item_pins->xy)
                    pin_y = cadr( lgs_item_pins->xy)
                    
                    pax = yb + pin_x
                    pay = ya + pin_y
                    
                    pbx = ya + pin_x
                    pby = yb + pin_y
                    
                    pcx = yd + pin_x
                    pcy = yc + pin_y
                    
                    pdx = yc + pin_x
                    pdy = yd + pin_y
                    
                    lgs_item_bBox_list = nil
                    
                    lgs_item_bBox_list = cons( list( list(pin_x-0.1 pin_y-0.1) list(pdx+0.1 pdy+0.1)) lgs_item_bBox_list)
                    lgs_item_bBox_list = cons( list( list(pax-lgs_soder_adder pay-0.1) list(pax pay+0.1)) lgs_item_bBox_list)
                    lgs_item_bBox_list = cons( list( list(pbx-0.1 pby-lgs_soder_adder) list(pbx pby+0.1)) lgs_item_bBox_list)
                    lgs_item_bBox_list = cons( list( list(pcx pcy-0.1) list(pcx+lgs_soder_adder pcy+0.1)) lgs_item_bBox_list)
                    lgs_item_bBox_list = cons( list( list(pdx pdy-0.1) list(pdx+0.1 pdy+lgs_soder_adder)) lgs_item_bBox_list)
                    
                    
                    lgs_area_list = cons( lgs_item_bBox_list lgs_area_list)
                    
                
                
                
                );end else if(mod( lgs_item_pins->rotation 45) == 0
            );end if(mod( lgs_item_pins->rotation 90) == 0
            ;================================================================================================
            
            
        );end if(lgs_item_pads->layer == lgs_layer
    );end foreach(lgs_item_pads lgs_all_pads_list

            lgs_temp = round( lgs_times * 50 / max(1 length( lgs_all_pins_list)))
            axlFormSetField( lgs_progress_form "lgs_progress" lgs_temp)
            axlUIWPrint( lgs_progress_form "%d%% 完成!" lgs_temp)
);end foreach(lgs_item_pins lgs_all_pins_list


axlSetFindFilter(?enabled '(noall VIAS CLINESEGS SHAPES PINS) ?onButtons '(noall VIAS CLINESEGS SHAPES PINS))

if(lgs_stol_checksamenet == nil
then                        ;not check same net error

    lgs_times = 0
    foreach(lgs_item_bBox_list lgs_area_list
        lgs_times++
        lgs_temp_select_list = nil
        foreach(lgs_item_bBox lgs_item_bBox_list
            axlSingleSelectBox( lgs_item_bBox)
            lgs_temp_select_list = append( axlGetSelSet()~>net~>name lgs_temp_select_list)        ;v1.3: 17.4跨轮dbid必死，当轮即提网络名字符串
        
        );end foreach(lgs_item_bBox lgs_item_bBox_list
        
        if(_lgs_check_list_same(lgs_temp_select_list) == nil
        then
            lgs_hilight_bBox = cons( lgs_item_bBox_list lgs_hilight_bBox)
         );end if
    
        axlClearSelSet()
    
        lgs_temp = round( lgs_times * 50 / max(1 length( lgs_area_list))) + 50
        axlFormSetField( lgs_progress_form "lgs_progress" lgs_temp)
        axlUIWPrint( lgs_progress_form "%d%% 完成!" lgs_temp)

    );end foreach

else                        ;check same net error

    lgs_times = 0
    foreach(lgs_item_bBox lgs_area_list
        lgs_times++
        axlSingleSelectBox( car( lgs_item_bBox))
        lgs_temp1 = axlGetSelSet()~>net~>name        ;v1.3: 当轮提取网络名，不存dbid(17.4跨轮失效)
        axlClearSelSet()
        axlSingleSelectBox( car( nthelem(lgs_times lgs_area_list_small)))
        lgs_temp2 = axlGetSelSet()~>net~>name        ;v1.3: 同上，当轮即用即弃
        if(null( and( length( lgs_temp1) == length( lgs_temp2) subsetp( lgs_temp1 lgs_temp2)))
        then
            lgs_hilight_bBox = cons( lgs_item_bBox lgs_hilight_bBox)
        );end if

        lgs_temp = round( lgs_times * 50 / max(1 length( lgs_area_list))) + 50
        axlFormSetField( lgs_progress_form "lgs_progress" lgs_temp)
        axlUIWPrint( lgs_progress_form "%d%% 完成!" lgs_temp)
        
    );end foreach
    


);end if(lgs_stol_checksamenet == nil
axlFormClose( lgs_progress_form)

);end let
);end (defun _lgs_solder_to_line_getpin ()

;***************************************************************************************************************************
;        _lgs_bBox_check_0 ( lgs_check_bBox
;***************************************************************************************************************************
(defun _lgs_bBox_check_0 ( lgs_check_bBox)
(prog ()
if(((car( car( lgs_check_bBox))-car( nthelem( 2 lgs_check_bBox))) != 0)
&& (nthelem( 2 car( lgs_check_bBox))-nthelem( 2 nthelem( 2 lgs_check_bBox)) != 0)
then
    return( t)

else
    return( nil)
  );end if
));end defun _lgs_bBox_check_0 ( lgs_check_bBox)
;***************************************************************************************************************************
;        _lgs_check_list_same (item_list)
;***************************************************************************************************************************
(defun _lgs_check_list_same (item_list)
prog(()

if(length( item_list) < 2
then
    return( t)
);end if

for(i 1 length( item_list)-1
    if(nequal( nthelem(i item_list) nthelem(i+1 item_list))        ;v1.3: 网络名字符串用nequal(==为身份比较)
    then
        return( nil)
    );end if
   );end for
return( t)

));end defun _lgs_check_list_same (item_list)

;***************************************************************************************************************************
;        _lgs_stol_main_back ( lgs_stol_main_form)
;***************************************************************************************************************************
(defun _lgs_stol_main_back ( lgs_stol_main_form)
case(lgs_stol_main_form->curField

    ("stol_checksamenet"
        lgs_stol_checksamenet = lgs_stol_main_form->curValue    
    )

    ("lgs_distance_D"
        lgs_soder_adder = lgs_stol_main_form->curValue
        ;axlFormSetField( lgs_stol_main_form "lgs_distance_D" lgs_soder_adder)
        axlFormSetField( lgs_stol_main_form "lgs_distance_O" lgs_soder_adder*1.4142)
    t)

    ("lgs_distance_O"
        lgs_soder_adder = 0.7071 * lgs_stol_main_form->curValue
        axlFormSetField( lgs_stol_main_form "lgs_distance_D" lgs_soder_adder)
        ;axlFormSetField( lgs_stol_main_form "lgs_distance_O" lgs_soder_adder*1.414)
    t)

    ("lgs_h_top"
        axlShell("setwindow pcb")
        axlVisibleDesign( nil)
        axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
        axlVisibleLayer("PIN/SOLDERMASK_TOP" t)
        ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
        ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
        axlVisibleLayer("ETCH/TOP" t)
        axlVisibleLayer("VIA CLASS/TOP" t)
        axlVisibleLayer("PIN/TOP" t)
        axlFlushDisplay()
        axlShell("redraw")
        lgs_layer = "top"
        _lgs_solder_to_line_check( "PIN/SOLDERMASK_TOP" lgs_soder_adder)

        sprintf(lgs_info "发现 %d 个错误!" length(lgs_hilight_bBox))
        axlFormSetField( lgs_stol_main_form "lgs_info" lgs_info)

    t)

    ("lgs_h_botm"
        axlShell("setwindow pcb")
        axlVisibleDesign( nil)
        axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
        axlVisibleLayer("PIN/SOLDERMASK_BOTTOM" t)
        ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
        ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
        axlVisibleLayer("ETCH/BOTTOM" t)
        axlVisibleLayer("VIA CLASS/BOTTOM" t)
        axlVisibleLayer("PIN/BOTTOM" t)
        axlFlushDisplay()
        axlShell("redraw")
        lgs_layer = "bottom"
        _lgs_solder_to_line_check( "PIN/SOLDERMASK_BOTTOM" lgs_soder_adder)

        sprintf(lgs_info "发现 %d 个错误!" length(lgs_hilight_bBox))
        axlFormSetField( lgs_stol_main_form "lgs_info" lgs_info)

    t)
    
    ("lgs_zoom"

            lgs_zoom = lgs_stol_main_form->curValue
            lgs_zoom_i = 70 + 4.5*lgs_zoom
            axlFormSetField( lgs_stol_main_form "shadow_factor"  strcat(sprintf( lgs_temp "%d" lgs_zoom) "%"))
            if(lgs_bBox_win != nil
            then
            axlWindowBoxSet(list((caar( lgs_bBox_win)-lgs_zoom_i):(cadar( lgs_bBox_win)-lgs_zoom_i)
                         (caar( lgs_bBox_win)+lgs_zoom_i):(cadar( lgs_bBox_win)+lgs_zoom_i)))
            );end if
            

    t)


    ("lgs_first"
        if(lgs_layer == "top"
        then
            axlShell("setwindow pcb")
            axlVisibleDesign( nil)
            axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
            axlVisibleLayer("PIN/SOLDERMASK_TOP" t)
            ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
            ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
            axlVisibleLayer("ETCH/TOP" t)
            axlVisibleLayer("VIA CLASS/TOP" t)
            axlVisibleLayer("PIN/TOP" t)
            axlFlushDisplay()
            axlShell("redraw")
        
        else if(lgs_layer == "bottom"
        then
            axlShell("setwindow pcb")
            axlVisibleDesign( nil)
            axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
            axlVisibleLayer("PIN/SOLDERMASK_BOTTOM" t)
            ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
            ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
            axlVisibleLayer("ETCH/BOTTOM" t)
            axlVisibleLayer("VIA CLASS/BOTTOM" t)
            axlVisibleLayer("PIN/BOTTOM" t)
            axlFlushDisplay()
            axlShell("redraw")

        ));end if(lgs_layer == "top"
    
    
        if(length( lgs_hilight_bBox) != 0
        then
            axlClearSelSet()
            lgs_view_number = 1
            lgs_bBox_win = car( nthelem(lgs_view_number lgs_hilight_bBox))
            axlWindowBoxSet(list((caar( lgs_bBox_win)-lgs_zoom_i):(cadar( lgs_bBox_win)-lgs_zoom_i)
                         (caar( lgs_bBox_win)+lgs_zoom_i):(cadar( lgs_bBox_win)+lgs_zoom_i)))
            axlSetFindFilter(?enabled '(noall VIAS CLINESEGS SHAPES PINS) ?onButtons '(noall VIAS CLINESEGS SHAPES PINS))
            axlSingleSelectBox( lgs_bBox_win)
            sprintf(lgs_info "%d/%d" lgs_view_number length(lgs_hilight_bBox))
            axlFormSetField( lgs_stol_main_form "lgs_info" lgs_info)
        else
            axlFormSetField( lgs_stol_main_form "lgs_info" "请先执行检查!")
            axlUIWPrint( lgs_stol_main_form "%s" "请先执行检查!")
        );end if
    t)

    ("lgs_next"
        if(lgs_layer == "top"
        then
            axlShell("setwindow pcb")
            axlVisibleDesign( nil)
            axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
            axlVisibleLayer("PIN/SOLDERMASK_TOP" t)
            ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
            ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
            axlVisibleLayer("ETCH/TOP" t)
            axlVisibleLayer("VIA CLASS/TOP" t)
            axlVisibleLayer("PIN/TOP" t)
            axlFlushDisplay()
            axlShell("redraw")
        
        else if(lgs_layer == "bottom"
        then
            axlShell("setwindow pcb")
            axlVisibleDesign( nil)
            axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
            axlVisibleLayer("PIN/SOLDERMASK_BOTTOM" t)
            ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
            ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
            axlVisibleLayer("ETCH/BOTTOM" t)
            axlVisibleLayer("VIA CLASS/BOTTOM" t)
            axlVisibleLayer("PIN/BOTTOM" t)
            axlFlushDisplay()
            axlShell("redraw")

        ));end if(lgs_layer == "top"

        if(length( lgs_hilight_bBox) > lgs_view_number
        then
            axlClearSelSet()
            lgs_view_number++
            lgs_bBox_win = car( nthelem(lgs_view_number lgs_hilight_bBox))
            axlWindowBoxSet(list((caar( lgs_bBox_win)-lgs_zoom_i):(cadar( lgs_bBox_win)-lgs_zoom_i)
                         (caar( lgs_bBox_win)+lgs_zoom_i):(cadar( lgs_bBox_win)+lgs_zoom_i)))
            axlSetFindFilter(?enabled '(noall VIAS CLINESEGS SHAPES PINS) ?onButtons '(noall VIAS CLINESEGS SHAPES PINS))
            axlSingleSelectBox( lgs_bBox_win)
            sprintf(lgs_info "%d/%d" lgs_view_number length(lgs_hilight_bBox))
            axlFormSetField( lgs_stol_main_form "lgs_info" lgs_info)
        else
            axlFormSetField( lgs_stol_main_form "lgs_info" "请先执行检查!")
            axlUIWPrint( lgs_stol_main_form "%s" "请先执行检查!")
        );end if
    t)

    ("lgs_prev"
        if(lgs_layer == "top"
        then
            axlShell("setwindow pcb")
            axlVisibleDesign( nil)
            axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
            axlVisibleLayer("PIN/SOLDERMASK_TOP" t)
            ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
            ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
            axlVisibleLayer("ETCH/TOP" t)
            axlVisibleLayer("VIA CLASS/TOP" t)
            axlVisibleLayer("PIN/TOP" t)
            axlFlushDisplay()
            axlShell("redraw")
        
        else if(lgs_layer == "bottom"
        then
            axlShell("setwindow pcb")
            axlVisibleDesign( nil)
            axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
            axlVisibleLayer("PIN/SOLDERMASK_BOTTOM" t)
            ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
            ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
            axlVisibleLayer("ETCH/BOTTOM" t)
            axlVisibleLayer("VIA CLASS/BOTTOM" t)
            axlVisibleLayer("PIN/BOTTOM" t)
            axlFlushDisplay()
            axlShell("redraw")

        ));end if(lgs_layer == "top"

        if(lgs_view_number > 1
        then
            axlClearSelSet()
            lgs_view_number--
            lgs_bBox_win = car( nthelem(lgs_view_number lgs_hilight_bBox))
            axlWindowBoxSet(list((caar( lgs_bBox_win)-lgs_zoom_i):(cadar( lgs_bBox_win)-lgs_zoom_i)
                         (caar( lgs_bBox_win)+lgs_zoom_i):(cadar( lgs_bBox_win)+lgs_zoom_i)))
            axlSetFindFilter(?enabled '(noall VIAS CLINESEGS SHAPES PINS) ?onButtons '(noall VIAS CLINESEGS SHAPES PINS))
            axlSingleSelectBox( lgs_bBox_win)
            sprintf(lgs_info "%d/%d" lgs_view_number length(lgs_hilight_bBox))
            axlFormSetField( lgs_stol_main_form "lgs_info" lgs_info)
        else
            axlFormSetField( lgs_stol_main_form "lgs_info" "请先执行检查!")
            axlUIWPrint( lgs_stol_main_form "%s" "请先执行检查!")
        );end if
    t)

    ("lgs_last"
        if(lgs_layer == "top"
        then
            axlShell("setwindow pcb")
            axlVisibleDesign( nil)
            axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
            axlVisibleLayer("PIN/SOLDERMASK_TOP" t)
            ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
            ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
            axlVisibleLayer("ETCH/TOP" t)
            axlVisibleLayer("VIA CLASS/TOP" t)
            axlVisibleLayer("PIN/TOP" t)
            axlFlushDisplay()
            axlShell("redraw")
        
        else if(lgs_layer == "bottom"
        then
            axlShell("setwindow pcb")
            axlVisibleDesign( nil)
            axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
            axlVisibleLayer("PIN/SOLDERMASK_BOTTOM" t)
            ;axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
            ;axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
            axlVisibleLayer("ETCH/BOTTOM" t)
            axlVisibleLayer("VIA CLASS/BOTTOM" t)
            axlVisibleLayer("PIN/BOTTOM" t)
            axlFlushDisplay()
            axlShell("redraw")

        ));end if(lgs_layer == "top"

        if(length( lgs_hilight_bBox) != 0
        then
            axlClearSelSet()
            lgs_view_number = length( lgs_hilight_bBox)
            lgs_bBox_win = car( nthelem(lgs_view_number lgs_hilight_bBox))
            axlWindowBoxSet(list((caar( lgs_bBox_win)-lgs_zoom_i):(cadar( lgs_bBox_win)-lgs_zoom_i)
                         (caar( lgs_bBox_win)+lgs_zoom_i):(cadar( lgs_bBox_win)+lgs_zoom_i)))
            axlSetFindFilter(?enabled '(noall VIAS CLINESEGS SHAPES PINS) ?onButtons '(noall VIAS CLINESEGS SHAPES PINS))
            axlSingleSelectBox( lgs_bBox_win)
            sprintf(lgs_info "%d/%d" lgs_view_number length(lgs_hilight_bBox))
            axlFormSetField( lgs_stol_main_form "lgs_info" lgs_info)
        else
            axlFormSetField( lgs_stol_main_form "lgs_info" "请先执行检查!")
            axlUIWPrint( lgs_stol_main_form "%s" "请先执行检查!")
        );end if
    t)

    ("done"
        axlFormClose( lgs_stol_main_form)
    t)

    ("lgs_hilight_help"
        _lgs_stol_help_Form()
    t)
 
    );end case

);end (defun _lgs_stol_main_back ( lgs_stol_main_form)


;***************************************************************************************************************************
;        _lgs_check_solder_to_line_main_form ()
;***************************************************************************************************************************
(defun _lgs_check_solder_to_line_main_form ()
    lgs31_main_form_path = strcat(axlTempFile() ".form")
    stol_Form_File = outfile(lgs31_main_form_path "w")
    fprintf( stol_Form_File "FILE_TYPE=FORM_DEFN VERSION=2\n")
    fprintf( stol_Form_File "FORM\n")
    fprintf( stol_Form_File "FIXED\n")
    fprintf( stol_Form_File "PORT 24 20\n")
    fprintf( stol_Form_File "HEADER \"\327\350\272\270\265\275\327\337\317\337 V1.0\"\n")
    fprintf( stol_Form_File "TILE\n")
    fprintf( stol_Form_File "FIELD lgs_distance_D\n")
    fprintf( stol_Form_File "FLOC 1 17\n")
    fprintf( stol_Form_File "REALFILLIN 5 5\n")
    fprintf( stol_Form_File "REALMIN 0\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "FIELD lgs_distance_O\n")
    fprintf( stol_Form_File "FLOC 17 17\n")
    fprintf( stol_Form_File "REALFILLIN 5 5\n")
    fprintf( stol_Form_File "REALMIN 0\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "TEXT \"X  1.4142  =\"\n")
    fprintf( stol_Form_File "TLOC 8 17\n")
    fprintf( stol_Form_File "ENDTEXT\n")
    fprintf( stol_Form_File "FIELD stol_checksamenet\n")
    fprintf( stol_Form_File "FLOC 2 20\n")
    fprintf( stol_Form_File "CHECKLIST \"\274\354\262\351\315\254\315\370\302\347\264\355\316\363\"\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "GROUP \"\"\n")
    fprintf( stol_Form_File "FLOC 1 22\n")
    fprintf( stol_Form_File "FSIZE 23 14\n")
    fprintf( stol_Form_File "INFO group\n")
    fprintf( stol_Form_File "ENDGROUP\n")
    fprintf( stol_Form_File "FIELD lgs_h_top\n")
    fprintf( stol_Form_File "FLOC 2 24\n")
    fprintf( stol_Form_File "MENUBUTTON \"\274\354\262\351\266\245\262\343\" 3 3\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "FIELD lgs_h_botm\n")
    fprintf( stol_Form_File "FLOC 12 24\n")
    fprintf( stol_Form_File "MENUBUTTON \"\274\354\262\351\265\327\262\343\" 3 3\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "FIELD lgs_info\n")
    fprintf( stol_Form_File "FLOC 2 27\n")
    fprintf( stol_Form_File "STRFILLIN 19 45\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "TEXT \"\313\365\267\305:\"                                \n")
    fprintf( stol_Form_File "TLOC 2 30                                                     \n")
    fprintf( stol_Form_File "ENDTEXT                                                       \n")
    fprintf( stol_Form_File "TEXT                                                          \n")
    fprintf( stol_Form_File "TLOC 18 30                                                    \n")
    fprintf( stol_Form_File "FGROUP \"\313\365\267\305\261\310\300\375\"                                        \n")
    fprintf( stol_Form_File "INFO shadow_factor 4                                          \n")
    fprintf( stol_Form_File "ENDTEXT                                                       \n")
    fprintf( stol_Form_File "FIELD lgs_zoom                                           \n")
    fprintf( stol_Form_File "FLOC 6 30                                                     \n")
    fprintf( stol_Form_File "TRACKBAR 12 4                                                 \n")
    fprintf( stol_Form_File "MIN 0                                                         \n")
    fprintf( stol_Form_File "MAX 100                                                       \n")
    fprintf( stol_Form_File "ENDFIELD                                                      \n")
    fprintf( stol_Form_File "FIELD lgs_first\n")
    fprintf( stol_Form_File "FLOC 2 33\n")
    fprintf( stol_Form_File "MENUBUTTON \"\312\327\270\366\" 3 3\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "FIELD lgs_next\n")
    fprintf( stol_Form_File "FLOC 7 33\n")
    fprintf( stol_Form_File "MENUBUTTON \"\317\302\270\366\" 3 3\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "FIELD lgs_prev\n")
    fprintf( stol_Form_File "FLOC 13 33\n")
    fprintf( stol_Form_File "MENUBUTTON \"\311\317\270\366\" 3 3\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "FIELD lgs_last\n")
    fprintf( stol_Form_File "FLOC 18 33\n")
    fprintf( stol_Form_File "MENUBUTTON \"\304\251\270\366\" 3 3\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "FIELD done\n")
    fprintf( stol_Form_File "FLOC 2 37\n")
    fprintf( stol_Form_File "MENUBUTTON \"\315\313\263\366\" 8 3\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "FIELD lgs_hilight_help\n")
    fprintf( stol_Form_File "FLOC 15 37\n")
    fprintf( stol_Form_File "MENUBUTTON \"\260\357\326\372\" 6 3\n")
    fprintf( stol_Form_File "ENDFIELD\n")
    fprintf( stol_Form_File "ENDTILE\n")
    fprintf( stol_Form_File "ENDFORM\n")

    close( stol_Form_File)
    lgs_stol_main_form = axlFormCreate( (gensym) lgs31_main_form_path
                        '(e outer) '_lgs_stol_main_back t)
    deleteFile( lgs31_main_form_path)
    axlFormDisplay( lgs_stol_main_form)
);end defun _lgs_check_solder_to_line_main_form ()

;***************************************************************************************************************************
;        _lgs_creat_progress_form()
;***************************************************************************************************************************
(defun _lgs_creat_progress_form ()
;let( (hilightsmd_Form)
lgs31_progress_form_path = strcat(axlTempFile() ".form")
hilightsmd_Form=outfile(lgs31_progress_form_path "w")
fprintf(hilightsmd_Form "#Write by lgs \n")
fprintf(hilightsmd_Form "FILE_TYPE=FORM_DEFN VERSION=2\n")
fprintf(hilightsmd_Form "FORM\n")
fprintf(hilightsmd_Form "FIXED\n")
fprintf(hilightsmd_Form "PORT 45 14\n")
fprintf(hilightsmd_Form "HEADER \"\274\354\262\351\327\350\272\270\265\275\327\337\317\337 V1.0\"\n")
fprintf(hilightsmd_Form "TILE\n")
fprintf(hilightsmd_Form "FIELD lgs_progress\n")
fprintf(hilightsmd_Form "FLOC 3 1\n")
fprintf(hilightsmd_Form "PROGRESS 40 3\n")
fprintf(hilightsmd_Form "ENDFIELD\n")
fprintf(hilightsmd_Form "ENDTILE\n")
fprintf(hilightsmd_Form "ENDFORM  \n")
close(hilightsmd_Form)
lgs_progress_form = axlFormCreate( (gensym) lgs31_progress_form_path '(e outer) '_lgs31_nil t)
deleteFile( lgs31_progress_form_path)
axlFormDisplay( lgs_progress_form)
;);end let
);end (defun _lgs_creat_hilight_smd_form ()

;------------------------------------------------------------------------
; 空回调：进度条表单专用（模块私有前缀，避免与check_90degline/29同名冲突）
;------------------------------------------------------------------------
(defun _lgs31_nil (form)
1==1
)
;************************************************************************************************************
;        _lgs_Build_Technics_Manager_Help_Form ()
;************************************************************************************************************
(defun _lgs_stol_help_Form ()
    setq( lgsfindcompshelpform strcat(axlTempFile() ".form"))
        deleteFile( lgsfindcompshelpform)
        FORMFINDHELPFILE = outfile( lgsfindcompshelpform)
        fprintf( FORMFINDHELPFILE "FILE_TYPE=FORM_DEFN VERSION=2\n")
        fprintf( FORMFINDHELPFILE "FORM\n")
        fprintf( FORMFINDHELPFILE "FIXED\n")
        fprintf( FORMFINDHELPFILE "PORT 33 70\n")
        fprintf( FORMFINDHELPFILE "HEADER \"\270\337\301\301SMD V1.0\"\n")
        fprintf( FORMFINDHELPFILE "TILE\n")
        fprintf( FORMFINDHELPFILE "GROUP \"\"\n")
        fprintf( FORMFINDHELPFILE "FLOC 3 0\n")
        fprintf( FORMFINDHELPFILE "FSIZE 28 6\n")
        fprintf( FORMFINDHELPFILE "INFO group\n")
        fprintf( FORMFINDHELPFILE "ENDGROUP\n")
        fprintf( FORMFINDHELPFILE "TEXT \"\327\350\272\270\265\275\327\337\317\337 V1.0\"\n")
        fprintf( FORMFINDHELPFILE "TLOC 10 2\n")
        fprintf( FORMFINDHELPFILE "ENDTEXT\n")
        fprintf( FORMFINDHELPFILE "TEXT \"\274\354\262\351\327\350\272\270\265\275\327\337\317\337\264\355\316\363\"\n")
        fprintf( FORMFINDHELPFILE "TLOC 8 4\n")
        fprintf( FORMFINDHELPFILE "ENDTEXT\n")
        fprintf( FORMFINDHELPFILE "TEXT \"\260\346\261\276:1.0\"\n")
        fprintf( FORMFINDHELPFILE "TLOC 13 6\n")
        fprintf( FORMFINDHELPFILE "ENDTEXT\n")
        fprintf( FORMFINDHELPFILE "TEXT \"\327\367\325\337:Li Guangsheng/24445\"\n")
        fprintf( FORMFINDHELPFILE "TLOC 6 8\n")
        fprintf( FORMFINDHELPFILE "ENDTEXT\n")
        fprintf( FORMFINDHELPFILE "TEXT \"HUAWEI CAD \"\n")
        fprintf( FORMFINDHELPFILE "TLOC 12 10\n")
        fprintf( FORMFINDHELPFILE "ENDTEXT\n")
        fprintf( FORMFINDHELPFILE "TEXT \"\310\325\306\332:05/25/2002\"\n")
        fprintf( FORMFINDHELPFILE "TLOC 11 12\n")
        fprintf( FORMFINDHELPFILE "ENDTEXT\n")
        fprintf( FORMFINDHELPFILE "TEXT \"\323\320\316\312\314\342\307\353\301\252\317\265\327\367\325\337!\"\n")
        fprintf( FORMFINDHELPFILE "TLOC 4 14\n")
        fprintf( FORMFINDHELPFILE "ENDTEXT\n")
        fprintf( FORMFINDHELPFILE "TEXT \"ADD:1618   TEL:50574\"\n")
        fprintf( FORMFINDHELPFILE "TLOC 8 16\n")
        fprintf( FORMFINDHELPFILE "ENDTEXT\n")
        fprintf( FORMFINDHELPFILE "FIELD lgsok\n")
        fprintf( FORMFINDHELPFILE "FLOC 11 18\n")
        fprintf( FORMFINDHELPFILE "MENUBUTTON \"\310\267\266\250\" 10 3\n")
        fprintf( FORMFINDHELPFILE "ENDFIELD\n")
        fprintf( FORMFINDHELPFILE "ENDTILE\n")
        fprintf( FORMFINDHELPFILE "ENDFORM\n")
        close( FORMFINDHELPFILE)
        findhelpform = (axlFormCreate (gensym) lgsfindcompshelpform '("E" "OUTER") '_lgs31_find_help_Callback t)
        axlFormDisplay( findhelpform)
);(defun _lgs_hilight_smd_help_Form ()

;************************************************************************************************************
;        _lgs31_find_help_Callback (findhelpform)  — 加模块前缀避免与29号冲突
;************************************************************************************************************
(defun _lgs31_find_help_Callback (findhelpform)
    axlFormClose( findhelpform)
    deleteFile( lgsfindcompshelpform)
);end defun lgs_tech_help_Callback (helpform)

;***************************************************************************************************************************
;***************************************************************************************************************************
;***************************************************************************************************************************
