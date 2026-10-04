;========================================================================
; 文件名    : text_importlogo.il
; 作者      : Wanghh (GTOpen)
; 创建日期  : [未知]
; 版本      : 1.4
; 功能描述  : 导入BMP图片作为Logo，转换为Shape放置到指定层
; 依赖模块  : 无
; 修改记录  :
;   [原始日期] v1.0 Wanghh 初始创建
;   2026-07-16 v1.1 ASTB 添加规范文件头
;   2026-08-13 v1.4 ASTB Team 格式再扩：+wmf/emf/ico（System.Drawing
;             原生支持，同一转换链路；webp/svg/heic 需外部解码器不支持）
;   2026-08-13 v1.3 ASTB Team 支持更多图片格式（用户要求）：
;             png/jpg/jpeg/gif/tif/tiff 经 tools/img2packed.ps1
;             （PowerShell System.Drawing，免装依赖）转 1bpp 打包
;             文本后装载，BMP 仍走原路径；格式错误消息走命令行
;   2026-07-18 v1.2 ASTB 整改：表单经 ASTB_GLOBAL->FormPath 引用 gtopen_Logo.form；
;             case 多值分支拆分为独立子句；bitfield1 改 logand 位运算；
;             axlDBCloak 改引用形式；axlDMFileBrowse 标题改 ?title 参数；
;             polys 空列表防护；?cmdType 改字符串；清理 FanySkill 旧路径注释
;========================================================================

;; ============================================================
;; File: text_importlogo.il
;; Purpose: Import logo
;; Encoding: GBK
;; ============================================================

/*
#########################################################################################                                                                    
#                      Command: FYLG                                                         #
#                      Skill File: FanySkill_Logo.il                                       #
#                      How To Load: Command> (load("FanySkill_Logo.il"))                    #
#                   How To Execute: Command> FYLG                                             #
#                       Write by: Wanghh Download Addr:https://github.com/whh5118/GTOpen     #
#########################################################################################
*/



procedure( ASTB_Text_ImportLogo()
let((form)
    
    axlShell("noappmode")
    form = gtopen_Logo_Createform()
    gtopen_Logo_Int_Var(form)
    gtopen_Logo_Update_form(form)
)
)




procedure( gtopen_Logo_Createform()
let((file form)
    when('gtopen_Logoform && boundp('gtopen_Logoform)
        when(axlIsFormType(eval('gtopen_Logoform))
            axlFormClose(eval('gtopen_Logoform))
        )
    )
    
    
    file = strcat(ASTB_GLOBAL->FormPath "/gtopen_Logo.form")
    form = axlFormCreate('gtopen_Logoform file nil 'gtopen_Logo_CB t)
    
    form
)
)


procedure( gtopen_Logo_Int_Var(form)
let((_getFontList)
    form->pop = ncons(nil)
    form->pop->layerclass = list("BOARD GEOMETRY" "PACKAGE GEOMETRY" "MANUFACTURING" "ETCH" "DRAWING FORMAT")

    
    form->var = ncons(nil)
    form->var->layerclass = "BOARD GEOMETRY"
    form->var->layersubclass = "DIMENSION"
    form->var->pic_size = 1
    form->var->neg = nil
)
)


procedure( gtopen_Logo_CB(form)
prog((tt bmp_show Blockw Blockh width height pixel_size box pick)
    case(form->curField
        ("layerclass"
            form->var->layerclass = form->curValue
            form->var->layersubclass = car(axlSubclasses(form->var->layerclass))
        )
        ("layersubclass"
            form->var->layersubclass = form->curValue
        )
        ("neg"
            form->var->neg = form->curValue
        )
        ("pic_size"
            form->var->pic_size = form->curValue
        )
        ("vis"
            if(form->curValue then
                axlVisibleLayer(strcat(form->var->layerclass "/" form->var->layersubclass) t)
            else
                axlVisibleLayer(strcat(form->var->layerclass "/" form->var->layersubclass) nil)
            )
            axlVisibleUpdate(t)
        )
        ("load"
            tt = axlDMFileBrowse(nil nil ?title "选择图片"
                ?optFilters "Image Files(*.bmp;*.png;*.jpg;*.jpeg;*.gif;*.tif;*.tiff;*.wmf;*.emf;*.ico)|*.bmp;*.png;*.jpg;*.jpeg;*.gif;*.tif;*.tiff;*.wmf;*.emf;*.ico|BMP Files(*.bmp)|*.bmp")
            when(tt
                if( isFile(tt) && member(upperCase(lastelem(axlDMFileParts(tt)))
                        list("BMP" "PNG" "JPG" "JPEG" "GIF" "TIF" "TIFF" "WMF" "EMF" "ICO")) then
                    form->var->bmpinput = tt
                else
                    axlUIWPrint(nil "ERROR: 不支持的图片格式(支持 bmp/png/jpg/gif/tif/wmf/emf/ico)")
                )
            )
        )
        ("place"
            when(form->bmpdate
                tt = axlGetParam(sprintf(nil "paramTextBlock:%d" form->var->pic_size))
                Blockw = tt->width
                Blockh = tt->height
                width = (form->bmpdate[21] << 24) + (form->bmpdate[20] << 16) + (form->bmpdate[19] << 8) + form->bmpdate[18]
                height = (form->bmpdate[25] << 24) + (form->bmpdate[24] << 16) + (form->bmpdate[23] << 8) + form->bmpdate[22]
                pixel_size = max(Blockw/width Blockh/height)
                box = list(list(0 0) list(width*pixel_size height*pixel_size))
                axlClearDynamics()
                axlAddSimpleMoveDynamics(0:0 axlPathStart(box) "box" ?ref_point 0:0)
                pick = axlEnterPoint()
                axlClearDynamics()
                when(pick
                    axlDBCloak('gtopen_Logo_addshape(form pick) '(shape))
                )
            )
        )
        ("textset"
            axlShell("define text")
        )
        (t
            return(t)
        )
    )
    gtopen_Logo_Update_form(form)
)
)

;------------------------------------------------------------------------
; 函数名  : _LogoLoadPackedImage
; 功能    : 非 BMP 图片装载：PowerShell（System.Drawing）转 1bpp 打包
;           文本（tools/img2packed.ps1），解析后合成与 BMP 逐字节读取
;           结果一致的像素数组（头部 54 字节仅填 offset/宽/高字段）
; 参数    : form - 表单句柄 ; filePath - 图片路径
; 返回值  : t 成功 / nil 失败
; 备注    : ipcBeginProcess 四件套（pitfalls 6.1）；打包文本格式：
;           第1行 "宽 高"，第2行 CSV 字节（BMP 1bpp 自底向上布局）
;------------------------------------------------------------------------
procedure( _LogoLoadPackedImage(form filePath)
    prog((ps1 tmpPacked cmd cid rc port line tokens w h total arr i n off)
        ps1 = strcat(getShellEnvVar("ASTB_INSTALL_DIR") "/tools/img2packed.ps1")
        unless( isFile(ps1)
            axlUIWPrint(nil "ERROR: 未找到 %s" ps1)
            return(nil)
        )
        tmpPacked = axlTempFile()
        cmd = sprintf(nil
            "powershell -NoProfile -ExecutionPolicy Bypass -File \"%s\" -src \"%s\" -dst \"%s\""
            ps1 filePath tmpPacked)
        cid = ipcBeginProcess(cmd "" nil nil nil nil)
        ipcWait(cid 300 30)
        rc = ipcGetExitStatus(cid)
        ipcReadProcess(cid 1)
        if( or(null(rc) rc != 0) then
            axlUIWPrint(nil "ERROR: 图片转换失败(退出码 %L): %s" rc filePath)
            return(nil)
        )
        port = errset( infile(tmpPacked) nil )
        unless( and(port car(port))
            axlUIWPrint(nil "ERROR: 转换产物读取失败")
            return(nil)
        )
        port = car(port)
        gets(line port)
        tokens = parseString(line " ")
        w = atoi(car(tokens))
        h = atoi(cadr(tokens))
        gets(line port)
        close(port)
        tokens = parseString(line ",")
        total = length(tokens)
        if( or(w <= 0 h <= 0 total != h * (((w + 31) / 32) * 4)) then
            axlUIWPrint(nil "ERROR: 转换产物格式异常(w=%d h=%d bytes=%d)" w h total)
            return(nil)
        )
        off = 54
        declare(arr[off + total])
        for(i 0 off + total - 1
            arr[i] = 0
        )
        ; BMP 头字段（后处理循环只读 10/18/22 三个偏移，小端）
        arr[10] = off
        arr[18] = logand(w 255)
        arr[19] = logand(w >> 8 255)
        arr[20] = logand(w >> 16 255)
        arr[21] = logand(w >> 24 255)
        arr[22] = logand(h 255)
        arr[23] = logand(h >> 8 255)
        arr[24] = logand(h >> 16 255)
        arr[25] = logand(h >> 24 255)
        n = 0
        foreach( n0 tokens
            arr[off + n] = atoi(n0)
            n = n + 1
        )
        form->bmpdate = arr
        form->bmpsize = off + total
        errset(deleteFile(tmpPacked) nil)
        return(t)
    )
)

procedure( gtopen_Logo_Update_form(form)
let((tt port bmpdate)

    form->pop->layersubclass = nil
    foreach(n0 axlSubclasses(form->var->layerclass)
        when(axlIsLayer(buildString(list(form->var->layerclass n0) "/"))
            form->pop->layersubclass = cons(list(n0 n0 axlLayerGet(buildString(list(form->var->layerclass n0) "/"))->color) form->pop->layersubclass)
        )
    )
    tt = axlLayerGet(strcat(form->var->layerclass "/" form->var->layersubclass))
    if(tt->visible then
        form->var->vis = tt->color
        axlFormSetField(form "vis" t)
    else
        form->var->vis = 0
        axlFormSetField(form "vis" nil)
    )
    
    foreach(n0 form->pop->?
        tt = member(n0 form->pop)
        axlFormBuildPopup(form symbolToString(car(tt)) cadr(tt))
    )
    foreach(n0 form->var->?
        tt = member(n0 form->var)
        axlFormSetField(form symbolToString(car(tt)) cadr(tt))
    )
    when(form->curField == "load" && form->var->bmpinput
        axlFormSetField(form "bmp_show" form->var->bmpinput)
        if( not(equal(upperCase(lastelem(axlDMFileParts(form->var->bmpinput))) "BMP")) then
            ; v1.3：非 BMP 格式经 PowerShell 转 1bpp 打包文本后装载
            unless( _LogoLoadPackedImage(form form->var->bmpinput)
                form->var->bmpinput = nil
            )
        else
            form->bmpsize = fileLength(form->var->bmpinput)
            port = infile(form->var->bmpinput)
            declare(bmpdate[form->bmpsize])
            for(i 0 form->bmpsize-1
                bmpdate[i] = charToInt(getc(port))
            )
            close(port)
            form->bmpdate = bmpdate
        )
    )
    if(form->var->bmpinput then
        axlFormSetFieldEditable(form "place" t)
    else
        axlFormSetFieldEditable(form "place" nil)
    )
    axlFormAutoResize(form)
    axlFormDisplay(form)
)
)

procedure( gtopen_Logo_addshape(form pickxy)
prog((tt Blockw Blockh number num row max_column column max_w bit x y offset width height Grid imagesize path polys symbolid)
    tt = axlGetParam(sprintf(nil "paramTextBlock:%d" form->var->pic_size))
    Blockw = tt->width
    Blockh = tt->height
    
    offset = (form->bmpdate[13] << 24) + (form->bmpdate[12] << 16) + (form->bmpdate[11] << 8) + form->bmpdate[10]
    width = (form->bmpdate[21] << 24) + (form->bmpdate[20] << 16) + (form->bmpdate[19] << 8) + form->bmpdate[18]
    height = (form->bmpdate[25] << 24) + (form->bmpdate[24] << 16) + (form->bmpdate[23] << 8) + form->bmpdate[22]
    imagesize = form->bmpsize - offset
    
    max_column = (imagesize / height) << 3
    max_w = (imagesize / width) << 3
    number = offset + imagesize - 1
    Grid = 1/min(width/Blockw height/Blockh)
    column = 0
    polys = '()
    if(!axlSelectByName("SYMTYPE" "GTLogo") then
    axlDBCreateSymDefSkeleton(list("GTLogo" "mechanical") list(list(0 0) list(width height)))
    else
      axlClearSelSet()
    )
    symbolid = car(axlDBCreateSymbolSkeleton(list("GTLogo" "mechanical") pickxy nil 0.0 nil))
    axlMeterCreate("进程中" "" t)
    for(i offset number
        tt = fix((50*i) / (imagesize-1))
        when(tt == 12 || tt == 25 || tt == 37 || tt == 50
            axlMeterUpdate(tt sprintf(nil "完成度 :%d / %d" (i-offset) (imagesize-1)))
        )
        
        y = Grid * fix((i - offset) / (max_column >> 3)) + cadr(pickxy)
        for(j 0 7
        bit = if( logand(form->bmpdate[i] (1 << (7 - j))) then 1 else 0)
        when(form->var->neg
            bit = abs(bit-1)
        )
        x = Grid * column + car(pickxy)
            when(zerop(bit) && (column < width)
                path = axlPathStart(list(x:y))
                axlPathLine(path 0.0 x:(y+1.1*Grid))
                axlPathLine(path 0.0 (x+1.1*Grid):(y+1.1*Grid))
                axlPathLine(path 0.0 (x+1.1*Grid):y)
                axlPathLine(path 0.0 x:y)
                polys = append(axlPolyFromDB(path) polys)
            )
        column++
        )
        when(column == max_column
        column = 0
        )
    )
    when(polys
        polys = axlPolyOperation(car(polys) cdr(polys) 'OR)
    )
    num = 1
    foreach(n0 polys
        tt = fix((50*num) / length(polys)) + 50
        when(tt == 62 || tt == 75 || tt == 87 || tt == 100
            axlMeterUpdate(tt sprintf(nil "完成度 :%d / %d" num length(polys)))
        )
        tt = axlDBCreateShape(n0 t strcat(form->var->layerclass "/" form->var->layersubclass) nil symbolid)
        axlCustomColorObject(car(tt) 0)
        num++
    )
    axlMeterDestroy()
    axlVisibleUpdate(t)
    
)
)

ASTB_RegisterCommand("ASTB_Text_ImportLogo" "ASTB_Text_ImportLogo" ?cmdType "interactive")

printf("[ASTB] text_importlogo.il loaded.\n")
