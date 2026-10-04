;========================================================================
; 文件名    : util_assembly.il
; 作者      : Pete Court (Modified by RBG)
; 创建日期  : 2004-05-05
; 版本      : 2.1
; 功能描述  : 自动生成Assembly装配图参考位号，将Refdes添加到Package
;             Geometry/Display_Top层
; 依赖模块  : core/trans.il (ASTB_DBTransactionMark)
; 警告      : 本命令会先永久删除 PACKAGE GEOMETRY/DISPLAY_TOP 层上的
;             全部已有 text，再重新创建位号文本！运行前会弹出确认框；
;             若该层另有用途，请勿执行或先备份设计。
; 修改记录  :
;   2004-05-05 v2.0 Pete Court (Modified by RBG) 初始创建
;   2026 v2.1 修复组 删除操作前加用户确认、命令入口包
;             ASTB_DBTransactionMark（数据库操作进入标准撤销历史，
;             ?undo t 因此真正有效）、全部裸全局变量局部化、
;             makeTable 表名笔误 retfable→reftable、无 refdes 的
;             symbol 显式过滤、删除/建文本检查返回值并计数汇报、
;             注册补 ?cmdType "interactive"
;========================================================================
;                Add Assembly Reference Designators
;                ----------------------------------

; This routine adds reference designator text to Package Geometry/
; Display_Top. The designators are positioned to be at the centre
; of the Place_Bound_Top rectangle(s) for each component. If the
; component is rotated so that the width is less than 129 mils
; (or it's equivalent in the current database units) the text is
; rotated to achieve a better fit. This will make the assembly
; drawing easier to read than having text at all four rotations.

; Any text already on the Package Geometry/Display_Top layer is
; deleted, so if this layer is used, modify the routine to add the
; text to an unused layer.

; It doesn't matter what units the database is in, because all
; numbers are converted at the start of the routine to the current
; database units.

; Text Block 2 is used, which is assumed to be set to 25 35 75 8 8
; (mils). If the text width and height are substantially different
; to this, the output may appear distorted.

; To run the program type "assembly" on the Allegro command line.

; -----------------------------------------------------------------
; Tested on Allegro 110 / 15.1 (历史声明；16.6/17.4/24.1 待实机验证)
; Written by: Pete Court  (Modified by RBG 05-05-2004)
; -----------------------------------------------------------------

;------------------------------------------------------------------------
; 函数名  : assembly
; 功能    : 删除 DISPLAY_TOP 全部文本后，按 Place_Bound_Top 中心重建
;           装配位号文本（宽>129mil 用 0°，否则 270°）
; 返回值  : t 完成
; 副作用  : 修改设计数据库（删除+创建 text）；调用方负责确认与事务
;------------------------------------------------------------------------
procedure( assembly()
    prog((min_width text_offset reftable rotate_no rotate_yes
          vis_list symbol_db_list refdes mir children_db_list
          isShape shape_layer boundary ref_exists old_boundary
          old_llx old_urx old_ury old_lly llx urx ury lly
          width height refpos_x refpos_y refpos result
          del_list del_ok create_ok create_fail)

        ; converts to current database units
        ; ----------------------------------

        min_width = axlMKSConvert(129 "MILS")
        text_offset = axlMKSConvert(18 "MILS")

        ; creates table
        ; -------------

        reftable = makeTable("reftable" nil)

        ; defines text blocks
        ; -------------------

        rotate_no = make_axlTextOrientation(
                        ?textBlock "2", ?rotation 0.,
                        ?mirrored nil, ?justify "center")
        rotate_yes = make_axlTextOrientation(
                        ?textBlock "2", ?rotation 270.,
                        ?mirrored nil, ?justify "center")

        ; deletes text on package geometry/display_top
        ; --------------------------------------------

        drain()
        axlClearSelSet()
        vis_list = axlVisibleGet()
        axlVisibleDesign(nil)
        axlVisibleLayer("PACKAGE GEOMETRY/DISPLAY_TOP" t)
        axlSetFindFilter(?enabled list("noall" "text")
                ?onButtons list("noall" "text"))
        axlAddSelectAll()
        del_list = axlGetSelSet()
        del_ok = 0
        when( del_list
            result = axlDeleteObject(del_list)
            when( result
                del_ok = if( listp(result) then length(result) else 1 )
            )
        )

        ; selects symbols
        ; ---------------

        axlClearSelSet()
        axlVisibleDesign(nil)
        axlVisibleLayer("PACKAGE GEOMETRY/ASSEMBLY_TOP" t)
        axlSetFindFilter(?enabled list("noall" "symbols")
                ?onButtons list("noall" "symbols"))
        axlAddSelectAll()
        axlVisibleSet(vis_list)
        symbol_db_list = axlGetSelSet()
        axlClearSelSet()
        create_ok = 0
        create_fail = 0
        foreach(symbol_db symbol_db_list
            refdes = symbol_db->refdes
            mir = symbol_db->isMirrored

            ; checks if symbol is mirrored; skips symbol without refdes
            ; ---------------------------------------------------------

            when( and(refdes eq(mir nil))
                children_db_list = symbol_db->children

                ; checks if symbol has attached shapes
                ; ------------------------------------

                when( neq(children_db_list nil)
                    foreach(children_db children_db_list
                        isShape = children_db->objType
                        shape_layer = children_db->layer
                        when( and(equal(isShape "shape")
                                  equal(shape_layer "PACKAGE GEOMETRY/PLACE_BOUND_TOP"))
                            boundary = children_db->bBox
                            ref_exists = reftable[refdes]

                            ; checks if shape already exists for refdes
                            ; -----------------------------------------

                            if( equal(ref_exists nil) then

                                ; adds refdes/boundary box to table
                                ; ---------------------------------

                                reftable[refdes] = boundary
                            else

                                ; calculates maximum size box
                                ; ----------------------------

                                old_boundary = reftable[refdes]
                                old_llx = caar(old_boundary)
                                old_urx = caadr(old_boundary)
                                old_ury = cadadr(old_boundary)
                                old_lly = cadar(old_boundary)
                                boundary = children_db->bBox
                                llx = caar(boundary)
                                urx = caadr(boundary)
                                ury = cadadr(boundary)
                                lly = cadar(boundary)
                                llx = min(llx old_llx)
                                urx = max(urx old_urx)
                                ury = max(ury old_ury)
                                lly = min(lly old_lly)
                                boundary = list(llx:lly urx:ury)
                                reftable[refdes] = boundary
                            ) ; end of if ref exists
                        ) ; end of shape on place_bound_top
                    ) ; end of foreach children_db
                ) ; end of if children
            ) ; end of refdes/mir check
        ) ; end of foreach symbol_db

        ; reads each refdes/boundary box pair
        ; -----------------------------------

        foreach( refdes reftable
            when( neq(refdes nil)
                boundary = reftable[refdes]
                llx = caar(boundary)
                urx = caadr(boundary)
                ury = cadadr(boundary)
                lly = cadar(boundary)
                width = urx-llx
                refpos_x = (width/2)+llx
                height = ury-lly
                refpos_y = (height/2)+lly

                ; if width > 129 mils text is at 0 degrees
                ; ----------------------------------------

                if( width > min_width then
                    refpos_y = refpos_y - text_offset
                    refpos = refpos_x:refpos_y
                    result = axlDBCreateText(refdes refpos rotate_no
                                    "package geometry/display_top")
                else

                ; if width <= 129 mils text is at 270 degrees
                ; -------------------------------------------

                    refpos_x = refpos_x - text_offset
                    refpos = refpos_x:refpos_y
                    result = axlDBCreateText(refdes refpos rotate_yes
                                    "package geometry/display_top")
                )
                if( and(result car(result)) then
                    create_ok = create_ok + 1
                else
                    create_fail = create_fail + 1
                )
            ) ; end of if refdes
        ) ; end of foreach refdes

        printf("[ASTB] assembly: deleted %d text(s), created %d, failed %d.\n"
            del_ok create_ok create_fail)

        ; 恢复可见性后，确保结果层处于打开状态（RBG 修改，刻意保留）
        axlVisibleLayer("PACKAGE GEOMETRY/DISPLAY_TOP" t)
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_AssemblyCmd
; 功能    : assembly 命令入口：用户确认 + ASTB_DBTransactionMark 包装。
;           ASTB_DBTransactionMark 仅用 errset 捕获错误，数据库操作
;           直接进入 Allegro 标准撤销历史，?undo t 因此有效。
;------------------------------------------------------------------------
procedure( ASTB_AssemblyCmd()
    prog(()
        unless( axlDBGetDesign()
            axlUIConfirm("No design open.")
            return(nil)
        )
        unless( axlUIConfirm(
            "assembly will DELETE all text on PACKAGE GEOMETRY/DISPLAY_TOP,\n"
            + "then recreate assembly refdes text.\n\nContinue?")
            printf("assembly cancelled by user.\n")
            return(nil)
        )
        return(ASTB_DBTransactionMark('assembly nil))
    )
)

; registers command assembly with Allegro
; ---------------------------------------

axlCmdRegister( "assembly" 'ASTB_AssemblyCmd ?cmdType "interactive")
