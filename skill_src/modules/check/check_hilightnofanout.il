;========================================================================
; 文件名    : check_hilightnofanout.il
; 作者      : LiGuangsheng/24445 (HUAWEI)
; 创建日期  : 2002-06-01
; 版本      : 1.3
; 功能描述  : 高亮显示无Fanout的SMD焊盘
; 依赖模块  : axlFormCreate, axlSetFindFilter, axlSingleSelectBox
; 修改记录  :
;   2002-06-01 v1.0 LiGuangsheng/24445 (HUAWEI) 初始创建
;   2026-07 v1.1 ASTB 第三方原样集成，仅修确定性bug：
;             修复deleteFile删错文件（主表单临时文件残留）；
;             无net的pin判空防nil~>bBox崩溃；axlShell逐pin高亮改axlHighlightObject；
;             临时表单改写临时目录；可见性退出前恢复；共享全局boundp保护；
;             废弃hl_nf系列裸命令注册，入口统一ASTB_Check_HilightNoFanout
;   2026-07-18 v1.2 ASTB 修复组 表单界面汉化：标题/按钮/选项/提示信息改中文
;   2026-09-09 v1.3 ASTB 修复组 17.4 跨轮 dbid 失效(S039)：候选SMD pin属性
;             先提取为纯数据(net判定/中心xy)；高亮按中心xy现场重解析即用即弃
;========================================================================

;            Hilight SMD Pins without Fanout
;        ------------------------------------------------
;
;
;File name: lgs_hilight_nofanout.il
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
; 入口统一为 ASTB_Check_HilightNoFanout（见 zz_wrappers.il）；
; 原 hl_nf_top/hl_nf_botm/hl_nf 裸命令注册已废弃
; --- 模块常量：导航窗口缩放边距 ---
C_LGS29_ZOOM_MARGIN = 200

; --- 异步表单共享状态（回调在主函数返回后触发，必须为全局，boundp保护） ---
unless( boundp('lgs_hilight_bBox) lgs_hilight_bBox = nil )
unless( boundp('lgs_view_number) lgs_view_number = 0 )
unless( boundp('lgs_info) lgs_info = nil )
unless( boundp('lgs_bBox) lgs_bBox = nil )
unless( boundp('lgs_hilight_smd_main_form) lgs_hilight_smd_main_form = nil )
unless( boundp('lgs_hilight_smd_form) lgs_hilight_smd_form = nil )
unless( boundp('lgsfindcompshelpform) lgsfindcompshelpform = nil )
unless( boundp('lgs29_main_form_path) lgs29_main_form_path = nil )
unless( boundp('lgs29_progress_form_path) lgs29_progress_form_path = nil )

;***************************************************************************************************************************
;        Main Function
;***************************************************************************************************************************
(defun _lgs_hilight_smd_main ()
let( ( lgs_smd_bBox lgs_all_pins_list lgs_hilight_bBox lgs_time lgs_step lgs_i lgs_item_bBox_mi lgs_hilight_smd_main_form)


 

;***************************************************************************************************************************
;        _lgs_creat_hilight_smd_main_form()
;***************************************************************************************************************************
(defun _lgs_creat_hilight_smd_main_form ()
    lgs29_main_form_path = strcat(axlTempFile() ".form")
    Hilight_SMD_Form_File = outfile(lgs29_main_form_path "w")
        fprintf( Hilight_SMD_Form_File "FILE_TYPE=FORM_DEFN VERSION=2\n")
        fprintf( Hilight_SMD_Form_File "FORM\n")
        fprintf( Hilight_SMD_Form_File "FIXED\n")
        fprintf( Hilight_SMD_Form_File "PORT 24 20\n")
        fprintf( Hilight_SMD_Form_File "HEADER \"\270\337\301\301SMD V1.0\"\n")
        fprintf( Hilight_SMD_Form_File "TILE\n")
        fprintf( Hilight_SMD_Form_File "GROUP \"\"\n")
        fprintf( Hilight_SMD_Form_File "FLOC 1 0\n")
        fprintf( Hilight_SMD_Form_File "FSIZE 23 11\n")
        fprintf( Hilight_SMD_Form_File "INFO group\n")
        fprintf( Hilight_SMD_Form_File "ENDGROUP  \n")
        fprintf( Hilight_SMD_Form_File "FIELD lgs_h_top\n")
        fprintf( Hilight_SMD_Form_File "FLOC 2 2\n")
        fprintf( Hilight_SMD_Form_File "MENUBUTTON \"\270\337\301\301\266\245\262\343\" 3 3\n")
        fprintf( Hilight_SMD_Form_File "ENDFIELD\n")
        fprintf( Hilight_SMD_Form_File "FIELD lgs_h_botm\n")
        fprintf( Hilight_SMD_Form_File "FLOC 12 2\n")
        fprintf( Hilight_SMD_Form_File "MENUBUTTON \"\270\337\301\301\265\327\262\343\" 3 3\n")
        fprintf( Hilight_SMD_Form_File "ENDFIELD\n")
        fprintf( Hilight_SMD_Form_File "FIELD lgs_info\n")
        fprintf( Hilight_SMD_Form_File "FLOC 2 5\n")
        fprintf( Hilight_SMD_Form_File "STRFILLIN 19 45\n")
        fprintf( Hilight_SMD_Form_File "ENDFIELD\n")
        fprintf( Hilight_SMD_Form_File "FIELD lgs_first\n")
        fprintf( Hilight_SMD_Form_File "FLOC 2 8\n")
        fprintf( Hilight_SMD_Form_File "MENUBUTTON \"\312\327\270\366\" 3 3\n")
        fprintf( Hilight_SMD_Form_File "ENDFIELD\n")
        fprintf( Hilight_SMD_Form_File "FIELD lgs_next\n")
        fprintf( Hilight_SMD_Form_File "FLOC 7 8\n")
        fprintf( Hilight_SMD_Form_File "MENUBUTTON \"\317\302\270\366\" 3 3\n")
        fprintf( Hilight_SMD_Form_File "ENDFIELD\n")
        fprintf( Hilight_SMD_Form_File "FIELD lgs_prev\n")
        fprintf( Hilight_SMD_Form_File "FLOC 13 8\n")
        fprintf( Hilight_SMD_Form_File "MENUBUTTON \"\311\317\270\366\" 3 3\n")
        fprintf( Hilight_SMD_Form_File "ENDFIELD\n")
        fprintf( Hilight_SMD_Form_File "FIELD lgs_last\n")
        fprintf( Hilight_SMD_Form_File "FLOC 18 8\n")
        fprintf( Hilight_SMD_Form_File "MENUBUTTON \"\304\251\270\366\" 3 3\n")
        fprintf( Hilight_SMD_Form_File "ENDFIELD\n")
        fprintf( Hilight_SMD_Form_File "FIELD done\n")
        fprintf( Hilight_SMD_Form_File "FLOC 2 12\n")
        fprintf( Hilight_SMD_Form_File "MENUBUTTON \"\315\313\263\366\" 8 3\n")
        fprintf( Hilight_SMD_Form_File "ENDFIELD\n")
        fprintf( Hilight_SMD_Form_File "FIELD lgs_hilight_help\n")
        fprintf( Hilight_SMD_Form_File "FLOC 15 12\n")
        fprintf( Hilight_SMD_Form_File "MENUBUTTON \"\260\357\326\372\" 6 3\n")
        fprintf( Hilight_SMD_Form_File "ENDFIELD\n")
        fprintf( Hilight_SMD_Form_File "ENDTILE\n")
        fprintf( Hilight_SMD_Form_File "ENDFORM\n")
    close( Hilight_SMD_Form_File)
    lgs_hilight_smd_main_form = axlFormCreate( (gensym) lgs29_main_form_path 
                        '(e outer) '_lgs_hilight_smd_main_back t)
    deleteFile( lgs29_main_form_path)
    axlFormDisplay( lgs_hilight_smd_main_form)
);end (defun _lgs_creat_hilight_smd_main_form ()

;***************************************************************************************************************************
;        _lgs_hilight_smd_main_back()
;***************************************************************************************************************************
(defun _lgs_hilight_smd_main_back ( lgs_hilight_smd_main_form)
case(lgs_hilight_smd_main_form->curField

    ("lgs_h_top"
        _lgs_hilight_no_fanoutsmd_top()
        sprintf(lgs_info "高亮 %d 个SMD Pin!" length(lgs_hilight_bBox))
        axlFormSetField( lgs_hilight_smd_main_form "lgs_info" lgs_info)
        lgs_view_number = 0
    t)

    ("lgs_h_botm"
        _lgs_hilight_no_fanoutsmd_botm()
        sprintf(lgs_info "高亮 %d 个SMD Pin!" length(lgs_hilight_bBox))
        axlFormSetField( lgs_hilight_smd_main_form "lgs_info" lgs_info)
        lgs_view_number = 0
    t)
    
    ("lgs_first"
        if(length( lgs_hilight_bBox) != 0
        then
            lgs_view_number = 1
            lgs_bBox = nthelem(lgs_view_number lgs_hilight_bBox)
            axlWindowBoxSet(list((caar( lgs_bBox)-C_LGS29_ZOOM_MARGIN):(cadar( lgs_bBox)-C_LGS29_ZOOM_MARGIN) 
                         (caar( lgs_bBox)+C_LGS29_ZOOM_MARGIN):(cadar( lgs_bBox)+C_LGS29_ZOOM_MARGIN)))
            sprintf(lgs_info "%d/%d" lgs_view_number length(lgs_hilight_bBox))
            axlFormSetField( lgs_hilight_smd_main_form "lgs_info" lgs_info)                     
        );end if
    t)
    
    ("lgs_next"
        if(length( lgs_hilight_bBox) > lgs_view_number
        then
            lgs_view_number++
            lgs_bBox = nthelem(lgs_view_number lgs_hilight_bBox)
            axlWindowBoxSet(list((caar( lgs_bBox)-C_LGS29_ZOOM_MARGIN):(cadar( lgs_bBox)-C_LGS29_ZOOM_MARGIN) 
                         (caar( lgs_bBox)+C_LGS29_ZOOM_MARGIN):(cadar( lgs_bBox)+C_LGS29_ZOOM_MARGIN)))
            sprintf(lgs_info "%d/%d" lgs_view_number length(lgs_hilight_bBox))
            axlFormSetField( lgs_hilight_smd_main_form "lgs_info" lgs_info)                     
        );end if
    t)
    
    ("lgs_prev"
        if(lgs_view_number > 1
        then
            lgs_view_number--
            lgs_bBox = nthelem(lgs_view_number lgs_hilight_bBox)
            axlWindowBoxSet(list((caar( lgs_bBox)-C_LGS29_ZOOM_MARGIN):(cadar( lgs_bBox)-C_LGS29_ZOOM_MARGIN) 
                         (caar( lgs_bBox)+C_LGS29_ZOOM_MARGIN):(cadar( lgs_bBox)+C_LGS29_ZOOM_MARGIN)))
            sprintf(lgs_info "%d/%d" lgs_view_number length(lgs_hilight_bBox))
            axlFormSetField( lgs_hilight_smd_main_form "lgs_info" lgs_info)                     
        );end if
    t)
    
    ("lgs_last"
        if(length( lgs_hilight_bBox) != 0
        then
            lgs_view_number = length( lgs_hilight_bBox)
            lgs_bBox = nthelem(lgs_view_number lgs_hilight_bBox)
            axlWindowBoxSet(list((caar( lgs_bBox)-C_LGS29_ZOOM_MARGIN):(cadar( lgs_bBox)-C_LGS29_ZOOM_MARGIN) 
                         (caar( lgs_bBox)+C_LGS29_ZOOM_MARGIN):(cadar( lgs_bBox)+C_LGS29_ZOOM_MARGIN)))
            sprintf(lgs_info "%d/%d" lgs_view_number length(lgs_hilight_bBox))
            axlFormSetField( lgs_hilight_smd_main_form "lgs_info" lgs_info)                     
        );end if
    t)
    
    ("done"
        axlFormClose( lgs_hilight_smd_main_form)
    t)
    
    ("lgs_hilight_help"
        _lgs_hilight_smd_help_Form()
    t)



);end case
);end defun _lgs_hilight_smd_main_back ()

;************************************************************************************************************
;        _lgs_Build_Technics_Manager_Help_Form ()
;************************************************************************************************************
(defun _lgs_hilight_smd_help_Form ()
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
        fprintf( FORMFINDHELPFILE "TEXT \"\270\337\301\301SMD V1.0\"\n")
        fprintf( FORMFINDHELPFILE "TLOC 10 2\n")
        fprintf( FORMFINDHELPFILE "ENDTEXT\n")
        fprintf( FORMFINDHELPFILE "TEXT \"\270\337\301\301\316\336Fanout\265\304SMD\"\n")
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
        findhelpform = (axlFormCreate (gensym) lgsfindcompshelpform '("E" "OUTER") '_lgs29_find_help_Callback t)
        axlFormDisplay( findhelpform)
);(defun _lgs_hilight_smd_help_Form ()

;************************************************************************************************************
;        _lgs29_find_help_Callback (findhelpform)  — 加模块前缀避免与31号冲突
;************************************************************************************************************
(defun _lgs29_find_help_Callback (findhelpform)
    axlFormClose( findhelpform)
    deleteFile( lgsfindcompshelpform)
);end defun lgs_tech_help_Callback (helpform) 

;***************************************************************************************************************************
;        _lgs_hilight_no_fanoutsmd_top()
;***************************************************************************************************************************
(defun _lgs_hilight_no_fanoutsmd_top ()
let( ( lgs_smd_bBox lgs_all_pins_list lgs_time lgs_step lgs_i lgs_item_bBox_mi visSave lgs_hilight_pins lgs_pins_data lgs_pin_data lgs_pin_xy lgs_pin_cx lgs_pin_cy lgs_item_pin )

visSave = axlVisibleGet()
_lgs_creat_hilight_smd_form()
axlUIWPrint( lgs_hilight_smd_form "正在获取Pin信息,请稍候...")
axlFormSetField( lgs_hilight_smd_form "lgs_progress" 1)                                                      
lgs_smd_bBox = nil

axlShell("setwindow pcb")
axlVisibleDesign( nil)
axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_TOP" t)
axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
axlVisibleLayer("ETCH/TOP" t)
axlVisibleLayer("VIA CLASS/TOP" t)
axlVisibleLayer("PIN/TOP" t)
axlFlushDisplay()
axlShell("redraw")
axlFormSetField( lgs_hilight_smd_form "lgs_progress" 2)
axlSetFindFilter(?enabled '(noall pins) ?onButtons '(noall pins))
axlAddSelectAll()
lgs_all_pins_list = axlGetSelSet()
;--- 17.4 S039 修复：dbid 不跨轮——循环内每轮 axlSingleSelectBox 会使之前全部 dbid 失效为 dbid:removed ---
;--- 趁 dbid 新鲜，先把候选 SMD pin 的判定与坐标全部读成纯数据记录 (无fanoutflag 中心x 中心y) ---
lgs_pins_data = nil
foreach(lgs_item_pin lgs_all_pins_list
    if((lgs_item_pin->isThrough==nil) && (lgs_item_pin->startEnd=='("ETCH/TOP" "ETCH/TOP"))
    then
        ; 无net的SMD pin（未连接）天然无fanout，一并计入；同时避免nil~>bBox崩溃
        lgs_pins_data = cons( list( (lgs_item_pin->net == nil || lgs_item_pin~>net~>bBox != lgs_item_pin~>bBox)
            (caar(lgs_item_pin->bBox)+caadr(lgs_item_pin->bBox))/2
            (cadar(lgs_item_pin->bBox)+cadadr(lgs_item_pin->bBox))/2 ) lgs_pins_data)
    );end if
);end foreach
lgs_pins_data = reverse( lgs_pins_data)
axlFormSetField( lgs_hilight_smd_form "lgs_progress" 10)
axlUIWPrint( lgs_hilight_smd_form "正在查找无Fanout的SMD Pin,请稍候...")
axlClearSelSet()
axlSetFindFilter(?enabled '(noall VIAS CLINESEGS SHAPES) ?onButtons '(noall VIAS CLINESEGS SHAPES))

;---------------get smd pin bBox--------------------------------------------------------------------------------------------
lgs_hilight_bBox = nil
lgs_hilight_pins = nil
lgs_time = 11
lgs_step = max(1 length( lgs_pins_data)/45)
lgs_i = 0
foreach(lgs_pin_data lgs_pins_data
    lgs_i++
    lgs_pin_cx = cadr( lgs_pin_data)
    lgs_pin_cy = caddr( lgs_pin_data)
    lgs_item_bBox_mi = list(list( lgs_pin_cx-1 lgs_pin_cy-1) list( lgs_pin_cx+1 lgs_pin_cy+1))
    ;-------------------check fanout---------------------------------------------------
    if(axlSingleSelectBox( lgs_item_bBox_mi) == nil
    then
        ;-----------check one point net---------------------------------------------
        if(car( lgs_pin_data)
        then
            lgs_hilight_bBox = append( lgs_hilight_bBox list(lgs_item_bBox_mi))
            lgs_hilight_pins = cons( list(lgs_pin_cx lgs_pin_cy) lgs_hilight_pins)
        );end if
    );end ifaxlSingle
    
    if(lgs_i > lgs_step
    then
        lgs_i = 0
        lgs_time++
        axlFormSetField( lgs_hilight_smd_form "lgs_progress" lgs_time)
    
    );end if(lgs_i > lgs_step

);end foreach(lgs_pin_data lgs_pins_data
;---------------high no fanout top smd pin----------------------------------------------------------------------------------
;---------------AXL直接高亮（替代逐pin axlShell pick，大设计提速）------------------
lgs_time = 55
axlFormSetField( lgs_hilight_smd_form "lgs_progress" lgs_time)
;--- 17.4 S039：lgs_hilight_pins 改存 pin 中心xy 纯数据；逐点现场重解析新鲜 dbid，当次立即高亮（即用即弃）---
axlSetFindFilter(?enabled '(noall pins) ?onButtons '(noall pins))
foreach(lgs_pin_xy lgs_hilight_pins
    axlClearSelSet()
    lgs_item_pin = car(axlSingleSelectPoint( lgs_pin_xy))
    if(lgs_item_pin then axlHighlightObject( lgs_item_pin))
);end foreach
axlClearSelSet()
axlFormClose( lgs_hilight_smd_form)
axlVisibleSet( visSave)

;------------printf information;---------------------------------
printf( "Hilight SMD Pin without fanout V1.0-----Write by HUAWEI: LiGuangsheng/24445\n")
printf( "Hilight SMD Pin without fanout Successful\n")
printf( " %d SMD Pin on ETCH/TOP without fanout, Already Hilight!\n" length( lgs_hilight_bBox))


;------------end defun _lgs_hilight_no_fanoutsmd_top;------------
);end let
);end (defun _lgs_hilight_no_fanoutsmd_top ()

;***************************************************************************************************************************
;        END _lgs_hilight_no_fanoutsmd_top()
;***************************************************************************************************************************






;***************************************************************************************************************************
;        _lgs_hilight_no_fanoutsmd_botm()
;***************************************************************************************************************************
(defun _lgs_hilight_no_fanoutsmd_botm ()
let( ( lgs_smd_bBox lgs_all_pins_list lgs_time lgs_step lgs_i lgs_item_bBox_mi visSave lgs_hilight_pins lgs_pins_data lgs_pin_data lgs_pin_xy lgs_pin_cx lgs_pin_cy lgs_item_pin )

visSave = axlVisibleGet()
_lgs_creat_hilight_smd_form()
axlUIWPrint( lgs_hilight_smd_form "正在获取Pin信息,请稍候...")
axlFormSetField( lgs_hilight_smd_form "lgs_progress" 1)                                                      
lgs_smd_bBox = nil

axlShell("setwindow pcb")
axlVisibleDesign( nil)
axlVisibleLayer("BOARD GEOMETRY/OUTLINE" t)
axlVisibleLayer("BOARD GEOMETRY/SILKSCREEN_BOTTOM" t)
axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_BOTTOM" t)
axlVisibleLayer("ETCH/BOTTOM" t)
axlVisibleLayer("VIA CLASS/BOTTOM" t)
axlVisibleLayer("PIN/BOTTOM" t)
axlFlushDisplay()
axlShell("redraw")
axlFormSetField( lgs_hilight_smd_form "lgs_progress" 2)
axlSetFindFilter(?enabled '(noall pins) ?onButtons '(noall pins))
axlAddSelectAll()
lgs_all_pins_list = axlGetSelSet()
;--- 17.4 S039 修复：dbid 不跨轮——循环内每轮 axlSingleSelectBox 会使之前全部 dbid 失效为 dbid:removed ---
;--- 趁 dbid 新鲜，先把候选 SMD pin 的判定与坐标全部读成纯数据记录 (无fanoutflag 中心x 中心y) ---
lgs_pins_data = nil
foreach(lgs_item_pin lgs_all_pins_list
    if((lgs_item_pin->isThrough==nil) && (lgs_item_pin->startEnd=='("ETCH/BOTTOM" "ETCH/BOTTOM"))
    then
        ; 无net的SMD pin（未连接）天然无fanout，一并计入；同时避免nil~>bBox崩溃
        lgs_pins_data = cons( list( (lgs_item_pin->net == nil || lgs_item_pin~>net~>bBox != lgs_item_pin~>bBox)
            (caar(lgs_item_pin->bBox)+caadr(lgs_item_pin->bBox))/2
            (cadar(lgs_item_pin->bBox)+cadadr(lgs_item_pin->bBox))/2 ) lgs_pins_data)
    );end if
);end foreach
lgs_pins_data = reverse( lgs_pins_data)
axlFormSetField( lgs_hilight_smd_form "lgs_progress" 10)
axlUIWPrint( lgs_hilight_smd_form "正在查找无Fanout的SMD Pin,请稍候...")
axlClearSelSet()
axlSetFindFilter(?enabled '(noall VIAS CLINESEGS SHAPES) ?onButtons '(noall VIAS CLINESEGS SHAPES))

;---------------get smd pin bBox--------------------------------------------------------------------------------------------
lgs_hilight_bBox = nil
lgs_hilight_pins = nil
lgs_time = 11
lgs_step = max(1 length( lgs_pins_data)/45)
lgs_i = 0

foreach(lgs_pin_data lgs_pins_data
    lgs_i++
    lgs_pin_cx = cadr( lgs_pin_data)
    lgs_pin_cy = caddr( lgs_pin_data)
    lgs_item_bBox_mi = list(list( lgs_pin_cx-1 lgs_pin_cy-1) list( lgs_pin_cx+1 lgs_pin_cy+1))
    ;-------------------check fanout---------------------------------------------------
    if(axlSingleSelectBox( lgs_item_bBox_mi) == nil
    then
        ;-----------check one point net---------------------------------------------
        if(car( lgs_pin_data)
        then
            lgs_hilight_bBox = append( lgs_hilight_bBox list(lgs_item_bBox_mi))
            lgs_hilight_pins = cons( list(lgs_pin_cx lgs_pin_cy) lgs_hilight_pins)
        );end if
    );end ifaxlSingle
    
    if(lgs_i > lgs_step
    then
        lgs_i = 0
        lgs_time++
        axlFormSetField( lgs_hilight_smd_form "lgs_progress" lgs_time)
    
    );end if(lgs_i > lgs_step

);end foreach(lgs_pin_data lgs_pins_data
;---------------high no fanout bottom smd pin-------------------------------------------------------------------------------
;---------------AXL直接高亮（替代逐pin axlShell pick，大设计提速）------------------
lgs_time = 55
axlFormSetField( lgs_hilight_smd_form "lgs_progress" lgs_time)
;--- 17.4 S039：lgs_hilight_pins 改存 pin 中心xy 纯数据；逐点现场重解析新鲜 dbid，当次立即高亮（即用即弃）---
axlSetFindFilter(?enabled '(noall pins) ?onButtons '(noall pins))
foreach(lgs_pin_xy lgs_hilight_pins
    axlClearSelSet()
    lgs_item_pin = car(axlSingleSelectPoint( lgs_pin_xy))
    if(lgs_item_pin then axlHighlightObject( lgs_item_pin))
);end foreach
axlClearSelSet()
axlFormClose( lgs_hilight_smd_form)
axlVisibleSet( visSave)

;------------printf information------------------------------------
printf( "Hilight SMD Pin without fanout V1.0-----Write by HUAWEI: LiGuangsheng/24445\n")
printf( "Hilight SMD Pin without fanout Successful\n")
printf( " %d SMD Pin on ETCH/BOTTOM without fanout, Already Hilight!\n" length( lgs_hilight_bBox))

;------------end defun _lgs_hilight_no_fanoutsmd_botm------------------------------------

);end let
);end (defun _lgs_hilight_no_fanoutsmd_botm ()

;***************************************************************************************************************************
;        END _lgs_hilight_no_fanoutsmd_botm()
;***************************************************************************************************************************



;***************************************************************************************************************************
;        _lgs_creat_hilight_smd_form()
;***************************************************************************************************************************
(defun _lgs_creat_hilight_smd_form ()
;let( (hilightsmd_Form)
lgs29_progress_form_path = strcat(axlTempFile() ".form")
hilightsmd_Form=outfile(lgs29_progress_form_path "w")
fprintf(hilightsmd_Form "#Write by lgs \n")
fprintf(hilightsmd_Form "FILE_TYPE=FORM_DEFN VERSION=2\n")
fprintf(hilightsmd_Form "FORM\n")     
fprintf(hilightsmd_Form "FIXED\n")               
fprintf(hilightsmd_Form "PORT 45 14\n")          
fprintf(hilightsmd_Form "HEADER \"\270\337\301\301\316\336Fanout\265\304SMD Pin V1.0\"\n")
fprintf(hilightsmd_Form "TILE\n")                
fprintf(hilightsmd_Form "FIELD lgs_progress\n")      
fprintf(hilightsmd_Form "FLOC 3 1\n")            
fprintf(hilightsmd_Form "PROGRESS 40 3\n")       
fprintf(hilightsmd_Form "ENDFIELD\n")            
fprintf(hilightsmd_Form "ENDTILE\n")             
fprintf(hilightsmd_Form "ENDFORM  \n")           
close(hilightsmd_Form)
lgs_hilight_smd_form = axlFormCreate( (gensym) lgs29_progress_form_path '(e outer) '_lgs29_nil t)
deleteFile( lgs29_progress_form_path)
axlFormDisplay( lgs_hilight_smd_form)
;);end let
);end (defun _lgs_creat_hilight_smd_form ()

;------------------------------------------------------------------------
; 空回调：进度条表单专用（模块私有前缀，避免与check_90degline/31同名冲突）
;------------------------------------------------------------------------
(defun _lgs29_nil (form)
1==1
)


;***************************************************************************************************************************
;***************************************************************************************************************************
;    END _lgs_hilight_no_fanoutsmd_top()
;***************************************************************************************************************************
;***************************************************************************************************************************


;--------main-----------------------
lgs_view_number = 0
_lgs_creat_hilight_smd_main_form()

);end let
);end (defun _lgs_hilight_smd_main ()
;***************************************************************************************************************************
;***************************************************************************************************************************
