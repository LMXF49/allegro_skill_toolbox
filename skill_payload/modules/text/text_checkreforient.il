;========================================================================
; 文件名    : text_checkreforient.il
; 作者      : JIAKE/15924（原作）；ASTB（工具箱集成整改）
; 创建日期  : 2001-08-04
; 版本      : 1.2
; 功能描述  : 检查元件位号(RefDes)方向是否合规：顶层应为 0/90 度、底层应为 0/270 度，
;             位号镜像属性应与父元件一致；不合规项高亮并写 dir_error.log
;             （FY_CRD 与 FY_CRD1 两命令逻辑已统一）
; 依赖模块  : core（ASTB_RegisterCommand）
; 修改记录  :
;   2001-08-04 v1.0 JIAKE 初始创建（原文件头中文已乱码，按代码语义重写；
;             原文件 jkcheck_refdes_direction.il）
;   2026-07-16 v1.1 ASTB 加规范文件头
;   2026-07-18 v1.2 ASTB 整改：查询类命令去掉 ?undo t；axlDMOpenLog 去掉扩展名
;             并判空；FY_CRD1 底层合法角度 90 改 270；函数变量收进 prog 绑定；
;             可见性改前保存、退出恢复；?cmdType 改字符串；文件转 GBK 编码
;========================================================================

;                  Check Refdes Direction Reference Designators
;              --------------------------------------------

; run load "jkcheck_refdes_direction.il"
;File name: jkcheck_refdes_direction.il
;Revision:1    
;date:08/04/2001 
;Writen by: JIAKE/15924
;tel: 6540492

;
;This routine check the refdes direction . You can only type the command "ch_dir" , 
;and it will hilight the component which refdes is illegal to be placed.

;=====================================================================================


axlCmdRegister( "FY_CRD1" 'jkCheck_Refdes_Direction1)
;axlSetFunckey("sk" "skXXX")

defun( jkCheck_Refdes_Direction1 ()
    prog((logfile allsym dir dircnt text txt x jkSavedVis)
        jkSavedVis = axlVisibleGet()    ;--- 保存用户可见性，退出前恢复 ---
        axlVisibleDesign(nil)
     axlVisibleLayer( "BOARD GEOMETRY/OUTLINE" t )
    axlVisibleLayer( "PIN/TOP" t )
    axlVisibleLayer( "PIN/BOTTOM" t )
    axlVisibleLayer( "REF DES/SILKSCREEN_TOP" t )
    axlVisibleLayer( "REF DES/SILKSCREEN_BOTTOM" t )
    axlVisibleLayer( "PACKAGE GEOMETRY/SILKSCREEN_TOP" t )
    axlVisibleLayer( "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM" t )

    logfile = axlDMOpenLog("dir_error")
    when( logfile == nil
        axlUIConfirm("\316\336\267\250\264\362\277\252\310\325\326\276\316\304\274\376 dir_error.log\243\254\274\354\262\351\326\325\326\271")
        axlVisibleSet(jkSavedVis)
        return(nil)
    )
    fprintf(logfile "#Check the direction errores of refdes . \n\n")
    fprintf(logfile "REF_DES  COORDIRATION\n")
    
    allsym = axlDBGetDesign()->symbols
    axlDehighlightObject(allsym)
    dir = nil    
    dircnt = 0
;    noref = nil
;    norefcnt = 0
    foreach(symbol allsym     ;n=0 ++n symbol=nthelem(n allsym)
        text= axlDBGetAttachedText(symbol)
        txt = nil
        foreach(find text
            if(find->layer == "REF DES/SILKSCREEN_TOP" || 
            find->layer == "REF DES/SILKSCREEN_BOTTOM" then                                     
                txt = find            
            )                                
        )
/*        if(txt == nil && symbol->refdes != nil then 
            axlHighlightObject(symbol)
            noref = cons(symbol->refdes noref)
            ++norefcnt
        )
*/        if(txt != nil && txt->text != nil then
            axlMsgPut("Processing package : %s " txt->text)        
            if(txt->layer == "REF DES/SILKSCREEN_TOP" then
                if(abs(txt->rotation - 0.0) < 5.0 || abs(txt->rotation - 90.0) < 5.0 || 
                abs(txt->rotation - 360.0) < 5.0 then
                x = 0
                else
                    axlHighlightObject(symbol)
                    ;dir = cons(symbol->refdes dir)
                    fprintf(logfile "%-8s %L\n" txt->text symbol->xy)
                    ++dircnt
                )
            else if(txt->layer == "REF DES/SILKSCREEN_BOTTOM" then
                if(abs(txt->rotation - 0.0) < 5.0 || abs(txt->rotation - 270.0) < 5.0 || 
                abs(txt->rotation - 360.0) < 5.0 then
                x = 0
                else
                    axlHighlightObject(symbol)
                    ;dir = cons(symbol->refdes dir)
                    fprintf(logfile "%-8s %L\n" txt->text symbol->xy)
                    ++dircnt
                )
                )            
            )
            if(txt->isMirrored == t then
                if(txt->parent->isMirrored != t then                
                    axlHighlightObject(symbol)
                    ;dir = cons(symbol->refdes dir)
                    fprintf(logfile "%-8s %L\n" txt->text symbol->xy)
                    ++dircnt
                )
            else
                if(txt->parent->isMirrored == t then
                    axlHighlightObject(symbol)
                    ;dir = cons(symbol->refdes dir)
                    fprintf(logfile "%-8s %L\n" txt->text symbol->xy)
                    ++dircnt            
                )                
            )
        );if_end
        
    );foreach-end

    fprintf(logfile "\nTotal direction error of refdes: %d\n" dircnt)
    axlDMClose(logfile)
    
    axlMsgPut("Total direction error of refdes: %d\n" dircnt)       
    axlMsgPut("Refdes direction error , please view logfile.") 
    axlVisibleSet(jkSavedVis)
;    axlMsgPut("Total of components without refdes is : %d %L .\nDone" norefcnt noref)        
;   axlUIViewFileCreate("dir_error.log" "Direction error Log" nil) 
    )
);defun_end


axlCmdRegister( "FY_CRD" 'jkCheck_Refdes_Direction2)
;axlSetFunckey("sk2" "sk2XXX")
defun( jkCheck_Refdes_Direction2 ()
    prog((logfile allsym dir dircnt text txt x jkSavedVis)
        jkSavedVis = axlVisibleGet()    ;--- 保存用户可见性，退出前恢复 ---
        axlVisibleDesign(nil)
     axlVisibleLayer( "BOARD GEOMETRY/OUTLINE" t )
    axlVisibleLayer( "PIN/TOP" t )
    axlVisibleLayer( "PIN/BOTTOM" t )
    axlVisibleLayer( "REF DES/SILKSCREEN_TOP" t )
    axlVisibleLayer( "REF DES/SILKSCREEN_BOTTOM" t )
    axlVisibleLayer( "PACKAGE GEOMETRY/SILKSCREEN_TOP" t )
    axlVisibleLayer( "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM" t )

    logfile = axlDMOpenLog("dir_error")
    when( logfile == nil
        axlUIConfirm("\316\336\267\250\264\362\277\252\310\325\326\276\316\304\274\376 dir_error.log\243\254\274\354\262\351\326\325\326\271")
        axlVisibleSet(jkSavedVis)
        return(nil)
    )
    fprintf(logfile "#Check the direction errores of refdes . \n\n")
    fprintf(logfile "REF_DES  COORDIRATION\n")
    
    allsym = axlDBGetDesign()->symbols
    axlDehighlightObject(allsym)
    dir = nil    
    dircnt = 0
;    noref = nil
;    norefcnt = 0
    foreach(symbol allsym     ;n=0 ++n symbol=nthelem(n allsym)
        text= axlDBGetAttachedText(symbol)
        txt = nil
        foreach(find text
            if(find->layer == "REF DES/SILKSCREEN_TOP" || 
            find->layer == "REF DES/SILKSCREEN_BOTTOM" then                                     
                txt = find            
            )                                
        )
/*        if(txt == nil && symbol->refdes != nil then 
            axlHighlightObject(symbol)
            noref = cons(symbol->refdes noref)
            ++norefcnt
        )
*/        if(txt != nil && txt->text != nil then
            axlMsgPut("Processing package : %s " txt->text)        
            if(txt->layer == "REF DES/SILKSCREEN_TOP" then
                if(abs(txt->rotation - 0.0) < 5.0 || abs(txt->rotation - 90.0) < 5.0 || 
                abs(txt->rotation - 360.0) < 5.0 then
                x = 0
                else
                    axlHighlightObject(symbol)
                    ;dir = cons(symbol->refdes dir)
                    fprintf(logfile "%-8s %L\n" txt->text symbol->xy)
                    ++dircnt
                )
            else if(txt->layer == "REF DES/SILKSCREEN_BOTTOM" then
                if(abs(txt->rotation - 0.0) < 5.0 || abs(txt->rotation - 270.0) < 5.0 || 
                abs(txt->rotation - 360.0) < 5.0 then
                x = 0
                else
                    axlHighlightObject(symbol)
                    ;dir = cons(symbol->refdes dir)
                    fprintf(logfile "%-8s %L\n" txt->text symbol->xy)
                    ++dircnt
                )
                )            
            )
            if(txt->isMirrored == t then
                if(txt->parent->isMirrored != t then                
                    axlHighlightObject(symbol)
                    ;dir = cons(symbol->refdes dir)
                    fprintf(logfile "%-8s %L\n" txt->text symbol->xy)
                    ++dircnt
                )
            else
                if(txt->parent->isMirrored == t then
                    axlHighlightObject(symbol)
                    ;dir = cons(symbol->refdes dir)
                    fprintf(logfile "%-8s %L\n" txt->text symbol->xy)
                    ++dircnt            
                )                
            )
        );if_end
        
    );foreach-end

    fprintf(logfile "\nTotal direction error of refdes: %d\n" dircnt)
    axlDMClose(logfile)
    
    axlMsgPut("Total direction error of refdes: %d\n" dircnt)       
    axlMsgPut("Refdes direction error , please view logfile.") 
    axlVisibleSet(jkSavedVis)
;    axlMsgPut("Total of components without refdes is : %d %L .\nDone" norefcnt noref)     
;   axlUIViewFileCreate("dir_error.log" "Direction error Log" nil)    
    )
);defun_end

procedure( ASTB_Text_CheckRefOrient()
  jkCheck_Refdes_Direction1()
)

ASTB_RegisterCommand("ASTB_Text_CheckRefOrient" "ASTB_Text_CheckRefOrient" ?cmdType "interactive")

printf("[ASTB] text_checkreforient.il loaded.\n")