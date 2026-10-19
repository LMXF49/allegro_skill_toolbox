;========================================================================
; 文件名    : text_addnetname.il
; 作者      : FYNN（原作）；ASTB（工具箱集成整改）
; 创建日期  : [未知]
; 版本      : 1.26
; 功能描述  : 在指定位置添加网络名称文本，支持交互式拾取管脚/过孔/图形并拖动放置
; 依赖模块  : core（ASTB_RegisterCommand / ASTB_RegisterUndo）
; 修改记录  :
;   [原始日期] v1.0 FYNN 初始创建（FanySkill_create_net_silk.il）
;   2026-10-19 v1.25 ASTB 回退为 FanySkill 原版表单与右键交互流程
;   2026-10-19 v1.26 ASTB 保留原版表单，修复原版中心锚点/放置失败：
;             放置阶段不再 erase+transform 预创建文本，改矩形预览后现场创建；
;             Text Just 按最终放置点生效；增加 astbundo 批次撤销
;========================================================================

;; ============================================================
;; File: text_addnetname.il
;; Purpose: Add net name
;; Encoding: GBK
;; Source: FanySkill_create_net_silk.il form flow + ASTB placement/undo
;; ============================================================

;--- 全局变量保护（表单句柄/事务标记/放置状态/撤销批次） ---
unless(boundp('_dbCreateNetSilkFinish) _dbCreateNetSilkFinish = nil)
unless(boundp('fm_crtn)                fm_crtn = nil)
unless(boundp('mk_crtn)                mk_crtn = nil)
unless(boundp('_dbCreateNetSilkStage)  _dbCreateNetSilkStage = nil)
unless(boundp('_dbCreateNetSilkBatch)  _dbCreateNetSilkBatch = nil)    ;--- v1.26: 当次会话放置记录 ---
unless(boundp('_TANN_placedBatches)    _TANN_placedBatches = nil)      ;--- v1.26: Done 撤销批次栈 ---

;------------------------------------------------------------------------
; 函数    : _NNTextBlockHeight
; 功能    : 取指定 text block 的高度(供放置预览矩形估算大小); 取不到返回 25
; 参数    : blk - block 号字符串(表单 "text_block" 字段值)
;------------------------------------------------------------------------
procedure( _NNTextBlockHeight(blk)
(let (param h)
    param = errset(axlGetParam(sprintf(nil "paramTextBlock:%s" blk)) t)
    h = if( param && car(param) then car(param)->height else 25.0 )
    if( h && h > 0.0 then h else 25.0 )
))

;;主函数
procedure( ASTB_Text_AddNetName()
(let (addr)
	_dbCreateNetSilkFinish = nil
    _dbCreateNetSilkBatch = nil    ;--- v1.26: 清空本次会话放置记录(供 Done 后撤销) ---

    ;创建FORM（沿用 FanySkill 原版 Ministatus 表单，仅文件名加 ASTB 前缀）
	addr = "./ASTB_CreateNetSilk.form"
	_dbCreatCreateNetSilkForm(addr)
    fm_crtn = axlMiniStatusLoad((gensym) addr `_dbCreateNetSilkCallback t)
	when(isFile(addr) errset(deleteFile(addr)))

    axlSetActiveLayer("BOARD GEOMETRY/SILKSCREEN_TOP")
    axlFormSetField(fm_crtn "mirror" nil)
    axlFormSetField(fm_crtn "angle" "0")
    axlFormSetField(fm_crtn "text_block" "2")
    axlFormSetField(fm_crtn "text_justification" "left")

	axlUIPopupSet(axlUIPopupDefine(nil
			'(("Done" _dbCreateNetSilkDone)
			  ("Oops" _dbCreateNetSilkOops)
			  ("Cancel" _dbCreateNetSilkCancel)
	)))
    axlControlRaise('options)	;右侧显示options选项置顶
    axlClearSelSet()
    axlSetFindFilter(?enabled `("NOALL" "PINS" "VIAS" "SHAPES" "CLINESEGS") ?onButtons `("PINS" "VIAS" "SHAPES" "CLINESEGS"))
	mk_crtn = axlDBTransactionStart()
    while( !_dbCreateNetSilkFinish
        when(axlSingleSelectPoint()
            axlDBTransactionMark(mk_crtn)
            _dbCreateNetSilk(axlLastPick(nil) axlGetSelSet())
        )
	)
    axlUIPopupSet(nil)
))

procedure(_dbCreateNetSilk(pt item)
(let (id layer mir ang blk jst myorient netname theight twidth x0 rect outline ptPlace ret )

    axlClearSelSet()
    id = car(item)
    layer = axlGetActiveLayer()
    mir = case(axlFormGetField(fm_crtn "mirror")  ("1" t) ("0" nil))
    ang = atof(axlFormGetField(fm_crtn "angle"))
    blk = axlFormGetField(fm_crtn "text_block")
    jst = axlFormGetField(fm_crtn "text_justification")
    myorient = make_axlTextOrientation(?textBlock blk ?rotation ang ?mirrored mir ?justify jst)

    ;--- v1.26: 进 enter 前提取纯数据；enter 后绝不再访问旧 dbid ---
    netname = id->net->name
    if( netname != "" && netname != nil then
        axlVisibleLayer(layer t)
        axlVisibleUpdate(nil)

        ;--- 预览只用矩形框，不预创建文本再 erase/transform ---
        theight = _NNTextBlockHeight(blk)
        twidth = theight * strlen(netname) * 0.6
        if( twidth < theight then twidth = theight )
        x0 = case(jst ("center" -twidth/2.0) ("right" -twidth) (t 0.0))
        rect = list(x0:0 x0+twidth:0 x0+twidth:theight x0:theight x0:0)
        outline = errset(axlPathStart(rect) t)
        when( and(outline car(outline))
            errset(axlAddSimpleMoveDynamics(0:0 car(outline) "path" ?ref_point 0:0) nil)
        )
        _dbCreateNetSilkStage = nil
        ptPlace = axlEnterPoint(?prompts `("\307\353\265\343\273\367\321\241\324\361\316\304\261\276\267\305\326\303\265\343"))
        axlClearDynamics()
        if( listp(ptPlace) then
            ;--- Text Just/角度/镜像在最终创建时生效，抓取点不再固定中心 ---
            ret = car(axlDBCreateText(netname ptPlace myorient layer nil))
            if( ret then
                _dbCreateNetSilkStage = t
                _dbCreateNetSilkBatch = cons(list(layer ptPlace netname) _dbCreateNetSilkBatch)
            else
                printf("\264\264\275\250\315\370\302\347\303\373\316\304\261\276\312\247\260\334\243\241\n")
            )
        )
        axlUIWRedraw(nil)
    else
        printf("\315\370\302\347\303\373\316\252\277\325\243\241\n")
    )
))

;;form响应函数
(defun _dbCreateNetSilkCallback (fm_crtn)
(prog ()
	case(fm_crtn->curField
		("subclass"
			t
		)
	)
	return()
))


;;创建form
defun(_dbCreatCreateNetSilkForm (addr)
(let (file)
	file = outfile(addr)
	
	fprintf(file "FILE_TYPE=FORM_DEFN VERSION=2\n")
	fprintf(file "FORM AUTOGREYTEXT\n")
	fprintf(file "FIXED\n")
	fprintf(file "PORT 55 20\n")			;长，高
	fprintf(file "HEADER \"CreateNetSilk\"\n")
	fprintf(file "\n")

    fprintf(file "POPUP <rotate>\"0\"\"0.000\",\"45\"\"45.000\",\"90\"\"90.000\",\"135\"\"135.000\",\
\"180\"\"180.000\",\"225\"\"225.000\",\"270\"\"270.000\",\"315\"\"315.000\".\n")
    fprintf(file "POPUP <justification>\"Left\"\"left\",\"Right\"\"right\",\"Center\"\"center\".\n")

	fprintf(file "TILE\n")
	fprintf(file "\n")
	
    fprintf(file "TEXT \"Active Class and Subclass:\"\n")
    fprintf(file "TLOC 1 1\n")
    fprintf(file "ENDTEXT\n")
    
    fprintf(file "FIELD class\n")
    fprintf(file "FLOC 5 3\n")
    fprintf(file "ENUMSET 19\n")
    fprintf(file "OPTIONS prettyprint\n")
    fprintf(file "POP \"class\"\n")
    fprintf(file "ENDFIELD\n")

    fprintf(file "FIELD subcolor\n")
    fprintf(file "FLOC 2 6\n")
    fprintf(file "COLOR 2 1\n")
    fprintf(file "OPTIONS colorchooser\n")
    fprintf(file "ENDFIELD\n")

    fprintf(file "FIELD subclass\n")
    fprintf(file "FLOC 5 6\n")
    fprintf(file "ENUMSET 19\n")
    fprintf(file "OPTIONS prettyprint ownerdrawn\n")
    fprintf(file "POP \"subclass\"\n")
    fprintf(file "ENDFIELD\n")

    fprintf(file "FIELD mirror\n")
    fprintf(file "FLOC 2 9\n")
    fprintf(file "CHECKLIST \"Mirror\"\n")
    fprintf(file "ENDFIELD\n")

    /* fprintf(file "TEXT \"Marker size:\"\n")
    fprintf(file "TLOC 5 11\n")
    fprintf(file "ENDTEXT\n")

    fprintf(file "FIELD text_marker_size\n")
    fprintf(file "FLOC 18 11\n")
    fprintf(file "REALFILLIN 9 9\n")
    fprintf(file "DECIMAL 5\n")
    fprintf(file "ENDFIELD\n") */

    fprintf(file "TEXT \"Rotate:\"\n")
    fprintf(file "TLOC 5 11\n")
    fprintf(file "ENDTEXT\n")
    
    fprintf(file "FIELD angle\n")
    fprintf(file "FLOC 18 11\n")
    fprintf(file "REALFILLIN 6 7\n")
    fprintf(file "POP \"rotate\"\n")
    fprintf(file "DECIMAL 3\n")
    fprintf(file "ENDFIELD\n")

    fprintf(file "TEXT \"Text block:\"\n")
    fprintf(file "TLOC 5 13\n")
    fprintf(file "ENDTEXT\n")
    
    fprintf(file "FIELD text_block\n")
    fprintf(file "FLOC 18 13\n")
    fprintf(file "INTSLIDEBAR 7 7\n")
    fprintf(file "MIN 1\n")
    fprintf(file "MAX 64\n")
    fprintf(file "ENDFIELD\n")

/*     fprintf(file "TEXT \"Text name:\"\n")
    fprintf(file "TLOC 5 17\n")
    fprintf(file "ENDTEXT\n")
    
    fprintf(file "FIELD text_name\n")
    fprintf(file "FLOC 18 17\n")
    fprintf(file "STRFILLIN 6 14\n")
    fprintf(file "POP \"text_names\"\n")
    fprintf(file "ENDFIELD\n") */

    fprintf(file "TEXT \"Text just:\"\n")
    fprintf(file "TLOC 5 15\n")
    fprintf(file "ENDTEXT\n")

    fprintf(file "FIELD text_justification\n")
    fprintf(file "FLOC 18 15\n")
    fprintf(file "ENUMSET 8\n")
    fprintf(file "POP \"justification\"\n")
    fprintf(file "ENDFIELD \n")
    
	fprintf(file "\n")
	
	fprintf(file "ENDTILE\n")
	fprintf(file "\n")
	
	fprintf(file "ENDFORM\n")

	close(file)
))

procedure( _dbCreateNetSilkDone()
    _dbCreateNetSilkFinish = t
    errset(axlDBTransactionCommit(mk_crtn) t)
    ;--- v1.26: 当批记录压栈，astbundo 按 LIFO 撤销 ---
    when( _dbCreateNetSilkBatch
        _TANN_placedBatches = cons(reverse(_dbCreateNetSilkBatch) _TANN_placedBatches)
        _dbCreateNetSilkBatch = nil
        ASTB_UndoJournalPush("text_addnetname")
        printf("\315\352\263\311\241\243\312\344\310\353 astbundo \277\311\263\267\317\372\261\276\264\316\320\336\270\304\n")
    )
    axlFinishEnterFun()
)

procedure( _dbCreateNetSilkCancel()
	_dbCreateNetSilkFinish = t
    errset(axlDBTransactionRollback(mk_crtn) t)
    _dbCreateNetSilkBatch = nil    ;--- v1.26: 已回滚，当批记录作废 ---
	axlCancelEnterFun()
)

procedure( _dbCreateNetSilkOops()
    when(!_dbCreateNetSilkStage
        axlClearDynamics()	;清除鼠标附着
        axlCancelEnterFun()
    )
    axlDBTransactionOops(mk_crtn)
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Text_AddNetName_Undo
; 功能    : 撤销最近一次 Done 放置的那批网络名文本(命令 ASTB_Text_AddNetNameu)
; 备注    : 批次栈只存 层+放置点+文本内容，不存跨命令会失效的 dbid
;------------------------------------------------------------------------
procedure( ASTB_Text_AddNetName_Undo()
(prog (batch rec lay pt txt hit obj n m rr)
    unless( _TANN_placedBatches
        axlUIWPrint(nil "\303\273\323\320\277\311\263\267\317\372\265\304\274\307\302\274")
        return(nil)
    )
    batch = car(_TANN_placedBatches)
    _TANN_placedBatches = cdr(_TANN_placedBatches)
    axlSetFindFilter(?enabled `("noall" "text") ?onButtons `("noall" "text"))
    n = 0
    m = 0
    foreach( rec batch
        lay = car(rec)
        pt  = cadr(rec)
        txt = caddr(rec)
        errset(axlVisibleLayer(lay t) t)
        axlVisibleUpdate(nil)
        axlClearSelSet()
        hit = nil
        when( axlSingleSelectPoint(pt)
            foreach( obj axlGetSelSet()
                when( and(null(hit)
                          equal(obj->layer lay)
                          equal(obj->text txt)
                          abs(car(obj->xy) - car(pt)) < 0.01
                          abs(cadr(obj->xy) - cadr(pt)) < 0.01)
                    hit = obj
                )
            )
        )
        if( hit then
            rr = errset( axlDeleteObject(hit) t )
            if( and(rr car(rr)) then
                n = n + 1
            else
                m = m + 1
                axlUIWPrint(nil "  \276\257\270\346: %L \264\246\316\304\261\276(%s)\311\276\263\375\312\247\260\334" pt txt)
            )
        else
            axlUIWPrint(nil "  \314\341\312\276: %L \264\246\316\264\325\322\265\275\316\304\261\276(%s), \277\311\304\334\322\321\261\273\311\276\263\375" pt txt)
        )
    )
    axlClearSelSet()
    axlFlushDisplay()
    axlUIWPrint(nil "\263\267\317\372\315\352\263\311: \311\276\263\375 %d \270\366\315\370\302\347\303\373\316\304\261\276, %d \270\366\312\247\260\334(\312\243\323\340\277\311\263\267\317\372 %d \305\372)"
        n m length(_TANN_placedBatches))
    return(t)
))

;--- ASTB 命令注册：保留 FanySkill 表单交互，接 ASTB 统一撤销 ---
ASTB_RegisterCommand("ASTB_Text_AddNetName" "ASTB_Text_AddNetName"
    ?cmdType "interactive" ?undo nil
    ?doneCmd '_dbCreateNetSilkDone ?cancelCmd '_dbCreateNetSilkCancel)

ASTB_RegisterCommand("ASTB_Text_AddNetNameu" "ASTB_Text_AddNetName_Undo"
    ?cmdType "general" ?undo nil)
ASTB_RegisterUndo("text_addnetname" 'ASTB_Text_AddNetName_Undo)

printf("[ASTB] text_addnetname.il v1.26 loaded (FanySkill form + ASTB placement/astbundo).\n")
