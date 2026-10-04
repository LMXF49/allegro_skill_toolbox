;========================================================================
; 文件名    : modules/manufacturing/mfg_exportdocs.il
; 作者      : ASTB Team
; 创建日期  : 2026-10-04
; 版本      : 0.1
; 功能描述  : PCB 生产文档一键导出（PDF 装配图 / DXF 结构图 / STEP-IDF
;             3D 模型）参数设置基座。参数默认值综合来源：
;             a) 凡亿 Fanyskill 导出 DXF 和 3D 文件清单（EET-China
;                a422747, 2025-07）：STEP 单位 Millimeter、协议 AP-214、
;                有/无 3D 模型器件都出、机械孔出、电气孔只 Pins 不出
;                Vias、External copper/Bare board/zip 不出；IDF 文件名
;                类型 PTC、默认封装高度 20mil(<=1mm)；DXF 单位 MM；
;             b) 凡亿导出 PDF 清单（eefocus 1865525）：默认 PCB 旁出件、
;                黑白输出选项；
;             c) 本仓 house 经验：临时目录纪律、版本门控。
;             v0.1 只交付参数系统(Get/Set/默认表/命令行打印/自检)与
;             film pdf 域规范化(为 PDF 通路预备, 依据 17.4 手册 film
;             记录 domains 支持 pdf + sequence 决定 PDF 页序)；
;             导出通路(表单 + 宏回放)留 v0.2+。
; 依赖模块  : core/utils.il、core/trans.il
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-10-04 v0.1 ASTB Team 参数基座：参数总表 g_EDocParamDefs 三组
;             格式 + 输出规则, EDoc_GetParam/EDoc_SetParam/EDoc_Cmd/
;             EDoc_SLFTEST; film pdf 域规范化 EDoc_NormalizeFilmPdf
; 实机待验证:
;   1) film 记录 domains/sequence 的 axlGetParam/axlSetParam 读写
;      (17.4 手册 02 章 film 记录, 16.6 行为未验)
;   2) PDF 导出的 shell 命令/表单名 (17.4 手册无产品命令层文档,
;      v0.2 通路实机探测, 参照 downrev 模块宏回放纪律)
;   3) STEP 导出 24.1 新 3D UI 与旧表单差异 (Cadence 社区 64671)
;========================================================================

;------------------------------------------------------------------------
; 参数项: '(键 默认值 说明)  —— 三组格式 + 输出规则
; 说明: 布尔值为 t/nil; 层清单为 "CLASS/SUBCLASS" 空格分隔串
;------------------------------------------------------------------------
defvar(g_EDocParamDefs nil)
g_EDocParamDefs = list(
    ; ---- DXF 结构图 ----
    '("dxf.units"          "MM"      "DXF 单位: MM/INCHES/MILS/CM/MICRONS")
    '("dxf.mirror_bottom"  t         "底层输出镜像(凡亿推荐; 亦可 CAD 侧镜像)")
    '("dxf.top_layers"     "BOARD GEOMETRY/OUTLINE BOARD GEOMETRY/SILKSCREEN_TOP PACKAGE GEOMETRY/SILKSCREEN_TOP BOARD GEOMETRY/ASSEMBLY_TOP PACKAGE GEOMETRY/ASSEMBLY_TOP"
                           "顶层 DXF 层清单")
    '("dxf.bottom_layers"  "BOARD GEOMETRY/OUTLINE BOARD GEOMETRY/SILKSCREEN_BOTTOM PACKAGE GEOMETRY/SILKSCREEN_BOTTOM BOARD GEOMETRY/ASSEMBLY_BOTTOM PACKAGE GEOMETRY/ASSEMBLY_BOTTOM"
                           "底层 DXF 层清单")
    '("dxf.separate_sides" t         "顶层/底层分文件输出")
    ; ---- STEP 3D ----
    '("step.units"         "Millimeter" "STEP 单位: Micron/Inch/Millimeter(凡亿建议 Millimeter)")
    '("step.protocol"      "AP-214"  "STEP 协议: AP-203/AP-214/AP-242(凡亿建议 AP-214)")
    '("step.with_model"    t         "有 3D 模型器件输出(须库挂 STEP 模型)")
    '("step.without_model" t         "无 3D 模型器件出占位")
    '("step.mech_holes"    t         "机械孔(无电气连接)输出")
    '("step.elec_pins"     t         "电气孔: 焊盘 Pins 输出")
    '("step.elec_vias"     nil       "电气孔: 过孔 Vias 不输出(凡亿建议)")
    '("step.ext_copper"    nil       "外部铜(走线/焊盘/铜皮)不输出")
    '("step.bare_board"    nil       "裸板不输出")
    '("step.zip"           nil       "压缩输出不开")
    ; ---- IDF(emn/emp, SolidWorks/ProE 可读) ----
    '("idf.name_type"      "PTC"     "IDF 文件名类型: IDF/PTC/SDRC(凡亿建议 PTC)")
    '("idf.default_height" "20mil"   "无 3D 模型器件默认高度(<=1mm)")
    ; ---- PDF 装配图 ----
    '("pdf.black_white"    t         "黑白输出(t=黑底白图/凡亿勾选项; nil=彩色)")
    '("pdf.scale"          "1:1"     "打印比例")
    '("pdf.mirror_bottom"  t         "底层装配图镜像")
    '("pdf.films_top"      "SILKSCREEN_TOP ASSEMBLY_TOP OUTLINE"
                           "顶层装配图底片组合(空格分隔 film 名)")
    '("pdf.films_bottom"   "SILKSCREEN_BOTTOM ASSEMBLY_BOTTOM OUTLINE"
                           "底层装配图底片组合")
    ; ---- 输出规则 ----
    '("out.root_mode"      "sibling" "输出根目录: sibling=PCB 同级/<板名>_export")
    '("out.make_subdir"    t         "自动建 DXF/3D/PDF 分类子目录")
)

defvar(g_EDocParamTable nil)

;------------------------------------------------------------------------
; 函数名  : EDoc_InitParams
; 功能    : 首次加载按默认表建参数表(显式 nil 默认值, 无缺键 unbound
;           哨兵问题; 已有键不覆盖, Reload 安全)
;------------------------------------------------------------------------
procedure( EDoc_InitParams()
    unless( g_EDocParamTable
        g_EDocParamTable = makeTable("EDocParam" nil)
    )
    foreach( item g_EDocParamDefs
        when( null(g_EDocParamTable[car(item)])
            g_EDocParamTable[car(item)] = cadr(item)
        )
    )
    t
)

;------------------------------------------------------------------------
; 函数名  : EDoc_GetParam
; 功能    : 取参数(表默认 nil, 直接索引即安全)
;------------------------------------------------------------------------
procedure( EDoc_GetParam(key)
    g_EDocParamTable[key]
)

;------------------------------------------------------------------------
; 函数名  : EDoc_SetParam
; 功能    : 设参数并返回新值
;------------------------------------------------------------------------
procedure( EDoc_SetParam(key value)
    g_EDocParamTable[key] = value
)

;------------------------------------------------------------------------
; 函数名  : EDoc_NormalizeFilmPdf
; 功能    : 规范化全部底片的 PDF 域与页序(依据 17.4 手册 film 记录:
;           domains 支持 pdf, sequence 0-255 决定 PDF 页序);
;           只补缺失/非法项, 不动用户既有合法页序
; 返回值  : 规范化数量 / 出错 nil
; 实机待验证: film 字段读写行为见文件头第 1) 条
;------------------------------------------------------------------------
procedure( EDoc_NormalizeFilmPdf()
    prog((art films n rec r domains seq)
        n = 0
        r = errset(art = axlGetParam("artwork") t)
        unless( and(r car(r)) return(nil) )
        films = art->groupMembers
        unless( films return(0) )
        foreach( fname films
            rec = errset(axlGetParam(strcat("artwork:" fname)) t)
            when( and(rec car(rec))
                rec = car(rec)
                ;; domains: 补 pdf 域
                domains = errset(rec->domains t)
                when( and(domains car(domains) listp(car(domains)))
                    domains = car(domains)
                    unless( member("pdf" domains)
                        rec->domains = append1(domains "pdf")
                        n = n+1
                    )
                )
                ;; sequence: 只在缺失/越界时按库序补 1..255
                seq = errset(rec->sequence t)
                unless( and(seq car(seq) numberp(car(seq))
                            car(seq) >= 0 car(seq) <= 255)
                    rec->sequence = min(n 255)
                    n = n+1
                )
            )
        )
        return(n)
    )
)

;------------------------------------------------------------------------
; 函数名  : EDoc_Cmd
; 功能    : 命令入口(v0.1): 初始化参数 -> 规范化 film PDF 域 ->
;           命令行打印三组参数供核对; v0.2 起换表单
;------------------------------------------------------------------------
procedure( EDoc_Cmd()
    prog((n)
        EDoc_InitParams()
        n = errset(EDoc_NormalizeFilmPdf() t)
        axlMsgPut("==== ExportDocs 参数基座 v0.1 ====")
        foreach( item g_EDocParamDefs
            axlMsgPut(sprintf(nil "  %-22s = %L" car(item) EDoc_GetParam(car(item))))
        )
        when( and(n car(n)) axlMsgPut(sprintf(nil "film PDF 域规范化: %d 项" car(n))) )
        axlMsgPut("提示: v0.1 仅参数基座; 导出通路(表单+宏回放)见 v0.2")
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : EDoc_SLFTEST
; 功能    : 自检: 遍历默认表取参打印, 检查缺键
;------------------------------------------------------------------------
procedure( EDoc_SLFTEST()
    prog((bad v)
        EDoc_InitParams()
        bad = 0
        foreach( item g_EDocParamDefs
            v = EDoc_GetParam(car(item))
            when( null(v)
                bad = bad+1
                printf("SLFTEST MISSING: %s\n" car(item))
            )
            printf("SLFTEST %-22s def=%-12L cur=%L\n" car(item) cadr(item) v)
        )
        printf("SLFTEST done, missing=%d\n" bad)
        t
    )
)

EDoc_InitParams()
ASTB_RegisterCommand("ASTB_Mfg_ExportDocs" "EDoc_Cmd" ?cmdType "general")

printf("[ASTB] mfg_exportdocs.il loaded.\n")
