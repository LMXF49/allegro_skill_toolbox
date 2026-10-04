;========================================================================
; 文件名    : modules/text/text_refdescenter.il
; 作者      : ASTB Team
; 创建日期  : 2026-08-16
; 版本      : 4.3
; 功能描述  : 位号居中/读向归一（v2.2 桥接真机验证后修正）。遍历器件用
;             components（不是 symbols——symbols 含 NO_TOUCH 等机械件且
;             无 refdes）；居中基准用 sym->xy 器件原点（place_bound/bBox
;             真机均不可靠）；读向随器件旋转角：顶层不镜像(左到右/下到
;             上)，底层镜像(右到左/下到上)；勾选统一字体才按 block(1-20)
;             统一字号，"设置"弹 Allegro 自带 textsetup；执行后表单保持
;             打开；层联动显示 PIN+阻焊+丝印/装配框；居中只作用当前选中
;             层；支持撤销(astbundo/refcu)。
; 依赖模块  : forms/text_refdescenter.form、core/trans.il
; 启动命令  : refc（或菜单 Text/Silk -> RefDes Center）
; 编码      : GBK（含中文，必须 GBK 保存）
; 风险提示  : 移动数据库中的位号文本，请先备份 .brd
; 修改记录  :
;   2026-08-16 v1.0 ASTB Team 初始创建
;   2026-08-28 v2.0 ASTB Team 表单优先；读向随器件旋转；textsetup
;   2026-08-28 v2.1 ASTB Team 六点修正（place_bound 居中/层联动等）
;   2026-08-28 v2.2 ASTB Team 桥接真机验证后修正：遍历改 components；
;                     居中基准改 sym->xy；撤销定位改 component->name；
;                     删除不存在的 axlFormSetEditable；选中模式选择集
;                     symbol 映射回 component
;   2026-08-28 v2.3 ASTB Team 桥接真机修正旋转/镜像 API：
;                     axlTransformObject 正确关键字为 ?angle（增量
;                     旋转），?rotate/?rotation 报 Invalid option；
;                     ?mirror 对文本不生效（底层文本靠所在层自动镜
;                     像读向），去掉手动转180镜像逻辑；撤销同步改 ?angle
;   2026-08-28 v2.4 ASTB Team 修居中不生效：axlTransformObject ?move
;                     要求文本在选择集里才生效（真机实测未选中返回 nil），
;                     移动前 axlSetSelSet 选中、移动后 axlClearSelSet
;   2026-08-28 v2.5 ASTB Team 阻焊层名修正（封装 PACKAGE GEOMETRY/
;                     SOLDERMASK_* + 板子 BOARD GEOMETRY/SOLDERMASK_*
;                     + 焊盘 PIN/*，替换错误的裸 SOLDERMASK_*）；设置
;                     命令改 define text（定义字体大小）；丝印角度跟
;                     随器件旋转角（不一致时自动旋转到器件角度）
;   2026-08-28 v2.6 ASTB Team 补 PIN/SOLDERMASK_* 联动层；修切层时
;                     旧联动层关不掉（_RC_ShowLayer 的 foreach 副作用
;                     调用不可靠，改 while 索引循环）；读向排序归一：
;                     丝印转到器件角度后，顶层归一从左到右/从下到上、
;                     底层归一从右到左/从下到上（倒字转正）
;   2026-08-28 v2.7 ASTB Team 读向改跟随器件本身旋转角（去掉90°
;                     吸附）：丝印角=器件角，器件角归一到[0,360)
;                     后落在 90°~270° 区间时 +180° 转正（倒字读正）
;   2026-08-28 v4.2 ASTB Team 摆放四周缺陷修复：
;                     1) 间隙按文本 block 高度动态计算;
;                     2) _RC_PickEmptiestSide 改用旋转后实体框
;                        _RC_SymBodyBox, 避免方向错误;
;                     3) 丝印框来源增加 BOARD GEOMETRY/REF DES
;                        的 SILKSCREEN_*, 最后才退回实体框;
;                     4) 占用检测增加其他位号文本 bBox 避让;
;                     5) 底层器件自动镜像, 摆放坐标用板坐标
;   2026-10-01 v4.3 ASTB Team 居中光学校正: 文本 bBox 是单元格框
;                     (含字腔 bearing 和降部区), 其几何中心低于大写+
;                     数字字形视觉中心 (D-b)/2; 新增 _RC_OpticalCorr
;                     按字块实测单元格参数(同层探针即建即删)补偿到
;                     真实视觉中心, 任意旋转角/镜像均适用
;========================================================================

unless( boundp('_RC_fw)         _RC_fw = nil )
unless( boundp('_RC_pickDone)   _RC_pickDone   = nil )
unless( boundp('_RC_pickCancel) _RC_pickCancel = nil )
unless( boundp('_RC_undoStack)  _RC_undoStack  = nil )
unless( boundp('_RC_curBatch)   _RC_curBatch   = nil )
unless( boundp('_RC_opticCache) _RC_opticCache = nil )

; 四个可选位号层（与表单 LAYERPOP 一致）
unless( boundp('_RC_layers)
    _RC_layers = '("REF DES/SILKSCREEN_TOP" "REF DES/SILKSCREEN_BOTTOM"
                   "REF DES/ASSEMBLY_TOP"  "REF DES/ASSEMBLY_BOTTOM")
)

; 各层联动显示的相关层：PIN + 阻焊 + 丝印框/装配框（不含铜层）
unless( boundp('_RC_visExtra)
    ; 每层联动显示：PIN + PIN阻焊 + 封装阻焊 + 板子阻焊 + 丝印/装配框
    ;              + 板框三层(OUTLINE/DESIGN_OUTLINE/CUTOUT) + 板框丝印
    _RC_visExtra = '(
        ("REF DES/SILKSCREEN_TOP"    "PIN/TOP" "PIN/Soldermask_Top"
            "PACKAGE GEOMETRY/Soldermask_Top" "BOARD GEOMETRY/Soldermask_Top"
            "PACKAGE GEOMETRY/SILKSCREEN_TOP"
            "BOARD GEOMETRY/OUTLINE" "BOARD GEOMETRY/DESIGN_OUTLINE"
            "BOARD GEOMETRY/CUTOUT" "BOARD GEOMETRY/SILKSCREEN_TOP")
        ("REF DES/SILKSCREEN_BOTTOM" "PIN/BOTTOM" "PIN/Soldermask_Bottom"
            "PACKAGE GEOMETRY/Soldermask_Bottom" "BOARD GEOMETRY/Soldermask_Bottom"
            "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
            "BOARD GEOMETRY/OUTLINE" "BOARD GEOMETRY/DESIGN_OUTLINE"
            "BOARD GEOMETRY/CUTOUT" "BOARD GEOMETRY/SILKSCREEN_BOTTOM")
        ("REF DES/ASSEMBLY_TOP"      "PIN/TOP" "PIN/Soldermask_Top"
            "PACKAGE GEOMETRY/Soldermask_Top" "BOARD GEOMETRY/Soldermask_Top"
            "PACKAGE GEOMETRY/ASSEMBLY_TOP"
            "BOARD GEOMETRY/OUTLINE" "BOARD GEOMETRY/DESIGN_OUTLINE"
            "BOARD GEOMETRY/CUTOUT" "BOARD GEOMETRY/ASSEMBLY_TOP")
        ("REF DES/ASSEMBLY_BOTTOM"   "PIN/BOTTOM" "PIN/Soldermask_Bottom"
            "PACKAGE GEOMETRY/Soldermask_Bottom" "BOARD GEOMETRY/Soldermask_Bottom"
            "PACKAGE GEOMETRY/ASSEMBLY_BOTTOM"
            "BOARD GEOMETRY/OUTLINE" "BOARD GEOMETRY/DESIGN_OUTLINE"
            "BOARD GEOMETRY/CUTOUT" "BOARD GEOMETRY/ASSEMBLY_BOTTOM")
    )
)

; 切层时要主动关闭的过孔层（"孔"=过孔 VIA CLASS，初始/切层时常残留）
unless( boundp('_RC_offViaLayers)
    _RC_offViaLayers = '("VIA CLASS/TOP" "VIA CLASS/BOTTOM"
        "VIA CLASS/L2-GND1" "VIA CLASS/L3-POWER1" "VIA CLASS/L4-GND2"
        "VIA CLASS/L5-POWER2" "VIA CLASS/L6-S2" "VIA CLASS/L7-GND3")
)

;------------------------------------------------------------------------
; 函数    : _RC_PtXY
; 功能    : 坐标点归一化为 (x y) 二维表（兼容 x:y 点对）
;------------------------------------------------------------------------
procedure( _RC_PtXY(p)
    if( listp(cdr(p)) then
        list(car(p) cadr(p))
    else
        list(car(p) cdr(p))
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_ShowLayer
; 功能    : 显示选中的位号层，关闭其他三个位号层，并联动显示该层对应
;           的 PIN + 阻焊 + 丝印框/装配框；居中只作用当前选中层。
;------------------------------------------------------------------------
procedure( _RC_ShowLayer(t_layer)
    prog( (lay extra i j sublays)
        ; 先关掉全部联动层（while 索引循环，foreach 副作用调用不可靠）
        i = 0
        while( i < length(_RC_visExtra)
            sublays = cdr(nth(i _RC_visExtra))
            j = 0
            while( j < length(sublays)
                errset( axlVisibleLayer(nth(j sublays) nil) nil )
                j = j + 1
            )
            i = i + 1
        )
        ; 关掉过孔层（"孔"=VIA CLASS，初始/切层时常残留）
        i = 0
        while( i < length(_RC_offViaLayers)
            errset( axlVisibleLayer(nth(i _RC_offViaLayers) nil) nil )
            i = i + 1
        )
        ; 四个位号层只留选中层
        i = 0
        while( i < length(_RC_layers)
            lay = nth(i _RC_layers)
            errset( axlVisibleLayer(lay equal(lay t_layer)) nil )
            i = i + 1
        )
        ; 开选中层对应的联动层（assoc 对字符串键用 eq 不可靠，改 equal 循环）
        extra = nil
        i = 0
        while( and(null(extra) i < length(_RC_visExtra))
            when( equal(car(nth(i _RC_visExtra)) t_layer)
                extra = nth(i _RC_visExtra)
            )
            i = i + 1
        )
        when( extra
            sublays = cdr(extra)
            j = 0
            while( j < length(sublays)
                errset( axlVisibleLayer(nth(j sublays) t) nil )
                j = j + 1
            )
        )
        axlVisibleUpdate(t)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_LayerSide
; 功能    : 判定层所属面："bottom"/"top"
;------------------------------------------------------------------------
procedure( _RC_LayerSide(t_layer)
    if( or(equal(t_layer "REF DES/SILKSCREEN_BOTTOM")
           equal(t_layer "REF DES/ASSEMBLY_BOTTOM"))
    then "bottom" else "top" )
)

;------------------------------------------------------------------------
; 函数    : _RC_NormReadAngle
; 功能    : 计算丝印应旋转的增量角：先对齐到器件旋转角，再按层归一
;           阅读方向。顶层归一到从左到右(0)/从下到上(90)；底层归一到
;           从右到左(180)/从下到上(90)。返回增量角(度)。
; 参数    : symRot - 器件旋转角 ; txtRot - 文本当前角 ; t_layer - 位号层
;------------------------------------------------------------------------
procedure( _RC_NormReadAngle(symRot txtRot t_layer)
    prog( (target side)
        side = _RC_LayerSide(t_layer)
        ; 读向跟随器件本身旋转角（不吸附90°倍数）：
        ; 丝印角 = 器件角；器件角归一到 [0,360) 后，
        ; 落在 (90,270] 区间（文字倒着读）时 +180° 转正
        target = symRot
        while( target < 0    target = target + 360.0 )
        while( target >= 360 target = target - 360.0 )
        when( and(target > 90.0 target <= 270.0)
            target = target + 180.0
            while( target >= 360 target = target - 360.0 )
        )
        ; 底层镜像读向：器件角在 [90,270) 区间时丝印角=器件角+180
        ; （90→270 从下到上；180→0；270 不在区间不转）
        when( equal(side "bottom")
            target = symRot
            while( target < 0    target = target + 360.0 )
            while( target >= 360 target = target - 360.0 )
            when( and(target >= 90.0 target < 270.0)
                target = target + 180.0
                while( target >= 360 target = target - 360.0 )
            )
        )
        return( target - txtRot )
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_TextBlockHeight
; 功能    : 取指定 text block 的高度; 取不到返回 25(mil)
; 参数    : blk - block 号(1-20)
;------------------------------------------------------------------------
procedure( _RC_TextBlockHeight(blk)
    let((param h)
        param = errset(axlGetParam(sprintf(nil "paramTextBlock:%d" blk)) t)
        h = if( param && car(param) then car(param)->height else 25.0 )
        if( h && h > 0.0 then h else 25.0 )
    )
)
;------------------------------------------------------------------------
; 函数    : _RC_SymCenter
; 功能    : 器件"正中间" = 器件原点 sym->xy（封装设计基准，不受丝印框
;           撑大影响；真机验证 place_bound/bBox 均不可靠）。
;------------------------------------------------------------------------
procedure( _RC_SymCenter(sym)
    _RC_PtXY(sym->xy)
)

;------------------------------------------------------------------------
; 函数    : _RC_SymBodyBox
; 功能    : 器件封装实体框（def->bBox）经旋转/镜像/平移变换到板上的
;           实际包围盒，返回 ((x1 y1)(x2 y2))。比 sym->bBox 准（不含
;           丝印文字等撑大元素），是"离丝印框6mil"的正确基准。
;------------------------------------------------------------------------
procedure( _RC_SymBodyBox(sym)
    prog( (def dbb x1 y1 x2 y2 rot mir ox oy corners p rx ry xs ys)
        def = car(errset(sym->definition t))
        dbb = and(def car(errset(def->bBox t)))
        unless( dbb return( sym->bBox ) )   ; 取不到退回 sym->bBox
        x1 = car(car(dbb))  y1 = cadr(car(dbb))
        x2 = car(cadr(dbb)) y2 = cadr(cadr(dbb))
        rot = car(errset(sym->rotation 0.0))
        mir = car(errset(sym->isMirrored nil))
        ox  = car(_RC_PtXY(sym->xy))
        oy  = cadr(_RC_PtXY(sym->xy))
        ; 四角
        corners = list( list(x1 y1) list(x2 y1) list(x2 y2) list(x1 y2) )
        xs = nil
        ys = nil
        foreach( p corners
            rx = car(p)
            ry = cadr(p)
            ; 镜像（绕器件 y 轴）：x 取反
            when( mir rx = 0.0 - rx )
            ; 旋转（90 倍数为主；一般角用三角）
            rad = rot * 3.14159265358979 / 180.0
            px = rx * cos(rad) - ry * sin(rad)
            py = rx * sin(rad) + ry * cos(rad)
            xs = cons(ox + px xs)
            ys = cons(oy + py ys)
        )
        return( list( list(apply('min xs) apply('min ys))
                      list(apply('max xs) apply('max ys)) ) )
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_OpticalCorr
; 功能    : 位号文本"视觉居中"校正位移(板框坐标)。Allegro 文本 bBox 是
;           单元格框: 含左侧字腔 bearing 和基线下方的降部区, 且内容无关
;           (17.4 实测: HHHHH/HgQyj/R1204/iiiii/WWWWW 同字块 bBox 完全
;           相同)。单元格几何中心比大写+数字字形的视觉中心低 (D-b)/2
;           (blk62 实测 4.165mil, blk1 实测 1.665mil)。
;           本函数用同层探针文本(即建即删)实测该字块的单元格参数,
;           把校正量按文本实际旋转角旋到板框; 探针失败返回 nil 不校正。
;           水平方向字腔两侧对称, 无需校正; 镜像为水平翻转, 不影响
;           竖直校正向量。
; 参数    : txt - 文本 dbid(旋转/字号已就位)
; 返回    : (dx dy) 校正位移, 或 nil(无需/失败)
;------------------------------------------------------------------------
procedure( _RC_OpticalCorr(txt)
    prog( (blk ent e orient rr probe bb p1 ox oy bd dn rot rad corr)
        blk = txt->textBlock
        unless( blk return(nil) )
        ; 字块缓存(每批次 _RC_Run 开头清空, 防 textsetup 后沿用旧值)
        ent = nil
        foreach( e _RC_opticCache
            when( and(null(ent) equal(car(e) blk)) ent = e )
        )
        if( ent then
            bd = cadr(ent)
            dn = caddr(ent)
        else
            orient = make_axlTextOrientation(?textBlock blk
                       ?rotation 0.0 ?mirrored nil ?justify "left")
            ; 探针: axlDBCreateText 返回 ((dbid) nil), dbid 用 caar 提取
            rr = errset( axlDBCreateText("Hg" _RC_PtXY(txt->xy)
                         orient txt->layer nil) nil )
            probe = and(rr car(rr) caar(car(rr)))
            unless( probe return(nil) )
            bb = probe->bBox
            if( bb then
                p1 = _RC_PtXY(car(bb))
                ox = car(_RC_PtXY(probe->xy))
                oy = cadr(_RC_PtXY(probe->xy))
                errset( axlDBDeleteObject(probe) nil )
                bd = ox - car(p1)    ; 字腔 bearing = 单元格左缘到原点距离
                dn = oy - cadr(p1)   ; 降部深度 = 单元格下缘到原点(基线)距离
                when( or(bd <= 0.0 dn <= 0.0) return(nil) )
                _RC_opticCache = cons(list(blk bd dn) _RC_opticCache)
            else
                errset( axlDBDeleteObject(probe) nil )
                return(nil)
            )
        )
        ; 单元格几何中心(基线以上) = (capH+bd-dn)/2, 字形视觉中心 = capH/2
        ; 文本需向本地系下方补移 (dn-bd)/2
        corr = (dn - bd) / 2.0
        when( corr < 0.001 return(nil) )
        rot = car(errset(txt->rotation 0.0))
        unless( rot rot = 0.0 )
        rad = rot * 3.14159265358979 / 180.0
        ; 本地向量 (0,-corr) 旋转到板框
        return( list(corr * sin(rad) (0.0 - corr * cos(rad))) )
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_CenterOne
; 功能    : 单个器件位号居中 + 读向随器件旋转角 + 可选统一字号
; 参数    : comp - 器件 component dbid ; t_layer - 位号层 ;
;           blk - 目标字号块号(1-20)，<=0 表示不改字号
; 返回    : t 成功 / nil 无位号或失败
;------------------------------------------------------------------------
procedure( _RC_CenterOne(comp t_layer blk)
    prog( (sym texts txt found cc cx cy tbb dx dy t1 t2 rec cname rr i symRot dRot corr)
        sym = comp->symbol
        cname = comp->name
        unless( and(sym cname) return(nil) )
        rr = errset( axlDBGetAttachedText(sym) nil )
        texts = and(rr car(rr))
        found = nil
        i = 0
        while( and(null(found) i < length(texts))
            txt = nth(i texts)
            when( equal(txt->layer t_layer) found = txt )
            i = i + 1
        )
        unless( found
            return(nil)
        )
        ; 撤销记录（改动前取旧值）：(位号 层 旧原点 旧角度 旧字号块)
        rec = list(cname t_layer _RC_PtXY(found->xy)
                   found->rotation found->textBlock)
        ; 统一字号
        when( and(blk blk > 0)
            errset( axlDBChangeText(found nil blk) nil )
        )
        ; 丝印角度跟随器件旋转角 + 读向排序归一：
        ; 先对齐到器件角度，再按层归一阅读方向——顶层从左到右/从下到上、
        ; 底层从右到左/从下到上（把倒字/反向转正）
        symRot = car(errset(sym->rotation 0.0))
        dRot = _RC_NormReadAngle(symRot found->rotation t_layer)
        when( abs(dRot) > 0.01
            errset( axlSetSelSet(list(found)) nil )
            errset( axlTransformObject(found ?angle dRot) nil )
            errset( axlClearSelSet() nil )
        )
        ; 读向由所在层决定：顶层文本不镜像(左到右/下到上)，底层文本
        ; 放到底层自动镜像(右到左/下到上)，无需手动转180
        ; 居中：器件原点中心 - 文本 bBox 中心
        cc = _RC_SymCenter(sym)
        cx = car(cc)
        cy = cadr(cc)
        tbb = found->bBox
        t1 = _RC_PtXY(car(tbb))
        t2 = _RC_PtXY(cadr(tbb))
        dx = cx - (car(t1) + car(t2)) / 2.0
        dy = cy - (cadr(t1) + cadr(t2)) / 2.0
        when( or(abs(dx) > 0.001 abs(dy) > 0.001)
            ; ?move 要求文本在选择集里才生效（真机实测）
            errset( axlSetSelSet(list(found)) nil )
            errset( axlTransformObject(found ?move list(dx dy)) nil )
            errset( axlClearSelSet() nil )
        )
        ; v4.3 光学校正: 单元格框几何中心 -> 字形视觉中心
        corr = _RC_OpticalCorr(found)
        when( corr
            errset( axlSetSelSet(list(found)) nil )
            errset( axlTransformObject(found ?move corr) nil )
            errset( axlClearSelSet() nil )
        )
        _RC_curBatch = cons(rec _RC_curBatch)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_Run
; 功能    : 批量执行体（ASTB_DBTransactionMark 包裹）
; 参数    : comps - component dbid 列表 ; t_layer - 位号层 ; blk - 字号块号
;------------------------------------------------------------------------
procedure( _RC_Run(comps t_layer blk)
    prog( (comp cnt miss)
        cnt = 0
        miss = 0
        _RC_curBatch = nil
        _RC_opticCache = nil
        foreach( comp comps
            if( _RC_CenterOne(comp t_layer blk) then
                cnt = cnt + 1
            else
                miss = miss + 1
            )
        )
        when( _RC_curBatch
            _RC_undoStack = cons(reverse(_RC_curBatch) _RC_undoStack)
            ASTB_UndoJournalPush("text_refdescenter")
            _RC_curBatch = nil
        )
        axlUIWPrint(nil "位号处理完成: 成功 %d 个, 无位号 %d 个(层 %s)"
            cnt miss t_layer)
        when( cnt > 0
            axlUIWPrint(nil "完成。输入 astbundo 可撤销本次修改")
        )
        return(cnt)
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_SymSilkBox
; 功能    : 器件丝印框 bBox：从 sym->children 里筛 PACKAGE GEOMETRY/
;           SILKSCREEN_<面> 的图元，合并它们的 bBox。取不到（器件该面
;           无丝印）则退回 _RC_SymBodyBox。返回 ((x1 y1)(x2 y2))。
;------------------------------------------------------------------------
procedure( _RC_SymSilkBox(sym t_layer)
    prog( (side silkLays ch xs ys cl cb c1 c2 layHit)
        ; 位号层 -> 丝印层候选列表: PACKAGE -> BOARD -> REF DES(v4.2)
        side = _RC_LayerSide(t_layer)
        if( equal(side "bottom") then
            silkLays = list(
                "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
                "BOARD GEOMETRY/SILKSCREEN_BOTTOM"
                "REF DES/SILKSCREEN_BOTTOM" )
        else
            silkLays = list(
                "PACKAGE GEOMETRY/SILKSCREEN_TOP"
                "BOARD GEOMETRY/SILKSCREEN_TOP"
                "REF DES/SILKSCREEN_TOP" )
        )
        xs = nil
        ys = nil
        layHit = nil
        ch = errset(sym->children nil)
        when( and(ch car(ch))
            foreach( cl car(ch)
                cb = errset(cl->bBox nil)
                when( and( cb car(cb)
                           member(car(errset(cl->layer t)) silkLays) )
                    cb = car(cb)
                    c1 = _RC_PtXY(car(cb))
                    c2 = _RC_PtXY(cadr(cb))
                    xs = cons(car(c1) cons(car(c2) xs))
                    ys = cons(cadr(c1) cons(cadr(c2) ys))
                    layHit = t
                )
            )
        )
        if( and(xs ys) then
            return( list( list(apply('min xs) apply('min ys))
                          list(apply('max xs) apply('max ys)) ) )
        else
            return( _RC_SymBodyBox(sym) )   ; 无丝印退回实体框
        )
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_PtOccupied
; 功能    : 检测点 pt 是否落在其他器件的 bBox 内（排除自身 sym）。
;           返回占位的器件数（0=空）
;------------------------------------------------------------------------
procedure( _RC_PtOccupied(pt sym allSyms t_layer)
    prog( (o ob o1 o2 px py cnt ot ot1 ot2 rr texts)
        px = car(pt)
        py = cadr(pt)
        cnt = 0
        foreach( o allSyms
            when( nequal(o sym)
                ; 1) 不进入其他器件实体/丝印框(v4.2)
                ob = errset(o->bBox nil)
                when( and(ob car(ob))
                    ob = car(ob)
                    o1 = _RC_PtXY(car(ob))
                    o2 = _RC_PtXY(cadr(ob))
                    when( and(px >= car(o1) px <= car(o2)
                              py >= cadr(o1) py <= cadr(o2))
                        cnt = cnt + 1
                    )
                )
                ; 2) 不进入该器件的位号文本 bBox(v4.2)
                rr = errset(axlDBGetAttachedText(o) nil)
                texts = and(rr car(rr))
                foreach( t texts
                    when( equal(t->layer t_layer)
                        ot = errset(t->bBox nil)
                        when( and(ot car(ot))
                            ot = car(ot)
                            ot1 = _RC_PtXY(car(ot))
                            ot2 = _RC_PtXY(cadr(ot))
                            when( and(px >= car(ot1) px <= car(ot2)
                                      py >= cadr(ot1) py <= cadr(ot2))
                                cnt = cnt + 1
                            )
                        )
                    )
                )
            )
        )
        return(cnt)
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_PickEmptiestSide
; 功能    : 智能分边：计算器件四边外侧候选点的占用数，返回最空的一侧
;           （0上 1右 2下 3左；并列时优先 上>右>下>左）
;------------------------------------------------------------------------
procedure( _RC_PickEmptiestSide(sym allSyms t_layer)
    prog( (bb b1 b2 cx cy ox oy pts scores best bestScore k sc)
        ; v4.2: 用旋转后的实体框, 不再用未旋转的 sym->bBox
        bb = _RC_SymBodyBox(sym)
        b1 = _RC_PtXY(car(bb))
        b2 = _RC_PtXY(cadr(bb))
        cx = (car(b1) + car(b2)) / 2.0
        cy = (cadr(b1) + cadr(b2)) / 2.0
        ; v4.2: gap 基准按实体框 0.5倍 + 20mil, 并用文本高度修正(外层算)
        ox = abs(car(b2) - car(b1)) * 0.5 + 20
        oy = abs(cadr(b2) - cadr(b1)) * 0.5 + 20
        ; 四边外侧候选点：上 右 下 左
        pts = list(
            list(cx cadr(b2) + oy)
            list(car(b2) + ox cy)
            list(cx car(b1) - oy)
            list(car(b1) - ox cy)
        )
        scores = nil
        foreach( pt pts
            scores = append1(scores _RC_PtOccupied(pt sym allSyms t_layer))
        )
        best = 0
        bestScore = 9999
        for( k 0 3
            sc = nth(k scores)
            when( sc < bestScore
                bestScore = sc
                best = k
            )
        )
        return(best)
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_SurroundOne
; 功能    : 单个器件位号摆到器件外侧四周：按方位 dir(0上 1右 2下 3左)
;           把位号移到器件 bBox 对应边外侧（偏移一个文本高度）
;------------------------------------------------------------------------
procedure( _RC_SurroundOne(comp t_layer blk dir tx ty)
    prog( (sym texts txt found i cname cur dx dy rec rr)
        sym = comp->symbol
        cname = comp->name
        unless( and(sym cname) return(nil) )
        rr = errset( axlDBGetAttachedText(sym) nil )
        texts = and(rr car(rr))
        found = nil
        i = 0
        while( and(null(found) i < length(texts))
            txt = nth(i texts)
            when( equal(txt->layer t_layer) found = txt )
            i = i + 1
        )
        unless( found return(nil) )
        ; 撤销记录（旧原点/角度/字号）
        rec = list(cname t_layer _RC_PtXY(found->xy)
                   found->rotation found->textBlock)
        when( and(blk blk > 0)
            errset( axlDBChangeText(found nil blk) nil )
        )
        ; 平移文本原点到目标点（?move 需先选中）
        cur = _RC_PtXY(found->xy)
        dx = tx - car(cur)
        dy = ty - cadr(cur)
        when( or(abs(dx) > 0.001 abs(dy) > 0.001)
            errset( axlSetSelSet(list(found)) nil )
            errset( axlTransformObject(found ?move list(dx dy)) nil )
            errset( axlClearSelSet() nil )
        )
        _RC_curBatch = cons(rec _RC_curBatch)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_RunSurround
; 功能    : 批量摆放四周：按器件顺序轮转分配上/右/下/左四边
;------------------------------------------------------------------------
procedure( _RC_RunSurround(comps t_layer blk)
    prog( (comp cnt miss allSyms groups dir rec0 sym bb b1 b2 edge
           items tx ty gap k it pairs coord linePos sbb sb1 sb2 th)
        cnt = 0
        miss = 0
        _RC_curBatch = nil
        allSyms = axlDBGetDesign()->symbols
        ; v4.2: 动态间距 = 文本高度 * 1.5 + 2mil, 保底 6mil
        th = _RC_TextBlockHeight(if( blk && blk > 0 then blk else 1))
        gap = max(6.0 th * 1.5 + 2.0)
        ; 第一遍：智能分边，把器件按边分组 groups=(上 右 下 左)
        groups = list(nil nil nil nil)
        foreach( comp comps
            when( and(comp->symbol comp->name)
                dir = _RC_PickEmptiestSide(comp->symbol allSyms t_layer)
                rec0 = nth(dir groups)
                rec0 = append1(rec0 comp)
                ; 写回对应边组
                cond(
                    ( equal(dir 0) groups = list(rec0 nth(1 groups) nth(2 groups) nth(3 groups)) )
                    ( equal(dir 1) groups = list(nth(0 groups) rec0 nth(2 groups) nth(3 groups)) )
                    ( equal(dir 2) groups = list(nth(0 groups) nth(1 groups) rec0 nth(3 groups)) )
                    ( equal(dir 3) groups = list(nth(0 groups) nth(1 groups) nth(2 groups) rec0) )
                )
            )
        )
        ; 第二遍：逐边摆放——按沿边坐标排序，对齐成一条线，间距错开
        for( dir 0 3
            items = nth(dir groups)
            when( items
                ; 沿边坐标排序：上/下边按 x，左/右边按 y。
                ; sortcar 要求元素是列表——包成 (坐标 comp) 对排序后取 cadr
                pairs = nil
                foreach( comp items
                    coord = if( or(equal(dir 0) equal(dir 2)) then
                        car(_RC_PtXY(comp->symbol->xy))
                    else
                        cadr(_RC_PtXY(comp->symbol->xy))
                    )
                    pairs = cons(list(coord comp) pairs)
                )
                pairs = sortcar(pairs 'lessp)   ; 按 car(坐标) 升序
                items = mapcar('cadr pairs)     ; 还原成器件列表
                ; 先算该边统一的摆放线（对齐整齐的关键）：
                ; 上/下边取所有器件实体框顶/底的最大/最小值，左/右边取左/右极值
                linePos = nil
                foreach( comp items
                    sbb = _RC_SymSilkBox(comp->symbol t_layer)
                    sb1 = _RC_PtXY(car(sbb))
                    sb2 = _RC_PtXY(cadr(sbb))
                    cond(
                        ( equal(dir 0) edge=cadr(sb2) )   ; 上：实体框顶
                        ( equal(dir 1) edge=car(sb2)  )   ; 右：实体框右
                        ( equal(dir 2) edge=cadr(sb1) )   ; 下：实体框底
                        ( equal(dir 3) edge=car(sb1)  )   ; 左：实体框左
                    )
                    if( null(linePos) then
                        linePos = edge
                    else
                        cond(
                            ( equal(dir 0) when( edge > linePos linePos = edge ) )
                            ( equal(dir 1) when( edge > linePos linePos = edge ) )
                            ( equal(dir 2) when( edge < linePos linePos = edge ) )
                            ( equal(dir 3) when( edge < linePos linePos = edge ) )
                        )
                    )
                )
                ; 摆放线统一外扩 6mil
                cond(
                    ( equal(dir 0) linePos = linePos + gap )
                    ( equal(dir 1) linePos = linePos + gap )
                    ( equal(dir 2) linePos = linePos - gap )
                    ( equal(dir 3) linePos = linePos - gap )
                )
                foreach( comp items
                    sym = comp->symbol
                    ; 实体框（变换到板上）作偏移基准
                    bb = _RC_SymSilkBox(sym t_layer)
                    b1 = _RC_PtXY(car(bb))
                    b2 = _RC_PtXY(cadr(bb))
                    ; 沿边坐标 = 器件中心（x 或 y），垂直方向 = 统一摆放线
                    cond(
                        ( equal(dir 0) tx=(car(b1)+car(b2))/2.0 ty=linePos )  ; 上
                        ( equal(dir 1) tx=linePos ty=(cadr(b1)+cadr(b2))/2.0 ) ; 右
                        ( equal(dir 2) tx=(car(b1)+car(b2))/2.0 ty=linePos )   ; 下
                        ( equal(dir 3) tx=linePos ty=(cadr(b1)+cadr(b2))/2.0 ) ; 左
                    )
                    if( _RC_SurroundOne(comp t_layer blk dir tx ty) then
                        cnt = cnt + 1
                    else
                        miss = miss + 1
                    )
                )
            )
        )
        when( _RC_curBatch
            _RC_undoStack = cons(reverse(_RC_curBatch) _RC_undoStack)
            ASTB_UndoJournalPush("text_refdescenter")
            _RC_curBatch = nil
        )
        axlUIWPrint(nil "摆放四周完成: 成功 %d 个, 无位号 %d 个(层 %s)"
            cnt miss t_layer)
        when( cnt > 0
            axlUIWPrint(nil "完成。输入 astbundo 可撤销本次修改")
        )
        return(cnt)
    )
)

;------------------------------------------------------------------------
; 函数    : RC_Undo
; 功能    : 撤销最近一次位号居中。按位号在 components 里找回器件，
;           恢复旧角度/旧原点/旧字号块/旧镜像状态。
;------------------------------------------------------------------------
procedure( RC_Undo()
    prog( (batch item refdes lay oldXY oldRot oldBlk oldMir blk comps comp c
           sym texts txt found n m curXY dx dy dRot rr i)
        unless( _RC_undoStack
            axlUIWPrint(nil "没有可撤销的记录")
            return(nil)
        )
        batch = car(_RC_undoStack)
        _RC_undoStack = cdr(_RC_undoStack)
        n = 0
        m = 0
        foreach( item batch
            refdes = nth(0 item)
            lay    = nth(1 item)
            oldXY  = nth(2 item)
            oldRot = nth(3 item)
            oldBlk = nth(4 item)
            found  = nil
            if( stringp(refdes) then
                comps = axlDBGetDesign()->components
                comp = nil
                foreach( c comps
                    when( and(null(comp) equal(c->name refdes))
                        comp = c
                    )
                )
                when( comp
                    sym = comp->symbol
                    rr    = errset( axlDBGetAttachedText(sym) nil )
                    texts = and(rr car(rr))
                    found = car(foreach( txt texts
                        when( equal(txt->layer lay) txt )
                    ))
                )
            )
            if( found then
                dRot = oldRot - found->rotation
                when( abs(dRot) > 0.01
                    errset( axlTransformObject(found ?angle dRot) nil )
                )
                curXY = _RC_PtXY(found->xy)
                dx = car(oldXY) - car(curXY)
                dy = cadr(oldXY) - cadr(curXY)
                when( or(abs(dx) > 0.001 abs(dy) > 0.001)
                    errset( axlSetSelSet(list(found)) nil )
                    errset( axlTransformObject(found ?move list(dx dy)) nil )
                    errset( axlClearSelSet() nil )
                )
                blk = oldBlk
                if( stringp(blk) then blk = atoi(blk) )
                errset( axlDBChangeText(found nil blk) nil )
                n = n + 1
            else
                m = m + 1
                axlUIWPrint(nil "  警告: 位号 %s 层 %s 未找到, 跳过恢复"
                    or(refdes "?") lay)
            )
        )
        axlClearSelSet()
        axlFlushDisplay()
        axlUIWPrint(nil "撤销完成: 恢复 %d 个位号, %d 个失败" n m)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_ParseBlock
; 功能    : 解析字号输入：返回 1-20 的块号，或 -1(不改)
;------------------------------------------------------------------------
procedure( _RC_ParseBlock(s)
    prog( (v)
        unless( and(s stringp(s)) return(-1) )
        v = atoi(s)
        if( and(v >= 1 v <= 20) then return(v) else return(-1) )
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_CollectComps
; 功能    : 按范围收集器件：all=全部 component；sel=当前选择集里的
;           symbol 映射回 component（无选择则先交互拾取）
;------------------------------------------------------------------------
procedure( _RC_CollectComps(scope)
    prog( (comps s c)
        if( equal(scope "all") then
            comps = axlDBGetDesign()->components
        else
            when( null(axlGetSelSet())
                _RC_PickSymbols()
            )
            comps = nil
            foreach( s axlGetSelSet()
                foreach( c axlDBGetDesign()->components
                    when( equal(c->symbol s)
                        comps = cons(c comps)
                    )
                )
            )
            comps = reverse(comps)
        )
        return(comps)
    )
)

;------------------------------------------------------------------------
; 函数    : _RC_FormCB
; 功能    : 表单回调
;------------------------------------------------------------------------
procedure( _RC_FormCB(fw)
    prog( (scope comps blk t_layer unifont)
        if( nequal(fw->doneState 0) then
            axlFormClose(fw)
            return(nil)
        )
        case( fw->curField
            ("layer"
                _RC_ShowLayer(axlFormGetField(fw "layer"))
            )
            ("unifont"
                ; 勾选统一字体才可设字号：未勾选时清空字号框
                unless( axlFormGetField(fw "unifont")
                    axlFormSetField(fw "blk" "")
                )
            )
            ("setsize"
                ; 先关表单再弹 Allegro 自带文本大小设置对话框
                axlFormClose(fw)
                errset( axlShell("define text") nil )
            )
            ("apply"
                scope = axlFormGetField(fw "scope")
                comps = _RC_CollectComps(scope)
                if( null(comps) then
                    axlUIWPrint(nil "ERROR: 没有可处理的器件(范围=选中时请先选择)")
                else
                    unifont = axlFormGetField(fw "unifont")
                    if( unifont then
                        blk = _RC_ParseBlock(axlFormGetField(fw "blk"))
                    else
                        blk = -1
                    )
                    t_layer = axlFormGetField(fw "layer")
                    ; 执行后表单保持打开
                    ASTB_DBTransactionMark('_RC_Run list(comps t_layer blk))
                )
            )
            ("surround"
                scope = axlFormGetField(fw "scope")
                comps = _RC_CollectComps(scope)
                if( null(comps) then
                    axlUIWPrint(nil "ERROR: 没有可处理的器件(范围=选中时请先选择)")
                else
                    unifont = axlFormGetField(fw "unifont")
                    if( unifont then
                        blk = _RC_ParseBlock(axlFormGetField(fw "blk"))
                    else
                        blk = -1
                    )
                    t_layer = axlFormGetField(fw "layer")
                    ASTB_DBTransactionMark('_RC_RunSurround list(comps t_layer blk))
                )
            )
            ("quit"
                axlFormClose(fw)
            )
            (t nil)
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数    : RC_PickDone / RC_PickCancel
; 功能    : 拾取循环右键菜单回调
;------------------------------------------------------------------------
procedure( RC_PickDone()
    _RC_pickDone = t
    axlUIPopupSet(nil)
    axlFinishEnterFun()
)

procedure( RC_PickCancel()
    _RC_pickCancel = t
    axlClearSelSet()
    axlUIPopupSet(nil)
    axlCancelEnterFun()
)

;------------------------------------------------------------------------
; 函数    : _RC_PickSymbols
; 功能    : 交互拾取器件（点选/框选，右键 Done）；选中 symbol 留在
;           选择集里供 _RC_CollectComps 映射回 component
;------------------------------------------------------------------------
procedure( _RC_PickSymbols()
    prog( (popup)
        _RC_pickDone   = nil
        _RC_pickCancel = nil
        axlSetFindFilter(?enabled '("noall" "symbols")
                         ?onButtons '("noall" "symbols"))
        axlClearSelSet()
        popup = axlUIPopupDefine(nil
            list(
                list("Done"   "RC_PickDone()")
                list("Cancel" "RC_PickCancel()")
            ))
        axlUIPopupSet(popup)
        axlSelect(?groupMode t
                  ?prompt "点选或框选要居中的器件, 右键 Done 完成")
        axlUIPopupSet(nil)
        when( _RC_pickCancel
            axlClearSelSet()
        )
        return( axlGetSelSet() )
    )
)

;------------------------------------------------------------------------
; 函数    : RC_Main
; 功能    : 命令入口：直接弹出位号居中表单（第一步即表单）。
;------------------------------------------------------------------------
procedure( RC_Main()
    prog( (fw formFile)
        unless( axlOKToProceed()
            axlUIWPrint(nil "ERROR: 当前环境不允许执行该操作")
            return(nil)
        )
        when( _RC_fw
            axlUIWExpose(_RC_fw)
            return(_RC_fw)
        )
        formFile = strcat(ASTB_GLOBAL->FormPath "/text_refdescenter.form")
        fw = axlFormCreate('_RC_fw formFile '("NE" "msglines" 1)
                           '_RC_FormCB t nil)
        unless( fw
            axlUIWPrint(nil "ERROR: 表单创建失败, 请检查 forms/text_refdescenter.form")
            return(nil)
        )
        axlFormSetField(fw "layer" car(_RC_layers))
        axlFormSetField(fw "scope" "all")
        axlFormSetField(fw "blk"   "")
        axlFormSetField(fw "unifont" nil)
        _RC_ShowLayer(car(_RC_layers))
        axlFormDisplay(fw)
        return(fw)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Text_RefDesCenter
; 功能    : Toolbox 菜单包装：位号居中（RC_Main 入口）
;------------------------------------------------------------------------
procedure( ASTB_Text_RefDesCenter()
    RC_Main()
)

ASTB_RegisterCommand("refc" 'RC_Main ?cmdType "interactive")
ASTB_RegisterCommand("refcu" "RC_Undo" ?cmdType "general" ?undo nil)
ASTB_RegisterUndo("text_refdescenter" 'RC_Undo)
ASTB_RegisterCommand("ASTB_Text_RefDesCenter" "ASTB_Text_RefDesCenter"
    ?cmdType "interactive")

printf("[ASTB] text_refdescenter.il v4.3 loaded, command: refc (undo: refcu/astbundo)\n")
