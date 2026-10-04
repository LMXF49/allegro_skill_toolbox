;========================================================================
; 文件名    : text_addchinese.il
; 作者      : ASTB Team
; 创建日期  : 2026-07-19
; 版本      : 3.9
; 功能描述  : 添加中文字符（仿凡亿 Add Chinese Text 表单）：
;             a) 表单收集：Chinese text、Font type（内置常用中文字体 + ...
;                浏览 ttf/ttc）、Font size (mil)、Font gap (times)、Class、
;                Subclass（axlSubclassFormPopup 颜色块下拉）、Drawing Type
;                （Line / Shape / AntiShape 单选）；
;             b) 流程：SKILL 写 job 文件（GBK）-> ipcBeginProcess 直起
;                Python 子进程（fontTools 提 TTF 轮廓，bat+system 为回退）
;                -> 读轮廓数据（mil）-> axlEnterPoint 连续点击放置，
;                右键菜单完成/撤销，退出后命令 achu 仍可撤销；
;             c) 绘制：Line = 0 宽轮廓线；Shape = 逐字形 open shape + void
;                自动挖孔；AntiShape = 外框 shape 减全部字形轮廓、字形内孔
;                以独立 shape 补回（无需 axlPolyOperation）。
; 依赖模块  : forms/text_addchinese.form、python/ttf_outline.exe
;             （v3.8 起优先，PyInstaller 单文件；缺失时退回
;             python/ttf_outline.py + 解释器）、
;             core/trans.il（ASTB_DBTransactionMark）、
;             ASTB_GLOBAL->ToolboxPath / FormPath
; 编码      : GBK（含中文注释）
; 修改记录  :
;   2026-07-19 v1.0 ASTB Team 初始创建
;   2026-07-19 v1.1 ASTB 实机修复：字符串比较改用 equal（SKILL ==/!= 为身份
;                   比较，导致 magic 头误判、S/H 轮廓漏画、默认子类不选中）；
;                   return 收敛进 prog（本版 procedure 无 prog 语义）；
;                   提取失败时回显 python 日志（ttf_outline.py 写 .log）
;   2026-07-19 v1.2 ASTB 实机修复：gets 读行保留行尾 \n（extracta 排障手册
;                   第 3 条），每个 gets 后剥 \n，否则 magic 头永远误判
;   2026-07-19 v1.3 ASTB 实机修复："点添加没反应"全流程反馈——提取前
;             printf 进度提示（大字体提取耗时可见）；提取为空、绘制 0 对象
;             均明确弹窗；python 端 0 字形时写错误日志并非零退出（SKILL 会弹出
;             真实原因）
;   2026-07-19 v1.4 ASTB 实机修复：提取调用命令去掉 ""..."" 双重引号
;             包裹（cmd 直接拒绝，rc=123/9009，python 从未运行——这是
;             "提取失败/没反应"的真正根因）；成败改以 dat 文件存在为准
;             （兼容 system 返回值差异）；失败时命令窗口打印完整诊断
;   2026-07-19 v1.5 ASTB 实机修复：system() 改为执行生成的 .bat 批处理
;             文件（cmd /c 对内联命令的引号剥离规则与 bat 行解析不同，
;             任何内联引号构造都无法保证两边正确；bat 行单层引号
;             构造已在 17.4 本机实测 rc=0）
;   2026-07-19 v1.6 ASTB 实机修复：bat 内清 PYTHONHOME/PYTHONPATH（防
;             Allegro 进程环境污染 venv 解释器致 fontTools 导入失败且无
;             日志）；bat 全程写 ach_trace.txt（启动标记+stdout/stderr+退出码），
;             失败时命令窗口可见真实原因
;   2026-07-19 v1.7 ASTB 实机修复：v1.6 实机 system() 返回 0 但 bat 未
;             执行（无 trace 无 dat），且"python 0 字形退出"时 dat 仅有
;             magic 头会被成功路径静默删光。提取改走 ipcBeginProcess 直起
;             子进程（Cadence IPC 手册标准进程 API，绕开 system 黑盒，
;             退出码与输出可见），bat+system 降为回退；dat 解析为 nil 时
;             打印行数/前 5 行/python 日志并保留全部临时文件取证；
;             ParseDat 各失败路径补 printf；python 日志记录解码后 TEXT
;   2026-07-19 v1.8 ASTB 实机修复：v1.7 实机 dat 完好（372 行、结构经
;             字节级验证合法）ParseDat 仍返回 nil 且无诊断输出。ParseDat
;             记录分发由 case 改为 if/equal（排除 case 对 parseString
;             产物的匹配差异）；全函数加记录级 trace（进入/记录类型/轮廓
;             点数/解析计数）；Extract 侧 errset 包裹解析调用让异常现形；
;             加载信息带版本号便于核对实机版本；进度提示"字符"改"字节"
;             （GBK 中文 1 字=2 字节，strlen 按字节计）
;   2026-07-19 v1.9 ASTB 实机修复：v1.8 实机 trace 显示 ParseDat 全部记录
;             解析成功（"解析出 1 个字形"已打印），调用方却收到 nil——唯一
;             未经实机验证的剩余函数是 reverse。glyphs 改为 cur+append1
;             正序累积、函数尾部直接返回 glyphs，彻底不再调用 reverse；
;             errset 失败时转储 errset.errset（错误详情属性），调用方打印
;             返回值判定（成功+长度 / 失败+错误详情），返回值去向一目了然
;   2026-07-19 v2.0 ASTB 实机修复：v1.9 实机证实 ParseDat 内部
;             length(glyphs)=1 而调用方 car(errset(...)) length=0——prog 或
;             errset 的返回值约定在本环境会丢失大结构（疑似 errset 第二参
;             非 nil 时返回 t 而非 (值)）。解析结果改经全局 _achGlyphs
;             通道传递（全局赋值不依赖 prog/errset 返回值约定），errset
;             返回值仅作诊断打印（t / 列表长度 / errset.errset 三分支）
;   2026-07-19 v2.1 ASTB 实机修复：v2.0 诊断打印误将 cond 与括号分行书写
;             （SKILL 特殊形式 cond( 必须连写，分行后 cond 被当作变量
;             引用报 unbound variable），改为 if/else 链；全局通道本身
;             已验证可行（"写入全局通道"正常打印）
;   2026-07-20 v2.2 ASTB 实机修复：Extract->OnAdd 的 prog 返回值再次丢失
;             （Extract 内 glyphs 长度 1，OnAdd 收到 nil 弹"未能提取"）——
;             证实本环境 prog 返回大结构随机丢失（GC 风格，同一结构
;             ParseDat->errset 一跳碰巧存活、Extract->OnAdd 一跳丢失），
;             所有跨函数大结构传递统一改全局 _achGlyphs 通道，OnAdd
;             忽略 Extract 返回值直接读全局
;   2026-07-20 v2.3 ASTB 实机修复：放置创建 0 对象——AXL 几何函数的点
;             必须是 x:y 点对（cons dotted pair），此前 ACH_ContourPts
;             生成二维 list 被 axlDBCreateLine 拒绝（errset 静默吞错无
;             迹可查）；点对格式修正后 Line/Shape/AntiShape 三模式同时
;             受益；绘制 errset 第二参改 t 让报错可见
;   2026-07-20 v2.4 ASTB 实机修复：放置时 *Error* car: argument #1 should
;             be a list——PlaceLoop 误用 car(org) 只传 x 坐标（axlEnterPoint
;             返回的就是 (x y) 点表），绘制函数对浮点 car 报错；改直接传 org
;   2026-07-20 v2.5 ASTB 实机修复：cons(浮点 浮点) 报 argument #2 should
;             be a list——本运行时 cons 只接受 list 第二参，无法用其构造
;             x:y 点对（手册示例的 9150:4450 是读入期字面量，不经 cons）；
;             新增 ACH_MakePt 用 rplacd 直接改造 cons 单元生成点对
;             （readstring 字面量语法兜底），ACH_ContourPts 改走该函数
;   2026-07-20 v2.6 ASTB 实机修复：点对已正确（日志可见 19.00008:119.0461
;             标准点对），但 axlDBCreateLine 仍创建 0 对象且内部
;             axlDBCreatePath 报 Not a floating point number! - range
;             （代码全文无 range 字样，疑似 17.4 S039 的 DBCreateLine
;             包装器内部问题）——Line 模式改走手册标准三步
;             axlPathStart+axlDBCreatePath（p.311/p.736/p.753 原例），
;             并保留 (x y) 二维表点兜底重试，一次复测即可判定本机
;             接受的点格式
;   2026-07-20 v2.7 ASTB 实机判定：v2.6 复测二维表通道创建成功（"我"
;             字 2 条轮廓均落板）——本机 axlPathStart/axlDBCreatePath
;             只接受 (x y) 二维表点，手册 x:y 点对被内部拒绝；统一
;             撤掉点对通道（删 ACH_MakePt/ContourPts2），
;             ACH_ContourPts 直接生成二维表点，Shape/AntiShape 随之
;             修复；shape 系 errset 第二参 nil 改 t 并检查 Void/Close
;             返回值（挖孔失败时提示该层可能不允许 void）
;   2026-07-20 v2.8 用户需求：放置中右键无"完成/撤销"、完成后也无法
;             撤销——axlDBTransaction* 不能跨命令保留（手册 p.854：
;             SKILL 终止时活动事务被取消，无法用来支持 undo），改为
;             模块自维护撤销：各绘制函数把新建 dbid 记入全局
;             _achLastBatch，每次点击作为一批压入 _achPlaced；放置循环
;             挂 axlUIPopup 右键菜单（完成/撤销），撤销即逐批
;             axlDeleteObject；命令 achu 在完成退出后仍可撤销
;   2026-07-20 v2.9 实机修复（按 practical-pitfalls 2.1/2.2/2.3）：v2.8
;             右键只剩 Snap pick to（popup 中文标签触发 Invalid
;             character，菜单创建失败），且 while(!_achDone) 无法区分
;             "菜单动作的 nil"与"done/cancel 的 nil"，命令行 done 退不出
;             ——popup 标签改英文 Done/Undo；ach 注册补
;             ?doneCmd/?cancelCmd 'ACH_PopDone ?undo nil（interactive
;             命令必须显式注册，否则内建 Done 只调 axlFinishEnterFun
;             不置退出标志）；ACH_PopDone 补 axlFinishEnterFun 解除
;             拾取阻塞（errset 包裹）；axlEnterPoint 返回值改 listp
;             防御，_achPopped 标志区分 Undo 菜单动作（继续等待）与
;             done/cancel（退出）
;   2026-07-20 v3.0 实机修复：v2.9 加载即失败——手册 p.954
;             axlCmdRegister 签名只有 ?cmdType/?doneCmd/?cancelCmd，
;             没有 ?undo；?undo nil 属非法关键字，注册行在加载期报错、
;             文件加载中止，内存里实际还是 v2.8（症状与 v2.9 复测完全
;             一致：无菜单 + done 退不出）。撤销 doneCmd/cancelCmd
;             方案（工具箱 9 个实证模块无一使用），整体改抄
;             via_stitching 实证模式：popup 回调用 ASCII 字符串表达式
;             （Done 置 _achDone + axlUIPopupSet(nil) +
;             axlFinishEnterFun；Undo 调 ACH_UndoLast 不解除拾取），
;             每次 enter 返回后重设 popup，循环条件 org && !_achDone
;   2026-07-20 v3.1 实机复测通过（右键 Done/Undo、命令行 done 退出、
;             achu 撤销均正常），出静默正式版：移除 ParseDat 记录级
;             trace / ipc 启动与退出码 / 全局通道取回等调试打印，
;             保留用户进度提示（提取中/完成/放置/撤销计数）与全部
;             失败路径取证打印；提示语统一为菜单实际标签 Done/Undo
;   2026-07-20 v3.2 ASTB 实机增强：
;             a）文字吸附鼠标：提取后把全部字形轮廓装入动态光标缓冲
;                （axlClearDynamics + axlPathStart +
;                axlAddSimpleMoveDynamics，手册 p.350 模式；缓冲跨多次
;                enter 有效，点用 (x y) 二维表，原点 list(0.0 0.0)）；
;             b）Subclass 旁新增色块复选框 fvis：背景 = 所选层颜色号
;                （axlFormColorize），勾选态 = 层可见性，点击经
;                axlLayerGet/Set + axlVisibleUpdate 开关该层显示；
;             c）右键 Done 改走命名函数串 ACH_DoneMark（printf 留痕 +
;                axlClearDynamics + FinishEnterFun），排查不退出时
;                可凭 [ACH] Done 判断弹的是否本工具菜单
;   2026-07-20 v3.3 ASTB 实机修复（v3.2 两项不生效）：
;             a）动态预览零效果：ACH_AddDyn 三形态参数探测
;                （list 原点+ref_point / rplacd 点对原点 / 无
;                ref_point），逐形态打印 ret 与 errset.errset，
;                首个可用形态记忆复用；
;             b）色块开关无效：改走 layer_view 实证 API
;                axlVisibleLayer + axlVisibleUpdate(t)，并用
;                axlIsVisibleLayer 回读校验；回调入口与
;                RefreshColor 增加 printf（分辨回调未触发 vs
;                API 失败）
;   2026-07-20 v3.4 ASTB 实机修复：
;             a）色块语义按用户指定：层开=层颜色、层关=熄灭
;                （black/默认），勾选态同步，点击切换后重刷；
;             b）切绘制类型再放仍是旧类型：dtype 改单选回调即记
;                （_achDType 全局），OnAdd 不再读 CHECKLIST 组字段，
;                并打印本次类型；加 _achPlacing 防重入锁（上次放置
;                未退出时点添加会明确提示）；
;             c）ANTISHAPE 预览增外框矩形（与创建同一外扩算法）；
;                SHAPE 预览保持轮廓（dynamics 无填充能力）
;   2026-07-21 v3.5 ASTB 实机修复：
;             a）色块不随层开关：可见性改以 axlIsVisibleLayer 为准
;                （手册 p.167：返回 t/nil；errset 成功即列表，层不可见
;                时 car 为 nil，可与读取失败区分），axlLayerGet 的
;                q->visibility 实机疑似不随开关更新，仅作读取失败兜底；
;                trace 同打印 color/qVis/isVis 三者对比取证；
;             b）主回调分发后（doneState==0）无条件重刷色块一次，
;                覆盖用户在 Allegro 颜色对话框改层显隐后回到本表单
;                的场景（点表单任意处即同步）
;   2026-07-21 v3.6 ASTB 实机修复：
;             a）"开关层的开关也没用了"：根因是单成员 CHECKLIST 组
;                为收音机语义——选中态点不动，v3.4/v3.5 读控件勾选态
;                决定目标状态，导致只能开不能关。v3.6 改为色块是
;                无状态按钮：勾选态恒置 nil（每次点击都是 关->开
;                翻转、必触发回调），点击时以 axlIsVisibleLayer 读
;                真实层状态取反写入，层状态只以色块背景色表达
;               （开=层色、关=黑），与系统层面板同步显示
;   2026-07-21 v3.7 ASTB：
;             a）内置便携 Python 运行时 python/runtime（CPython 3.12
;                + fontTools 4.62.1，约 45MB，裁 tcl/test/pip），
;                ACH_GetPython 优先级改为：ASTB_ACH_PYTHON 环境变量 >
;                _achPython > 内置运行时 > Kimi 托管运行时 > PATH；
;                换机整体拷贝工具箱目录即用，免装 Python、全程不联网
;   2026-07-21 v3.8 ASTB：
;             a）45MB 便携运行时换成 PyInstaller 单文件
;                python/ttf_outline.exe（约 16MB，排除 numpy/pandas 等
;                fontTools 可选依赖；冒烟：提取"我Al"3 字形 2.4s），
;                ACH_Extract 改为 exe 优先、解释器+脚本链兜底，
;                ipc/bat 两条命令路径均支持无脚本参数模式
;   2026-08-13 v3.9 ASTB Team 16.6 兼容：axlDBCreateVoid(nil ...) 改
;                显式传打开铜皮 dbid（16.6 上 nil 取不到打开态报挖孔
;                失败）；表单标签全中文化（forms/text_addchinese.form）
;========================================================================
;
; 注意：
;   1. 本模块向数据库写入图形对象（line/shape）：放置前请先保存设计；
;      撤销由模块自维护（右键"撤销"或命令 achu 逐批回退）——Allegro
;      标准 Ctrl+Z 不覆盖 AXL 创建的对象，axlDBTransaction* 也不能
;      跨命令保留（手册 p.854），故未采用。
;   2. 字体提取优先用 python/ttf_outline.exe（v3.8 起随包分发，PyInstaller
;      单文件，目标机免装 Python、运行全程不联网）；exe 缺失时退回
;      解释器+脚本链：ASTB_ACH_PYTHON 环境变量 > _achPython 全局 >
;      Kimi 托管运行时 > PATH 的 python（均需已装 fontTools）。
;   3. 中文经 GBK job 文件传递，不经过命令行，避免编码问题。
;   4. 轮廓数据坐标为 mil、Y 向上、相对整行文字原点；放置时按当前设计
;      单位换算。

unless( boundp('_achForm)   defvar(_achForm nil))
unless( boundp('_achPython) defvar(_achPython nil))
unless( boundp('_achGlyphs) defvar(_achGlyphs nil))
unless( boundp('_achDone)   defvar(_achDone nil))
unless( boundp('_achPlaced) defvar(_achPlaced nil))
unless( boundp('_achLastBatch) defvar(_achLastBatch nil))
unless( boundp('_achDynMode)   defvar(_achDynMode nil))
unless( boundp('_achDType)     defvar(_achDType "LINE"))
unless( boundp('_achPlacing)   defvar(_achPlacing nil))

axlCmdRegister( "ach" 'ACH_Run ?cmdType "interactive")
axlCmdRegister( "achu" 'ACH_UndoLast ?cmdType "interactive")

;------------------------------------------------------------------------
; 函数名  : ACH_GetPython
; 功能    : 取 Python 解释器路径，优先级：环境变量 ASTB_ACH_PYTHON >
;           _achPython 全局 > 工具箱内置便携运行时（python/runtime，
;           v3.7 起随包分发，目标机免装 Python）> Kimi 托管运行时
;           （本机开发环境）> PATH 中的 python
; 返回值  : 路径字符串
;------------------------------------------------------------------------
procedure( ACH_GetPython()
    let((p cand)
        p = getShellEnvVar("ASTB_ACH_PYTHON")
        unless( p && !equal(p "")
            p = _achPython
        )
        ; v3.7：内置便携运行时优先（随工具箱目录整体拷贝即可用）
        unless( p && !equal(p "")
            p = nil
            when( boundp('ASTB_GLOBAL) && ASTB_GLOBAL->InstallPath
                cand = strcat(ASTB_GLOBAL->InstallPath
                              "/python/runtime/python.exe")
                when( isFile(cand)
                    p = cand
                )
            )
        )
        unless( p && !equal(p "")
            cand = strcat("C:/Users/Lenovo/AppData/Roaming/kimi-desktop/"
                   "daimon-share/daimon/runtime/python/.venv/Scripts/python.exe")
            when( isFile(cand)
                p = cand
            )
        )
        unless( p && !equal(p "")
            p = "python"
        )
        p
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_Slash
; 功能    : 路径反斜杠转正斜杠
;------------------------------------------------------------------------
procedure( ACH_Slash(p)
    if( p && !equal(p "") then
        axlOSSlash(p)
    else
        p
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_MilFactor
; 功能    : mil 到当前设计单位的换算系数
; 返回值  : 浮点系数（mil 设计返回 1.0）
;------------------------------------------------------------------------
procedure( ACH_MilFactor()
    let((units f)
        units = axlGetParam("paramDesign")->units
        f = 1.0
        case( units
            ("millimeters" f = 0.0254)
            ("microns"     f = 25.4)
            ("inch"        f = 0.001)
            (t             f = 1.0)
        )
        f
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_FieldOn
; 功能    : 读取复选/单选框状态（兼容字符串模式 "t"/t）
;------------------------------------------------------------------------
procedure( ACH_FieldOn(fw fld)
    let((v)
        v = axlFormGetField(fw fld)
        if( v == t || equal(v "t") || equal(v "T") || equal(v "1") then t else nil )
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_RebuildSubclass
; 功能    : 按当前 Class 重建 Subclass 颜色块下拉并设置默认值
;           （BOARD GEOMETRY 优先 SILKSCREEN_TOP，否则取第一个；
;           当前值仍有效则保持）
;------------------------------------------------------------------------
procedure( ACH_RebuildSubclass(fw)
    let((cls r subs cur)
        cls = axlFormGetField(fw "fclass")
        unless( cls && !equal(cls "")
            cls = "BOARD GEOMETRY"
        )
        r = errset(axlGetParam(strcat("paramLayerGroup:" cls))->groupMembers nil)
        subs = car(r)
        when( subs
            axlSubclassFormPopup(fw "fsub" cls nil)
            cur = axlFormGetField(fw "fsub")
            if( equal(cls "BOARD GEOMETRY") && member("SILKSCREEN_TOP" subs) then
                axlFormSetField(fw "fsub" "SILKSCREEN_TOP")
            else
                unless( cur && member(cur subs)
                    axlFormSetField(fw "fsub" car(subs))
                )
            )
        )
        ACH_RefreshColor(fw)
        t
    )
)


;------------------------------------------------------------------------
; 函数名  : ACH_RefreshColor
; 功能    : 刷新 Subclass 旁色块：层开=背景填层颜色号、层关=背景熄灭
;           （'black，失败退回系统默认）。v3.6 起色块当无状态按钮——
;           勾选态恒置 nil（单成员 CHECKLIST 组是收音机语义，选中后
;           用户点不动；恒置 nil 保证每次点击都是 关->开 的状态翻转、
;           必触发回调），层状态只以背景色表达
;------------------------------------------------------------------------
procedure( ACH_RefreshColor(fw)
    let((cls sub layer r q r2 isVis vis)
        cls = axlFormGetField(fw "fclass")
        sub = axlFormGetField(fw "fsub")
        when( cls && sub && !equal(cls "") && !equal(sub "")
            layer = strcat(cls "/" sub)
            q = nil
            r = errset(q = axlLayerGet(layer) nil)
            when( r && q
                ; v3.5：可见性以 axlIsVisibleLayer 为准（手册 p.167 实证
                ; t/nil）；errset 成功返回单元素表（层不可见时 car 为
                ; nil），读取失败才退回 q->visibility 兜底
                isVis = errset(axlIsVisibleLayer(layer) nil)
                if( isVis then vis = car(isVis) else vis = q->visibility )
                if( vis then
                    axlFormColorize(fw "fvis" 'background q->color)
                else
                    r2 = errset(axlFormColorize(fw "fvis" 'background 'black) nil)
                    unless( r2 && car(r2)
                        axlFormColorize(fw "fvis" 'background nil)
                    )
                )
                axlFormSetField(fw "fvis" nil)
                printf("[ACH] 色块刷新：%s color=%L qVis=%L isVis=%L\n"
                       layer q->color q->visibility
                       if( isVis then car(isVis) else "err" ))
            )
        )
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_OnVisToggle
; 功能    : 色块点击：不读控件勾选态（v3.6——单成员 CHECKLIST 组是
;           收音机语义，选中态点不动，读值不可靠），以 axlIsVisibleLayer
;           读真实层状态取反写入（layer_view 实证序列
;           axlVisibleLayer(层名 状态) + axlVisibleUpdate(t)），
;           每次点击必翻转，最后重刷色块
;------------------------------------------------------------------------
procedure( ACH_OnVisToggle(fw)
    prog((cls sub layer isVis cur new)
        cls = axlFormGetField(fw "fclass")
        sub = axlFormGetField(fw "fsub")
        unless( cls && sub && !equal(cls "") && !equal(sub "")
            axlUIConfirm("请先选择 Class / Subclass")
            return(nil)
        )
        layer = strcat(cls "/" sub)
        isVis = errset(axlIsVisibleLayer(layer) nil)
        if( isVis then cur = car(isVis) else cur = t )
        new = !cur
        printf("[ACH] 色块点击：%s 实际 %L -> 目标 %L\n" layer cur new)
        errset(axlVisibleLayer(layer new) nil)
        errset(axlVisibleUpdate(t) nil)
        ACH_RefreshColor(fw)
        t
    )
)
;------------------------------------------------------------------------
; 函数名  : ACH_BrowseFont
; 功能    : "..." 按钮：浏览 ttf/ttc 字体文件并回填（失败时提示手动粘贴）
;------------------------------------------------------------------------
procedure( ACH_BrowseFont(fw)
    let((r)
        r = errset(axlDMFileBrowse("font" nil
                       ?title "选择字体文件"
                       ?optFilters "Font files(*.ttf;*.ttc)|*.ttf;*.ttc|All files(*.*)|*.*"
                       ) nil)
        if( car(r) then
            axlFormSetField(fw "font" ACH_Slash(car(r)))
        else
            axlUIConfirm("浏览不可用，请将字体路径直接粘贴到 Font type 输入框")
        )
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_GetFont
; 功能    : 取字体文件路径；支持只输字体名时自动到 C:/Windows/Fonts 补全
; 返回值  : 存在的路径字符串；找不到返回 nil
;------------------------------------------------------------------------
procedure( ACH_GetFont(fw)
    let((v cand)
        v = axlFormGetField(fw "font")
        if( v && isFile(v) then
            ACH_Slash(v)
        else
            cand = nil
            when( v && !equal(v "")
                foreach( ext '(".ttf" ".ttc" ".TTF" ".TTC")
                    unless( cand
                        when( isFile(strcat("C:/Windows/Fonts/" v ext))
                            cand = strcat("C:/Windows/Fonts/" v ext)
                        )
                    )
                )
            )
            cand
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_Extract
; 功能    : 写 GBK job 文件 -> 提取轮廓
;           v1.7：主用 ipcBeginProcess 直起子进程（绕开 system 黑盒，退出码
;           与输出可见；路径含空格时自动跳过 ipc 走 bat）；bat+system 为
;           回退；dat 解析为 nil 时打印行数/前 5 行/python 日志并保留全部
;           临时文件取证（仅成功路径才清理临时文件）
; 参数    : font - 字体路径；text - 文字；size - 字号 mil；gap - 字距倍数
; 返回值  : 字形结构列表 ((adv . contours) ...)，失败 nil
;------------------------------------------------------------------------
procedure( ACH_Extract(font text size gap)
    prog((job dat bat trace ipcLog port cmd py script rc glyphs log logp trp
          line msg cid out n head dp tried reading useIpc s exe)
        job = strcat(axlTempDirectory() "/ach_job.txt")
        dat = strcat(axlTempDirectory() "/ach_outline.dat")
        bat = strcat(axlTempDirectory() "/ach_run.bat")
        trace = strcat(axlTempDirectory() "/ach_trace.txt")
        ipcLog = strcat(axlTempDirectory() "/ach_ipc.log")
        port = outfile(job "w")
        unless( port
            axlUIConfirm("无法创建临时 job 文件，请检查 TEMPDIR 权限")
            return(nil)
        )
        fprintf(port "FONT=%s\n" font)
        fprintf(port "SIZE=%.4f\n" size)
        fprintf(port "GAP=%.4f\n" gap)
        fprintf(port "TEXT=%s\n" text)
        close(port)
        ; v3.8：优先打包好的单文件 exe（随包分发约 16MB，目标机免装
        ;       Python）；缺失时退回 解释器+脚本 链（ACH_GetPython）
        exe = strcat(ASTB_GLOBAL->ToolboxPath "/python/ttf_outline.exe")
        if( isFile(exe) then
            py = exe
            script = nil
        else
            py = ACH_GetPython()
            script = strcat(ASTB_GLOBAL->ToolboxPath "/python/ttf_outline.py")
            unless( isFile(script)
                axlUIConfirm(sprintf(nil "找不到提取脚本：%s" script))
                return(nil)
            )
        )
        ; 清旧产物，避免以 dat 存在误判成功
        errset(deleteFile(dat) nil)
        errset(deleteFile(strcat(dat ".log")) nil)
        errset(deleteFile(trace) nil)
        errset(deleteFile(ipcLog) nil)
        ;----------------------------------------------------------------
        ; 方式 1（优先）：ipcBeginProcess 直起子进程
        ; 说明：cmd 不带引号（路径含空格时 ipc 分词不可靠，改走 bat 回退）
        ;----------------------------------------------------------------
        tried = nil
        useIpc = t
        foreach( s list(py script job dat)
            when( s && index(s " ")
                useIpc = nil
            )
        )
        when( useIpc
            if( script then
                cmd = strcat(py " " script " --job " job " --out " dat)
            else
                cmd = strcat(py " --job " job " --out " dat)
            )
            rc = errset(ipcBeginProcess(cmd "" nil nil nil ipcLog) nil)
            cid = car(rc)
            if( cid then
                tried = t
                errset(ipcWait(cid 3600 120) nil)
                rc = errset(ipcIsAliveProcess(cid) nil)
                if( car(rc) then
                    errset(ipcKillProcess(cid) nil)
                    printf("[ACH] 子进程超时（120s）已强制终止\n")
                )
                rc = errset(ipcGetExitStatus(cid) nil)
                ; 排空子进程输出回显到命令窗口（python 侧汇总行）
                n = 0
                reading = t
                while( n < 20 && reading
                    rc = errset(ipcReadProcess(cid 1) nil)
                    out = car(rc)
                    if( out then
                        printf("[ACH] py> %s" out)
                        n = n + 1
                    else
                        reading = nil
                    )
                )
            else
                printf("[ACH] ipcBeginProcess 不可用，改用 bat 方式\n")
            )
        )
        ;----------------------------------------------------------------
        ; 方式 2（回退）：bat + system()
        ;----------------------------------------------------------------
        unless( tried
            port = outfile(bat "w")
            unless( port
                axlUIConfirm("无法创建临时 bat 文件，请检查 TEMPDIR 权限")
                return(nil)
            )
            fprintf(port "@echo off\n")
            fprintf(port "set PYTHONHOME=\n")
            fprintf(port "set PYTHONPATH=\n")
            fprintf(port "echo BAT_START > \"%s\"\n" trace)
            if( script then
                fprintf(port "\"%s\" \"%s\" --job \"%s\" --out \"%s\" >> \"%s\" 2>&1\n"
                        py script job dat trace)
            else
                fprintf(port "\"%s\" --job \"%s\" --out \"%s\" >> \"%s\" 2>&1\n"
                        py job dat trace)
            )
            fprintf(port "echo BAT_RC=%%ERRORLEVEL%% >> \"%s\"\n" trace)
            close(port)
            printf("[ACH] 批处理：%s\n" bat)
            rc = errset(system(strcat("call \"" bat "\"")) nil)
            printf("[ACH] system 返回：%L\n" car(rc))
            unless( isFile(trace)
                printf("[ACH] 警告：bat 未被执行（无 ach_trace.txt）\n")
            )
        )
        ;----------------------------------------------------------------
        ; 结果判定与取证（仅解析成功才清理临时文件）
        ;----------------------------------------------------------------
        if( isFile(dat) then
            glyphs = nil
            _achGlyphs = nil
            rc = errset(ACH_ParseDat(dat) t)
            ; v2.0：解析结果走全局通道；errset 仅失败时打印错误详情
            glyphs = _achGlyphs
            unless( rc
                printf("[ACH] errset 捕获错误：%L\n" errset.errset)
            )
            if( glyphs then
                ; 成功：清理全部临时文件
                errset(deleteFile(job) nil)
                errset(deleteFile(dat) nil)
                errset(deleteFile(strcat(dat ".log")) nil)
                errset(deleteFile(bat) nil)
                errset(deleteFile(trace) nil)
                errset(deleteFile(ipcLog) nil)
                glyphs
            else
                ; dat 存在但解析为 nil：打印行数+前 5 行+python 日志，保留现场
                n = 0
                head = ""
                dp = infile(dat)
                when( dp
                    while( gets(line dp)
                        n = n + 1
                        when( n <= 5
                            head = strcat(head line)
                        )
                    )
                    close(dp)
                )
                printf("[ACH] dat 共 %d 行，前 5 行：\n%s" n head)
                msg = ""
                log = strcat(dat ".log")
                when( isFile(log)
                    logp = infile(log)
                    when( logp
                        while( gets(line logp)
                            msg = strcat(msg line)
                        )
                        close(logp)
                    )
                )
                when( !equal(msg "")
                    printf("[ACH] python 日志：\n%s" msg)
                )
                axlUIConfirm(sprintf(nil
                    "轮廓数据为空或解析失败（dat 共 %d 行）。临时文件已保留在 %s ，请把 ach_job.txt / ach_outline.dat / ach_outline.dat.log 发给开发排查。"
                    n axlTempDirectory()))
                nil
            )
        else
            ; 无 dat：python 未产出，读 log / ipcLog / trace 取证，保留全部文件
            msg = ""
            log = strcat(dat ".log")
            when( isFile(log)
                logp = infile(log)
                when( logp
                    while( gets(line logp)
                        msg = strcat(msg line)
                    )
                    close(logp)
                )
            )
            when( equal(msg "") && isFile(ipcLog)
                trp = infile(ipcLog)
                when( trp
                    while( gets(line trp)
                        msg = strcat(msg line)
                    )
                    close(trp)
                )
            )
            when( equal(msg "") && isFile(trace)
                trp = infile(trace)
                when( trp
                    while( gets(line trp)
                        msg = strcat(msg line)
                    )
                    close(trp)
                )
            )
            when( strlen(msg) > 600
                msg = substring(msg 1 600)
            )
            printf("[ACH] 提取失败日志：\n%s\n" msg)
            axlUIConfirm(sprintf(nil
                "字体轮廓提取失败（python 未生成数据文件）。临时文件已保留在 %s ，请把 ach_*.* 发给开发排查。\n%s"
                axlTempDirectory() msg))
            nil
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_ParseDat
; 功能    : 解析轮廓数据文件（ASCII）：G=字形 advance，S/H=轮廓及点数，
;           随后逐行读坐标（mil，Y 向上，整行文字坐标系）
;           v1.7：所有失败路径补 printf（此前静默 nil 导致无法定位）
; 返回值  : ((advMil . contours) ...) 列表；contour = (kind . ptList)
;------------------------------------------------------------------------
procedure( ACH_ParseDat(dat)
    prog((port line tokens glyphs cur n pts i xy recType traced)
        printf("[ACH] ParseDat：开始解析 %s\n" dat)
        port = infile(dat)
        unless( port
            printf("[ACH] ParseDat：无法打开 dat 文件\n")
            return(nil)
        )
        unless( gets(line port)
            close(port)
            printf("[ACH] ParseDat：dat 是空文件\n")
            return(nil)
        )
        line = car(parseString(line "\n"))
        if( !equal(line "# ASTB_TTF_OUTLINE_V1") then
            close(port)
            printf("[ACH] ParseDat：magic 头不符，实际首行为：%s\n" line)
            return(nil)
        )
        ; v1.9：glyphs 用 cur+append1 正序累积，不再使用 reverse/cons 倒序
        ; v3.1：记录级 trace 降级移除（失败路径打印保留）
        glyphs = nil
        cur = nil
        while( gets(line port)
            line = car(parseString(line "\n"))
            tokens = parseString(line " ")
            recType = car(tokens)
            if( equal(recType "G") then
                when( cur
                    glyphs = append1(glyphs cur)
                )
                cur = list(atof(cadr(tokens)))
            else
                if( equal(recType "S") || equal(recType "H") then
                    unless( cur
                        close(port)
                        printf("[ACH] ParseDat：%s 记录出现在任何 G 之前\n"
                               recType)
                        return(nil)
                    )
                    n = atoi(cadr(tokens))
                    pts = nil
                    for( i 1 n
                        unless( gets(line port)
                            close(port)
                            printf("[ACH] ParseDat：轮廓点缺失（应 %d 点，实得 %d）\n"
                                   n length(pts))
                            return(nil)
                        )
                        line = car(parseString(line "\n"))
                        xy = parseString(line " ")
                        pts = append1(pts list(atof(car(xy)) atof(cadr(xy))))
                    )
                    cur = append1(cur cons(recType pts))
                )
            )
        )
        close(port)
        when( cur
            glyphs = append1(glyphs cur)
        )
        unless( glyphs
            printf("[ACH] ParseDat：dat 中没有任何 G 字形记录（python 端 0 字形）\n")
            return(nil)
        )
        ; v2.0：prog/errset 返回值在本环境丢失大结构，改经全局通道传递
        _achGlyphs = glyphs
        glyphs
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_ContourPts
; 功能    : mil 轮廓点列转设计单位绝对坐标点列，并闭合（首点补到末尾）
; 参数    : pts - ((x y) ...) mil；org - 放置原点；f - 单位换算系数
; 返回值  : point 列表（(x y) 二维表，首尾相同）
; 说明    : v2.6 实机判定：本机（17.4 S039）axlPathStart/axlDBCreatePath
;           只接受 (x y) 二维表点；手册示例的 x:y 点对反被内部拒绝
;           （报 Not a floating point number! - range）
;------------------------------------------------------------------------
procedure( ACH_ContourPts(pts org f)
    let((out)
        out = nil
        foreach( p pts
            out = append1(out list(car(org) + car(p) * f
                                   cadr(org) + cadr(p) * f))
        )
        append1(out car(out))
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_TryPath
; 功能    : 建线：axlPathStart(全点列 宽) + axlDBCreatePath
; 参数    : pl - 点列；layer - 目标层
; 返回值  : errset 结果（car 非空即创建成功）；path 失败返回 nil
;------------------------------------------------------------------------
procedure( ACH_TryPath(pl layer)
    let((path)
        path = axlPathStart(pl 0.0)
        if( path then
            errset(axlDBCreatePath(path layer) t)
        else
            printf("[ACH] axlPathStart 返回 nil\n")
            nil
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_DrawLineContour
; 功能    : Line 模式：单条轮廓画 0 宽闭合线
; 返回值  : 1 - 成功；0 - 失败
;------------------------------------------------------------------------
procedure( ACH_DrawLineContour(pts org layer f)
    let((r ids d)
        r = ACH_TryPath(ACH_ContourPts(pts org f) layer)
        if( r && listp(r) && car(r) then
            ; v2.8：l_result 的 car 是新建 dbid 列表，记入本批供撤销
            ids = caar(r)
            when( listp(ids)
                foreach( d ids
                    _achLastBatch = cons(d _achLastBatch)
                )
            )
            1
        else
            0
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_DrawShapeGlyph
; 功能    : Shape 模式：逐字形建填充 shape，S 开新 shape、紧随的 H 作 void
; 参数    : contours - 单字形的 (kind . pts) 列表
; 返回值  : 创建的 shape 数
;------------------------------------------------------------------------
procedure( ACH_DrawShapeGlyph(contours org layer f)
    let((made c sh path holePath r vr cr)
        made = 0
        while( contours
            c = car(contours)
            contours = cdr(contours)
            when( equal(car(c) "S")
                path = axlPathStart(ACH_ContourPts(cdr(c) org f))
                ; v2.7：errset 第二参 t——创建失败让 *Error* 可见
                r = errset(axlDBCreateOpenShape(path t layer nil nil) t)
                sh = car(r)
                when( sh
                    while( contours && equal(caar(contours) "H")
                        c = car(contours)
                        contours = cdr(contours)
                        holePath = axlPathStart(ACH_ContourPts(cdr(c) org f))
                        vr = errset(axlDBCreateVoid(sh holePath) t)
                        unless( vr && car(vr)
                            printf("[ACH] 挖孔失败：%s 可能不允许 void\n" layer)
                        )
                    )
                    cr = errset(axlDBCreateCloseShape(sh) t)
                    when( cr && car(cr)
                        made = made + 1
                        ; v2.8：CloseShape 返回值的 car 是 shape dbid，记入本批
                        when( caar(cr)
                            _achLastBatch = cons(caar(cr) _achLastBatch)
                        )
                    )
                )
            )
        )
        made
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_DrawAntiShape
; 功能    : AntiShape 模式：全文字 bbox 外扩 10% 建外框 shape，逐 S 挖空，
;           逐 H 以独立填充 shape 补回（等效 外框 - 字形油墨）
; 返回值  : 创建的 shape 数
;------------------------------------------------------------------------
procedure( ACH_DrawAntiShape(glyphs org layer f)
    let((minx miny maxx maxy first p mg rx0 ry0 rx1 ry1
         rect path sh r vr cr made c holePath)
        first = t
        minx = 0.0
        miny = 0.0
        maxx = 0.0
        maxy = 0.0
        foreach( g glyphs
            foreach( c cdr(g)
                foreach( p cdr(c)
                    if( first then
                        minx = car(p)
                        maxx = car(p)
                        miny = cadr(p)
                        maxy = cadr(p)
                        first = nil
                    else
                        minx = min(minx car(p))
                        maxx = max(maxx car(p))
                        miny = min(miny cadr(p))
                        maxy = max(maxy cadr(p))
                    )
                )
            )
        )
        made = 0
        unless( first
            mg = (maxy - miny) * 0.1
            rx0 = car(org) + (minx - mg) * f
            ry0 = cadr(org) + (miny - mg) * f
            rx1 = car(org) + (maxx + mg) * f
            ry1 = cadr(org) + (maxy + mg) * f
            rect = list(list(rx0 ry0) list(rx1 ry0) list(rx1 ry1)
                        list(rx0 ry1) list(rx0 ry0))
            path = axlPathStart(rect)
            ; v2.7：errset 第二参 t——创建失败让 *Error* 可见
            r = errset(axlDBCreateOpenShape(path t layer nil nil) t)
            sh = car(r)
            when( sh
                foreach( g glyphs
                    foreach( c cdr(g)
                        when( equal(car(c) "S")
                            holePath = axlPathStart(ACH_ContourPts(cdr(c) org f))
                            vr = errset(axlDBCreateVoid(sh holePath) t)
                            unless( vr && car(vr)
                                printf("[ACH] 挖孔失败：%s 可能不允许 void\n" layer)
                            )
                        )
                    )
                )
                cr = errset(axlDBCreateCloseShape(sh) t)
                when( cr && car(cr)
                    made = made + 1
                    ; v2.8：记入本批供撤销
                    when( caar(cr)
                        _achLastBatch = cons(caar(cr) _achLastBatch)
                    )
                )
            )
            ; 字形内孔以独立 shape 补回
            foreach( g glyphs
                foreach( c cdr(g)
                    when( equal(car(c) "H")
                        holePath = axlPathStart(ACH_ContourPts(cdr(c) org f))
                        r = errset(axlDBCreateOpenShape(holePath t layer nil nil) t)
                        when( car(r)
                            cr = errset(axlDBCreateCloseShape(car(r)) t)
                            when( cr && car(cr)
                                made = made + 1
                                ; v2.8：记入本批供撤销
                                when( caar(cr)
                                    _achLastBatch = cons(caar(cr) _achLastBatch)
                                )
                            )
                        )
                    )
                )
            )
        )
        made
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_PlaceOnce
; 功能    : 在指定原点放置一次全部字形（经 ASTB_DBTransactionMark 包装调用）
; 返回值  : 创建的对象数；v1.3 起 0 个时明确弹窗（杜绝静默失败）
;------------------------------------------------------------------------
procedure( ACH_PlaceOnce(glyphs org layer dtype)
    let((f made)
        f = ACH_MilFactor()
        made = 0
        ; v2.8：本批新建 dbid 收集器清零（各绘制函数往里 cons）
        _achLastBatch = nil
        case( dtype
            ("LINE"
                foreach( g glyphs
                    foreach( c cdr(g)
                        made = made + ACH_DrawLineContour(cdr(c) org layer f)
                    )
                )
            )
            ("SHAPE"
                foreach( g glyphs
                    made = made + ACH_DrawShapeGlyph(cdr(g) org layer f)
                )
            )
            ("ANTISHAPE"
                made = ACH_DrawAntiShape(glyphs org layer f)
            )
        )
        printf("[ACH] 创建对象 %d 个（%s @ %s）\n" made dtype layer)
        when( made == 0
            axlUIConfirm(sprintf(nil
                "未能在 %s 上创建任何对象。\n请确认该层存在、未被锁定，且当前处于可编辑状态"
                layer))
        )
        made
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_UndoLast
; 功能    : 撤销最近一次点击放置：弹出 _achPlaced 栈顶批次，逐个删除
;           dbid（已失效的 dbid 静默跳过）；注册为命令 achu，
;           放置循环右键"撤销"与完成后命令行均可用
; 返回值  : t
;------------------------------------------------------------------------
procedure( ACH_UndoLast()
    let((batch n r d)
        if( _achPlaced then
            batch = car(_achPlaced)
            _achPlaced = cdr(_achPlaced)
            n = 0
            foreach( d batch
                ; dbid 可能已被用户手删——静默尝试，成功才计数
                r = errset(axlDeleteObject(d) nil)
                when( r && car(r)
                    n = n + 1
                )
            )
            printf("[ACH] 撤销：删除 %d 个对象（剩余可撤销 %d 批）\n"
                   n length(_achPlaced))
        else
            printf("[ACH] 没有可撤销的放置\n")
        )
        t
    )
)


;------------------------------------------------------------------------
; 函数名  : ACH_AddDyn
; 功能    : 单条轮廓装入动态光标缓冲；未定型时依次探测三种参数形态
;           （1=list 原点+ref_point，2=rplacd 点对原点，3=无 ref_point），
;           逐形态打印 ret 与 errset.errset，首个可用形态记入
;           _achDynMode 供本次会话复用（v3.3）
; 返回值  : t - 装入成功；nil - 三形态均不可用
;------------------------------------------------------------------------
procedure( ACH_AddDyn(path)
    prog((org r)
        when( _achDynMode == 1
            r = errset(axlAddSimpleMoveDynamics(list(0.0 0.0) path "path"
                            ?ref_point list(0.0 0.0)) nil)
            return(r && car(r))
        )
        when( _achDynMode == 2
            org = cons(0.0 nil)
            rplacd(org 0.0)
            r = errset(axlAddSimpleMoveDynamics(org path "path"
                            ?ref_point org) nil)
            return(r && car(r))
        )
        when( _achDynMode == 3
            r = errset(axlAddSimpleMoveDynamics(list(0.0 0.0) path "path") nil)
            return(r && car(r))
        )
        r = errset(axlAddSimpleMoveDynamics(list(0.0 0.0) path "path"
                        ?ref_point list(0.0 0.0)) nil)
        if( r && car(r) then
            _achDynMode = 1
            printf("[ACH] 动态预览参数形态 1 可用（list 原点 + ref_point）\n")
            return(t)
        )
        printf("[ACH] 形态1不可用 ret=%L err=%L\n" r errset.errset)
        org = cons(0.0 nil)
        rplacd(org 0.0)
        r = errset(axlAddSimpleMoveDynamics(org path "path"
                        ?ref_point org) nil)
        if( r && car(r) then
            _achDynMode = 2
            printf("[ACH] 动态预览参数形态 2 可用（点对原点）\n")
            return(t)
        )
        printf("[ACH] 形态2不可用 ret=%L err=%L\n" r errset.errset)
        r = errset(axlAddSimpleMoveDynamics(list(0.0 0.0) path "path") nil)
        if( r && car(r) then
            _achDynMode = 3
            printf("[ACH] 动态预览参数形态 3 可用（无 ref_point）\n")
            return(t)
        )
        printf("[ACH] 形态3不可用 ret=%L err=%L\n" r errset.errset)
        return(nil)
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_LoadDynamics
; 功能    : 把全部字形轮廓装入动态光标缓冲（文字吸附鼠标预览）：
;           axlClearDynamics -> 逐轮廓 axlPathStart(相对坐标) ->
;           ACH_AddDyn（三形态自探测）；缓冲在显式 clear 前一直有效，
;           跨多次 enter 无需重载；本机点用 (x y) 二维表。
;           v3.4：ANTISHAPE 增外框矩形预览（与 ACH_DrawAntiShape 同一
;           外扩 10% 算法）；SHAPE 因 dynamics 无填充能力仍显轮廓
; 返回值  : 装入成功的轮廓数；0 表示本机不支持，仅无预览不影响放置
;------------------------------------------------------------------------
procedure( ACH_LoadDynamics(glyphs dtype)
    let((f n path minx miny maxx maxy first p mg
         rx0 ry0 rx1 ry1 rect)
        f = ACH_MilFactor()
        n = 0
        errset(axlClearDynamics() nil)
        foreach( g glyphs
            foreach( c cdr(g)
                path = axlPathStart(ACH_ContourPts(cdr(c) list(0.0 0.0) f))
                when( path
                    when( ACH_AddDyn(path)
                        n = n + 1
                    )
                )
            )
        )
        when( equal(dtype "ANTISHAPE")
            first = t
            foreach( g glyphs
                foreach( c cdr(g)
                    foreach( p cdr(c)
                        if( first then
                            minx = car(p)
                            maxx = car(p)
                            miny = cadr(p)
                            maxy = cadr(p)
                            first = nil
                        else
                            minx = min(minx car(p))
                            maxx = max(maxx car(p))
                            miny = min(miny cadr(p))
                            maxy = max(maxy cadr(p))
                        )
                    )
                )
            )
            unless( first
                mg = (maxy - miny) * 0.1
                rx0 = (minx - mg) * f
                ry0 = (miny - mg) * f
                rx1 = (maxx + mg) * f
                ry1 = (maxy + mg) * f
                rect = list(list(rx0 ry0) list(rx1 ry0) list(rx1 ry1)
                            list(rx0 ry1) list(rx0 ry0))
                path = axlPathStart(rect)
                when( path
                    when( ACH_AddDyn(path)
                        n = n + 1
                    )
                )
            )
        )
        if( n > 0 then
            printf("[ACH] 预览轮廓 %d 条已吸附鼠标（形态 %L）\n" n _achDynMode)
        else
            printf("[ACH] 本机不支持动态预览，仅无吸附效果，不影响放置\n")
        )
        n
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_DoneMark
; 功能    : 右键 Done 统一出口（popup 字符串 "ACH_DoneMark()" 调用）：
;           printf 留痕（排查"点了不退出"时凭 [ACH] Done 判断弹出的是
;           否本工具菜单）-> 清动态缓冲 -> 置完成标志 -> 解除拾取
;------------------------------------------------------------------------
procedure( ACH_DoneMark()
    printf("[ACH] Done\n")
    axlClearDynamics()
    _achDone = t
    axlUIPopupSet(nil)
    axlFinishEnterFun()
    t
)
;------------------------------------------------------------------------
; 函数名  : ACH_PlaceLoop
; 功能    : axlEnterPoint 连续放置循环；右键菜单：Done / Undo
; 说明    : v3.0 按 via_stitching 实证模式——popup 回调用 ASCII 字符串
;           表达式；每次 enter 返回后重设 popup；循环条件 org && !_achDone
;           双保险，enter 返回值经 listp 防御才取坐标（pitfalls 2.3）；
;           v3.2 起 Done 走 ACH_DoneMark 命名串（留痕+清动态缓冲）；
;           v3.4 起入口置 _achPlacing 防重入锁，退出清零
;------------------------------------------------------------------------
procedure( ACH_PlaceLoop(glyphs layer dtype)
    let((org cnt popup)
        cnt = 0
        _achDone = nil
        _achPlacing = t
        popup = axlUIPopupDefine(nil list(
                    list("Done" "ACH_DoneMark()")
                    list("Undo" "ACH_UndoLast()")))
        if( popup then
            axlUIPopupSet(popup)
        else
            printf("[ACH] 右键菜单创建失败；可用 done 结束、achu 撤销\n")
        )
        ; v3.2：文字轮廓吸附鼠标（动态光标预览）
        ACH_LoadDynamics(glyphs dtype)
        org = axlEnterPoint(?prompts
                '("请点击中文字符放置点（右键：Done/Undo）") ?gridSnap t)
        while( org && !_achDone
            when( listp(org)
                ; v2.4：axlEnterPoint 返回的就是 (x y) 点表，直接传递
                if( fboundp('ASTB_DBTransactionMark) then
                    ASTB_DBTransactionMark('ACH_PlaceOnce
                                           list(glyphs org layer dtype))
                else
                    ACH_PlaceOnce(glyphs org layer dtype)
                )
                ; 本批有新建对象则压入撤销栈
                when( _achLastBatch
                    _achPlaced = cons(_achLastBatch _achPlaced)
                )
                cnt = cnt + 1
            )
            ; via_stitching 实证：每次 enter 返回后重设 popup
            when( popup
                axlUIPopupSet(popup)
            )
            org = axlEnterPoint(?prompts
                    '("继续点击放置（右键：Done/Undo）") ?gridSnap t)
        )
        axlClearDynamics()
        axlUIPopupSet(nil)
        _achPlacing = nil
        printf("[ACH] 共放置 %d 处；输入 achu 可继续撤销\n" cnt)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_OnAdd
; 功能    : "添加"按钮：校验输入 -> 提取轮廓 -> 进入放置循环
;           v1.3：全程 printf 进度；提取为空明确弹窗（杜绝"点了没反应"）
;           v3.4：绘制类型改取 _achDType（单选回调即记，避开 GetField
;           对 CHECKLIST 组的语义差异），并打印本次类型；放置中防重入
;------------------------------------------------------------------------
procedure( ACH_OnAdd(fw)
    prog((text font sizeS gapS size gap cls sub layer dtype glyphs)
        when( _achPlacing
            axlUIConfirm("上一个放置尚未结束，请先在画布右键 Done 退出")
            return(nil)
        )
        text = axlFormGetField(fw "ctext")
        unless( text && !equal(text "")
            axlUIConfirm("请输入 Chinese text")
            return(nil)
        )
        font = ACH_GetFont(fw)
        unless( font
            axlUIConfirm("字体文件不存在，请检查 Font type")
            return(nil)
        )
        sizeS = axlFormGetField(fw "fsize")
        gapS = axlFormGetField(fw "fgap")
        size = 100.0
        gap = 1.0
        when( sizeS && !equal(sizeS "")
            size = atof(sizeS)
        )
        when( gapS && !equal(gapS "")
            gap = atof(gapS)
        )
        when( size <= 0
            size = 100.0
        )
        when( gap <= 0
            gap = 1.0
        )
        cls = axlFormGetField(fw "fclass")
        sub = axlFormGetField(fw "fsub")
        unless( cls && sub && !equal(cls "") && !equal(sub "")
            axlUIConfirm("请选择 Class / Subclass")
            return(nil)
        )
        layer = strcat(cls "/" sub)
        dtype = _achDType
        unless( dtype
            dtype = "LINE"
        )
        printf("[ACH] 本次绘制类型：%s @ %s\n" dtype layer)
        printf("[ACH] 正在提取字体轮廓（%d 字节），请稍候...\n" strlen(text))
        ; v2.2：prog 返回大结构在本环境随机丢失，跨函数传递统一走全局通道
        _achGlyphs = nil
        ACH_Extract(font text size gap)
        glyphs = _achGlyphs
        unless( glyphs
            axlUIConfirm("未能提取到字形轮廓：字体可能不包含这些字符。\n请换用 simhei.ttf（黑体）等中文字体后重试；\n详细原因见命令窗口提示。")
            return(nil)
        )
        printf("[ACH] 提取完成，共 %d 个字形\n" length(glyphs))
        printf("[ACH] 请在画布上点击放置点（可连续放置，右键：Done/Undo）\n")
        ACH_PlaceLoop(glyphs layer dtype)
        t
    )
)

;------------------------------------------------------------------------
; 函数名  : ACH_Help
; 功能    : "说明"按钮：显示用法说明
;------------------------------------------------------------------------
procedure( ACH_Help()
    axlUIConfirm("用法：输入文字与字体参数 -> 点 添加 -> 板上连续点击放置（右键菜单：Done/Undo）。\nLine = 0 宽轮廓线；Shape = 填充铜皮（自动挖孔）；\nAntiShape = 外框铜皮镂空字形（内孔补铜）。\n放置后可输入 achu 逐批撤销。\n中文经 Python(fontTools) 提取，解释器配置见模块文件头注释。")
    t
)

;------------------------------------------------------------------------
; 函数名  : ACH_MainCB
; 功能    : 主表单回调分发
;------------------------------------------------------------------------
procedure( ACH_MainCB(fw)
    case( fw->curField
        ("fontbrowse"
            ACH_BrowseFont(fw)
        )
        ("fclass"
            ACH_RebuildSubclass(fw)
        )
        ("fsub"
            ACH_RefreshColor(fw)
        )
        ("dt_line"
            _achDType = "LINE"
        )
        ("dt_shape"
            _achDType = "SHAPE"
        )
        ("dt_anti"
            _achDType = "ANTISHAPE"
        )
        ("fvis"
            ACH_OnVisToggle(fw)
        )
        ("add"
            ACH_OnAdd(fw)
        )
        ("help"
            ACH_Help()
        )
        ("done"
            axlFormClose(fw)
        )
        (t
            nil
        )
    )
    ; v3.5：任何字段交互后重同步色块（覆盖用户在 Allegro 颜色对话框
    ;       改层显隐后回到本表单的场景；doneState!=0 表单将关不刷）
    when( fw->doneState == 0
        ACH_RefreshColor(fw)
    )
    when( fw->doneState != 0
        axlFormClose(fw)
    )
    t
)

;------------------------------------------------------------------------
; 函数名  : ACH_Run
; 功能    : 模块入口：加载表单并回填默认值（ach 命令）
; 示例    : 在 Allegro 命令行输入 ach
;------------------------------------------------------------------------
procedure( ACH_Run()
    prog((f)
        f = strcat(ASTB_GLOBAL->FormPath "/text_addchinese.form")
        _achForm = axlFormCreate((gensym) f '(e inner) 'ACH_MainCB t)
        unless( _achForm
            axlUIConfirm("无法加载表单 text_addchinese.form，请检查 forms 目录")
            return(nil)
        )
        axlFormDisplay(_achForm)
        axlFormSetField(_achForm "font" "C:/Windows/Fonts/simhei.ttf")
        axlFormSetField(_achForm "fsize" "100")
        axlFormSetField(_achForm "fgap" "1.0")
        axlFormSetField(_achForm "fclass" "BOARD GEOMETRY")
        ACH_RebuildSubclass(_achForm)
        axlFormSetField(_achForm "dt_line" t)
        _achDType = "LINE"
        _achPlacing = nil
        t
    )
)

printf("[ASTB] text_addchinese.il v3.8 loaded, command: ach / achu(撤销)\n")
