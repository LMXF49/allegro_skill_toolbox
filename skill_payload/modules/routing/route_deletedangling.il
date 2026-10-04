;========================================================================
; 文件名    : route_deletedangling.il
; 作者      : Allegro SKILL Toolbox
; 创建日期  : 2026-07-16
; 版本      : 1.2
; 功能描述  : 删除悬垂对象（悬垂走线/悬垂过孔/孤岛铜皮），支持 GUI 批量操作
; 依赖模块  : core/menu.il, core/utils.il, core/trans.il
; 参考来源  : FanySkill_quick_danglings.il (EDA365)
; 修改记录  :
;   2026-07-16 v1.0 Allegro SKILL Toolbox 初始创建
;   2026-07-17 v1.1 Allegro SKILL Toolbox 整改：
;                   1) 重写全部损毁的用户界面中文字符串（原内容为字面 ?）
;                   2) 修复 axlUIConfirm 多参数崩溃（帮助文本拼成单串）
;                   3) 删除假事务桩；删除/换网/挖空统一接入 ASTB_DBTransactionMark
;                   4) dynamic 孤岛挖除改 foreach 处理全部结果块并判空，
;                      修复只取第一块导致其余铜皮静默丢失的问题
;                   5) 下线旧版 EDA365 实现（quick_danglings/ps_*，归档备查）；
;                      其 net->branches 孤岛检测与 symbolEtch 排除回补进新实现
;   2026-09-09 v1.2 Allegro SKILL Toolbox 修 17.4 S039 跨交互轮 dbid 失效：
;                   1) ddoAssign 过孔当轮改存身份纯数据(xy 焊盘名 旧网络名
;                      层名)，_AST_AssignViaNets 凭 (xy 焊盘名) 现场重解析
;                      旧孔再删建（via_changevianet v1.6 实证模式）
;                   2) ddoLineList/ddoLinesDel/ddoViaList/ddoViasDel/
;                      ddoShapeList/ddoShapesDel(static) 高亮与删除全部挪进
;                      当次迭代内现场执行，不再跨迭代攒 dbid
;========================================================================

;;#########################################################################
;;#  功能: 删除悬垂对象 (Delete Dangling Objects)                          #
;;#  命令: ASTB_Route_DeleteDangling                                       #
;;#  说明: 检查全板悬垂走线、悬垂过孔、孤岛铜皮，GUI 列表高亮定位并处理     #
;;#  API:  axlDBGetConnect, axlDeleteObject, axlFormCreate,                #
;;#        axlHighlightObject, axlPolyOperation                            #
;;#########################################################################

;;=========================================================================
;; 全局变量（表单回调异步访问，有意全局）
;;=========================================================================

unless( boundp('g_DanglingForm)
    g_DanglingForm = nil
)
unless( boundp('g_DanglingData)
    g_DanglingData = nil
)

;;=========================================================================
;; 命令入口: 检查全板悬垂对象并打开处理 GUI
;;=========================================================================

procedure( ASTB_Route_DeleteDangling()
  prog((lData lLines lVias lShapes)

    ;; 环境检查
    unless(axlOKToProceed()
      axlUIConfirm("\265\261\307\260\273\267\276\263\262\273\324\312\320\355\326\264\320\320\270\303\262\331\327\367")
      return(nil)
    )

    ;; 全板检查
    lData = _AST_DanglingCheck()
    lLines = car(lData)
    lVias = cadr(lData)
    lShapes = caddr(lData)

    ;; 缓存检查结果供回调使用
    g_DanglingData = lData

    ;; 未发现问题时直接提示
    unless(lLines || lVias || lShapes
      axlUIConfirm("\316\264\267\242\317\326\320\374\264\271\327\337\317\337/\271\375\277\327/\271\302\265\272\315\255\306\244")
      return(0)
    )

    unless(axlUIConfirm("\267\242\317\326\320\374\264\271\266\324\317\363\243\254\312\307\267\361\264\362\277\252 GUI \275\347\303\346\305\372\301\277\264\246\300\355\243\277\n\n\312\307 - \264\362\277\252\264\246\300\355\275\347\303\346\243\250\301\320\261\355\277\311\270\337\301\301\266\250\316\273\243\251\n\267\361 - \310\241\317\373\262\331\327\367")
      return(nil)
    )

    ;; 创建并显示 GUI
    g_DanglingForm = _AST_CreateDanglingForm(lData)
    when(g_DanglingForm
      axlFormDisplay(g_DanglingForm)
      axlUIWDisableQuit(g_DanglingForm)

      ;; 消息区提示各类数量
      when(lLines
        axlMsgPut(sprintf(nil "[AST] \267\242\317\326 %d \314\365\320\374\264\271\327\337\317\337" length(lLines)))
      )
      when(lVias
        axlMsgPut(sprintf(nil "[AST] \267\242\317\326 %d \270\366\320\374\264\271\271\375\277\327" length(lVias)))
      )
      when(lShapes
        axlMsgPut(sprintf(nil "[AST] \267\242\317\326 %d \277\351\271\302\265\272\315\255\306\244" length(lShapes)))
      )
    )

    return(length(lLines) + length(lVias) + length(lShapes))
  )
)

;;=========================================================================
;; 创建 GUI 表单（临时表单文件写入系统临时目录）
;;=========================================================================

procedure( _AST_CreateDanglingForm(lData)
  prog((formFile formPort formHandle lLines lVias lShapes)

    lLines = car(lData)
    lVias = cadr(lData)
    lShapes = caddr(lData)

    formFile = strcat(axlTempDirectory() "/AST_DanglingForm.form")
    formPort = outfile(formFile "w")
    unless(formPort
      axlUIConfirm("\316\336\267\250\264\264\275\250\301\331\312\261\261\355\265\245\316\304\274\376\243\254\307\353\274\354\262\351\301\331\312\261\304\277\302\274\310\250\317\336")
      return(nil)
    )

    fprintf(formPort "FILE_TYPE=FORM_DEFN VERSION=2\n")
    fprintf(formPort "FORM\n")
    fprintf(formPort "FIXED\n")
    fprintf(formPort "PORT 50 50\n")
    fprintf(formPort "HEADER \"AST - \311\276\263\375\320\374\264\271\266\324\317\363\"\n")
    fprintf(formPort "TILE\n")

    fprintf(formPort "FIELD ddoRefresh\n")
    fprintf(formPort "FLOC 2 47\n")
    fprintf(formPort "MENUBUTTON \"\313\242\320\302(Refresh)\" 12 3\n")
    fprintf(formPort "ENDFIELD\n")

    fprintf(formPort "FIELD ddoHelp\n")
    fprintf(formPort "FLOC 18 47\n")
    fprintf(formPort "MENUBUTTON \"\260\357\326\372(Help)\" 10 3\n")
    fprintf(formPort "ENDFIELD\n")

    fprintf(formPort "FIELD ddoClose\n")
    fprintf(formPort "FLOC 34 47\n")
    fprintf(formPort "MENUBUTTON \"\271\330\261\325(Close)\" 10 3\n")
    fprintf(formPort "ENDFIELD\n")

    fprintf(formPort "TABSET tset\n")
    fprintf(formPort "FLOC 2 2\n")
    fprintf(formPort "FSIZE 46 44\n")

    fprintf(formPort "TAB \"\320\374\264\271\327\337\317\337 (%d)\"\n" length(lLines))
    fprintf(formPort "TEXT \"\320\374\264\271\327\337\317\337\301\320\261\355:\"\n")
    fprintf(formPort "TLOC 2 1\n")
    fprintf(formPort "ENDTEXT\n")
    fprintf(formPort "TEXT \"\n")
    fprintf(formPort "FLOC 16 1\n")
    fprintf(formPort "INFO ddoLineInfo 10\n")
    fprintf(formPort "ENDTEXT\n")
    fprintf(formPort "FIELD ddoLineList\n")
    fprintf(formPort "FLOC 2 3\n")
    fprintf(formPort "LIST \"\" 40 16\n")
    fprintf(formPort "OPTIONS multiselect\n")
    fprintf(formPort "ENDFIELD\n")
    fprintf(formPort "FIELD ddoLinesDel\n")
    fprintf(formPort "FLOC 16 34\n")
    fprintf(formPort "MENUBUTTON \"\311\276\263\375(Delete)\" 14 3\n")
    fprintf(formPort "ENDFIELD\n")
    fprintf(formPort "ENDTAB\n")

    fprintf(formPort "TAB \"\320\374\264\271\271\375\277\327 (%d)\"\n" length(lVias))
    fprintf(formPort "TEXT \"\320\374\264\271\271\375\277\327\301\320\261\355:\"\n")
    fprintf(formPort "TLOC 2 1\n")
    fprintf(formPort "ENDTEXT\n")
    fprintf(formPort "TEXT \"\n")
    fprintf(formPort "FLOC 16 1\n")
    fprintf(formPort "INFO ddoViaInfo 10\n")
    fprintf(formPort "ENDTEXT\n")
    fprintf(formPort "FIELD ddoViaList\n")
    fprintf(formPort "FLOC 2 3\n")
    fprintf(formPort "LIST \"\" 40 16\n")
    fprintf(formPort "OPTIONS multiselect\n")
    fprintf(formPort "ENDFIELD\n")
    fprintf(formPort "FIELD ddoViasDel\n")
    fprintf(formPort "FLOC 2 34\n")
    fprintf(formPort "MENUBUTTON \"\311\276\263\375(Delete)\" 14 3\n")
    fprintf(formPort "ENDFIELD\n")
    fprintf(formPort "FIELD ddoAssign\n")
    fprintf(formPort "FLOC 24 34\n")
    fprintf(formPort "MENUBUTTON \"\273\273\315\370\302\347(Change Net)\" 14 3\n")
    fprintf(formPort "ENDFIELD\n")
    fprintf(formPort "ENDTAB\n")

    fprintf(formPort "TAB \"\271\302\265\272\315\255\306\244 (%d)\"\n" length(lShapes))
    fprintf(formPort "TEXT \"\271\302\265\272\315\255\306\244\301\320\261\355:\"\n")
    fprintf(formPort "TLOC 2 1\n")
    fprintf(formPort "ENDTEXT\n")
    fprintf(formPort "TEXT \"\n")
    fprintf(formPort "FLOC 16 1\n")
    fprintf(formPort "INFO ddoShapeInfo 10\n")
    fprintf(formPort "ENDTEXT\n")
    fprintf(formPort "FIELD ddoShapeList\n")
    fprintf(formPort "FLOC 2 3\n")
    fprintf(formPort "LIST \"\" 40 16\n")
    fprintf(formPort "OPTIONS multiselect\n")
    fprintf(formPort "ENDFIELD\n")
    fprintf(formPort "FIELD ddoShapesDel\n")
    fprintf(formPort "FLOC 2 34\n")
    fprintf(formPort "MENUBUTTON \"\311\276\263\375(Delete)\" 12 3\n")
    fprintf(formPort "ENDFIELD\n")
    fprintf(formPort "FIELD ddoShapesVoid\n")
    fprintf(formPort "FLOC 18 34\n")
    fprintf(formPort "MENUBUTTON \"\315\332\277\325(Void)\" 12 3\n")
    fprintf(formPort "ENDFIELD\n")
    fprintf(formPort "ENDTAB\n")

    fprintf(formPort "ENDTABSET\n")
    fprintf(formPort "ENDTILE\n")
    fprintf(formPort "ENDFORM\n")

    close(formPort)

    formHandle = axlFormCreate((gensym) formFile '(e outer) '_AST_DanglingFormCallback t)
    unless(formHandle
      axlUIConfirm("\264\264\275\250\320\374\264\271\266\324\317\363\264\246\300\355\261\355\265\245\312\247\260\334")
      deleteFile(formFile)
      return(nil)
    )

    ;; 填充列表与计数
    axlFormSetField(formHandle "ddoLineList" lLines)
    axlFormSetField(formHandle "ddoViaList" lVias)
    axlFormSetField(formHandle "ddoShapeList" lShapes)
    axlFormSetField(formHandle "ddoLineInfo" length(lLines))
    axlFormSetField(formHandle "ddoViaInfo" length(lVias))
    axlFormSetField(formHandle "ddoShapeInfo" length(lShapes))

    ;; 计数标红提醒
    when(length(lLines) > 0
      axlFormColorize(formHandle "ddoLineInfo" 'text 'red)
    )
    when(length(lVias) > 0
      axlFormColorize(formHandle "ddoViaInfo" 'text 'red)
    )
    when(length(lShapes) > 0
      axlFormColorize(formHandle "ddoShapeInfo" 'text 'red)
    )

    ;; 表单已解析，删除临时文件
    unless(deleteFile(formFile)
      printf("[WARN] \311\276\263\375\301\331\312\261\261\355\265\245\316\304\274\376\312\247\260\334: %s\n" formFile)
    )

    return(formHandle)
  )
)

;;=========================================================================
;; 事务包装用辅助函数（经 ASTB_DBTransactionMark 调用，errset 错误捕获，
;; 保留 Allegro 原生 Ctrl+Z 撤销历史）
;;=========================================================================

procedure( _AST_DeleteObjects(lObjs)
  axlDeleteObject(lObjs)
)

procedure( _AST_CreateShapeVoid(dShape voidPoly)
  axlDBCreateVoid(dShape voidPoly)
)

;------------------------------------------------------------------------
; 函数名  : _AST_AssignViaNets
; 功能    : 在原地以新网络重建过孔并删除旧过孔（先建后删）
; 说明    : v1.2 起 lViaSpecs 为身份纯数据 (xy 焊盘名 旧网络名 层名)——
;           17.4 S039 跨交互轮 dbid 必失效（dbid:removed），逐条凭
;           (xy 焊盘名) 现场重解析旧孔、即用即弃
;           （via_changevianet v1.6 实证模式）
;------------------------------------------------------------------------
procedure( _AST_AssignViaNets(lViaSpecs sNet)
  prog((item xy sPad sOldNet sLayer dOld v sMessage lSysSave)
    lSysSave = axlVisibleGet()
    axlSetFindFilter(?enabled '("noall" "vias") ?onButtons '("vias"))
    foreach( item lViaSpecs
      xy = car(item)
      sPad = cadr(item)
      sOldNet = caddr(item)
      sLayer = cadddr(item)
      ;; 凭 (xy 焊盘名) 现场重解析旧孔；层不可见时临时打开 via class
      axlVisibleLayer(strcat("via class/" sLayer) t)
      dOld = nil
      axlClearSelSet()
      when( axlSingleSelectPoint(xy)
        foreach( v axlGetSelSet()
          when( null(dOld) && equal(v->name sPad)
            dOld = v
          )
        )
      )
      axlClearSelSet()
      if( null(dOld) then
        axlUIWPrint(nil "[AST] \271\375\277\327\326\330\275\342\316\366\312\247\260\334 @ %L\243\254\322\321\314\370\271\375" xy)
      else
        ;; 先建新孔，再删旧孔（同轮 dbid 仍有效，即用即弃）
        axlDBCloak('axlDBCreateVia(sPad xy sNet) 'shape)
        if( sOldNet then
          sMessage = sprintf(nil "[AST] \271\375\277\327\315\370\302\347\323\311 %s \270\304\316\252 %s" sOldNet sNet)
        else
          sMessage = sprintf(nil "[AST] \271\375\277\327\315\370\302\347\323\311 nil \270\304\316\252 %s" sNet)
        )
        axlMsgPut(sMessage)
        axlDeleteObject(dOld)
      )
      axlVisibleLayer(strcat("via class/" sLayer) nil)
    )
    axlVisibleSet(lSysSave)
  )
)

;------------------------------------------------------------------------
; 函数名  : _AST_VoidIslandFromDynamic
; 功能    : 从 dynamic 母铜皮中挖除孤岛铜皮并重建剩余全部铜皮块
; 说明    : axlPolyOperation 'ANDNOT 结果可能为多块（母铜皮被分裂），
;           必须全部重建；结果为空表示孤岛即整块母铜皮，直接删除即可
;------------------------------------------------------------------------
procedure( _AST_VoidIslandFromDynamic(dShape)
  prog((dVoidPoly dDynaShapePoly lNewPolys dNewPoly sNetName sShapeLayer dNewShape)
    dVoidPoly = car(axlPolyFromDB(dShape))
    dDynaShapePoly = car(axlPolyFromDB(dShape->shapeBoundary))
    lNewPolys = axlPolyOperation(dDynaShapePoly dVoidPoly 'ANDNOT)
    sNetName = dShape->net->name
    sShapeLayer = dShape->shapeBoundary->layer
    axlDeleteObject(dShape->shapeBoundary)
    ;; 遍历全部结果块重建；为空时即整块删除，无需重建
    foreach( dNewPoly lNewPolys
      dNewShape = car(axlDBCreateShape(dNewPoly t sShapeLayer sNetName))
      when( dNewShape
        axlShapeDynamicUpdate(dNewShape t)
      )
    )
    return(t)
  )
)

;;=========================================================================
;; GUI 表单回调
;;=========================================================================

procedure( _AST_DanglingFormCallback(form)
  prog((lData lLines lVias lShapes selItems lIssueObjs obj dVia dShape
        lCoord fCoordX fCoordY lClines lSeg lStartA lEndA lStartB lEndB
        sStartTempA sEndTempA sStartTempB sEndTempB sStart sEnd
        sLayer fStartX fStartY fEndX fEndY fFindRange
        lVia lShape sNet sMessage bDRC bDynFill lSys
        lDynCount lStaticCount lVoidCount voidPoly lViaSpecs nDelCnt)

    fFindRange = axlMKSConvert(1 "MILS")

    case(form->curField

      ;;-------------------------------------------------------------------
      ;; 刷新：重新检查并填充列表
      ;;-------------------------------------------------------------------
      ("ddoRefresh"
        axlClearSelSet()
        lData = _AST_DanglingCheck()
        g_DanglingData = lData
        lLines = car(lData)
        lVias = cadr(lData)
        lShapes = caddr(lData)

        ;; 清空并重新填充列表
        axlFormListDeleteAll(form "ddoLineList")
        axlFormListDeleteAll(form "ddoViaList")
        axlFormListDeleteAll(form "ddoShapeList")
        axlFormSetField(form "ddoLineList" lLines)
        axlFormSetField(form "ddoViaList" lVias)
        axlFormSetField(form "ddoShapeList" lShapes)
        axlFormSetField(form "ddoLineInfo" length(lLines))
        axlFormSetField(form "ddoViaInfo" length(lVias))
        axlFormSetField(form "ddoShapeInfo" length(lShapes))

        when(length(lLines) > 0
          axlFormColorize(form "ddoLineInfo" 'text 'red)
        )
        when(length(lVias) > 0
          axlFormColorize(form "ddoViaInfo" 'text 'red)
        )
        when(length(lShapes) > 0
          axlFormColorize(form "ddoShapeInfo" 'text 'red)
        )

        axlMsgPut("[AST] \313\242\320\302\315\352\263\311")
      )

      ;;-------------------------------------------------------------------
      ;; 走线列表 - 高亮定位
      ;;-------------------------------------------------------------------
      ("ddoLineList"
        selItems = axlFormListGetSelItems(form "ddoLineList")
        when(selItems
          axlClearSelSet()
          axlSetFindFilter(?enabled '("noall" "clines") ?onButtons '("clines"))
          axlVisibleDesign(nil)

          foreach(sline selItems
            lCoord = parseString(sline " ,()")
            sLayer = car(lCoord)
            fStartX = atof(nth(2 lCoord))
            fStartY = atof(nth(3 lCoord))
            fEndX = atof(nth(5 lCoord))
            fEndY = atof(nth(6 lCoord))

            axlVisibleLayer(strcat("etch/" sLayer) t)
            axlVisibleLayer(strcat("via class/" sLayer) t)
            axlVisibleLayer(strcat("pin/" sLayer) t)

            sStart = sprintf(nil "x%0.3fy%0.3f" fStartX fStartY)
            sEnd = sprintf(nil "x%0.3fy%0.3f" fEndX fEndY)

            lClines = axlGetSelSet(
              axlSingleSelectBox(
                list((fStartX - fFindRange):(fStartY - fFindRange)
                     (fStartX + fFindRange):(fStartY + fFindRange))
              )
            )
            axlClearSelSet()

            ;; 17.4 S039 跨交互轮 dbid 必失效：每轮重新收集、当轮即用，
            ;; 不跨迭代攒 dbid
            lIssueObjs = nil
            when(lClines
              foreach(cline lClines
                lSeg = cline->segments
                lStartA = car(car(lSeg)->startEnd)
                lEndA = cadr(car(last(lSeg))->startEnd)
                sStartTempA = sprintf(nil "x%0.3fy%0.3f" car(lStartA) cadr(lStartA))
                sEndTempA = sprintf(nil "x%0.3fy%0.3f" car(lEndA) cadr(lEndA))
                lStartB = car(car(last(lSeg))->startEnd)
                lEndB = cadr(car(lSeg)->startEnd)
                sStartTempB = sprintf(nil "x%0.3fy%0.3f" car(lStartB) cadr(lStartB))
                sEndTempB = sprintf(nil "x%0.3fy%0.3f" car(lEndB) cadr(lEndB))

                when((sStartTempA == sStart && sEndTempA == sEnd) ||
                     (sStartTempA == sEnd && sEndTempA == sStart) ||
                     (sStartTempB == sStart && sEndTempB == sEnd) ||
                     (sStartTempB == sEnd && sEndTempB == sStart)
                  lIssueObjs = cons(cline lIssueObjs)
                )
              )
            )
            ;; 本轮匹配到的走线当轮立即高亮
            when(lIssueObjs
              axlHighlightObject(lIssueObjs)
            )
          )
          ;; 仅末轮匹配结果的 dbid 仍存活，缩放定位到末项
          when(lIssueObjs
            axlZoomToDbid(lIssueObjs t)
          )
        )
      )

      ;;-------------------------------------------------------------------
      ;; 删除选中走线
      ;;-------------------------------------------------------------------
      ("ddoLinesDel"
        selItems = axlFormListGetSelItems(form "ddoLineList")
        when(selItems
          nDelCnt = 0
          foreach(sline selItems
            lCoord = parseString(sline " ,()")
            sLayer = car(lCoord)
            fStartX = atof(nth(2 lCoord))
            fStartY = atof(nth(3 lCoord))
            fEndX = atof(nth(5 lCoord))
            fEndY = atof(nth(6 lCoord))

            sStart = sprintf(nil "x%0.3fy%0.3f" fStartX fStartY)
            sEnd = sprintf(nil "x%0.3fy%0.3f" fEndX fEndY)

            lClines = axlGetSelSet(
              axlSingleSelectBox(
                list((fStartX - fFindRange):(fStartY - fFindRange)
                     (fStartX + fFindRange):(fStartY + fFindRange))
              )
            )
            axlClearSelSet()

            ;; 17.4 S039 跨交互轮 dbid 必失效：每轮重新收集、当轮即用，
            ;; 不跨迭代攒 dbid
            lIssueObjs = nil
            when(lClines
              foreach(cline lClines
                lSeg = cline->segments
                lStartA = car(car(lSeg)->startEnd)
                lEndA = cadr(car(last(lSeg))->startEnd)
                sStartTempA = sprintf(nil "x%0.3fy%0.3f" car(lStartA) cadr(lStartA))
                sEndTempA = sprintf(nil "x%0.3fy%0.3f" car(lEndA) cadr(lEndA))
                lStartB = car(car(last(lSeg))->startEnd)
                lEndB = cadr(car(lSeg)->startEnd)
                sStartTempB = sprintf(nil "x%0.3fy%0.3f" car(lStartB) cadr(lStartB))
                sEndTempB = sprintf(nil "x%0.3fy%0.3f" car(lEndB) cadr(lEndB))

                when((sStartTempA == sStart && sEndTempA == sEnd) ||
                     (sStartTempA == sEnd && sEndTempA == sStart) ||
                     (sStartTempB == sStart && sEndTempB == sEnd) ||
                     (sStartTempB == sEnd && sEndTempB == sStart)
                  lIssueObjs = cons(cline lIssueObjs)
                )
              )
            )
            ;; 本轮匹配到的走线当轮立即删除，不跨迭代攒 dbid
            when(lIssueObjs
              ASTB_DBTransactionMark('_AST_DeleteObjects list(lIssueObjs))
              nDelCnt = nDelCnt + length(lIssueObjs)
            )
          )

          when(nDelCnt > 0
            axlFormListDeleteItem(form "ddoLineList" selItems)
            axlFormSetField(form "ddoLineInfo"
              axlFormListGetCount(form "ddoLineList"))
            axlMsgPut("[AST] \320\374\264\271\327\337\317\337\322\321\311\276\263\375")
          )
        )
      )

      ;;-------------------------------------------------------------------
      ;; 过孔列表 - 高亮定位
      ;;-------------------------------------------------------------------
      ("ddoViaList"
        selItems = axlFormListGetSelItems(form "ddoViaList")
        when(selItems
          axlClearSelSet()
          axlSetFindFilter(?enabled '("noall" "vias") ?onButtons '("vias"))
          axlVisibleDesign(nil)

          foreach(svia selItems
            lCoord = parseString(svia " ,()")
            sLayer = car(lCoord)
            fCoordX = atof(nth(2 lCoord))
            fCoordY = atof(nth(3 lCoord))

            axlVisibleLayer(strcat("via class/" sLayer) t)
            axlVisibleLayer(strcat("etch/" sLayer) t)
            axlVisibleLayer(strcat("pin/" sLayer) t)

            dVia = car(axlGetSelSet(axlSingleSelectPoint(fCoordX:fCoordY)))
            axlClearSelSet()
            ;; 17.4 S039 跨交互轮 dbid 必失效：当轮解析到当轮
            ;; 高亮/缩放，不跨迭代攒 dbid
            when(dVia
              axlHighlightObject(dVia)
              axlZoomToDbid(dVia t)
            )
          )
        )
      )

      ;;-------------------------------------------------------------------
      ;; 删除选中过孔
      ;;-------------------------------------------------------------------
      ("ddoViasDel"
        bDRC = axlDBControl('drcEnable nil)
        bDynFill = axlDBControl('dynamicFillMode nil)

        selItems = axlFormListGetSelItems(form "ddoViaList")
        when(selItems
          nDelCnt = 0
          lSys = axlVisibleGet()
          axlVisibleDesign(nil)

          foreach(svia selItems
            lCoord = parseString(svia " ,()")
            sLayer = car(lCoord)
            fCoordX = atof(nth(2 lCoord))
            fCoordY = atof(nth(3 lCoord))

            axlVisibleLayer(strcat("via class/" sLayer) t)
            dVia = car(axlGetSelSet(axlSingleSelectPoint(fCoordX:fCoordY)))
            axlClearSelSet()
            ;; 17.4 S039 跨交互轮 dbid 必失效：当轮解析到当轮删除，
            ;; 不跨迭代攒 dbid
            when(dVia
              ASTB_DBTransactionMark('_AST_DeleteObjects list(dVia))
              nDelCnt = nDelCnt + 1
            )
            axlVisibleLayer(strcat("via class/" sLayer) nil)
          )

          when(nDelCnt > 0
            axlFormListDeleteItem(form "ddoViaList" selItems)
            axlFormSetField(form "ddoViaInfo"
              axlFormListGetCount(form "ddoViaList"))
            axlMsgPut("[AST] \320\374\264\271\271\375\277\327\322\321\311\276\263\375")
          )
          axlVisibleSet(lSys)
        )

        axlDBControl('drcEnable bDRC)
        axlDBControl('dynamicFillMode bDynFill)
      )

      ;;-------------------------------------------------------------------
      ;; 换网络：选中过孔后在画布点选目标网络
      ;;-------------------------------------------------------------------
      ("ddoAssign"
        bDRC = axlDBControl('drcEnable nil)
        bDynFill = axlDBControl('dynamicFillMode nil)

        selItems = axlFormListGetSelItems(form "ddoViaList")
        if(selItems then
          lViaSpecs = nil
          lSys = axlVisibleGet()
          axlVisibleDesign(nil)

          foreach(svia selItems
            lCoord = parseString(svia " ,()")
            sLayer = car(lCoord)
            fCoordX = atof(nth(2 lCoord))
            fCoordY = atof(nth(3 lCoord))

            axlVisibleLayer(strcat("via class/" sLayer) t)
            dVia = car(axlGetSelSet(axlSingleSelectPoint(fCoordX:fCoordY)))
            axlClearSelSet()
            ;; 17.4 S039 跨交互轮 dbid 必失效：当轮立即把过孔身份信息
            ;; (xy 焊盘名 旧网络名 层名) 存成纯数据，事后凭 (xy 焊盘名)
            ;; 现场重解析再删建（via_changevianet v1.6 实证模式）
            when(dVia
              lViaSpecs = cons(list(fCoordX:fCoordY dVia->name dVia->net->name sLayer)
                lViaSpecs)
            )
            axlVisibleLayer(strcat("via class/" sLayer) nil)
          )

          axlVisibleSet(lSys)
          axlMsgPut("[AST] \307\353\324\332\273\255\262\274\326\320\265\343\321\241\304\277\261\352\315\370\302\347")
          axlSetFindFilter(?enabled '("noall" "nets") ?onButtons '("nets"))

          if(axlSingleSelectPoint() then
            sNet = car(axlGetSelSet())->name
            axlClearSelSet()

            ASTB_DBTransactionMark('_AST_AssignViaNets list(lViaSpecs sNet))

            axlFormListDeleteItem(form "ddoViaList" selItems)
            axlFormSetField(form "ddoViaInfo"
              axlFormListGetCount(form "ddoViaList"))
          else
            axlMsgPut("[AST] \316\264\321\241\324\361\315\370\302\347\243\254\267\305\306\372\320\336\270\304")
          )
        else
          axlUIConfirm("\307\353\317\310\324\332\301\320\261\355\326\320\321\241\324\361\266\324\317\363")
        )

        axlDBControl('drcEnable bDRC)
        axlDBControl('dynamicFillMode bDynFill)
      )

      ;;-------------------------------------------------------------------
      ;; 铜皮列表 - 高亮定位
      ;;-------------------------------------------------------------------
      ("ddoShapeList"
        selItems = axlFormListGetSelItems(form "ddoShapeList")
        when(selItems
          axlClearSelSet()
          axlSetFindFilter(?enabled '("noall" "shapes") ?onButtons '("shapes"))
          axlVisibleDesign(nil)

          foreach(sshape selItems
            lCoord = parseString(sshape " ,()")
            sLayer = car(lCoord)
            fCoordX = atof(nth(2 lCoord))
            fCoordY = atof(nth(3 lCoord))

            axlVisibleLayer(strcat("via class/" sLayer) t)
            axlVisibleLayer(strcat("etch/" sLayer) t)
            axlVisibleLayer(strcat("pin/" sLayer) t)

            dShape = car(axlGetSelSet(axlSingleSelectPoint(fCoordX:fCoordY)))
            axlClearSelSet()
            ;; 17.4 S039 跨交互轮 dbid 必失效：当轮解析到当轮
            ;; 高亮/缩放，不跨迭代攒 dbid
            when(dShape
              axlHighlightObject(dShape)
              axlZoomToDbid(dShape t)
            )
          )
        )
      )

      ;;-------------------------------------------------------------------
      ;; 删除选中铜皮：static 批量删 / dynamic 参考 FanySkill 挖除孤岛
      ;;-------------------------------------------------------------------
      ("ddoShapesDel"
        axlMsgPut("[AST] \262\316\277\274 FanySkill \267\275\312\275\311\276\263\375/\315\332\263\375\315\255\306\244...")
        bDRC = axlDBControl('drcEnable nil)
        bDynFill = axlDBControl('dynamicFillMode nil)

        selItems = axlFormListGetSelItems(form "ddoShapeList")
        if(selItems then
          lShape = nil
          lDynCount = 0
          lStaticCount = 0
          lSys = axlVisibleGet()
          axlVisibleDesign(nil)

          foreach(sshape selItems
            lCoord = parseString(sshape " ,()")
            sLayer = car(lCoord)
            fCoordX = atof(nth(2 lCoord))
            fCoordY = atof(nth(3 lCoord))

            axlVisibleLayer(strcat("via class/" sLayer) t)
            axlVisibleLayer(strcat("etch/" sLayer) t)
            axlVisibleLayer(strcat("pin/" sLayer) t)

            dShape = car(axlGetSelSet(axlSingleSelectPoint(fCoordX:fCoordY)))
            axlClearSelSet()
            when(dShape
              if(dShape->shapeBoundary then
                ;; Dynamic 铜皮：挖除孤岛并重建全部结果块（事务包装）
                when(ASTB_DBTransactionMark('_AST_VoidIslandFromDynamic list(dShape))
                  lDynCount = lDynCount + 1
                )
              else
                ;; Static 铜皮：当轮解析到当轮立即删除（17.4 跨轮 dbid 必失效）
                ASTB_DBTransactionMark('_AST_DeleteObjects list(dShape))
                lStaticCount = lStaticCount + 1
              )
            )
            axlVisibleLayer(strcat("etch/" sLayer) nil)
          )

          axlFormListDeleteItem(form "ddoShapeList" selItems)
          axlFormSetField(form "ddoShapeInfo"
            axlFormListGetCount(form "ddoShapeList"))
          axlMsgPut(sprintf(nil "[AST] \322\321\311\276\263\375 %d \277\351 static + %d \277\351 dynamic \271\302\265\272\315\255\306\244"
            lStaticCount lDynCount))
          axlVisibleSet(lSys)
          axlFlushDisplay()
        else
          axlUIConfirm("\307\353\317\310\324\332\301\320\261\355\326\320\321\241\324\361\266\324\317\363")
        )

        axlDBControl('drcEnable bDRC)
        axlDBControl('dynamicFillMode bDynFill)
      )

      ;;-------------------------------------------------------------------
      ;; 挖空选中 dynamic 铜皮（在孤岛中心创建矩形 void）
      ;;-------------------------------------------------------------------
      ("ddoShapesVoid"
        bDRC = axlDBControl('drcEnable nil)
        bDynFill = axlDBControl('dynamicFillMode nil)

        selItems = axlFormListGetSelItems(form "ddoShapeList")
        if(selItems then
          lVoidCount = 0
          lSys = axlVisibleGet()
          axlVisibleDesign(nil)

          foreach(sshape selItems
            lCoord = parseString(sshape " ,()")
            sLayer = car(lCoord)
            fCoordX = atof(nth(2 lCoord))
            fCoordY = atof(nth(3 lCoord))

            axlVisibleLayer(strcat("via class/" sLayer) t)
            axlVisibleLayer(strcat("etch/" sLayer) t)
            axlVisibleLayer(strcat("pin/" sLayer) t)

            dShape = car(axlGetSelSet(axlSingleSelectPoint(fCoordX:fCoordY)))
            axlClearSelSet()
            when(dShape
              when(dShape->shapeType == "DYNAMIC" || dShape->shapeAuto
                ;; 以孤岛中心创建矩形 void
                voidPoly = list(
                  list((fCoordX - 5.0):(fCoordY - 5.0)
                       (fCoordX + 5.0):(fCoordY - 5.0)
                       (fCoordX + 5.0):(fCoordY + 5.0)
                       (fCoordX - 5.0):(fCoordY + 5.0))
                )
                ASTB_DBTransactionMark('_AST_CreateShapeVoid list(dShape voidPoly))
                lVoidCount = lVoidCount + 1
              )
            )
            axlVisibleLayer(strcat("etch/" sLayer) nil)
          )

          when(lVoidCount > 0
            axlFormListDeleteItem(form "ddoShapeList" selItems)
            axlFormSetField(form "ddoShapeInfo"
              axlFormListGetCount(form "ddoShapeList"))
            axlMsgPut(sprintf(nil "[AST] \322\321\266\324 %d \277\351 dynamic \271\302\265\272\315\255\306\244\264\264\275\250 void" lVoidCount))
          )
          axlVisibleSet(lSys)
          axlFlushDisplay()
        else
          axlUIConfirm("\307\353\317\310\324\332\301\320\261\355\326\320\321\241\324\361\266\324\317\363")
        )

        axlDBControl('drcEnable bDRC)
        axlDBControl('dynamicFillMode bDynFill)
      )

      ;;-------------------------------------------------------------------
      ;; 关闭
      ;;-------------------------------------------------------------------
      ("ddoClose"
        axlFormClose(form)
        axlClearSelSet()
        axlFlushDisplay()
        axlEndSkillMode()
        axlMsgPut("[AST] \262\331\327\367\315\352\263\311\243\254\307\353\270\374\320\302 DRC \262\242\313\242\320\302\315\255\306\244")
      )

      ;;-------------------------------------------------------------------
      ;; 帮助（单串显示，避免 axlUIConfirm 多参数崩溃）
      ;;-------------------------------------------------------------------
      ("ddoHelp"
        axlUIConfirm(strcat(
          "AST - \311\276\263\375\320\374\264\271\266\324\317\363 \260\357\326\372\n"
          "\n"
          "\271\246\304\334\313\265\303\367:\n"
          "  \274\354\262\351\262\242\264\246\300\355\320\374\264\271\327\337\317\337\241\242\320\374\264\271\271\375\277\327\323\353\271\302\265\272\315\255\306\244\241\243\n"
          "\n"
          "\262\331\327\367\262\275\326\350:\n"
          "  1. \324\332\301\320\261\355\326\320\321\241\324\361\322\252\264\246\300\355\265\304\266\324\317\363\243\250\277\311\266\340\321\241\243\251\n"
          "  2. \321\241\326\320\272\363\265\343\273\367 Delete \311\276\263\375\327\337\317\337/\271\375\277\327/\315\255\306\244\n"
          "  3. \321\241\326\320\271\375\277\327\272\363\277\311\323\303 Change Net \270\374\273\273\315\370\302\347\n"
          "  4. dynamic \271\302\265\272\315\255\306\244\277\311\323\303 Void \267\275\312\275\315\332\263\375\n"
          "  5. \265\343\273\367 Refresh \326\330\320\302\274\354\262\351\n"
          "  6. \265\343\273\367 Close \315\313\263\366\n"
          "\n"
          "\327\242\322\342\312\302\317\356:\n"
          "  - \311\276\263\375\307\260\307\353\317\310\261\243\264\346\311\350\274\306\n"
          "  - \262\331\327\367\315\352\263\311\272\363\307\353\270\374\320\302 DRC \262\242\313\242\320\302\315\255\306\244\n"
          "  - dynamic \315\255\306\244\304\254\310\317\322\324\315\332\277\325(void)\267\275\312\275\264\246\300\355"
        ))
      )
    )
  )
)

;;=========================================================================
;; 功能    : 检查全板悬垂对象
;; 返回值  : list(lDanglingLines lDanglingVias lIslandShapes)
;;           列表元素为显示字符串: "layer, net, x,y" 或 "layer, net, x,y to x,y"
;;=========================================================================

procedure( _AST_DanglingCheck()
  prog((lClines lVias lShapes lDanglingLines lDanglingVias lIslandShapes
        sNet sLine sVia sShape bIgnore net branch obj)

    lDanglingLines = nil
    lDanglingVias = nil
    lIslandShapes = nil

    ;; 检查悬垂走线：连接数 < 2 且非 Fillet/封装内走线
    axlClearSelSet()
    axlSetFindFilter(?enabled '("noall" "invisible" "clines") ?onButtons '("clines"))
    axlAddSelectAll()
    lClines = axlGetSelSet()
    axlClearSelSet()

    foreach(cline lClines
      when(length(axlDBGetConnect(cline t)) < 2
        unless(cline->prop->FILLET || cline->symbolEtch
          if(cline->net then
            sNet = cline->net->name
          else
            sNet = "Dummy"
          )
          sLine = sprintf(nil "%s, %s, %L to %L"
            cadr(parseString(cline->layer "/"))
            sNet
            car(car(cline->segments)->startEnd)
            cadr(car(last(cline->segments))->startEnd)
          )
          lDanglingLines = cons(sLine lDanglingLines)
        )
      )
    )
    lDanglingLines = reverse(sort(lDanglingLines nil))

    ;; 检查悬垂过孔：连接数 0 或 1，排除测试点/_VOID/封装内过孔
    axlClearSelSet()
    axlSetFindFilter(?enabled '("noall" "invisible" "vias") ?onButtons '("vias"))
    axlAddSelectAll()
    lVias = axlGetSelSet()
    axlClearSelSet()

    foreach(via lVias
      unless(via->symbolEtch
        bIgnore = nil
        if(via->net then
          sNet = via->net->name
          when(rexMatchp("^SNN_" sNet)
            bIgnore = t
          )
        else
          sNet = "Dummy"
        )

        sVia = sprintf(nil "%s, %s, %L"
          cadr(parseString(car(via->startEnd) "/"))
          sNet
          via->xy
        )

        unless(bIgnore
          when(onep(length(axlDBGetConnect(via t)))
            unless(via->testPoint || rexMatchp("_VOID$" via->name)
              lDanglingVias = cons(sVia lDanglingVias)
            )
          )
          when(zerop(length(axlDBGetConnect(via t)))
            unless(via->testPoint || rexMatchp("_VOID$" via->name)
              lDanglingVias = cons(sVia lDanglingVias)
            )
          )
        )
      )
    )
    lDanglingVias = reverse(sort(lDanglingVias nil))

    ;; 检查孤岛铜皮：连接数 < 2，排除封装内(symbolEtch)铜皮
    lShapes = axlDBGetShapes("etch")
    foreach(shape lShapes
      when(length(axlDBGetConnect(shape t)) < 2
        unless(shape->symbolEtch
          sNet = "Dummy"
          when(shape->net && shape->net->name != ""
            sNet = shape->net->name
          )
          sShape = sprintf(nil "%s, %s, %L"
            cadr(parseString(shape->layer "/"))
            sNet
            car(car(shape->segments)->startEnd)
          )
          lIslandShapes = cons(sShape lIslandShapes)
        )
      )
    )

    ;; 补充检测（源自旧版 EDA365 实现）：同一网络存在多个连接分支时，
    ;; 非主分支上的铜皮为被分割出的孤岛
    foreach(net axlDBGetDesign()->nets
      when(net->nBranches > 1
        foreach(branch cdr(net->branches)
          foreach(obj branch->children
            when(obj->objType == "shape"
              sShape = sprintf(nil "%s, %s, %L"
                cadr(parseString(obj->layer "/"))
                net->name
                car(car(obj->segments)->startEnd)
              )
              unless(member(sShape lIslandShapes)
                lIslandShapes = cons(sShape lIslandShapes)
              )
            )
          )
        )
      )
    )
    lIslandShapes = reverse(sort(lIslandShapes nil))

    return(list(lDanglingLines lDanglingVias lIslandShapes))
  )
)

ASTB_RegisterCommand("ASTB_Route_DeleteDangling" "ASTB_Route_DeleteDangling" ?cmdType "interactive")

printf("[ASTB] route_deletedangling.il loaded.\n")
