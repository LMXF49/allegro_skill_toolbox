;========================================================================
; 文件名    : text_checkoverlap.il
; 作者      : [原作者未知]；ASTB（工具箱集成整改）
; 创建日期  : [未知]
; 版本      : 1.2
; 功能描述  : 丝印文本重叠检查：逐个检查位号/文本与焊盘、过孔、测试点、
;             其他文本的间距，冲突项记录并可逐个定位查看
; 依赖模块  : core（ASTB_RegisterCommand）
; 修改记录  :
;   [原始日期] v1.0 初始创建
;   2026-07-18 v1.1 ASTB 整改：查询类命令去掉 ?undo t；泛名全局加 boundp 保护；
;             axlGetSelSet 0 参 API 误用拆两行；坐标 atoi 改 atof；
;             临时 form 改写临时目录；?cmdType 改字符串；文件转 GBK 编码
;   2026-07-18 v1.2 ASTB 界面汉化：表单标题/分组/复选项/按钮及状态提示译为中文
;========================================================================

axlCmdRegister( "ch_text_overlap" `check_text_overlap)

unless(boundp('layer)             layer = "TOP")
unless(boundp('clearance)         clearance = 3)
unless(boundp('text_pad)          text_pad = t)
unless(boundp('text_testpoint)    text_testpoint = nil)
unless(boundp('text_text)         text_text = nil)
unless(boundp('barcode_overlap)   barcode_overlap = nil)
unless(boundp('refdes_component)  refdes_component = nil)
unless(boundp('formname)          formname = nil)
unless(boundp('location)          location = makeTable("loc" 0))
unless(boundp('num)               num = 0)
unless(boundp('cnt)               cnt = 0)

(defun check_text_overlap ()
    axlVisibleDesign(nil)
    turn_on_layer( layer)
    formname = strcat(axlTempFile() ".form")
    biuld_form(formname)
)

(defun biuld_form (formname)
(prog ()
   pform = outfile(formname "w")

   fprintf(pform "FILE_TYPE=FORM_DEFN VERSION=2\n")

   fprintf(pform "FORM\n")

   fprintf(pform "FIXED\n")

   fprintf(pform "PORT 26 10\n")

   fprintf(pform "HEADER \"\313\277\323\241\326\330\265\376\274\354\262\351\"\n")

   fprintf(pform "POPUP <Layer_Names>")

   fprintf(pform "\"TOP\" \"TOP\",\"BOTTOM\" \"BOTTOM\".\n")

   fprintf(pform "TILE\n")


   fprintf(pform "TEXT \"\321\241\324\361\274\354\262\351\262\343\243\272\"\n")

   fprintf(pform "TLOC 3 1\n")

   fprintf(pform "ENDTEXT\n")

   fprintf(pform "FIELD check_layer\n")

   fprintf(pform "FLOC 6 3\n")

   fprintf(pform "ENUMSET 11\n")

   fprintf(pform "POP \"Layer_Names\"\n")

   fprintf(pform "ENDFIELD\n")


   fprintf(pform "TEXT \"\274\344\276\340\243\272\"\n")

   fprintf(pform "TLOC 3 6\n")

   fprintf(pform "ENDTEXT\n")

   fprintf(pform "FIELD clearance\n")

   fprintf(pform "FLOC 12 6\n")

   fprintf(pform "REALFILLIN 6 6\n")

   fprintf(pform "REALMIN -50.0\n")

   fprintf(pform "REALMAX 100.0\n")

   fprintf(pform "ENDFIELD\n")


   fprintf(pform "FIELD text_pad\n")

   fprintf(pform "FLOC 6 9\n")

   fprintf(pform "FGROUP \"\326\330\265\376\"\n")

   fprintf(pform "CHECKLIST \"\316\304\261\276\323\353\272\270\305\314\" \"overlap\"\n")

   fprintf(pform "ENDFIELD\n")

   fprintf(pform "FIELD text_testpoint\n")

   fprintf(pform "FLOC 6 11\n")

   fprintf(pform "FGROUP \"\326\330\265\376\"\n")

   fprintf(pform "CHECKLIST \"\316\304\261\276\323\353\262\342\312\324\265\343\" \"overlap\"\n")

   fprintf(pform "ENDFIELD\n")

   fprintf(pform "FIELD text_text\n")

   fprintf(pform "FLOC 6 13\n")

   fprintf(pform "FGROUP \"\326\330\265\376\"\n")

   fprintf(pform "CHECKLIST \"\316\304\261\276\323\353\316\304\261\276\" \"overlap\"\n")

   fprintf(pform "ENDFIELD\n")

   fprintf(pform "FIELD refdes_component\n")

   fprintf(pform "FLOC 6 15\n")

   fprintf(pform "FGROUP \"\326\330\265\376\"\n")

   fprintf(pform "CHECKLIST \"\316\273\272\305\323\353\324\252\274\376\" \"overlap\"\n")

   fprintf(pform "ENDFIELD\n")

   fprintf(pform "FIELD barcode_overlap\n")

   fprintf(pform "FLOC 6 17\n")

   fprintf(pform "FGROUP \"\326\330\265\376\"\n")

   fprintf(pform "CHECKLIST \"\314\365\302\353\326\330\265\376\" \"overlap\"\n")

   fprintf(pform "ENDFIELD\n")


   fprintf(pform "TEXT \"\262\351\277\264\264\355\316\363\243\272\"\n")

   fprintf(pform "TLOC 3 20\n")

   fprintf(pform "ENDTEXT\n")

   fprintf(pform "FIELD next_view\n")

   fprintf(pform "FLOC 6 22\n")

   fprintf(pform "STRFILLIN 10 20\n")

   fprintf(pform "ENDFIELD\n")

   fprintf(pform "FIELD prv_ctl\n")

   fprintf(pform "FLOC 18 22\n")

   fprintf(pform "MENUBUTTON \"<<\" 3 3\n")

   fprintf(pform "ENDFIELD\n")

   fprintf(pform "FIELD next_ctl\n")

   fprintf(pform "FLOC 22 22\n")

   fprintf(pform "MENUBUTTON \">>\" 3 3\n")

   fprintf(pform "ENDFIELD\n")


   fprintf(pform "FIELD done\n")

   fprintf(pform "FLOC 2 26\n")

   fprintf(pform "MENUBUTTON \"\315\352\263\311\" 5 3\n")

   fprintf(pform "ENDFIELD\n")

   fprintf(pform "FIELD check\n")

   fprintf(pform "FLOC 8 26\n")

   fprintf(pform "MENUBUTTON \"\274\354\262\351\" 5 3\n")

   fprintf(pform "ENDFIELD\n")

   fprintf(pform "FIELD unselect\n")

   fprintf(pform "FLOC 15 26\n")

   fprintf(pform "MENUBUTTON \"\310\253\262\273\321\241\" 6 3\n")

   fprintf(pform "ENDFIELD\n")


   fprintf(pform "ENDTILE\n")

   fprintf(pform "ENDFORM\n")

   close(pform)


   form=axlFormCreate( (gensym) formname
   `(e inner) `pform_Action t)


   axlFormDisplay(form)

   axlFormSetField(form "check_layer" layer)

   axlFormSetField(form "clearance" clearance)

   axlFormSetField(form "text_pad" text_pad)

   axlFormSetField(form "text_testpoint" text_testpoint)

   axlFormSetField(form "text_text" text_text)

   axlFormSetField(form "barcode_overlap" barcode_overlap)

   axlFormSetField(form "refdes_component" refdes_component)

))

(defun pform_Action (form)


 axlDBRefreshId(axlDBGetDesign())
   (case form->curField


       ("done"

            axlFormClose(form)

            axlCancelEnterFun()

            deleteFile(formname)
           axlMsgPut("\322\321\315\352\263\311\241\243")
            nil

       )

       ("check"
           init_loc_text()
           axlMsgPut("\325\375\324\332\274\354\262\351\313\277\323\241\316\304\261\276\326\330\265\376\241\255\241\255")
             turn_on_layer(layer)
           refdes_on_pad()
           axlFormSetField(form "next_view" sprintf(dummy "\327\334\274\306\243\272 %d" cnt))
           t
       )
       ("unselect"
           axlMsgPut("\322\321\310\241\317\373\321\241\324\361\313\371\323\320\266\324\317\363\241\243")
           unselect_object()
           t
       )
       ("next_ctl"
           axlMsgPut("\266\250\316\273\265\275\317\302\322\273\270\366\316\273\326\303\241\243")
           location_text(location)
           t
       )
       ("prv_ctl"
           axlMsgPut("\266\250\316\273\265\275\311\317\322\273\270\366\316\273\326\303\241\243")
           location_prv(location)
           t
       )

       ("check_layer"
           layer = form->curValue
             turn_on_layer(layer)    ;turn on the layer etch : etch pin via
           axlMsgPut("\322\321\321\241\324\361 %s \262\343" layer)
           t
       )
       ("clearance"

            clearance = form->curValue
           axlMsgPut("\274\344\276\340\311\350\326\303\316\252\243\272 %f" clearance)
            t

       )
       ("text_pad"
            text_pad = form->curValue

           if(text_pad then
                axlMsgPut("\274\354\262\351\272\270\305\314\311\317\265\304\316\304\261\276\241\243" )
           else
                axlMsgPut("\262\273\274\354\262\351\272\270\305\314\311\317\265\304\316\304\261\276\241\243" )
           )
            t

       )
       ("text_testpoint"
            text_testpoint = form->curValue
            if(layer == "TOP" then
                if(text_testpoint axlMsgPut("\266\245\262\343\303\273\323\320\262\342\312\324\265\343\241\243" ))
            else
               if(text_testpoint then
                  axlMsgPut("\274\354\262\351\262\342\312\324\265\343\311\317\265\304\316\304\261\276\241\243" )
               else
                   axlMsgPut("\262\273\274\354\262\351\262\342\312\324\265\343\311\317\265\304\316\304\261\276\241\243" )
               )
            )
            t

       )
      ("barcode_overlap"
            barcode_overlap = form->curValue

           if(barcode_overlap then
               axlMsgPut("\274\354\262\351\314\365\302\353\326\330\265\376\241\243" )
           else
               axlMsgPut("\262\273\274\354\262\351\314\365\302\353\326\330\265\376\241\243" )
           )
            t

       )

       ("refdes_component"
            refdes_component = form->curValue

           if(refdes_component then
               axlMsgPut("\274\354\262\351\324\252\274\376\311\317\265\304\316\273\272\305\241\243" )
           else
               axlMsgPut("\262\273\274\354\262\351\324\252\274\376\311\317\265\304\316\273\272\305\241\243" )
           )
            t

       )

     ("text_text"
            text_text = form->curValue

           if(text_text then
               axlMsgPut("\274\354\262\351\316\304\261\276\274\344\326\330\265\376\241\243" )
           else
               axlMsgPut("\262\273\274\354\262\351\316\304\261\276\274\344\326\330\265\376\241\243" )
           )
            t

       )

    )
)

(defun refdes_on_pad ()

    if(barcode_overlap then
        Going_On=axlGetParam("paramLayerGroup:PACKAGE GEOMETRY/paramLayer:SILKSCREEN_TOP")

        Going_On->visible=t

        axlSetParam(Going_On)
        Going_On=axlGetParam("paramLayerGroup:PACKAGE GEOMETRY/paramLayer:SILKSCREEN_BOTTOM")

        Going_On->visible=t

        axlSetParam(Going_On)

        axlUIWRedraw(nil)
        axlClearSelSet()

    )

    unselect_object()
    axlSetFindFilter(?enabled '(noall text) ?onButtons '(noall text))

    axlAddSelectAll()
    alltexts = axlGetSelSet()


    if(text_pad then
        cnt = 0
        if(layer == "TOP" then
          axlSetFindFilter(?enabled '(noall pins)

          ?onButtons '(noall pins))
        else
          axlSetFindFilter(?enabled '(noall pins)

          ?onButtons '(noall pins))
        )
        foreach(txt alltexts text_on_pad(txt))
        axlMsgPut("%s \262\343\272\270\305\314\311\317\265\304\316\304\261\276\327\334\312\375\243\272 %d" layer cnt)
    )
    if(text_testpoint then
        cnt = 0
        if(layer == "TOP" then
          axlSetFindFilter(?enabled '(noall )

          ?onButtons '(noall ))
        else
          axlSetFindFilter(?enabled '(noall vias)

          ?onButtons '(noall vias))
        )
        foreach(txt alltexts text_on_testpoints(txt))
        axlMsgPut("%s \262\343\262\342\312\324\265\343\311\317\265\304\316\304\261\276\327\334\312\375\243\272 %d" layer cnt)
    )
    if(text_text then
        cnt = 0
        allseltext = nil
        axlSetFindFilter(?enabled '(noall text) ?onButtons '(noall text))

        foreach(txt alltexts text_overlap_text(txt))
        axlHighlightObject( allseltext)
        axlMsgPut("%s \262\343\316\304\261\276\274\344\326\330\265\376\327\334\312\375\243\272 %d" layer cnt)
    )
    if(refdes_component then
        allselcom = nil
        cnt = 0
    axlSetFindFilter(?enabled '(noall shapes) ?onButtons '(noall shapes))

        foreach(txt alltexts refdes_overlap_component(txt))
        axlHighlightObject( allselcom)
        axlMsgPut("%s \262\343\324\252\274\376\311\317\265\304\316\273\272\305\327\334\312\375\243\272 %d" layer cnt)
    )
    if(barcode_overlap then
        axlSetFindFilter(?enabled '(noall pins vias text) ?onButtons '(noall pins vias text ))

        allselcom = nil
        cnt = 0
        foreach(txt alltexts      ; i=0 j=0 k=0 n=0 ++i txt = nthelem(i alltexts)
       if(txt->text == "BAR  CODE" then
           barcode_overlap_atom(txt)
       )
        )
        axlHighlightObject( allselcom)
        axlMsgPut("\314\365\302\353\323\353\306\344\313\373\266\324\317\363\326\330\265\376\241\243")

        Going_On=axlGetParam("paramLayerGroup:PACKAGE GEOMETRY/paramLayer:SILKSCREEN_TOP")

        Going_On->visible=nil

        axlSetParam(Going_On)
        Going_On=axlGetParam("paramLayerGroup:PACKAGE GEOMETRY/paramLayer:SILKSCREEN_BOTTOM")

        Going_On->visible=nil

        axlSetParam(Going_On)
        Going_On=axlGetParam(sprintf(dummy "paramLayerGroup:PACKAGE GEOMETRY/paramLayer:SILKSCREEN_%s" layer))

        Going_On->visible=t

        axlSetParam(Going_On)

        axlUIWRedraw(nil)
        axlClearSelSet()

    )
)

(defun barcode_overlap_atom (txt)
(prog ()

    bars = txt->parent->name
    barx = txt->parent->name
    if(txt->layer == strcat( "PACKAGE GEOMETRY/SILKSCREEN_" layer)
    || (txt->layer != strcat( "PACKAGE GEOMETRY/SILKSCREEN_" layer)
    && index(barx "X") == "X") then
    if(axlSingleSelectBox(get_bar_code_box(txt)) != nil then
        allboxes = axlGetSelSet()
        axlClearSelSet()
        have = nil
        foreach(item allboxes ;++k item = nthelem(k allboxes)
            if(txt->text != item->text && (item->objType != "via"
            || item->testPoint != nil)  then
                allselcom = cons(item allselcom)
                   allselcom = cons(txt->parent allselcom)
            have = t
        )
        )
        if(have then ++cnt add_loc_text(txt))
    )
    )
))

(defun refdes_overlap_component ( txt)
(prog ()
let( (item allbox)

    if(txt->layer == strcat( "REF DES/SILKSCREEN_" layer) then
    if(axlSingleSelectBox(getbox(txt)) != nil then
        allboxes = axlGetSelSet()
        axlClearSelSet()
        have = nil
        foreach(item allboxes ;++k item = nthelem(k allboxes)
            if(item->objType == "shape" &&
            item->layer == strcat( "PACKAGE GEOMETRY/PLACE_BOUND_" layer) then
                allselcom = cons(item allselcom)
                   allselcom = cons(txt allselcom)
                   have = t
        )
        )
        if(have then ++cnt add_loc_text(txt))
    )
    )
)))

(defun text_overlap_text ( txt)
(prog ()
let( (item allbox)

    if(txt->layer == strcat( "REF DES/SILKSCREEN_" layer)
    || txt->layer == strcat( "PACKAGE GEOMETRY/SILKSCREEN_" layer) then
        if(axlSingleSelectBox(getbox(txt)) != nil then
            allboxes = axlGetSelSet()
        axlClearSelSet()
        allbox = nil
        foreach(item allboxes    ;++n item = nthelem(n allboxes)
            if(item->text != txt->text then
                allbox = cons(item allbox)
            )
        )
        have = nil
            foreach(item allbox ;++k item = nthelem(k allbox)
            if(item->objType == "text" then
                if(text_on_text(txt item) != nil then
                allseltext = cons(item allseltext)
                allseltext = cons(txt allseltext)
                have = t
                )
            )
        )
        if(have then ++cnt add_loc_text(txt))
        )
    )
)))

(defun text_on_pad (txt)
(prog ()
let( (item allbox)

        if(txt->layer == strcat( "REF DES/SILKSCREEN_" layer)
        || txt->layer == strcat( "PACKAGE GEOMETRY/SILKSCREEN_" layer) then
        if(axlSingleSelectBox(getbox(txt)) != nil then
            allboxes = axlGetSelSet()
        axlClearSelSet()
        allbox = nil
        foreach(item allboxes    ;++n item = nthelem(n allboxes)
            if(item->text != txt->text then
                allbox = cons(item allbox)
            )
        )
        have = nil
            foreach(item allbox ;++k item = nthelem(k allbox)
            if(item->objType == "pin" then
            ;allselpad = cons(txt allselpad)
            axlHighlightObject(list(txt item))
            have = t
            )
        )
        if(have then ++cnt add_loc_text(txt))
        )
    )
)))

(defun text_on_testpoints (txt)
(prog ()
let( (item allbox)

        if(txt->layer == strcat( "REF DES/SILKSCREEN_" layer)
        || txt->layer == strcat( "PACKAGE GEOMETRY/SILKSCREEN_" layer) then
        if(axlSingleSelectBox(getbox(txt)) != nil then
            allboxes = axlGetSelSet()
        axlClearSelSet()
        allselvia = nil
        have = nil
            foreach(item allboxes ;++k item = nthelem(k allbox)
            if(layer == "BOTTOM" && item->objType == "via" && item->testPoint != nil then
            allselvia = cons(txt allselvia)
                axlHighlightObject(list(item txt))
                have = t
            )
        )
        if(have then ++cnt add_loc_text(txt))
        )
    )
)))

(defun get_bar_code_box (txt)
(prog ()
    if(txt->text == "BAR  CODE"  then
        box = txt->parent->bBox
        bleft   = car( nth(0 box)) - clearance
        btop    = cadr(nth(1 box)) + clearance
        bright  = car( nth(1 box)) + clearance
        bbottom = cadr(nth(0 box)) - clearance
        return(list(bleft:btop bright:bbottom))
    )
    return(nil)
))

(defun getbox (txt)
(prog ()
    loff = 3 toff = 0 roff = -4 boff = 16
    left = car(nth(0 txt->bBox)) - clearance
    top = cadr(nth(1 txt->bBox)) + clearance
    right = car(nth(1 txt->bBox)) + clearance
    bottom = cadr(nth(0 txt->bBox)) - clearance
;    boff = round((top - bottom)/5)+3
    if(layer == "TOP" then
        case(round(txt->rotation)
            (0
                boff = round(abs(top - bottom)/5)+3
                 left = left + loff     top = top + toff
                right = right + roff      bottom = bottom + boff
              t
            )
            (90
                boff = round(abs(right - left)/5)+3
                 left = left - toff     top = top + roff
                right = right - boff      bottom = bottom + loff
              t
            )
            (180
                boff = round(abs(top - bottom)/5)+3
                 left = left - roff     top = top - boff
                right = right - loff      bottom = bottom - toff
              t
            )
            (270
                boff = round(abs(right - left)/5)+3
                 left = left + boff     top = top - loff
                right = right + toff      bottom = bottom - roff
              t
            )
        )
    )
    if(layer == "BOTTOM" then
        case(round(txt->rotation)
            (0
                boff = round(abs(top - bottom)/5)+3
                 left = left - roff     top = top + toff
                right = right - loff      bottom = bottom + boff
              t
            )
            (90
                boff = round(abs(right - left)/5)+3
                 left = left - toff     top = top - loff
                right = right - boff      bottom = bottom - roff
              t
            )
            (180
                boff = round(abs(top - bottom)/5)+3
                 left = left + loff     top = top - boff
                right = right + roff      bottom = bottom - toff
              t
            )
            (270
                boff = round(abs(right - left)/5)+3
                 left = left + boff     top = top + roff
                right = right + toff      bottom = bottom + loff
              t
            )
        );case
    )
    return(list(left:top right:bottom))
))

(defun text_on_text (text item)
(prog ()
(let (tt1 tt2 left top right bottom lt tp rt bm )

    tt2 = getbox(item)
    lt  = car(nth(0 tt2))
    tp  = cadr(nth(0 tt2))
    rt  = car(nth(1 tt2))
    bm  = cadr(nth(1 tt2))

    tt1    = getbox(text)
    left   = car(nth(0 tt1))
    top    = cadr(nth(0 tt1))
    right  = car(nth(1 tt1))
    bottom = cadr(nth(1 tt1))

    if(lt>=left && lt<=right && tp<=top && tp>=bottom return(t) )
    if(lt>=left && lt<=right && bm<=top && bm>=bottom return(t) )
    if(rt>=left && rt<=right && bm<=top && bm>=bottom return(t) )
    if(rt>=left && rt<=right && tp<=top && tp>=bottom return(t) )

    return(nil)
)))

(defun unselect_object ()
(let (allsel)
    axlSetFindFilter(?enabled '(noall shapes pins vias text) ?onButtons '(noall shapes pins vias text))

   ; axlSetFindFilter(?enabled '(all) ?onButtons '(all))

    axlAddSelectAll()
    allsel = axlGetSelSet()

    axlClearSelSet()

    axlSetFindFilter(?enabled '(noall symbols) ?onButtons '(noall symbols))

    axlAddSelectAll()
    allsel = axlGetSelSet()

    axlClearSelSet()

))

(defun turn_on_layer ( layer)
    axlVisibleDesign(nil)

    Going_On=axlGetParam("paramLayerGroup:BOARD GEOMETRY/paramLayer:OUTLINE")

    Going_On->visible=t

    axlSetParam(Going_On)


    Going_On=axlGetParam(sprintf(dummy "paramLayerGroup:VIA CLASS/paramLayer:%s" layer))

    if(layer == "BOTTOM" then
        Going_On->visible=t

    else
        Going_On->visible=nil
    )
    axlSetParam(Going_On)


    Going_On=axlGetParam(sprintf(dummy "paramLayerGroup:PIN/paramLayer:%s" layer))

    Going_On->visible=t

    axlSetParam(Going_On)

    Going_On=axlGetParam(sprintf(dummy "paramLayerGroup:PACKAGE GEOMETRY/paramLayer:SILKSCREEN_%s" layer))

    Going_On->visible=t

    axlSetParam(Going_On)
    Going_On=axlGetParam(sprintf(dummy "paramLayerGroup:REF DES/paramLayer:SILKSCREEN_%s" layer))

    Going_On->visible=t

    axlSetParam(Going_On)


    Going_On = axlGetParam(sprintf(dummy "paramLayerGroup:PACKAGE GEOMETRY/paramLayer:PLACE_BOUND_%s" layer))

    Going_On->visible = refdes_component
    axlSetParam(Going_On)


    axlUIWRedraw(nil)
    axlClearSelSet()

)

(defun init_loc_text ()
    location = makeTable("loc" 0)
    num = 0
)

(defun add_loc_text (item)
    if(item != nil then        ;i = 0 i++ item = nthelem(i alltexts)
        ++num
        x = nthelem(1 item->xy)
        y = nthelem(2 item->xy)
        location[num] = sprintf(dummy "%s,%f,%f" item->text x y)
    )
)

(defun location_text ( location)
    viewx = 400
    viewy = 300

    if(tablep(location) == t && length(location) > 0 then
        if(num < length(location) then
            ++num
        else
            num = 1
        )
        lst = parseString(location[num] ",")
        refdes = sprintf(dummy " %d/%d : %s" num length(location) nthelem(1 lst))
        x = atof(nthelem(2 lst))
        y = atof(nthelem(3 lst))
        ;Display the refdes on the interface.
        axlFormSetField(form "next_view" refdes)
    axlWindowBoxSet(list(x-viewx:y-viewy x+viewx:y+viewy))
    )
)
(defun location_prv ( location)
    viewx = 400
    viewy = 300

    if(tablep(location) == t && length(location) > 0 then
        if(num > 1 then
           --num
        else
           num = length(location)
        )
        lst = parseString(location[num] ",")
        refdes = sprintf(dummy " %d/%d : %s" num length(location) nthelem(1 lst))
        x = atof(nthelem(2 lst))
        y = atof(nthelem(3 lst))
        ;Display the refdes on the interface.
        axlFormSetField(form "next_view" refdes)
    axlWindowBoxSet(list(x-viewx:y-viewy x+viewx:y+viewy))
    )
)

procedure( ASTB_Text_CheckOverlap()
  check_text_overlap()
)

ASTB_RegisterCommand("ASTB_Text_CheckOverlap" "ASTB_Text_CheckOverlap" ?cmdType "interactive")

printf("[ASTB] text_checkoverlap.il loaded.\n")