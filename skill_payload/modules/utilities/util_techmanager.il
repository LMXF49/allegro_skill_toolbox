;========================================================================
; 文件名    : util_techmanager.il
; 作者      : LiGuangsheng（原始作者，2002 年华为内部工具）
; 创建日期  : 2002-06-08
; 版本      : 1.1 [DEPRECATED - 已弃用]
; 功能描述  : 工艺规则管理器，加载和设置PCB工艺技术文件参数
; 依赖模块  : 无
; 弃用说明  : 本模块为 2002 年 Unix 环境专用工具，在当前
;             Windows + Allegro 16.6/17.4/24.1 目标环境下不可用：
;             1) 硬编码 Unix 路径 /home/regul（lgstechfiledir），Windows
;                上 isDir 必为 nil，后续对 nil 端口读写会直接崩溃；
;             2) shell("textedit ...&") 为 Unix 专用命令；
;             3) 约束加载依赖回放 14.1 时代 CNS 表单脚本
;                lgsloadtechfile.lgc，16.6+ 约束管理器界面与字段名
;                已完全不同，回放必然失败。
;             因无修复价值，本模块已于 2026-07-17 从 ASTB 菜单摘除，
;             文件保留仅供历史参考。如需同类功能，请基于 axlCns* API
;             重写。命令 "lgs_tech_in" 仍注册但不建议使用。
; 修改记录  :
;   2026-07-18 v1.1 ASTB 修复组 表单界面汉化：标题/分组/按钮/复选框/信息分隔
;             及 axlMsgPut 提示改中文（模块仍为 DEPRECATED 仅供历史参考）
;   2002-06-08 v1.0 LiGuangsheng 初始创建
;   2026-07-17 v1.0 ASTB 修复组 标注 DEPRECATED，从 ASTB 菜单摘除
;========================================================================
axlCmdRegister( "lgs_tech_in" `lgstech)
;=========================================================================
;=========================================================================
(defun lgstech ()
setq( lgstechnicsmanagerform "./lgstechmanager.form")
setq( lgstechfiledir "/home/regul")     ;!!!

techfile = nil            ;var:  select techfile ;number of flowlist/2 -1 (0 1 2...)
techflow = nil            ;var:  selsct flow. number of flowlist
lgstechfiledata =nil        ;list: all of the tech file data
flowlist = nil            ;list: all of flow in select tech file (name linenumber name linenumber...)
informationlist = nil        ;list: will be setup to the information window
arealist = nil            ;list: all of area file data (name linenumber name linenumber...)
unselectarealist = nil        ;list: all of unselect area file data (name linenumber name linenumber...)
selectarealist = nil        ;list: all of select area file data (name linenumber name linenumber...)
un_selectarea = nil        ;var:  select area. every time if selectarea != nil then un_selectarea must = nil
selectarea =nil            ;var:  select area. every time if un_selectarea != nil then selectarea must = nil
lgs_select_type = nil        ;var:  select type. must is one of: nil "file" "flow" "area"
lgs_select_line_number = nil
lgs_board_thick = "VIA-TYPE2-"    ;var:  board thick. must is one of:  "VIA-TYPE1.6-" "VIA-TYPE2-" "VIA-TYPE2.5-" "VIA-TYPE3-"
lgs_type_or_min = 0        ;var:  tech rule type or min. 0:type  1:min


if(isDir(lgstechfiledir)==t
  then    techfileList = setof(x getDirFiles(  lgstechfiledir) rexMatchp( "[a-z]*.lte" x))
  else  techfileList = nil
  );end if

if( techfileList != nil
    then
        techfile = car( techfileList)
        lgs_select_type = "file"
    else
        techfile = nil
  );end if 


lgs_techrepfileCallback()

_lgs_Build_Technics_Manager_Form()
axlFormSetField( form "check_technics" techfile)
axlFormSetField( form "selectthick" "VIA-TYPE2-")
axlFormSetField( form "lgstype" 1)
_lgs_setup_flow()
_lgs_setup_information()

);end (defun lgs ()




;=========================================================================

;=========================================================================
;=========================================================================
(defun lgs_techrepfileCallback ()

;axlMsgPut("ok")

techfileport = infile( strcat(lgstechfiledir "/" techfile))        ;dir+file name
flowlist = nil
informationlist = nil
lgstechfiledata =nil
;-------------read tech file to lgstechfiledata---------------------------
lgstemp = t
while(lgstemp
    lgstemp1 = gets(line techfileport)
    if(lgstemp1 != nil
      then
          lgstechfiledata = nconc(lgstechfiledata list(car(parseString(lgstemp1 "\n"))))
      else
          lgstemp = nil
      );end if
      );end while
;------------get flow and tech information------------------------------
i = 0
foreach(lgstemp  lgstechfiledata
    i++
    lgstemp1 = parseString(lgstemp " ")
    if(length(lgstemp1)>1
    then
    case(car(lgstemp1)                ;load keyword
        
        ("TECHNICS"
            
            lgstemp2 = ">"
            ;axlMsgPut("here12")
            for(j 2 length(lgstemp1)
                lgstemp2=strcat( lgstemp2 nthelem(j lgstemp1))
                );end for
            lgstemp2 = substring(lgstemp2 2 strlen( lgstemp2)-1)    
            ;axlMsgPut("here")
            flowlist = nconc(flowlist list(lgstemp2) list(i))    ;add the flow and begin line number to flowlist
        
        t)
          
        ("FILE-INFO"
            lgstemp2 = ">"
            for(j 2 length(lgstemp1)
                lgstemp2=strcat( lgstemp2 " " nthelem(j lgstemp1))
                );end for
            lgstemp2 = substring(lgstemp2 2 strlen( lgstemp2)-1)
            informationlist = nconc(informationlist list(lgstemp2))    ;add to informationlist
        
        t)
          
         );end case
       );end if    
    );end foreach          
;--------------------------------------------------          

);end defun lgs_techrepfileCallback ()
;=========================================================================
(defun lgs_techrepflowCallback ()
informationlist = nil
arealist = nil
lgstemp = t
i = nthelem( techflow*2+2 flowlist)+1    ;get flow begin line number
lgs_select_line_number = i-1
while(lgstemp
    lgstemp1 = nthelem(i++ lgstechfiledata)
    if(lgstemp1 != nil
      then
        lgstemp1 = parseString( lgstemp1 " ")
        if(length(lgstemp1)>1
        then
        case(car(lgstemp1)                ;load keyword
            
            ("AREA"
                
                lgstemp2 = ">"
                ;axlMsgPut("here12")
                for(j 2 length(lgstemp1)    
                    lgstemp2=strcat( lgstemp2 nthelem(j lgstemp1))
                    );end for
                ;axlMsgPut(i)
                lgstemp2 = substring(lgstemp2 2 strlen( lgstemp2)-1)
                arealist = nconc(arealist list(lgstemp2) list(i-1))    ;add the flow and begin line number to flowlist
        
            t)
          
            ("TECHNICS-INFO"
                lgstemp2 = ">"
                for(j 2 length(lgstemp1)
                    lgstemp2=strcat( lgstemp2 " " nthelem(j lgstemp1))
                    );end for
                lgstemp2 = substring(lgstemp2 2 strlen( lgstemp2)-1)
                informationlist = nconc(informationlist list(lgstemp2))    ;add to informationlist
            
            t)
            
            ("TECHNICS"
                lgstemp = nil        ;all data in this TECHNICS FLOW be read,then end while
            
            t)
          
             );end case
           );end if(length(lgstemp1)>1    
       else
           lgstemp = nil    ;all data in the lgstechfiledata be read,then end while
      );end if(lgstemp1 != nil






      );end while    



);end defun lgs_techrepflowCallback ()
;=========================================================================
;=========================================================================
(defun _lgs_moreinfo_callback ()
prog(()
lgs_temp = nil
lgs_info_file = outfile( "./LGS_TECH_INFORMATION.TXT")
case(lgs_select_type
    ;----------------------------------------------
    (nil
        return(t)
    t)
    ;----------------------------------------------
    ("file"
        foreach(lgs_temp lgstechfiledata 
            fprintf(lgs_info_file "%s\n" lgs_temp)
            );end foreach
    t)
    ;----------------------------------------------
    ("flow"
        i = lgs_select_line_number
        fprintf(lgs_info_file "%s\n" nthelem(i lgstechfiledata))
        lgstemp = t
        while(lgstemp    
            lgs_temp = nthelem(++i lgstechfiledata)
            if(lgs_temp != nil
              then
                lgstemp2 = parseString( lgs_temp " ")
                case(car(lgstemp2)                ;load keyword
            
                    ("TECHNICS"
                        lgstemp = nil        ;all data in this TECHNICS be read,then end while
                    t)
                    
                     );end case

              else 
                  lgstemp = nil                ;last data in lgstechfiledata have be read
              );end if(lgstemp1 != nil
        
            ;------------------------
            if(lgstemp != nil
                then    fprintf(lgs_info_file "%s\n" lgs_temp)            
              );end if
            ;------------------------
              
              );end while            


    t);end case-("flow"
    ;----------------------------------------------
    ("area"
        i = lgs_select_line_number
        fprintf(lgs_info_file "%s\n" nthelem(i lgstechfiledata))
        lgstemp = t
        while(lgstemp    
            lgs_temp = nthelem(++i lgstechfiledata)
            if(lgs_temp != nil
              then
                lgstemp2 = parseString( lgs_temp " ")
                case(car(lgstemp2)                ;load keyword
            
                    ("TECHNICS"
                        lgstemp = nil        ;all data in this TECHNICS be read,then end while
                    t)
                    
                    ("AREA"
                        lgstemp = nil        ;all data in this AREA be read,then end while
                    t)

                    
                     );end case

              else 
                  lgstemp = nil                ;last data in lgstechfiledata have be read
              );end if(lgstemp1 != nil
        
            ;------------------------
            if(lgstemp != nil
                then    fprintf(lgs_info_file "%s\n" lgs_temp)            
              );end if
            ;------------------------
              
              );end while            


    t);end case-("flow"
    ;----------------------------------------------

     );end case
close( lgs_info_file)
shell("textedit LGS_TECH_INFORMATION.TXT&")

));end defun _lgs_moreinfo_callback ()
;=========================================================================


;=========================================================================
(defun lgs_call_techfile ()

i=nil


);end defun lgs_call_techfile ()

;=========================================================================
(defun _lgs_setup_flow ()
axlFormListDeleteAll(form "lgsflow")
if(flowlist != nil
  then
      for(i 1 length(flowlist)/2
          axlFormSetField( form "lgsflow" nthelem(2*i-1 flowlist))
          );end foreach
          
      axlFormSetField( form "lgsflow" nil)
   );end if

);end dufun _lgs_setup_flow ()

;=========================================================================
(defun _lgs_setup_area_information ()
informationlist = nil
i = nil
if(selectarea != nil
    then    i = nthelem( selectarea*2+2  selectarealist)
        lgs_select_line_number = i
  );end if

if(un_selectarea != nil
    then    i = nthelem( un_selectarea*2+2  unselectarealist)
        lgs_select_line_number = i
  );end if
if(i != nil
    then

lgstemp = t

while(lgstemp
    lgstemp1 = nthelem(++i lgstechfiledata)
    if(lgstemp1 != nil
      then
        lgstemp1 = parseString( lgstemp1 " ")
        if(length(lgstemp1)>1
        then
        case(car(lgstemp1)                ;load keyword
            
            ("AREA"
                lgstemp = nil        ;all data in this AREA be read,then end while
            t)
          
            ("AREA-INFO"
                lgstemp2 = ">"
                for(j 2 length(lgstemp1)
                    lgstemp2=strcat( lgstemp2 " " nthelem(j lgstemp1))
                    );end for
                lgstemp2 = substring(lgstemp2 2 strlen( lgstemp2)-1)
                informationlist = nconc(informationlist list(lgstemp2))    ;add to informationlist
            
            t)
            
            ("TECHNICS"
                lgstemp = nil        ;all data in this AREA be read,then end while
            
            t)
          
             );end case
           );end if(length(lgstemp1)>1    
       else
           lgstemp = nil    ;all data in the lgstechfiledata be read,then end while
      );end if(lgstemp1 != nil

      );end while        

  );end if
_lgs_setup_information()  
);end defun _lgs_get_areainformation ()
;=========================================================================
;=========================================================================
(defun _lgs_setup_information ()
axlFormListDeleteAll(form "lgsinformation")
if(lgs_select_type == "file"
    axlFormSetField( form "lgsinformation" "========\316\304\274\376=====\320\305\317\242================")
  );end if
if(lgs_select_type == "flow"
    axlFormSetField( form "lgsinformation" "========\301\367\263\314=====\320\305\317\242================")
  );end if
if(lgs_select_type == "area"
    axlFormSetField( form "lgsinformation" "========\307\370\323\362=====\320\305\317\242================")
  );end if

if(informationlist != nil
  then
      foreach(lgstemp informationlist
          axlFormSetField( form "lgsinformation" lgstemp)
          );end foreach
      axlFormSetField( form "lgsinformation" nil)
   );end if
);end defun _lgs_setup_information ()


;=========================================================================
(defun _lgs_setup_area ()
_lgs_setup_area_unsel()
_lgs_setup_area_sel()
);end defun _lgs_setup_area ()
;--------------------------------------------------------------------------
(defun _lgs_setup_area_unsel ()
un_selectarea = nil
axlFormListDeleteAll(form "lgsbeselectarea")
if(unselectarealist != nil
  then
      for(i 1 length(unselectarealist)/2
          axlFormSetField( form "lgsbeselectarea" nthelem(2*i-1 unselectarealist))
          );end foreach
          
      axlFormSetField( form "lgsbeselectarea" nil)
   );end if
);end (defun _lgs_setup_area_unsel ()

;--------------------------------------------------------------------------
(defun _lgs_setup_area_sel ()
selectarea = nil
axlFormListDeleteAll(form "lgsselectarea")
if(selectarealist != nil
  then
      for(i 1 length(selectarealist)/2
          axlFormSetField( form "lgsselectarea" nthelem(2*i-1 selectarealist))
          );end foreach
          
      axlFormSetField( form "lgsselectarea" nil)
  );end if
);end (defun _lgs_setup_area_sel ()

;=========================================================================

;=========================================================================
;=========================================================================
(defun lgs_techrepCallback (form)
;axlMsgPut("ok")
case(form->curField

    ("check_technics"
        lgs_select_type = "file"
        techfile = form->curValue
        lgs_techrepfileCallback()
        axlFormSetField( form "check_technics" techfile)
        arealist = nil
        unselectarealist = nil
        selectarealist = nil
        techflow = nil
        _lgs_setup_area()
        _lgs_setup_flow()
        _lgs_setup_information()

    t)
    
    ("lgsflow"
        lgs_select_type = "flow"
        techflow = form->curValueInt    ;number of flowlist/2 -1 (0 1 2...)
        lgs_techrepflowCallback()
        unselectarealist = arealist
        selectarealist = nil
        _lgs_setup_area()
        _lgs_setup_information()    
    
    
    t)

    ("lgsbeselectarea"
        lgs_select_type = "area"
        un_selectarea = form->curValueInt
        selectarea =nil
        _lgs_setup_area_sel()
        _lgs_setup_area_information()
        ;this area add get area information
    t)

    ("lgsselectarea"
        lgs_select_type = "area"
        selectarea = form->curValueInt
        un_selectarea =nil
        _lgs_setup_area_unsel()
        _lgs_setup_area_information()
        ;this area add get area information
    t)

    ("lgsunse_se"
        if((selectarea == nil) && (un_selectarea != nil)
        then
        selectarealist = nconc(selectarealist list(nthelem(un_selectarea*2+1 unselectarealist) nthelem(un_selectarea*2+2 unselectarealist) ))
        unselectarealist = _lgs_del_mum_list(unselectarealist un_selectarea*2+1 2)
        _lgs_setup_area()
          );end if
    t)

    ("lgsse_unse"
        if((selectarea != nil) && (un_selectarea == nil)
        then
        unselectarealist = nconc(unselectarealist list(nthelem(selectarea*2+1 selectarealist) nthelem(selectarea*2+2 selectarealist) ))
        selectarealist = _lgs_del_mum_list(selectarealist selectarea*2+1 2)
        _lgs_setup_area()
          );end if
    t)

    ("lgsunse_seall"
        unselectarealist = nil
        selectarealist = arealist
               _lgs_setup_area()
    t)

    ("lgsse_unseall"
        unselectarealist = arealist
        selectarealist = nil
               _lgs_setup_area()
    t)

    
    ("lgstype"
               if(form->curValue
                  then    lgs_type_or_min = 0
           
              );end if
    t)
    ("lgsmin"
               if(form->curValue
                  then    lgs_type_or_min = 1
          
              );end if
    t)
        
    ("selectthick"
        lgs_board_thick = form->curValue
    t)            

        ("lgscancel"
              axlFormClose( form)
                deleteFile( lgstechnicsmanagerform)
         nil)
            
        ("lgsmoreinformation"
        _lgs_moreinfo_callback()
         nil)

        ("lgsload"
              _lgs_load_callback()
              ;shell("rm lgsloadtechfile.lgc&")
              axlFormClose( form)
                deleteFile( lgstechnicsmanagerform)
         nil)



     );end case
);end defun lgs_techrepCallback ()

;=========================================================================
(defun _lgs_del_mum_list (lgslist i j)
prog(()
k = 1
lgs_templist = nil
foreach(lgs_temp lgslist 
    if((k<i)||(k>=(i+j))
      then
        lgs_templist = nconc(lgs_templist list(lgs_temp))
      );end if
    k++
    );end for each
return(lgs_templist)    
));end defun


;=========================================================================
;=========================================================================
(defun _lgs_load_callback ()
prog(()
lgs_load_scrfile = outfile( "./lgsloadtechfile.lgc")
if(lgs_load_scrfile == nil                ;out file error
then
    axlMsgPut("\320\264\316\304\274\376\312\247\260\334")
    axlMsgPut("\274\323\324\330\271\244\322\325\322\321\310\241\317\373")
    return( nil)
);end if(lgs_load_scrfile == nil
;---
_lgs_default_area_drcmode_set()                ;write default area drc mode to the scr file
                            ;open cns,but not close

;---
if(techflow == nil                    ;no flow select
then
    axlMsgPut("\276\257\270\346\243\272\316\264\321\241\324\361\301\367\263\314")
else
;-----------------------------------------------
_lgs_write_flow_drc_scr(nthelem(techflow*2+2 flowlist))    ;setup sold to sold
if(length( selectarealist)>1
then
    axlMsgPut("\325\375\324\332\311\350\326\303\307\370\323\362\271\244\322\325\271\346\324\362\243\254\307\353\311\324\272\362\241\243")
    for(i 1 length( selectarealist)/2
        _lgs_write_area_drc_scr( nthelem(2*i selectarealist)  nthelem(2*i-1 selectarealist))
        );end for
else
    axlMsgPut("\276\257\270\346\243\272\316\264\321\241\324\361\307\370\323\362")
);end if(length( selectarealist)>1
;-----------------------------------------------
);end if(techflow == nil
        fprintf( lgs_load_scrfile "setwindow form.cns \n")
        fprintf( lgs_load_scrfile "FORM cns drc_on YES \n")
        fprintf( lgs_load_scrfile "FORM cns done  \n")
        close( lgs_load_scrfile)
        axlShell("replay lgsloadtechfile.lgc")
        axlMsgPut("\271\244\322\325\271\346\324\362\274\323\324\330\263\311\271\246")
));end defun _lgs_load_callback ()
;=========================================================================
;=========================================================================
(defun _lgs_write_area_drc_scr (i areaname)
if(areaname != "DEFAULT"
then
        fprintf( lgs_load_scrfile "setwindow pcb\n")
        fprintf( lgs_load_scrfile "trapsize 3318\n")
        fprintf( lgs_load_scrfile "cns space values \n")
        fprintf( lgs_load_scrfile "setwindow form.cns_space_values\n")
        fprintf( lgs_load_scrfile "FORM cns_space_values constraint_name %s \n" areaname)
        fprintf( lgs_load_scrfile "FORM cns_space_values add  \n")
        fprintf( lgs_load_scrfile "FORM cns_space_values done  \n")
        fprintf( lgs_load_scrfile "setwindow pcb\n")
        fprintf( lgs_load_scrfile "cns physical values \n")
        fprintf( lgs_load_scrfile "setwindow form.cns_data_values\n")
        fprintf( lgs_load_scrfile "FORM cns_data_values constraint_name %s \n" areaname)
        fprintf( lgs_load_scrfile "FORM cns_data_values add  \n")
        fprintf( lgs_load_scrfile "FORM cns_data_values done  \n")

);end if(areaname != "DEFAULT"
lgstemp = t
while(lgstemp
    i++
    lgstemp = _lgs_line_processor(i areaname)
);end while
fprintf( lgs_load_scrfile "FORM cns_data_values done  \n")
);end defun _lgs_write_area_drc_scr (i)
;------------------------------------------------------------------------
;=========================================================================



(defun _lgs_line_processor (i areaname)
prog(()
lgstemp1 = nthelem(i++ lgstechfiledata)
if(lgstemp1 == nil
   then
    return(nil)
   else     
    lgstemp1 = parseString( lgstemp1 " ")
    if(length(lgstemp1)>1
    then
    case(car(lgstemp1)                ;load keyword
    ;---------------------------------------------------------------------------    
        ("AREA"
            return(nil)        ;all data in this AREA be processor
        t)
        
        ("TECHNICS"
            return(nil)        ;all data in this AREA be processor
        t)
      
        ("RULE-TYPE"
            case(nthelem(2 lgstemp1)
                ("SPACING"
                        fprintf( lgs_load_scrfile "setwindow pcb\n")
                        fprintf( lgs_load_scrfile "cns space values \n")
                        fprintf( lgs_load_scrfile "setwindow form.cns_space_values\n")
                        fprintf( lgs_load_scrfile "FORM cns_space_values constraint_set_name %s \n" areaname)

                t)
                ("PHYSICAL"
                        fprintf( lgs_load_scrfile "setwindow pcb\n")
                        fprintf( lgs_load_scrfile "cns physical values \n")
                        fprintf( lgs_load_scrfile "setwindow form.cns_data_values\n")
                        fprintf( lgs_load_scrfile "FORM cns_data_values constraint_set_name %s \n" areaname)


                t)
                 );end case
        t)
        
        ("PIN-PIN"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_pin %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_pin %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_pin %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("PIN-SMD"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_smd_pin %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_smd_pin %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_smd_pin %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("PIN-TPIN"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_pin %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_pin %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_pin %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("PIN-VIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("PIN-TVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("PIN-BBVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("PIN-BONDPAD"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("PIN-LINE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("PIN-SHAPE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("SMD-SMD"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Smd Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_smd_pin %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_smd_pin %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_smd_pin %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("SMD-TPIN"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Smd Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_pin %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_pin %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_pin %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("SMD-VIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Smd Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("SMD-TVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Smd Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("SMD-BBVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Smd Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("SMD-BONDPAD"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Smd Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("SMD-LINE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Smd Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("SMD-SHAPE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Smd Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TPIN-TPIN"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_pin %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_pin %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_pin %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TPIN-VIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TPIN-TVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TPIN-BBVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TPIN-BONDPAD"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TPIN-LINE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TPIN-SHAPE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Pin \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("VIA-VIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_thru_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("VIA-TVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("VIA-BBVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("VIA-BONDPAD"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("VIA-LINE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("VIA-SHAPE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Thru Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TVIA-TVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_test_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TVIA-BBVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TVIA-BONDPAD"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TVIA-LINE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("TVIA-SHAPE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Test Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("BBVIA-BBVIA"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list B/B Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bb_via %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("BBVIA-BONDPAD"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list B/B Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("BBVIA-LINE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list B/B Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("BBVIA-SHAPE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list B/B Via \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
                
        ("BONDPAD-BONDPAD"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Bondpad \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_bondpad %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("BONDPAD-LINE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Bondpad \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("BONDPAD-SHAPE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Bondpad \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        

        ("LINE-LINE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Line \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_line %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("LINE-SHAPE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Line \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("SHAPE-SHAPE"
                fprintf( lgs_load_scrfile "FORM cns_space_values elements_list Shape \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass ALL ETCH \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass TOP \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_space_values subclass BOTTOM \n")
                fprintf( lgs_load_scrfile "FORM cns_space_values _to_shape %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
        
        ("LINE-WIDTH"
                fprintf( lgs_load_scrfile "FORM cns_data_values subclass ALL ETCH  \n")
                fprintf( lgs_load_scrfile "FORM cns_data_values min_line_width %s \n" nthelem(lgs_type_or_min+6 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_data_values subclass TOP  \n")
                fprintf( lgs_load_scrfile "FORM cns_data_values min_line_width %s \n" nthelem(lgs_type_or_min+2 lgstemp1))
                fprintf( lgs_load_scrfile "FORM cns_data_values subclass BOTTOM  \n")
                fprintf( lgs_load_scrfile "FORM cns_data_values min_line_width %s \n" nthelem(lgs_type_or_min+4 lgstemp1))
        t)
            
        ("VIA-TYPE1.6-TYPE"
            if(lgs_type_or_min == 0
                then
                if(lgs_board_thick == "VIA-TYPE1.6-"
                    then
                        lgstemp1 = cdr( lgstemp1)    ;del hotkey
                        if(lgstemp1 != nil
                            then
                                foreach(lgstemp4 lgstemp1
                                    fprintf( lgs_load_scrfile "FORM cns_data_values subclass ALL ETCH  \n")
                                        fprintf( lgs_load_scrfile "FORM cns_data_values via_name %s  \n" lgstemp4)
                                        fprintf( lgs_load_scrfile "FORM cns_data_values add_via   \n")
                                    );end for each            
                          );end if
                  );end if
            
              );end if(lgs_type_or_min == 0        
        t)
        
        ("VIA-TYPE1.6-MIN"
            if(lgs_type_or_min == 1
                then
                if(lgs_board_thick == "VIA-TYPE1.6-"
                    then
                        lgstemp1 = cdr( lgstemp1)    ;del hotkey
                        if(lgstemp1 != nil
                            then
                                foreach(lgstemp4 lgstemp1
                                    fprintf( lgs_load_scrfile "FORM cns_data_values subclass ALL ETCH  \n")
                                        fprintf( lgs_load_scrfile "FORM cns_data_values via_name %s  \n" lgstemp4)
                                        fprintf( lgs_load_scrfile "FORM cns_data_values add_via   \n")
                                    );end for each            
                          );end if
                  );end if
            
              );end if(lgs_type_or_min == 1        
        
        t)
        
        ("VIA-TYPE2-TYPE"
            if(lgs_type_or_min == 0
                then
                if(lgs_board_thick == "VIA-TYPE2-"
                    then
                        lgstemp1 = cdr( lgstemp1)    ;del hotkey
                        if(lgstemp1 != nil
                            then
                                foreach(lgstemp4 lgstemp1
                                    fprintf( lgs_load_scrfile "FORM cns_data_values subclass ALL ETCH  \n")
                                        fprintf( lgs_load_scrfile "FORM cns_data_values via_name %s  \n" lgstemp4)
                                        fprintf( lgs_load_scrfile "FORM cns_data_values add_via   \n" )
                                    );end for each            
                          );end if
                  );end if
            
              );end if(lgs_type_or_min == 0        
        
        t)
        
        ("VIA-TYPE2-MIN"
            if(lgs_type_or_min == 1
                then
                if(lgs_board_thick == "VIA-TYPE2-"
                    then
                        lgstemp1 = cdr( lgstemp1)    ;del hotkey
                        if(lgstemp1 != nil
                            then
                                foreach(lgstemp4 lgstemp1
                                    fprintf( lgs_load_scrfile "FORM cns_data_values subclass ALL ETCH  \n")
                                        fprintf( lgs_load_scrfile "FORM cns_data_values via_name %s  \n" lgstemp4)
                                        fprintf( lgs_load_scrfile "FORM cns_data_values add_via   \n" )
                                    );end for each            
                          );end if
                  );end if
            
              );end if(lgs_type_or_min == 1    
        
        t)
        
        ("VIA-TYPE2.5-TYPE"
            if(lgs_type_or_min == 0
                then
                if(lgs_board_thick == "VIA-TYPE2.5-"
                    then
                        lgstemp1 = cdr( lgstemp1)    ;del hotkey
                        if(lgstemp1 != nil
                            then
                                foreach(lgstemp4 lgstemp1
                                    fprintf( lgs_load_scrfile "FORM cns_data_values subclass ALL ETCH  \n")
                                        fprintf( lgs_load_scrfile "FORM cns_data_values via_name %s  \n" lgstemp4)
                                        fprintf( lgs_load_scrfile "FORM cns_data_values add_via   \n" )
                                    );end for each            
                          );end if
                  );end if
            
              );end if(lgs_type_or_min == 0        
        
        t)
        
        ("VIA-TYPE2.5-MIN"
            if(lgs_type_or_min == 1
                then
                if(lgs_board_thick == "VIA-TYPE2.5-"
                    then
                        lgstemp1 = cdr( lgstemp1)    ;del hotkey
                        if(lgstemp1 != nil
                            then
                                foreach(lgstemp4 lgstemp1
                                    fprintf( lgs_load_scrfile "FORM cns_data_values subclass ALL ETCH  \n")
                                        fprintf( lgs_load_scrfile "FORM cns_data_values via_name %s  \n" lgstemp4)
                                        fprintf( lgs_load_scrfile "FORM cns_data_values add_via   \n" )
                                    );end for each            
                          );end if
                  );end if
            
              );end if(lgs_type_or_min == 1        
        
        t)
        
        ("VIA-TYPE3-TYPE"
            if(lgs_type_or_min == 0
                then
                if(lgs_board_thick == "VIA-TYPE3-"
                    then
                        lgstemp1 = cdr( lgstemp1)    ;del hotkey
                        if(lgstemp1 != nil
                            then
                                foreach(lgstemp4 lgstemp1
                                    fprintf( lgs_load_scrfile "FORM cns_data_values subclass ALL ETCH  \n")
                                        fprintf( lgs_load_scrfile "FORM cns_data_values via_name %s  \n" lgstemp4)
                                        fprintf( lgs_load_scrfile "FORM cns_data_values add_via   \n" )
                                    );end for each            
                          );end if
                  );end if
            
              );end if(lgs_type_or_min == 0        
        
        t)
        
        ("VIA-TYPE3-MIN"
            if(lgs_type_or_min == 1
                then
                if(lgs_board_thick == "VIA-TYPE3-"
                    then
                        lgstemp1 = cdr( lgstemp1)    ;del hotkey
                        if(lgstemp1 != nil
                            then
                                foreach(lgstemp4 lgstemp1
                                    fprintf( lgs_load_scrfile "FORM cns_data_values subclass ALL ETCH  \n")
                                        fprintf( lgs_load_scrfile "FORM cns_data_values via_name %s  \n" lgstemp4)
                                        fprintf( lgs_load_scrfile "FORM cns_data_values add_via   \n" )
                                    );end for each            
                          );end if
                  );end if
            
              );end if(lgs_type_or_min == 1        
        
        t)
        
        
        
      ;----------------------------------------------------------------------------
         );end case
     );end if(length(lgstemp1)>1
return(t)    
);end if(lgstemp1 == nil     
));end defun _lgs_line_processor (i)
;=========================================================================
(defun _lgs_write_flow_drc_scr (i)
lgstemp = t
while(lgstemp
    lgstemp1 = nthelem(++i lgstechfiledata)
    if(lgstemp1 != nil
      then
        lgstemp1 = parseString( lgstemp1 " ")
        if(length(lgstemp1)>1
        then
        case(car(lgstemp1)                ;load keyword

            ("RULE-TYPE"
                if(nthelem(2 lgstemp1)=="CONSTRAINTS"
                then
                    ;open "Design Constraints" window
                    fprintf( lgs_load_scrfile "cns design \n")
                        fprintf( lgs_load_scrfile "setwindow form.cns_design\n")
                );end if(nthelem(2 lgstemp1)=="CONSTRAINTS"
            t)

            ("PLANE-ISLANDS"
                ;write PLANE-ISLANDS setup information
                fprintf( lgs_load_scrfile "FORM cns_design negative_plane_islands.value %s \n" nthelem(2 lgstemp1))
            t)

            ("SOLDER-ALIGNMENT"
                ;write SOLDER-ALIGNMENT setup information
                fprintf( lgs_load_scrfile "FORM cns_design pad_soldermask_alignment.value %s \n" nthelem(2 lgstemp1))
            t)

            ("SOLDER-SOLDER"
                ;write SOLDER-SOLDER setup information
                fprintf( lgs_load_scrfile "FORM cns_design pad_soldermask_to_pad_soldermask_spacing.value %s \n" nthelem(2 lgstemp1))
            t)

            ("AREA"
                lgstemp = nil        ;all data in this AREA be read,then end while
            t)
            
            ("TECHNICS"
                lgstemp = nil        ;all data in this AREA be read,then end while
            
            t)
          
             );end case
           );end if(length(lgstemp1)>1    
       else
           lgstemp = nil    ;all data in the lgstechfiledata be read,then end while
      );end if(lgstemp1 != nil

      );end while
fprintf( lgs_load_scrfile "setwindow form.cns  \n")
fprintf( lgs_load_scrfile "FORM cns_design done  \n")          
);end (defun _lgs_write_flow_drc_scr (i)
;=========================================================================
(defun _lgs_default_area_drcmode_set ()
        fprintf( lgs_load_scrfile "version 14.1\n")
        fprintf( lgs_load_scrfile "setwindow pcb\n")
        fprintf( lgs_load_scrfile "trapsize 6636\n")
        fprintf( lgs_load_scrfile "cns \n")
        fprintf( lgs_load_scrfile "setwindow form.cns\n")
        fprintf( lgs_load_scrfile "FORM cns drc_off YES \n")
        fprintf( lgs_load_scrfile "setwindow pcb\n")
        fprintf( lgs_load_scrfile "cns simple \n")
        fprintf( lgs_load_scrfile "setwindow form.cns_simple\n")
        fprintf( lgs_load_scrfile "FORM cns_simple same_net_drc On \n")
        fprintf( lgs_load_scrfile "FORM cns_simple done  \n")
        fprintf( lgs_load_scrfile "setwindow pcb\n")
        fprintf( lgs_load_scrfile "cns space values \n")
        fprintf( lgs_load_scrfile "setwindow form.cns_space_values\n")
        fprintf( lgs_load_scrfile "FORM cns_space_values constraint_set_name DEFAULT \n")
        fprintf( lgs_load_scrfile "FORM cns_space_values same_net_drc On \n")
        fprintf( lgs_load_scrfile "FORM cns_space_values done  \n")
        fprintf( lgs_load_scrfile "setwindow pcb\n")
        fprintf( lgs_load_scrfile "cns space modes \n")
        fprintf( lgs_load_scrfile "setwindow form.cns_space_modes\n")
        fprintf( lgs_load_scrfile "FORM cns_space_modes all_spacing_chk Always \n")
        fprintf( lgs_load_scrfile "FORM cns_space_modes length_tolerance Never \n")
        fprintf( lgs_load_scrfile "FORM cns_space_modes secondary_max_len Never \n")
        fprintf( lgs_load_scrfile "FORM cns_space_modes done  \n")
        fprintf( lgs_load_scrfile "setwindow pcb\n")
        fprintf( lgs_load_scrfile "cns physical values \n")
        fprintf( lgs_load_scrfile "setwindow form.cns_data_values\n")
        fprintf( lgs_load_scrfile "FORM cns_data_values constraint_set_name DEFAULT \n")
        fprintf( lgs_load_scrfile "FORM cns_data_values direct_connect Via/Via Allowed \n")
        fprintf( lgs_load_scrfile "FORM cns_data_values direct_connect Not Allowed \n")
        fprintf( lgs_load_scrfile "FORM cns_data_values done  \n")
        fprintf( lgs_load_scrfile "setwindow pcb\n")
        fprintf( lgs_load_scrfile "cns physical modes \n")
        fprintf( lgs_load_scrfile "setwindow form.cns_data_modes\n")
        fprintf( lgs_load_scrfile "FORM cns_data_modes min_line_width Always \n")
        fprintf( lgs_load_scrfile "FORM cns_data_modes direct_connect Always \n")
        fprintf( lgs_load_scrfile "FORM cns_data_modes done  \n")
        fprintf( lgs_load_scrfile "setwindow pcb\n")
        fprintf( lgs_load_scrfile "cns design \n")
        fprintf( lgs_load_scrfile "setwindow form.cns_design\n")
        fprintf( lgs_load_scrfile "FORM cns_design cancel  \n")
);end defun _lgs_default_area_drcmode_set () 
;=========================================================================
(defun _lgs_Build_Technics_Manager_Form ()
        deleteFile( lgstechnicsmanagerform)
        FORMFILE = outfile( lgstechnicsmanagerform)
        fprintf( FORMFILE "#GIRD SYSTEM FROM FILE\n")
        fprintf( FORMFILE "#WRITE BY LIGUANGSHENG HUAWEI 24445\n")
        fprintf( FORMFILE "FILE_TYPE=FORM_DEFN VERSION=2\n")
        fprintf( FORMFILE "FORM\n")
        fprintf( FORMFILE "FIXED\n")
        fprintf( FORMFILE "PORT 45 70\n")
        fprintf( FORMFILE "HEADER \"\271\244\322\325\271\346\324\362\271\334\300\355\306\367 V1.0\"\n")
        fprintf( FORMFILE "TILE\n")
;-----------build tech file name pop-------------------------------------------------------------
        fprintf( FORMFILE "POPUP <file_Names>")
        if(length(techfileList)>1
          then
            for(i 1 length(techfileList)-1
            fprintf( FORMFILE "\"%s\" \"%s\"," nthelem(i techfileList)  nthelem(i techfileList))
                );end for
            fprintf( FORMFILE "\"%s\" \"%s\".\n" nthelem(length(techfileList) techfileList)  nthelem(length(techfileList) techfileList))
          else if(length(techfileList)==1    
                then
                    fprintf( FORMFILE "\"%s\" \"%s\".\n" car(techfileList)  car(techfileList))
                else
                    fprintf( FORMFILE "\"\" \"\".\n")
                );end else if
           );end if      
;--------------------------------------------------------------------------------------------------

;        fprintf( FORMFILE "POPUP <file_Names>\"debug.lte\" \"debug.lte\",\"debugtest2.lte\" \"debugtest2.lte\".\n")
;        fprintf( FORMFILE "POPUP <flow_sel>\">WAVE\" \">WAVE\",\">WAVE\" \">WAVE\".\n")
        fprintf( FORMFILE "POPUP <lgspopthick>\"1.6mm\" \"VIA-TYPE1.6-\",\"2mm\" \"VIA-TYPE2-\",\"2.5mm\" \"VIA-TYPE2.5-\",\"3mm\" \"VIA-TYPE3-\".\n")
        fprintf( FORMFILE "GROUP \"\321\241\324\361\271\244\322\325\316\304\274\376\"\n")
        fprintf( FORMFILE "FLOC 1 0\n")
        fprintf( FORMFILE "FSIZE 27 14\n")
        fprintf( FORMFILE "INFO group\n")
        fprintf( FORMFILE "ENDGROUP\n")
        fprintf( FORMFILE "TEXT \"\316\304\274\376\243\272\"\n")
        fprintf( FORMFILE "TLOC 2 3\n")
        fprintf( FORMFILE "ENDTEXT\n")
        fprintf( FORMFILE "TEXT \"\301\367\263\314\243\272\"\n")
        fprintf( FORMFILE "TLOC 2 7\n")
        fprintf( FORMFILE "ENDTEXT\n")
        fprintf( FORMFILE "FIELD check_technics\n")
        fprintf( FORMFILE "FLOC 7 3\n")
        fprintf( FORMFILE "ENUMSET 17\n")
        fprintf( FORMFILE "POP \"file_Names\"\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgsflow\n")
        fprintf( FORMFILE "FLOC 7 7\n")
        fprintf( FORMFILE "LIST \"\" 19 4\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "GROUP \"\260\345\272\361\"\n")
        fprintf( FORMFILE "FLOC 29 0\n")
        fprintf( FORMFILE "FSIZE 16 6\n")
        fprintf( FORMFILE "INFO group\n")
        fprintf( FORMFILE "ENDGROUP\n")
        fprintf( FORMFILE "TEXT \"\272\361\266\310\243\272\"\n")
        fprintf( FORMFILE "TLOC 30 3\n")
        fprintf( FORMFILE "ENDTEXT\n")
        fprintf( FORMFILE "FIELD selectthick\n")
        fprintf( FORMFILE "FLOC 36 3\n")
        fprintf( FORMFILE "ENUMSET 5\n")
        fprintf( FORMFILE "POP \"lgspopthick\"\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "GROUP \"\300\340\320\315\"\n")
        fprintf( FORMFILE "FLOC 29 6\n")
        fprintf( FORMFILE "FSIZE 16 8\n")
        fprintf( FORMFILE "INFO group\n")
        fprintf( FORMFILE "ENDGROUP\n")
        fprintf( FORMFILE "FIELD lgstype\n")
        fprintf( FORMFILE "FLOC 30 9\n")
        fprintf( FORMFILE "FGROUP \"lgstype\"\n")
        fprintf( FORMFILE "CHECKLIST \"\265\344\320\315\326\265\271\346\324\362\" \"lgstype\"\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgsmin\n")
        fprintf( FORMFILE "FLOC 30 11\n")
        fprintf( FORMFILE "FGROUP \"lgstype\"\n")
        fprintf( FORMFILE "CHECKLIST \"\327\356\320\241\326\265\271\346\324\362\" \"lgstype\"\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "GROUP \"\321\241\324\361\307\370\323\362\271\346\324\362\"\n")
        fprintf( FORMFILE "FLOC 1 14\n")
        fprintf( FORMFILE "FSIZE 44 18\n")
        fprintf( FORMFILE "INFO group\n")
        fprintf( FORMFILE "ENDGROUP\n")
        fprintf( FORMFILE "TEXT \"\316\264\321\241\"\n")
        fprintf( FORMFILE "TLOC 3 16\n")
        fprintf( FORMFILE "ENDTEXT\n")
        fprintf( FORMFILE "TEXT \"\322\321\321\241\"\n")
        fprintf( FORMFILE "TLOC 25 16\n")
        fprintf( FORMFILE "ENDTEXT\n")
        fprintf( FORMFILE "FIELD lgsbeselectarea\n")
        fprintf( FORMFILE "FLOC 2 18\n")
        fprintf( FORMFILE "LIST \"\" 20 6\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgsselectarea\n")
        fprintf( FORMFILE "FLOC 24 18\n")
        fprintf( FORMFILE "LIST \"\" 20 6\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgsunse_seall\n")
        fprintf( FORMFILE "FLOC 3 29\n")
        fprintf( FORMFILE "MENUBUTTON \"\310\253\262\277>>\" 8 3\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgsunse_se\n")
        fprintf( FORMFILE "FLOC 13 29\n")
        fprintf( FORMFILE "MENUBUTTON \">>\" 8 3\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgsse_unse\n")
        fprintf( FORMFILE "FLOC 25 29\n")
        fprintf( FORMFILE "MENUBUTTON \"<<\" 8 3\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgsse_unseall\n")
        fprintf( FORMFILE "FLOC 35 29\n")
        fprintf( FORMFILE "MENUBUTTON \"<<\310\253\262\277\" 8 3\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "GROUP \"\320\305\317\242\"\n")
        fprintf( FORMFILE "FLOC 1 32\n")
        fprintf( FORMFILE "FSIZE 44 20\n")
        fprintf( FORMFILE "INFO group\n")
        fprintf( FORMFILE "ENDGROUP\n")
        fprintf( FORMFILE "FIELD lgsinformation\n")
        fprintf( FORMFILE "FLOC 2 34\n")
        fprintf( FORMFILE "LIST \"\" 42 8\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgsmoreinformation\n")
        fprintf( FORMFILE "FLOC 3 49\n")
        fprintf( FORMFILE "MENUBUTTON \"\270\374\266\340\320\305\317\242\" 40 3\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgsload\n")
        fprintf( FORMFILE "FLOC 5 53\n")
        fprintf( FORMFILE "MENUBUTTON \"\274\323\324\330\" 10 3\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD lgscancel\n")
        fprintf( FORMFILE "FLOC 18 53\n")
        fprintf( FORMFILE "MENUBUTTON \"\310\241\317\373\" 10 3\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "FIELD help\n")
        fprintf( FORMFILE "FLOC 31 53\n")
        fprintf( FORMFILE "MENUBUTTON \"\260\357\326\372\" 10 3\n")
        fprintf( FORMFILE "ENDFIELD\n")
        fprintf( FORMFILE "ENDTILE\n")
        fprintf( FORMFILE "ENDFORM\n")
        close( FORMFILE)
        form = (axlFormCreate (gensym) lgstechnicsmanagerform `("E" "OUTER") `lgs_techrepCallback t)
        axlFormDisplay( form)
);defun _lgs_Build_Technics_Manager_Form ()



