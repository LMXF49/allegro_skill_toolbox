;========================================================================
; 文件名    : mfg_gerbersetup.il
; 作者      : ASTB Team
; 创建日期  : 2026-07-19
; 版本      : 3.0
; 功能描述  : Gerber 加工文件一键输出（仿凡亿"文件输出"表单）：
;             a) 主表单：输出路径（默认 ./当前pcb文件名，自动建 CAM/ASM/SMT/PCB
;                四个分类子目录）、光绘/钻孔/坐标复选项、IPC 版本下拉、
;                全部选择、生成加工文件；
;             b) 光绘参数：输出格式（默认 Gerber RS274X）、精度（默认 5.5）、
;                Undefined line width（默认 6 mil）；"定义参数"点击即把光绘
;                输出/数控全部参数按内置值静默设全（v2.9.4 起含
;                nc_param.txt 落盘），"设置光绘"/"数控参数"打开系统
;                面板供查看核对；
;             c) "创建/更新Film"：先删除全部已有底片（axlDeleteObject
;                + 事务，17.4 必需），再按当前叠层重建标准底片清单
;                （ETCH/DRILL/PASTEMASK/SOLDERMASK/SILKSCREEN，写入
;                artwork film 控制）；
;             d) 钻孔"数控参数"按钮：打开系统 nc_parameters 面板查看（位数由
;                定义参数预调：默认 5/5，自动按设计精度下限校正）；
;             e) 生成通路：光绘 = film_control FORM 宏，钻孔 = nctape_full +
;                nc_drill 宏，坐标 = plctxt 宏 + ipc356_out 批处理；
;             f) 生成后按底片名自动分类复制到 CAM/ASM/SMT/PCB
;                （钢网->SMT，装配->ASM，丝印及其余->CAM）。
; 依赖模块  : forms/mfg_gerbersetup.form、ASTB_GLOBAL->FormPath
;             （mfg_artparam.form/mfg_ncparam.form 自 v2.9.3 停用保留）
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-10-01 v3.0 ASTB Team 底片全量重建 + 参数对齐截图目标态：
;                     a) 创建/更新Film 改全量替换重建（同名不保留），
;                        多余底片列名提示手动删除（getd('axlfdelete)
;                        16.6/17.4 均 nil，groupMembers 写入与底片记录
;                        axlSetParam 均被拒——17.4 桥实测）；
;                     b) GBS_Filmcreat 换 axlFilmCreate 关键字接口：
;                        底片选项对齐截图（阻隔未连接焊盘+矢量焊盘
;                        行为勾选，其余不勾），Undefined line width
;                        浮点生效（旧 axlfcreate 位置参数 ulw 整数不
;                        生效、#6 极性相反 1=正片——桥实测）；
;                     c) 定义参数扩充：光绘常规参数加 出错全部中止/
;                        菲林限制24x16/单位非公英制（对齐截图），全套
;                        落 art_param.txt（INCHES/MM token 实测）；
;                        数控加 ASCII/绝对/单位/引线12 宏定向，
;                        nc_param.txt 全套键重写（尾零/增强Excellon 关、
;                        背钻/埋头/图例列全关，对齐 s/s1/s2/s5）；
;                        新增 GBS_ApplyLegendParams 预设钻孔图例
;                        （单位/标题/升序/非电镀优先/按层）；
;                     d) 删除 GBS_ApplyUndefWidth（底片记录只读，该
;                        写入从未生效，ULW 改随 axlFilmCreate 创建写入）；
;                     e) GBS_BoardDirFile 补目录尾 "/"（原拼出
;                        DDR_DEOM174/DDR_DEOMart_param.txt 错路径）；
;                        修复历史 python 补丁把 SKILL 串 "\n" 写成原始
;                        换行字节（读成空格，参数文件曾变单行）——全仓
;                        扫描修复 11 个文件；
;                     f) 用户专业评审定值：精度公制2.5/英制2.4（新增
;                        GBS_ComputePrec，art/nc 一致）；增强Excellon
;                        开（槽孔刀具信息）；钻孔前导零压缩开（与
;                        Gerber 侧一致）；钻孔合并输出（SEPARATE NO）；
;                        图例电镀优先+模板按单位 default-mil/mm.dlt；
;                        art_param ABORT-ON-ERROR NO（=全部中止，对话
;                        框落盘反推实证）；nc_param 写抽 GBS_WriteNCParam
;                        链尾兜底（图例对话框 OK 也会整写该文件）；
;                     g) 创建/更新Film 真删除：axlDeleteObject(
;                        artwork:名)（老版 GBS_FilmDelete 实证机制捞回；
;                        17.4 S039 必须包 axlDBTransactionStart/Commit
;                        否则静默拒绝，16.6 裸调即可——双版本桥实测），
;                        extras 报告逻辑退役；
;                     h) 每张底片带板框 3 层（GBS_OutlineLayers/
;                        GBS_FilmLayers：DESIGN_OUTLINE/OUTLINE/CUTOUT
;                        存在才带）；图例列定值：Tool size/公差钻孔/
;                        槽孔分行/三个 Suppress 全勾；Legends 按层数
;                        >2 层 By layer、2 层 Layer pair;
;                     i) 光绘精度同 NC 加 acc+1 下限（acc=4 板 FORMAT 2.4
;                        触发 photoplot 精度警告、坐标向下取整——实测）；
;                     j) art_param.txt/nc_param.txt 显式归入 CAM；
;                        .log 不再归类留板子目录；精度统一 5.5（用户
;                        最终定值）
;   2026-10-01 v2.9.4 ASTB Team 定义参数设全 + 面板恢复：
;                     a) 光绘调参加齐 general_parameters 确定性字段
;                        （输出单位随设计/绝对坐标/单张出错不中断/缩放1）；
;                     b) 数控调参同步落 nc_param.txt（勾选类宏无法定向，
;                        参数文件是确定性载体，生成时 nctape/ncdrill 读它）；
;                     c) 设置光绘/数控参数 恢复为打开系统面板供核对
;   2026-10-01 v2.9.3 ASTB Team 表单按钮改造：
;                     a) 删除"删除Film"按钮（GBS_FilmDelete 一并删除）——
;                        删除底片属危险操作，交还给系统 film 控制面板；
;                     b) 定义参数/设置光绘/数控参数不再弹表单，改为静默
;                        程序化调参（FORM 宏只设参子集 + GBS_ApplyUndefWidth，
;                        命令行打印摘要）——新增 GBS_ApplyArtParams/
;                        GBS_ApplyNCParams：btn_artparam 一键全调、
;                        btn_artsetup 只调光绘、btn_ncparam 只调数控；
;                     c) 设置钻孔/设置槽孔/钻孔图例 维持打开系统对话框
;                        （生成入口非参数持有者）；
;                     e) 子表单回调 GBS_OpenArtParam/GBS_ArtParamCB/
;                        GBS_OpenNCParam/GBS_NCParamCB 不再被引用，一并
;                        删除（mfg_artparam.form/mfg_ncparam.form 保留）
;   2026-10-01 v2.9.2 ASTB Team 创建/更新Film 改为同名保留不更新：
;                     axlfcreate 同名是整体替换，会把用户既有底片的
;                     层/选项设置冲掉（实测"创建/更新"后原底片丢失）；
;                     现逐张判存，已存在跳过，只新建缺失底片
;   2026-07-19 v1.0 ASTB Team 初始创建
;   2026-07-19 v1.1 ASTB Team 修复 let(()) 空绑定表导致的运行时报错
;             （4 处 PARSER WARNING: extra ')'）；新增 创建/更新Film
;             （GBS_FilmBuild/GBS_Filmcreat，移植自 _QEA_QuickArtSetCore
;             实测底片方案，去掉全量删除）；钻孔参数子表单 + 生成时自动
;             写入 nc_parameters（整数位/小数位）
;   2026-07-19 v2.0 ASTB Team 大版本增强：
;             a) 修复字符串身份比较（==/!= 改 equal，含 IPC 版本判断、
;                place_txt 归类等 9 处）；return 全部收敛进 prog（5 函数）；
;             b) 创建/更新Film 新增 ASSEMBLY_TOP/BOTTOM 底片与分层钻孔
;                底片（扫描 padstack startEnd，每个钻孔跨层一张 DRILL_i_j）；
;             c) 新增 删除Film/输出装配层PDF/输出丝印层PDF/设置槽孔/
;                设置钻孔图例 5 按钮（调系统对话框）；钻孔 定义参数 改为
;                直开系统数控参数（ncdrill param）；
;             d) 分类改版：ASM=装配底片，CAM=其余光绘+钻孔+槽孔+IPC，
;                SMT=钢网+坐标，PCB=当前 .brd 复制
;   2026-07-19 v2.1 ASTB 实机修复：FilmCats 改 底片名优先+cond（旧版层内容
;             匹配失常导致全部底片误入 ASM、CAM 无光绘）；装配底片补
;             PIN/ASSEMBLY_*；钻孔跨层 NCLEGEND 缺失时打印重建提示；
;             分类逐文件 printf 便于核对
;   2026-07-19 v2.2 ASTB 实机修复：
;             a) 分类改为纯底片名判定：PASTE*->SMT（钢网）、ASSEMBLY/SILK*->ASM
;                （装配/丝印）、其余->CAM；删掉层内容兜底（旧逻辑因 param 记录
;                行为差异致全部底片误入 ASM）；
;             b) DRILL 按 NCLEGEND-* 图例层拆分为 DRILL_i_j / SLOTS_i_j，
;                通层 DRILL 始终保留，统一连续编号；
;             c) 钻孔格式默认 2:4 -> 5:5（旧会话自动迁移），生成时按
;                设计精度自动上调小数位（dec 必须 >= accuracy+1，否则
;                nc_parameters done 被拒、.drl 不生成）；
;             d) ncdrill param 后补 generaledit（与 21_Quick_ExportARK 实测序列一致）
;   2026-07-19 v2.3 ASTB 实机修复：GBS_DrillSpans 局部变量误用保留字 t
;             （parser 拒绝赋值，a/b 交换后 b 恒为 t）导致跨层钻孔对恒为
;             (a t)、DRILL_i_j 拆分失效——改名 tmp，parser warning 同步消除
;   2026-07-20 v2.4 ASTB 实机修复：
;             a）SILKSCREEN_* 底片由 ASM 改归 CAM（ASM 只留 ASSEMBLY_*，
;                PASTEMASK_* 归 SMT 不变）；
;             b）.drl 已生成却从不进 CAM 的根因：旧 .drl 滞留目录后
;                文件名已进入 beforeFiles，快照差集永远漏判；art/drl/
;                rou/ipc/tap 改为一律纳入分类，不再依赖快照差集
;   2026-08-01 v2.5 ASTB Team 创建/更新Film 新增 OUTLINE 板框底片
;             （BOARD GEOMETRY/DESIGN_OUTLINE + OUTLINE + CUTOUT，
;             GBS_LayersExist 过滤存在性；分类归 CAM）
;   2026-08-01 v2.6 ASTB Team 新增 输出DXF / 输出3D(STEP) 复选项：
;             DXF 走批处理 a2dxf（按底片层内容自动生成 cnv 层转换
;             文件），3D 走批处理 step_out，均输出到 CAM 目录
;   2026-08-01 v2.7 ASTB Team 实机修复：
;             a) axlShell 报 Command not found——a2dxf/step_out 不在
;                Allegro 批处理注册表，改 axlRunBatchDBProgram 执行
;                （UI 的 DXF 导出同通路）；
;             b) DXF/3D 由复选框改独立按钮（btn_dxf/btn_step），
;                不再并入"生成加工文件"流程
;   2026-08-01 v2.8 ASTB Team 实机修复：axlRunBatchDBProgram 返回 -1
;             （a2dxf/step_out 是独立翻译器非 DB 程序）——改
;             ipcBeginProcess 四件套直起 exe（CDSROOT/tools/bin），
;             brd 用 axlGetDrawingName 全路径，失败打印退出码+日志
;   2026-08-01 v2.9 ASTB Team 新增 装配顶层DXF / 装配底层DXF 按钮：
;             cnv 生成与按层输出抽公共（GBS_WriteDxfCnv /
;             GBS_ExportDxfLayers），装配层优先取 ASSEMBLY_* 底片
;             层内容、无底片回退标准装配层集，输出到 ASM 目录；
;             GBS_RunExe 兼容 16.6 tools/pcb/bin 旧布局
;   2026-08-01 v2.9.1 ASTB Team 输出目录调整：DXF（全板+装配）统一
;             输出到 DXF 子目录，STEP 输出到 3D 子目录
;========================================================================
;
; 注意：
;   1. Undefined line width 经两处生效：新底片由 axlfcreate 直接写入；
;      既有底片由 errset(axlSetParam) 尝试更新（手册未明确可写，失败仅提示）。
;      运行前请先保存设计。
;   2. FORM 宏序列（film_control / nc_parameters / nc_drill / plctxt）取自
;      mfg_quickexportark.il 与 mfg_camout.il 在 17.4 的实测序列，跨版本
;      如失效需按当前版本适配。
;   3. ipc356_out 为 Allegro 批处理程序（tools/bin/ipc356_out.exe），经
;      axlRunBatchDBProgram 调用；-A 输出 IPC-D-356A，缺省 IPC-D-356。
;   4. axlfcreate 为 Cadence 样例沿用的底层底片接口（18_film_reorder /
;      21_Quick_ExportARK 均用），单张失败仅计数提示，不中断流程。

unless( boundp('_gbsForm)      defvar(_gbsForm nil))
unless( boundp('_gbsArtFormat) defvar(_gbsArtFormat "gerber_rs274x"))
unless( boundp('_gbsArtInt)    defvar(_gbsArtInt 5))
unless( boundp('_gbsArtDec)    defvar(_gbsArtDec 5))
unless( boundp('_gbsUlw)       defvar(_gbsUlw 6.0))
unless( boundp('_gbsNcInt)     defvar(_gbsNcInt 5))
unless( boundp('_gbsNcDec)     defvar(_gbsNcDec 5))
; v2.2：旧会话残留的 2:4 默认值迁移为 5:5（5:5 为本工具既定默认值）
when( _gbsNcInt == 2 && _gbsNcDec == 4
    _gbsNcInt = 5
    _gbsNcDec = 5
    printf("[GBS] 钻孔格式默认值已由 2:4 迁移为 5:5\n")
)

axlCmdRegister( "gbs" 'GBS_Run ?cmdType "interactive")

;------------------------------------------------------------------------
; 函数名  : GBS_Slash
; 功能    : 路径反斜杠转正斜杠（SKILL 文件操作统一用正斜杠）
; 参数    : p - 路径字符串
; 返回值  : 转换后的字符串；nil/空串原样返回
;------------------------------------------------------------------------
procedure( GBS_Slash(p)
    if( p && !equal(p "") then
        axlOSSlash(p)
    else
        p
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_BoardDirFile
; 功能    : 取当前板子的目录与不带扩展名的文件名
; 返回值  : list(dir file)；dir 末尾带 "/"，未保存的新板退化为 "./"
;------------------------------------------------------------------------
procedure( GBS_BoardDirFile()
    let((dn parts dir file)
        dn = axlGetDrawingName()
        parts = axlDMFileParts(dn)
        dir = car(parts)
        file = cadr(parts)
        if( dir && !equal(dir "") then
            dir = GBS_Slash(dir)
            ; v3.0：axlDMFileParts 返回的目录不带尾分隔符，axlOSSlash 只
            ; 转换斜杠方向不补尾——必须补 "/"，否则 strcat 拼出
            ; "DDR_DEOMart_param.txt"/"DDR_DEOM174" 这类错路径(实测)
            when( substring(dir strlen(dir) 1) != "/"
                dir = strcat(dir "/")
            )
        else
            dir = "./"
        )
        unless( file && !equal(file "")
            file = axlCurrentDesign()
        )
        list(dir file)
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_EnsureDir
; 功能    : 确保目录存在，不存在则创建
; 返回值  : t - 已存在或创建成功；nil - 创建失败
;------------------------------------------------------------------------
procedure( GBS_EnsureDir(path)
    unless( isDir(path)
        errset(createDir(path) nil)
    )
    isDir(path)
)

;------------------------------------------------------------------------
; 函数名  : GBS_CheckOn
; 功能    : 读取复选框状态（兼容字符串模式 "t"/t）
; 返回值  : t - 勾选；nil - 未勾选
;------------------------------------------------------------------------
procedure( GBS_CheckOn(fw fld)
    let((v)
        v = axlFormGetField(fw fld)
        if( v == t || equal(v "t") || equal(v "T") || equal(v "1") then t else nil )
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_FileExt / GBS_StripExt
; 功能    : 取小写扩展名 / 去扩展名的主名（按第一个点截断）
;------------------------------------------------------------------------
procedure( GBS_FileExt(f)
    let((ps)
        ps = parseString(f ".")
        if( cdr(ps) then lowerCase(car(last(ps))) else "" )
    )
)

procedure( GBS_StripExt(f)
    car(parseString(f "."))
)

;------------------------------------------------------------------------
; 函数名  : GBS_DesignLen
; 功能    : 把 mil 为基准的线宽值换算成当前设计单位
; 参数    : milVal - 以 mil 为单位的数值
; 返回值  : 当前设计单位下的浮点值
;------------------------------------------------------------------------
procedure( GBS_DesignLen(milVal)
    let((units v)
        units = axlGetParam("paramDesign")->units
        v = milVal
        case( units
            ("millimeters" v = milVal * 0.0254)
            ("microns"     v = milVal * 25.4)
            ("inch"        v = milVal / 1000.0)
            (t             v = milVal)
        )
        v
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_FilmCats
; 功能    : 按底片名判定分类（纯名字判定，index 为 strstr 语义）：
;           PASTE* -> SMT（钢网）；ASSEMBLY* -> ASM（装配）；
;           其余（含 SILKSCREEN/SOLDERMASK/ETCH/DRILL）一律 CAM。
;           v2.4：SILKSCREEN 由 ASM 改归 CAM（应用户要求，ASM 只留装配）
; 返回值  : ("SMT") / ("ASM") / ("CAM")
;------------------------------------------------------------------------
procedure( GBS_FilmCats(filmName)
    let((un)
        un = upperCase(filmName)
        cond(
            ( index(un "PASTE")
                list("SMT")
            )
            ( index(un "ASSEMBLY")
                list("ASM")
            )
            ( t
                list("CAM")
            )
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_CopyTo
; 功能    : 把当前目录的文件复制到指定子目录
; 返回值  : t - 成功；nil - 失败（errset 防护，不中断流程）
;------------------------------------------------------------------------
procedure( GBS_CopyTo(srcFile destDir)
    let((r)
        r = nil
        when( GBS_EnsureDir(destDir)
            r = errset(axlOSFileCopy(srcFile strcat(destDir "/" srcFile) nil) nil)
        )
        if( r then t else nil )
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_Filmcreat
; 功能    : 新建单张底片（调用方须先判存：axlfcreate 同名是整体替换，会冲掉既有底片设置；Undefined line width
;           随 _gbsUlw 写入，单位换算同 Filmcreat 实测公式）
; 参数    : FilmName - 底片名；artList - 层全名列表
; 返回值  : t - 成功；nil - 失败
;------------------------------------------------------------------------
procedure( GBS_Filmcreat(FilmName artList seq)
    let((uw negLay r)
        uw = GBS_DesignLen(_gbsUlw)
        ; 第二个层是 ETCH/xxx 时按该层是否负片决定底片 N/P；
        ; v3.0 换 axlFilmCreate 关键字接口（文档明确，?negative t=负片；
        ; 旧 axlfcreate 位置参数 #6 极性相反 1=正片、#5 ulw 整数不生效
        ; ——17.4 桥实测；底片选项对齐用户截图：只勾 阻隔未连接焊盘 +
        ; 基于矢量的焊盘行为，其余不勾）
        negLay = cdr(artList) && strncmp(nth(1 artList) "ETCH/" 4) == 0 &&
                 axlIsLayerNegative(nth(1 artList)) == t
        r = errset(axlFilmCreate( FilmName
                                  ?negative negLay
                                  ?undefineLineWidth uw
                                  ?sequence seq
                                  ?suppressUnconnectPads t
                                  ?vectorBasedPad t
                                  ?layers artList ) nil)
        if( r && car(r) then t else nil )
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_FilmBuild
; 功能    : "创建/更新Film"：按当前叠层创建/更新标准底片清单并写入
;           artwork film 控制。清单顺序：ETCH 每层一张 -> OUTLINE
;           板框层（DESIGN_OUTLINE/OUTLINE/CUTOUT，v2.5 新增）->
;           DRILL（按 NCLEGEND-* 图例层拆分为 DRILL_i_j / SLOTS_i_j，
;           通层 DRILL 始终保留）-> PASTEMASK/SOLDERMASK/SILKSCREEN/
;           ASSEMBLY 各 TOP/BOTTOM；统一连续编号；v3.0 先经
;           axlDeleteObject 删除全部已有底片（17.4 需事务包裹）再重建
; 返回值  : t - 完成；nil - 用户取消或环境不允许
;------------------------------------------------------------------------
procedure( GBS_FilmBuild()
    prog((layerlist layertotal namelist specs num mkCnt delCnt fname
          mfgMembers x parts spanList drills slots hasThrough layeradd
          oldFilms f r mk)
        unless( axlOKToProceed()
            axlUIConfirm("当前状态不允许修改数据库，请先退出其他命令")
            return(nil)
        )
        unless( axlUIConfirm(sprintf(nil
                "将删除全部 %d 张已有底片，并按当前叠层重建标准底片，是否继续？"
                length(axlGetParam("artwork")->groupMembers)))
            return(nil)
        )
        layerlist = axlGetParam("paramLayerGroup:ETCH")->groupMembers
        layertotal = length(layerlist)
        namelist = list("01_" "02_" "03_" "04_" "05_" "06_" "07_" "08_" "09_"
                        "10_" "11_" "12_" "13_" "14_" "15_" "16_" "17_" "18_"
                        "19_" "20_" "21_" "22_" "23_" "24_" "25_" "26_" "27_"
                        "28_" "29_" "30_" "31_" "32_" "33_" "34_" "35_" "36_")
        specs = nil
        ; 第 1 步：ETCH 每层一张
        foreach( lay layerlist
            specs = append1(specs
                list(lay GBS_FilmLayers(list(strcat("ETCH/" lay)
                              strcat("VIA CLASS/" lay)
                              strcat("PIN/" lay)))))
        )
        ; 第 1.5 步：板框层（17.4 三种板框子类，存在才纳入）
        layeradd = GBS_OutlineLayers()
        when( layeradd
            specs = append1(specs list("OUTLINE" layeradd))
        )
        ; 第 2 步：DRILL 按 NCLEGEND-* 图例层拆分：NCLEGEND-i-j -> DRILL_i_j，
        ; NCLEGEND-SLOTS-i-j -> SLOTS_i_j；无图例层则只建通层 DRILL
        mfgMembers = axlGetParam("paramLayerGroup:MANUFACTURING")->groupMembers
        spanList = nil
        foreach( x mfgMembers
            when( strncmp("NCLEGEND-" x 9) == 0
                parts = parseString(x "-")
                if( length(parts) >= 4 && equal(cadr(parts) "SLOTS") then
                    spanList = append1(spanList
                        list(atoi(caddr(parts)) atoi(cadddr(parts)) t x))
                else
                    when( length(parts) >= 3
                        spanList = append1(spanList
                            list(atoi(cadr(parts)) atoi(caddr(parts)) nil x))
                    )
                )
            )
        )
        spanList = sortcar(spanList 'lessp)
        drills = nil
        slots = nil
        foreach( sp spanList
            if( caddr(sp) then
                slots = append1(slots sp)
            else
                drills = append1(drills sp)
            )
        )
        hasThrough = exists( e drills car(e) == 1 && cadr(e) == layertotal )
        unless( hasThrough
            ; 通层 DRILL 始终保留（含主钻孔图例层）
            specs = append1(specs
                list("DRILL"
                     GBS_FilmLayers(list(
                         "MANUFACTURING/NCDRILL_LEGEND"
                         "MANUFACTURING/NCDRILL_FIGURE"
                         "MANUFACTURING/PHOTOPLOT_OUTLINE"))))
        )
        foreach( sp drills
            if( car(sp) == 1 && cadr(sp) == layertotal then
                layeradd = GBS_FilmLayers(list(
                    "MANUFACTURING/NCDRILL_LEGEND"
                    "MANUFACTURING/NCDRILL_FIGURE"
                    "MANUFACTURING/PHOTOPLOT_OUTLINE"
                    strcat("MANUFACTURING/" cadddr(sp))))
            else
                layeradd = GBS_FilmLayers(list(
                    strcat("MANUFACTURING/" cadddr(sp))
                    "MANUFACTURING/PHOTOPLOT_OUTLINE"))
            )
            specs = append1(specs
                list(sprintf(nil "DRILL_%d_%d" car(sp) cadr(sp)) layeradd))
        )
        foreach( sp slots
            specs = append1(specs
                list(sprintf(nil "SLOTS_%d_%d" car(sp) cadr(sp))
                     GBS_FilmLayers(list(
                         strcat("MANUFACTURING/" cadddr(sp))
                         "MANUFACTURING/PHOTOPLOT_OUTLINE"))))
        )
        when( null(spanList)
            axlUIConfirm("未发现 NCLEGEND-* 钻孔图例层，DRILL 只建了通层一张。\n如需按跨层（如 1-6/3-4）和槽孔拆分底片，请先点 钻孔图例 生成图例后再 创建/更新Film")
        )
        ; 第 3 步：固定 8 张（钢网/阻焊/丝印/装配 各 TOP/BOTTOM）
        foreach( fixed list(
                list("PASTEMASK_TOP" list(
                     "PIN/PASTEMASK_TOP" "PACKAGE GEOMETRY/PASTEMASK_TOP"))
                list("PASTEMASK_BOTTOM" list(
                     "PIN/PASTEMASK_BOTTOM" "PACKAGE GEOMETRY/PASTEMASK_BOTTOM"))
                list("SOLDERMASK_TOP" list(
                     "PIN/SOLDERMASK_TOP" "PACKAGE GEOMETRY/SOLDERMASK_TOP"
                     "BOARD GEOMETRY/SOLDERMASK_TOP"))
                list("SOLDERMASK_BOTTOM" list(
                     "PIN/SOLDERMASK_BOTTOM" "PACKAGE GEOMETRY/SOLDERMASK_BOTTOM"
                     "BOARD GEOMETRY/SOLDERMASK_BOTTOM"))
                list("SILKSCREEN_TOP" list(
                     "REF DES/SILKSCREEN_TOP" "PACKAGE GEOMETRY/SILKSCREEN_TOP"
                     "BOARD GEOMETRY/SILKSCREEN_TOP"))
                list("SILKSCREEN_BOTTOM" list(
                     "REF DES/SILKSCREEN_BOTTOM" "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
                     "BOARD GEOMETRY/SILKSCREEN_BOTTOM"))
                list("ASSEMBLY_TOP" list(
                     "PIN/ASSEMBLY_TOP" "REF DES/ASSEMBLY_TOP"
                     "PACKAGE GEOMETRY/ASSEMBLY_TOP" "BOARD GEOMETRY/ASSEMBLY_TOP"))
                list("ASSEMBLY_BOTTOM" list(
                     "PIN/ASSEMBLY_BOTTOM" "REF DES/ASSEMBLY_BOTTOM"
                     "PACKAGE GEOMETRY/ASSEMBLY_BOTTOM" "BOARD GEOMETRY/ASSEMBLY_BOTTOM"))
            )
            layeradd = GBS_LayersExist(cadr(fixed))
            when( layeradd
                specs = append1(specs list(car(fixed) GBS_FilmLayers(cadr(fixed))))
            )
        )
        ; 第 4 步：统一编号并创建/更新
        when( length(specs) > length(namelist)
            axlUIConfirm(sprintf(nil "底片数量 %d 超过支持上限（36 张）" length(specs)))
            return(nil)
        )
        ; 第 4 步：先删全部已有底片，再统一编号重建（v3.0）
        ; 删除机制：axlDeleteObject(artwork:名字)——老版 GBS_FilmDelete
        ; 实证；17.4 S039 必须包事务否则静默 nil，16.6 裸调即可
        oldFilms = axlGetParam("artwork")->groupMembers
        delCnt = 0
        mk = errset(axlDBTransactionStart() nil)
        foreach( f oldFilms
            r = errset(axlDeleteObject(axlGetParam(strcat("artwork:" f))) nil)
            when( and(r car(r))
                delCnt = delCnt + 1
            )
        )
        when( and(mk car(mk))
            errset(axlDBTransactionCommit(car(mk)) nil)
        )
        num = 0
        mkCnt = 0
        foreach( sp specs
            fname = strcat(nth(num namelist) car(sp))
            when( GBS_Filmcreat(fname cadr(sp) (num + 1))
                mkCnt = mkCnt + 1
            )
            num = num + 1
        )
        ; padstack 有跨层但 NCLEGEND 层缺失时提示（先 钻孔图例 再重建底片）
        foreach( sp GBS_DrillSpans()
            unless( axlIsLayer(sprintf(nil "MANUFACTURING/NCLEGEND-%d-%d"
                                        car(sp) cadr(sp)))
                printf("[GBS] 提示：跨层 %d-%d 的 NCLEGEND 层不存在，\n"
                       car(sp) cadr(sp))
                printf("[GBS]   请先点 钻孔图例 生成图例，再重新 创建/更新Film\n")
            )
        )
        axlUIConfirm(sprintf(nil "底片重建完成：删除旧底片 %d 张，新建 %d 张（可在 设置光绘 中查看）"
                             delCnt mkCnt))
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_LayersExist
; 功能    : 过滤层列表，只保留设计中真实存在的层（axlIsLayer）
;------------------------------------------------------------------------
procedure( GBS_LayersExist(ll)
    let((out)
        out = nil
        foreach( l ll
            when( axlIsLayer(l)
                out = append1(out l)
            )
        )
        out
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_EtchIdx
; 功能    : 层名（可带 "ETCH/" 前缀）-> 走线层 1 基序号；找不到返回 nil
;------------------------------------------------------------------------
procedure( GBS_OutlineLayers()
    ; 板框 3 层（存在才带）：设计板框/CUT 板框/装配板框
    GBS_LayersExist(list("BOARD GEOMETRY/DESIGN_OUTLINE"
                         "BOARD GEOMETRY/OUTLINE"
                         "BOARD GEOMETRY/CUTOUT"))
)

;------------------------------------------------------------------------
; 函数名  : GBS_FilmLayers
; 功能    : 底片层列表 = 板框 3 层 + 功能层（各自过滤存在性）；
;           v3.0 起每张底片都带全部板框层（用户要求）
;------------------------------------------------------------------------
procedure( GBS_FilmLayers(featureLayers)
    append(GBS_OutlineLayers() GBS_LayersExist(featureLayers))
)

;------------------------------------------------------------------------
procedure( GBS_EtchIdx(tn etchList)
    prog((nm i found)
        nm = tn
        when( index(nm "/")
            nm = cadr(parseString(nm "/"))
        )
        nm = upperCase(nm)
        i = 0
        found = nil
        foreach( e etchList
            i = i + 1
            when( equal(nm upperCase(e)) && null(found)
                found = i
            )
        )
        found
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_DrillSpans
; 功能    : 扫描设计全部 padstack 的钻孔跨层（startEnd），归一去重
; 返回值  : ((i j) ...) 层号对（1 基，i<j），如 ((1 6) (3 4))
;------------------------------------------------------------------------
procedure( GBS_DrillSpans()
    prog((etch psl se a b tmp spans pair)
        etch = axlGetParam("paramLayerGroup:ETCH")->groupMembers
        spans = nil
        psl = axlDBGetDesign()->padstacks
        foreach( ps psl
            se = errset(ps->startEnd nil)
            when( car(se)
                se = car(se)
                when( se && cadr(se)
                    a = GBS_EtchIdx(car(se) etch)
                    b = GBS_EtchIdx(cadr(se) etch)
                    when( a && b && a != b
                        when( a > b
                            tmp = a
                            a = b
                            b = tmp
                        )
                        pair = list(a b)
                        unless( member(pair spans)
                            spans = append1(spans pair)
                        )
                    )
                )
            )
        )
        spans
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_PdfOut
; 功能    : PDF 输出按钮：在输出根目录下建 PDF 子目录，并打开系统
;           Export PDF 对话框（pdf out），由用户勾选对应底片导出
; 参数    : subDir - 子目录名；filmHint - 提示用户勾选的底片
;------------------------------------------------------------------------
procedure( GBS_PdfOut(fw subDir filmHint)
    prog((outRoot dirFile folder)
        outRoot = axlFormGetField(fw "outpath")
        if( outRoot == nil || equal(outRoot "") then
            dirFile = GBS_BoardDirFile()
            outRoot = strcat(car(dirFile) cadr(dirFile))
        )
        outRoot = GBS_Slash(outRoot)
        folder = strcat(outRoot "/" subDir)
        unless( GBS_EnsureDir(folder)
            axlUIConfirm(sprintf(nil "无法创建目录：%s" folder))
            return(nil)
        )
        axlUIConfirm(sprintf(nil
            "将打开系统 Export PDF 对话框，请勾选 %s 后导出，文件保存到：\n%s"
            filmHint folder))
        axlShell("setwindow pcb")
        axlShell("pdf out")
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_RunNCRoute
; 功能    : NCroute FORM 宏生成槽孔铣板文件（.rou，21_Quick_ExportARK 实测序列）
; 返回值  : t
;------------------------------------------------------------------------
procedure( GBS_RunNCRoute()
    axlShell("setwindow pcb")
    axlShell("generaledit")
    axlShell("NCroute ")
    axlShell("setwindow form.nc_route")
    axlShell("FORM nc_route execute  ")
    axlShell("FORM nc_route close  ")
    axlShell("setwindow pcb")
    axlShell("generaledit")
    t
)

;------------------------------------------------------------------------
; 函数名  : GBS_ComputePrec
; 功能    : 按设计单位定光绘/钻孔精度（v3.0 用户评审定值）：
;           公制 2.5 / 英制 2.4；Gerber 与钻孔强制一致（混用是 CAM
;           出错高发原因）。在 ApplyArt/ApplyNC 开头调用。
;------------------------------------------------------------------------
procedure( GBS_ComputePrec()
    prog((acc)
        ; v3.0 用户最终定值：精度统一 5.5（不再按单位分档）
        _gbsArtInt = 5  _gbsArtDec = 5
        _gbsNcInt  = 5  _gbsNcDec  = 5
        ; 设计精度下限：小数位 < acc+1 则自动上调（光绘侧同样必要——
        ; acc=4 板 2.4 会触发 photoplot 精度警告并向下取整，实测）
        acc = axlGetParam("paramDesign")->accuracy
        when( _gbsArtDec < acc + 1
            _gbsArtDec = acc + 1
            printf("[GBS] 设计精度 %d 位，光绘小数位自动上调为 %d
" acc _gbsArtDec)
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_WriteArtParam
; 功能    : 光绘常规参数全套落 art_param.txt 到板子目录（与
;           nc_param.txt 同理：勾选类字段宏只能翻转不能定向，参数文件
;           才是确定性载体）。键序/取值对齐 Cadence 官方样例及本机真实
;           项目实测（OUTPUT-UNITS 英制=INCHES 公制=MM；FILM-SIZE=
;           输出单位数值x1e5 的整数，24x16 英寸 = 609.6x406.4 毫米；
;           ABORT-ON-ERROR NO=全部中止 YES=中止菲林单张不中断——
;           film_control 对话框 OK 落盘值反推实证）。
; 返回值  : t/nil
;------------------------------------------------------------------------
procedure( GBS_WriteArtParam()
    prog((bf pf dev du ou fsx fsy ap)
        bf = GBS_BoardDirFile()
        pf = strcat(car(bf) "art_param.txt")
        dev = cond( (index(_gbsArtFormat "rs274x") "GERBER_RS274X")
                    (index(_gbsArtFormat "6x00")   "GERBER_6X00")
                    (index(_gbsArtFormat "4x00")   "GERBER_4X00")
                    (index(_gbsArtFormat "barco")  "BARCO_DPF")
                    (index(_gbsArtFormat "mda")    "MDA")
                    (t                             "GERBER_RS274X") )
        du = car(axlDBGetDesignUnits())
        if( rexMatchp("milli" du) then
            ou = "MM"
            fsx = 60960000
            fsy = 40640000
        else
            ou = "INCHES"
            fsx = 2400000
            fsy = 1600000
        )
        ap = outfile(pf)
        if( ap then
            fprintf(ap "DEVICE-TYPE           %s\n" dev)
            fprintf(ap "OUTPUT-UNITS          %s\n" ou)
            fprintf(ap "FILM-SIZE             %d %d\n" fsx fsy)
            fprintf(ap "FORMAT                %d.%d\n" _gbsArtInt _gbsArtDec)
            fprintf(ap "ABORT-ON-ERROR        NO\n")
            fprintf(ap "SCALE                 1\n")
            fprintf(ap "SUPPRESS-LEAD-ZEROES  YES\n")
            fprintf(ap "SUPPRESS-TRAIL-ZEROES NO\n")
            fprintf(ap "SUPPRESS-EQUAL        YES\n")
            fprintf(ap "UNDEF-APT-CONT        NO\n")
            close(ap)
            printf("[GBS] art_param.txt 已写入 %s\n" pf)
            return(t)
        else
            printf("[GBS] 警告: art_param.txt 写入失败: %s\n" pf)
            return(nil)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_ApplyArtParams
; 功能    : 静默调光绘参数（v2.9.3 起不弹表单）：film_control FORM 宏
;           只设参（general_parameters + 格式 + 单位 + 出错全部中止 +
;           整数/小数位 + 菲林限制 + 缩放 + ok，去掉 select_all/create
;           ——那是生成动作，仍由 GBS_RunArtwork 走全序列）；勾选类经
;           art_param.txt 落盘（GBS_WriteArtParam，v3.0 新增）。完成后
;           命令行打印实际值摘要
; 返回值  : t
;------------------------------------------------------------------------
procedure( GBS_ApplyArtParams()
    prog((du unitsFld)
        ; v3.0 对齐用户截图目标态：错误操作改 全部中止；单位非公制一律
        ; 英寸；补菲林尺寸限制 24x16；勾选类（前导零/等坐标/未定义光圈
        ; 继续）宏只能翻转不能定向，全套常规参数同步落 art_param.txt；
        ; 既有底片记录只读（17.4 实测 axlSetParam 全拒），Undefined
        ; line width 改在 创建/更新Film 时随 axlFilmCreate 写入
        GBS_ComputePrec()
        du = car(axlDBGetDesignUnits())
        unitsFld = if( rexMatchp("milli" du) then "units_metric"
                       else "units_english" )
        axlShell("setwindow pcb")
        axlShell("generaledit")
        axlShell("artwork ")
        axlShell("setwindow form.film_control")
        axlShell("FORM film_control general_parameters ")
        axlShell(sprintf(nil "FORM film_control %s YES " _gbsArtFormat))
        axlShell(sprintf(nil "FORM film_control %s " unitsFld))
        axlShell("FORM film_control coords_absolute ")
        axlShell("FORM film_control error_abort_all ")
        axlShell(sprintf(nil "FORM film_control format_int_places %d " _gbsArtInt))
        axlShell(sprintf(nil "FORM film_control format_dec_places %d " _gbsArtDec))
        axlShell("FORM film_control film_max_x 24 ")
        axlShell("FORM film_control film_max_y 16 ")
        axlShell("FORM film_control scale 1 ")
        axlShell("FORM film_control ok  ")
        axlShell("setwindow pcb")
        axlShell("generaledit")
        GBS_WriteArtParam()
        axlUIWPrint(nil "光绘参数已设全: 格式 %s, 单位 %s, 绝对坐标, 出错全部中止, 精度 %d.%d, 缩放 1, 菲林限制 24x16, 阻隔前导零/等坐标（art_param.txt 已落板子目录）"
            _gbsArtFormat unitsFld _gbsArtInt _gbsArtDec)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_ApplyNCParams
; 功能    : 静默调数控参数（v2.9.3 起不弹表单）：ncdrill param 打开
;           nc_parameters 定向写入 ASCII/绝对坐标/单位/引线12/整数位/
;           小数位（先按 v2.2 精度下限校正：_gbsNcDec < 设计精度+1 则
;           上调）后 done；勾选类经 nc_param.txt 全套键落盘（v3.0）。
; 返回值  : t
;------------------------------------------------------------------------
procedure( GBS_ApplyNCParams()
    prog((acc du unitsFld)
        GBS_ComputePrec()
        acc = axlGetParam("paramDesign")->accuracy
        when( _gbsNcDec < acc + 1
            _gbsNcDec = acc + 1
            printf("[GBS] 设计精度 %d 位，钻孔小数位自动上调为 %d\n" acc _gbsNcDec)
        )
        ; v3.0：radio 组宏定向补齐（ASCII码/绝对坐标/单位随设计/引线12，
        ; 对齐用户截图）；勾选类（零压缩/增强Excellon/自动选刀建文本等）
        ; 宏只能翻转不能定向，nc_param.txt 全套键重写承载（含钻孔图例
        ; 列选项键，对齐官方样例键序）
        du = car(axlDBGetDesignUnits())
        unitsFld = if( rexMatchp("milli" du) then "metric_units"
                       else "english_units" )
        axlShell("ncdrill param ")
        axlShell("generaledit ")
        axlShell("setwindow form.nc_parameters")
        axlShell("FORM nc_parameters ascii_code ")
        axlShell("FORM nc_parameters absolute_coords ")
        axlShell(sprintf(nil "FORM nc_parameters %s " unitsFld))
        axlShell("FORM nc_parameters tape_leader 12 ")
        axlShell(sprintf(nil "FORM nc_parameters integer_places %d " _gbsNcInt))
        axlShell(sprintf(nil "FORM nc_parameters decimal_places %d " _gbsNcDec))
        axlShell("FORM nc_parameters done  ")
        axlShell("setwindow pcb")
        axlShell("generaledit")
        GBS_WriteNCParam()
        axlUIWPrint(nil "数控参数已设全: 格式 %d.%d, ASCII码, 绝对坐标, 单位随设计, 引线12, 前导零压缩, 增强Excellon, 合并钻孔文件（nc_param.txt 已落板子目录）"
            _gbsNcInt _gbsNcDec)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_WriteNCParam
; 功能    : nc_param.txt 全套键落板子目录（勾选类参数确定性载体：
;           数控/钻孔/钻孔图例列选项全在里面，键序对齐官方样例；
;           勾选状态目标值=Allegro 默认值全套）。ncdrill param 与
;           钻孔图例对话框 done/OK 时也会整写本文件——本函数在
;           btn_artparam 链尾最后调用，保证最终文件态确定。
; 返回值  : t/nil
;------------------------------------------------------------------------
procedure( GBS_WriteNCParam()
    prog((bf pf ncp ou)
        bf = GBS_BoardDirFile()
        pf = strcat(car(bf) "nc_param.txt")
        ou = if( rexMatchp("milli" car(axlDBGetDesignUnits())) then "METRIC"
                 else "ENGLISH" )
        ncp = outfile(pf)
        if( ncp then
            fprintf(ncp "INTEGER-PLACES         %d\n" _gbsNcInt)
            fprintf(ncp "DECIMAL-PLACES         %d\n" _gbsNcDec)
            fprintf(ncp "X-OFFSET               0.000000\n")
            fprintf(ncp "Y-OFFSET               0.000000\n")
            fprintf(ncp "FEEDRATE               1\n")
            fprintf(ncp "COORDINATES            ABSOLUTE\n")
            fprintf(ncp "OUTPUT-UNITS           %s\n" ou)
            fprintf(ncp "TOOL-ORDER             INCREASING\n")
            fprintf(ncp "REPEAT-CODES           YES\n")
            fprintf(ncp "SUPPRESS-LEAD-ZEROES   YES\n")
            fprintf(ncp "SUPPRESS-TRAIL-ZEROES  NO\n")
            fprintf(ncp "SUPPRESS-EQUAL         NO\n")
            fprintf(ncp "TOOL-SELECT            YES\n")
            fprintf(ncp "OPTIMIZE_DRILLING      YES\n")
            fprintf(ncp "ENHANCED_EXCELLON      YES\n")
            fprintf(ncp "HEADER                 none\n")
            fprintf(ncp "LEADER                 12\n")
            fprintf(ncp "CODE                   ASCII\n")
            fprintf(ncp "SEPARATE               NO\n")
            fprintf(ncp "SEPARATE-ROUTING       NO\n")
            fprintf(ncp "DRILLING               LAYER-PAIR\n")
            fprintf(ncp "BACKDRILL              NO\n")
            fprintf(ncp "CAVITY                 NO\n")
            fprintf(ncp "COUNTER                NO\n")
            fprintf(ncp "TOLERANCE_DRILL        YES\n")
            fprintf(ncp "TOLERANCE_TRAVEL       NO\n")
            fprintf(ncp "TOOL_SIZE              YES\n")
            fprintf(ncp "ROTATION               NO\n")
            fprintf(ncp "NON_STANDARD           NO\n")
            fprintf(ncp "TOTAL_DRILL            NO\n")
            fprintf(ncp "SEPARATE_SLOT          YES\n")
            fprintf(ncp "SUPPRESS_TOLERANCE     YES\n")
            fprintf(ncp "SUPPRESS_TOOLSIZE      YES\n")
            fprintf(ncp "SUPPRESS_ROTATION      YES\n")
            close(ncp)
            printf("[GBS] nc_param.txt 已写入 %s\n" pf)
            return(t)
        else
            printf("[GBS] 警告: nc_param.txt 写入失败: %s\n" pf)
            return(nil)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_ApplyLegendParams
; 功能    : 钻孔图例参数预设（v3.0 新增）：nc_drilllegend FORM 宏定向
;           设置确定性字段——输出单位/图例标题/孔排序（升序+非电镀优先）
;           /按层出图（对齐用户截图）；勾选类（含背钻/埋头/空腔及各列
;           显示开关）宏只能翻转不能定向，由 nc_param.txt 全套键承载
;           （GBS_ApplyNCParams 已落盘）。counter_title 字段 16.6 表单
;           没有，按版本跳过。
; 返回值  : t
;------------------------------------------------------------------------
procedure( GBS_ApplyLegendParams()
    prog((du ou tpl)
        du = car(axlDBGetDesignUnits())
        if( rexMatchp("milli" du) then
            ou = "MM"
            tpl = "default-mm.dlt"
        else
            ou = "Mils"
            tpl = "default-mil.dlt"
        )
        axlShell("setwindow pcb")
        axlShell("generaledit")
        axlShell("ncdrill legend ")
        axlShell("setwindow form.nc_drilllegend")
        axlShell(sprintf(nil "FORM nc_drilllegend filename %s " tpl))
        axlShell(sprintf(nil "FORM nc_drilllegend output_unit %s " ou))
        axlShell("FORM nc_drilllegend drill_title \"DRILL CHART: $lay_nams$\" ")
        axlShell("FORM nc_drilllegend backdrill_title \"BACKDRILL: $lay_nams$\" ")
        unless( ASTB_IsVersion166()
            axlShell("FORM nc_drilllegend counter_title \"COUNTERBORE/COUNTERSINK: $lay_nams$\" ")
        )
        axlShell("FORM nc_drilllegend cavity_title \"CAVITY LEGEND\" ")
        axlShell("FORM nc_drilllegend ascending ")
        axlShell("FORM nc_drilllegend platedf ")
        ; 多层板(>2)按层出图, 两层板按层对（用户评审定值）
        if( length(axlGetParam("paramLayerGroup:ETCH")->groupMembers) > 2 then
            axlShell("FORM nc_drilllegend by_layer_legends ")
        else
            axlShell("FORM nc_drilllegend layer_pair_legends ")
        )
        axlShell("FORM nc_drilllegend done  ")
        axlShell("setwindow pcb")
        axlShell("generaledit")
        axlUIWPrint(nil "钻孔图例参数已预设: 模板 %s, 单位 %s, 升序, 电镀优先, 按层, 标题已标准化" tpl ou)
        t
    )
)

procedure( GBS_RunArtwork()
    axlShell("setwindow pcb")
    axlShell("generaledit")
    axlShell("artwork ")
    axlShell("setwindow form.film_control")
    axlShell("FORM film_control general_parameters ")
    axlShell(sprintf(nil "FORM film_control %s YES " _gbsArtFormat))
    axlShell(sprintf(nil "FORM film_control format_int_places %d " _gbsArtInt))
    axlShell(sprintf(nil "FORM film_control format_dec_places %d " _gbsArtDec))
    axlShell("FORM film_control film_control ")
    axlShell("FORM film_control select_all ")
    axlShell("FORM film_control create  ")
    axlShell("setwindow text")
    axlShell("close")
    axlShell("setwindow form.film_control")
    axlShell("FORM film_control ok  ")
    axlShell("setwindow pcb")
    axlShell("generaledit")
    t
)

;------------------------------------------------------------------------
; 函数名  : GBS_RunNCDrill
; 功能    : 生成钻孔 .drl：写数控参数（nc_parameters FORM 宏，序列与
;           21_Quick_ExportARK 实测一致）-> nctape_full 执行。
;           v2.2：小数位必须 >= 设计精度+1，否则 done 被拒、.drl 不生成
; 返回值  : t
;------------------------------------------------------------------------
procedure( GBS_RunNCDrill()
    prog((acc)
        acc = axlGetParam("paramDesign")->accuracy
        when( _gbsNcDec < acc + 1
            _gbsNcDec = acc + 1
            printf("[GBS] 设计精度 %d 位，钻孔小数位自动上调为 %d\n" acc _gbsNcDec)
        )
        printf("[GBS] 钻孔格式设置 %d:%d\n" _gbsNcInt _gbsNcDec)
        axlShell("setwindow pcb")
        axlShell("generaledit")
        axlShell("ncdrill param ")
        axlShell("generaledit ")
        axlShell("setwindow form.nc_parameters")
        axlShell(sprintf(nil "FORM nc_parameters integer_places %d " _gbsNcInt))
        axlShell(sprintf(nil "FORM nc_parameters decimal_places %d " _gbsNcDec))
        axlShell("FORM nc_parameters done  ")
        axlShell("setwindow pcb")
        axlShell("nctape_full ")
        axlShell("setwindow form.nc_drill")
        axlShell("FORM nc_drill execute  ")
        axlShell("FORM nc_drill close  ")
        axlShell("setwindow pcb")
        axlShell("generaledit")
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_RunPlctxt
; 功能    : plctxt FORM 宏导出坐标文件 place_txt.txt（21_Quick_ExportARK 实测）
; 返回值  : t
;------------------------------------------------------------------------
procedure( GBS_RunPlctxt()
    errset(axlSetVariable("place_text_filename" nil) nil)
    axlShell("setwindow pcb")
    axlShell("generaledit")
    axlShell("plctxt out")
    axlShell("setwindow form.plctxt")
    axlShell("FORM plctxt execute")
    axlShell("FORM plctxt cancel")
    axlShell("setwindow pcb")
    axlShell("generaledit")
    t
)

;------------------------------------------------------------------------
; 函数名  : GBS_RunIPC356
; 功能    : axlRunBatchDBProgram 调 ipc356_out 生成 IPC-D-356(A) 网表
; 参数    : ipcA - t 输出 IPC-D-356A；nil 输出 IPC-D-356
; 返回值  : t - 成功；nil - 失败
;------------------------------------------------------------------------
procedure( GBS_RunIPC356(ipcA)
    let((base fmt aFlag r)
        base = axlCurrentDesign()
        aFlag = ""
        when( ipcA
            aFlag = "-A "
        )
        fmt = sprintf(nil "ipc356_out %s%%s \"%s\"" aFlag base)
        r = errset(axlRunBatchDBProgram("ipc356_out" fmt) nil)
        if( r && car(r) == t then
            printf("[GBS] ipc356_out 输出完成\n")
            t
        else
            axlUIConfirm("IPC-D-356 输出失败，请检查 ipc356_out.log 或许可")
            nil
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_Classify
; 功能    : 把输出文件按类型分类复制到 outRoot 下的 CAM/ASM/SMT/PCB，
;           复制后清理当前目录原始文件。
;           v2.4：art/drl/rou/ipc/tap 不再依赖前后快照差集——同名旧文件
;           覆盖生成时按名比对必漏判（旧 .drl 滞留目录后文件名早已进入
;           beforeFiles，导致 .drl 实际已生成却永远不进 CAM）；这几类
;           CAM 产物一律纳入分类，log/txt 仍只收本次新增。
; 参数    : outRoot - 输出根目录；beforeFiles - 生成前 getDirFiles 快照
; 返回值  : 复制的文件份数
;------------------------------------------------------------------------
procedure( GBS_Classify(outRoot beforeFiles)
    let((afterFiles newFiles sweepExt ext cats movedOk)
        movedOk = 0
        afterFiles = getDirFiles("./")
        newFiles = setof( x afterFiles
            !equal(x ".") && !equal(x "..") && !member(x beforeFiles) && isFile(x) )
        sweepExt = '("art" "drl" "rou" "ipc" "tap")
        foreach( f afterFiles
            when( !equal(f ".") && !equal(f "..") && isFile(f)
                  && ( member(f newFiles) || member(GBS_FileExt(f) sweepExt)
                     || member(f '("art_param.txt" "nc_param.txt")) )
                ext = GBS_FileExt(f)
                cats = nil
                case( ext
                    ("art"
                        cats = GBS_FilmCats(GBS_StripExt(f))
                    )
                    ("drl"
                        cats = list("CAM")
                    )
                    ("rou"
                        cats = list("CAM")
                    )
                    ("ipc"
                        cats = list("CAM")
                    )
                    ("tap"
                        cats = list("CAM")
                    )
                    ("txt"
                        if( equal(lowerCase(f) "place_txt.txt") then
                            cats = list("SMT")
                        else
                            cats = list("CAM")
                        )
                    )
                    ; v3.0: .log 不归类，留在板子目录备查
                    (t
                        cats = nil
                    )
                )
                when( cats
                    printf("[GBS] %s -> %s\n" f buildString(cats ","))
                )
                foreach( c cats
                    when( GBS_CopyTo(f strcat(outRoot "/" c))
                        movedOk = movedOk + 1
                    )
                )
                when( cats
                    deleteFile(f)
                )
            )
        )
        printf("[GBS] 输出文件分类完成，共复制 %d 份\n" movedOk)
        movedOk
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_DoBrowse
; 功能    : 弹出目录选择框并回填输出路径
;------------------------------------------------------------------------
procedure( GBS_DoBrowse(fw)
    let((cur sel)
        cur = axlFormGetField(fw "outpath")
        unless( cur && !equal(cur "")
            cur = car(GBS_BoardDirFile())
        )
        sel = axlDMDirectoryBrowse(cur t ?title "选择输出目录")
        when( sel
            axlFormSetField(fw "outpath" GBS_Slash(sel))
        )
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_DoSelectAll
; 功能    : 勾选全部三个加工文件复选框
;------------------------------------------------------------------------
procedure( GBS_DoSelectAll(fw)
    axlFormSetField(fw "chk_gerber" t)
    axlFormSetField(fw "chk_drill" t)
    axlFormSetField(fw "chk_coord" t)
    t
)

;------------------------------------------------------------------------
; 函数名  : GBS_DoGenerate
; 功能    : "生成加工文件"主流程：建目录 -> 快照 -> 按勾选项生成 ->
;           分类复制 -> 汇报
;------------------------------------------------------------------------
; 函数名  : GBS_DxfLayerName
; 功能    : 生成 DXF 层名（class 内空格转下划线，拼 _subclass；
;           DXF 层名不宜带空格）
;------------------------------------------------------------------------
procedure( GBS_DxfLayerName(cls sub)
    prog((w res)
        res = ""
        foreach( w parseString(cls " ")
            res = strcat(res w "_")
        )
        return( strcat(res sub) )
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_RunExe
; 功能    : ipcBeginProcess 四件套拉起 Cadence 批处理 exe
;           （pitfalls 6.1 实证模式），捕获退出码与日志；
;           失败时把日志前 10 行打到命令行
; 参数    : exeName - 不带路径/扩展名的程序名（如 "a2dxf"）；
;           args - 命令行参数串
; 返回值  : 退出码（0 = 成功）；exe 不存在返回 -1
;------------------------------------------------------------------------
procedure( GBS_RunExe(exeName args)
    prog((exe cid rc logFile port line out)
        ; 17.4/24.1 布局 tools/bin；16.6 旧布局 tools/pcb/bin（实机盘点）
        exe = strcat(getShellEnvVar("CDSROOT") "/tools/bin/" exeName ".exe")
        unless( isFile(exe)
            exe = strcat(getShellEnvVar("CDSROOT") "/tools/pcb/bin/" exeName ".exe")
        )
        unless( isFile(exe)
            axlUIWPrint(nil "ERROR: 未找到 %s（CDSROOT=%s, 已试 tools/bin 与 tools/pcb/bin）"
                exe getShellEnvVar("CDSROOT"))
            return(-1)
        )
        logFile = axlTempFile()
        cid = ipcBeginProcess(strcat("\"" exe "\" " args) "" nil nil nil logFile)
        ipcWait(cid 3600 120)
        rc = ipcGetExitStatus(cid)
        ipcReadProcess(cid 1)
        when( rc != 0
            axlUIWPrint(nil "ERROR: %s 退出码 %d, 日志:" exeName rc)
            port = errset( infile(logFile) nil )
            when( and(port car(port))
                port = car(port)
                out = 0
                while( and(gets(line port) out < 10)
                    axlUIWPrint(nil "  %s" line)
                    out = out + 1
                )
                close(port)
            )
        )
        return(rc)
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_WriteDxfCnv
; 功能    : 按给定层列表生成 a2dxf 层转换文件(cnv)
;           （格式参照 Cadence 社区 DXF.il 实证：CLASS! /
;           SUBCLASS!DXF_LAYER! / END）
; 参数    : layerList - "CLASS/SUBCLASS" 全名列表
; 返回值  : cnv 临时文件路径；失败 nil
;------------------------------------------------------------------------
procedure( GBS_WriteDxfCnv(layerList)
    prog((cnvFile p layerStr cls sub)
        cnvFile = axlTempFile()
        p = outfile(cnvFile "w")
        unless( p
            axlUIWPrint(nil "ERROR: DXF 层转换文件创建失败")
            return(nil)
        )
        fprintf(p "This is the Layer Conversion File used for\n")
        fprintf(p "importing DXF data into Allegro/APD.\n\n")
        fprintf(p "CLASS!SUBCLASS!DXF_LAYER!\n\n")
        foreach( layer layerList
            layerStr = parseString(layer "/")
            cls = car(layerStr)
            sub = cadr(layerStr)
            when( and(cls sub)
                fprintf(p "%s!\n%s!%s!\n\n" cls sub GBS_DxfLayerName(cls sub))
            )
        )
        fprintf(p "END\n")
        close(p)
        return(cnvFile)
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_ExportDxfLayers
; 功能    : 按给定层列表输出 DXF 到指定目录（a2dxf -u MM）
; 参数    : outDir - 输出目录（已存在）；dxfName - 文件名；
;           layerList - "CLASS/SUBCLASS" 全名列表
;------------------------------------------------------------------------
procedure( GBS_ExportDxfLayers(outDir dxfName layerList)
    prog((cnvFile cmd designName rc)
        unless( layerList
            axlUIWPrint(nil "ERROR: 无可输出的层")
            return(nil)
        )
        cnvFile = GBS_WriteDxfCnv(layerList)
        unless( cnvFile
            return(nil)
        )
        designName = axlGetDrawingName()
        cmd = sprintf(nil "-u MM \"%s\" \"%s\" \"%s\""
            cnvFile strcat(outDir "/" dxfName) designName)
        rc = GBS_RunExe("a2dxf" cmd)
        if( rc == 0 && isFile(strcat(outDir "/" dxfName)) then
            axlUIWPrint(nil "DXF 输出完成: %s/%s" outDir dxfName)
        else
            axlUIWPrint(nil "ERROR: DXF 未生成(退出码 %d)" rc)
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_ExportDxf
; 功能    : 输出全板 DXF：收集全部底片层内容 -> CAM/<设计名>.dxf
;------------------------------------------------------------------------
procedure( GBS_ExportDxf(outRoot)
    prog((films film layers seen layer dxfName)
        films = axlGetParam("artwork")->groupMembers
        unless( films
            axlUIConfirm("当前设计没有底片(film)，DXF 依赖底片层内容，请先点 创建/更新Film")
            return(nil)
        )
        seen = nil
        foreach( film films
            layers = axlGetParam(strcat("artwork:" film))->groupMembers
            foreach( layer layers
                unless( member(layer seen)
                    seen = cons(layer seen)
                )
            )
        )
        dxfName = strcat(car(parseString(axlCurrentDesign() ".")) ".dxf")
        GBS_ExportDxfLayers(strcat(outRoot "/DXF") dxfName reverse(seen))
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_ExportStep
; 功能    : 输出 3D STEP：ipc 拉起 step_out -u MILLIMETER
;           输出到 CAM/<设计名>.stp
;------------------------------------------------------------------------
procedure( GBS_ExportStep(outRoot)
    prog((designName stpName rc)
        designName = axlGetDrawingName()
        stpName = strcat(car(parseString(axlCurrentDesign() ".")) ".stp")
        rc = GBS_RunExe("step_out"
            sprintf(nil "-u MILLIMETER -o \"%s\" \"%s\""
                strcat(outRoot "/3D/" stpName) designName))
        if( rc == 0 && isFile(strcat(outRoot "/3D/" stpName)) then
            axlUIWPrint(nil "STEP 输出完成: 3D/%s" stpName)
        else
            axlUIWPrint(nil "ERROR: STEP 未生成(退出码 %d)" rc)
        )
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_AssyLayers
; 功能    : 装配层列表：优先取 ASSEMBLY_TOP/BOTTOM 底片层内容，
;           无底片时回退标准装配层集（GBS_LayersExist 过滤存在性）
;------------------------------------------------------------------------
procedure( GBS_AssyLayers(side)
    prog((film layers std)
        film = strcat("ASSEMBLY_" side)
        layers = nil
        when( and(axlGetParam("artwork")->groupMembers
                  member(film axlGetParam("artwork")->groupMembers))
            layers = axlGetParam(strcat("artwork:" film))->groupMembers
        )
        unless( layers
            std = list("BOARD GEOMETRY/OUTLINE"
                strcat("PIN/ASSEMBLY_" side)
                strcat("REF DES/ASSEMBLY_" side)
                strcat("PACKAGE GEOMETRY/ASSEMBLY_" side)
                strcat("BOARD GEOMETRY/ASSEMBLY_" side))
            layers = GBS_LayersExist(std)
        )
        return(layers)
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_DoAssyDxf
; 功能    : 独立按钮：装配顶层/底层 DXF 输出到 ASM 目录
; 参数    : side - "TOP" / "BOTTOM"
;------------------------------------------------------------------------
procedure( GBS_DoAssyDxf(fw side)
    prog((outRoot dirFile dxfName)
        unless( axlOKToProceed()
            axlUIConfirm("当前状态不允许操作，请先退出其他命令")
            return(nil)
        )
        outRoot = axlFormGetField(fw "outpath")
        if( outRoot == nil || equal(outRoot "") then
            dirFile = GBS_BoardDirFile()
            outRoot = strcat(car(dirFile) cadr(dirFile))
            axlFormSetField(fw "outpath" outRoot)
        )
        outRoot = GBS_Slash(outRoot)
        unless( GBS_EnsureDir(strcat(outRoot "/DXF"))
            axlUIConfirm(sprintf(nil "无法创建目录：%s/DXF" outRoot))
            return(nil)
        )
        dxfName = sprintf(nil "%s_ASSY_%s.dxf"
            car(parseString(axlCurrentDesign() ".")) side)
        GBS_ExportDxfLayers(strcat(outRoot "/DXF") dxfName GBS_AssyLayers(side))
        return(t)
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_DoDxf / GBS_DoStep
; 功能    : 独立按钮：解析输出路径（同 DoGenerate 缺省逻辑）并确保
;           CAM 目录后，分别输出 DXF / 3D STEP
;------------------------------------------------------------------------
procedure( GBS_ResolveOutRoot(fw subDir)
    prog((outRoot dirFile)
        outRoot = axlFormGetField(fw "outpath")
        if( outRoot == nil || equal(outRoot "") then
            dirFile = GBS_BoardDirFile()
            outRoot = strcat(car(dirFile) cadr(dirFile))
            axlFormSetField(fw "outpath" outRoot)
        )
        outRoot = GBS_Slash(outRoot)
        unless( GBS_EnsureDir(strcat(outRoot "/" subDir))
            axlUIConfirm(sprintf(nil "无法创建目录：%s/%s" outRoot subDir))
            return(nil)
        )
        return(outRoot)
    )
)

procedure( GBS_DoDxf(fw)
    prog((outRoot)
        unless( axlOKToProceed()
            axlUIConfirm("当前状态不允许操作，请先退出其他命令")
            return(nil)
        )
        outRoot = GBS_ResolveOutRoot(fw "DXF")
        when( outRoot
            GBS_ExportDxf(outRoot)
        )
        return(t)
    )
)

procedure( GBS_DoStep(fw)
    prog((outRoot)
        unless( axlOKToProceed()
            axlUIConfirm("当前状态不允许操作，请先退出其他命令")
            return(nil)
        )
        outRoot = GBS_ResolveOutRoot(fw "3D")
        when( outRoot
            GBS_ExportStep(outRoot)
        )
        return(t)
    )
)

;------------------------------------------------------------------------
procedure( GBS_DoGenerate(fw)
    prog((outRoot bf doG doD doC ipcA dirFile films)
        outRoot = axlFormGetField(fw "outpath")
        if( outRoot == nil || equal(outRoot "") then
            dirFile = GBS_BoardDirFile()
            outRoot = strcat(car(dirFile) cadr(dirFile))
            axlFormSetField(fw "outpath" outRoot)
        )
        outRoot = GBS_Slash(outRoot)
        doG = GBS_CheckOn(fw "chk_gerber")
        doD = GBS_CheckOn(fw "chk_drill")
        doC = GBS_CheckOn(fw "chk_coord")
        ipcA = equal(axlFormGetField(fw "ipc_ver") "IPC-D-356A")
        unless( doG || doD || doC
            axlUIConfirm("请至少勾选一项加工文件")
            return(nil)
        )
        unless( axlOKToProceed()
            axlUIConfirm("当前状态不允许操作，请先退出其他命令")
            return(nil)
        )
        unless( GBS_EnsureDir(outRoot)
            axlUIConfirm(sprintf(nil "无法创建输出目录：%s" outRoot))
            return(nil)
        )
        foreach( d '("CAM" "ASM" "SMT" "PCB")
            unless( GBS_EnsureDir(strcat(outRoot "/" d))
                axlUIConfirm(sprintf(nil "无法创建子目录：%s/%s" outRoot d))
                return(nil)
            )
        )
        films = axlGetParam("artwork")->groupMembers
        when( doG && null(films)
            axlUIConfirm("当前设计没有任何底片(film)，请先点 创建/更新Film")
            return(nil)
        )
        bf = getDirFiles("./")
        when( doG
            GBS_RunArtwork()
        )
        when( doD
            GBS_RunNCDrill()
            GBS_RunNCRoute()
        )
        when( doC
            GBS_RunPlctxt()
            GBS_RunIPC356(ipcA)
        )
        GBS_Classify(outRoot bf)
        ; 当前 PCB 文件复制到 PCB 目录
        dirFile = axlGetDrawingName()
        when( dirFile && isFile(dirFile)
            errset(axlOSFileCopy(GBS_Slash(dirFile)
                       strcat(outRoot "/PCB/" cadr(axlDMFileParts(dirFile)) ".brd")
                       nil) nil)
        )
        axlUIConfirm(sprintf(nil "加工文件已生成并分类到：%s" outRoot))
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : GBS_MainCB
; 功能    : 主表单回调分发
;------------------------------------------------------------------------
procedure( GBS_MainCB(fw)
    case( fw->curField
        ("browse"
            GBS_DoBrowse(fw)
        )
        ; 定义参数：一键静默调好光绘+数控+钻孔图例全部参数（内置默认值，不弹表单）
        ("btn_artparam"
            GBS_ApplyArtParams()
            GBS_ApplyNCParams()
            GBS_ApplyLegendParams()
            GBS_WriteNCParam()
        )
        ("btn_filmupd"
            GBS_FilmBuild()
        )
        ; 设置光绘：打开系统光绘控制面板（查看/核对 定义参数 写入的结果）
        ("btn_artsetup"
            axlShell("setwindow pcb")
            axlShell("artwork ")
        )
        ; 数控参数：打开系统数控参数面板（同上，供查看核对）
        ("btn_ncparam"
            axlShell("setwindow pcb")
            axlShell("ncdrill param ")
        )
        ; 设置钻孔/设置槽孔/钻孔图例 是生成入口（打开系统对话框执行
        ; 生成），不是参数持有者——维持打开表单不变
        ("btn_ncsetup"
            axlShell("setwindow pcb")
            axlShell("nctape_full ")
        )
        ("btn_pdfasm"
            GBS_PdfOut(fw "装配层pdf" "装配层底片（ASSEMBLY_TOP / ASSEMBLY_BOTTOM）")
        )
        ("btn_pdfsilk"
            GBS_PdfOut(fw "丝印层pdf" "丝印层底片（SILKSCREEN_TOP / SILKSCREEN_BOTTOM）")
        )
        ("btn_slotsetup"
            axlShell("setwindow pcb")
            axlShell("NCroute ")
        )
        ("btn_legend"
            axlShell("setwindow pcb")
            axlShell("ncdrill legend ")
        )
        ("btn_dxf"
            GBS_DoDxf(fw)
        )
        ("btn_step"
            GBS_DoStep(fw)
        )
        ("btn_dxfat"
            GBS_DoAssyDxf(fw "TOP")
        )
        ("btn_dxfab"
            GBS_DoAssyDxf(fw "BOTTOM")
        )
        ("btn_all"
            GBS_DoSelectAll(fw)
        )
        ("btn_gen"
            GBS_DoGenerate(fw)
        )
        ("done"
            axlFormClose(fw)
        )
        (t
            nil
        )
    )
    when( fw->doneState != 0
        axlFormClose(fw)
    )
    t
)

;------------------------------------------------------------------------
; 函数名  : GBS_Run
; 功能    : 模块入口：加载主表单并回填默认值（gbs 命令）
; 示例    : 在 Allegro 命令行输入 gbs
;------------------------------------------------------------------------
procedure( GBS_Run()
    prog((f dirFile)
        f = strcat(ASTB_GLOBAL->FormPath "/mfg_gerbersetup.form")
        _gbsForm = axlFormCreate((gensym) f '(e inner) 'GBS_MainCB t)
        unless( _gbsForm
            axlUIConfirm("无法加载表单 mfg_gerbersetup.form，请检查 forms 目录")
            return(nil)
        )
        axlFormDisplay(_gbsForm)
        dirFile = GBS_BoardDirFile()
        axlFormSetField(_gbsForm "outpath" strcat(car(dirFile) cadr(dirFile)))
        axlFormSetField(_gbsForm "chk_gerber" t)
        axlFormSetField(_gbsForm "chk_drill" t)
        axlFormSetField(_gbsForm "chk_coord" t)
        axlFormSetField(_gbsForm "ipc_ver" "IPC-D-356A")
        t
    )
)

printf("[ASTB] manufacturing/mfg_gerbersetup.il loaded, command: gbs\n")
