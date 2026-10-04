;========================================================================
; 文件名    : util_supernetfinder.il
; 作者      : LiGuangsheng（原始作者）/ ASTB 修复组（规范化整改）
; 创建日期  : 2002-06-08
; 版本      : 2.5
; 功能描述  : 超级网络查找器，按长度、曼哈顿距离百分比、过孔数筛选网络
; 依赖模块  : 无
; 修改记录  :
;   2002-06-08 v1.0 LiGuangsheng 初始创建（原 lgs_super_net_finder_V1_0.il）
;   2026-07-18 v2.4 ASTB 修复组 表单界面汉化：标题/分组/按钮/提示信息改中文
;   2026-09-09 v2.5 ASTB 修复组 修 17.4 跨交互轮 dbid 失效（S039）：
;             lgs_sn_last_hl 原存网络 dbid，新一轮列表点选回调后失效为
;             dbid:removed，axlDehighlightObject 失败、旧高亮残留。
;             改存网络名字符串，去高亮时 axlClearSelSet+axlSingleSelectName
;             按名现场重解析，当轮立即 axlDehighlightObject(axlGetSelSet())
;   2026-07-18 v2.3 ASTB 修复组 正式版：
;             1) 缩放改 axlZoomToDbid（自动按网络范围居中，替代手工 bBox+window）
;             2) 清除 v1.7/v2.1 调试代码，恢复数据文件用后删除
;   2026-07-18 v2.2 ASTB 修复组 根治解析：实测 gets 剥 \r 留 \n（rawlen/last 实证），
;             行尾剥离改用 \n 转义（LF）；空字段补 0 后全部记录恰为 5 token。
;   2026-07-18 v2.1 ASTB 修复组 调试：打印前 5 条原始记录的 strlen/token 数，
;             定位 mainlist=0 原因，定位后移除。
;   2026-07-18 v2.0 ASTB 修复组 修复 index 误用：index 对字符串返回匹配点尾串
;             （strstr 语义）而非位置，改用 strlen 换算插入位置。
;   2026-07-18 v1.9 ASTB 修复组 修复 rexReplace 误用（第 3 参数为整数位置）：
;             空字段补 0 改为 index+substring+strcat 手工替换。
;   2026-07-18 v1.8 ASTB 修复组 修复解析丢记录（列表只剩 13 个电源网）：
;             extracta 输出 CRLF，gets 不剥 \r 使每条记录多出 "\r" token；
;             parseString 吞空字段，普通记录变 6 token 被 length==5 误杀，
;             空曼哈顿字段记录恰好 5 token 存活。修正：先剥 \r，空字段补 0。
;   2026-07-18 v1.7 ASTB 修复组 调试：暂时保留 extract 数据文件（不删除），
;             用于分析会话内提取记录不全问题；定位后恢复删除。
;   2026-07-18 v1.6 ASTB 修复组 修复 axlDehighlightObject 无参报错：
;             该函数至少需 1 个参数，改为全局 lgs_sn_last_hl 记录上次高亮对象，
;             点选新网络前只对上次对象去高亮。
;   2026-07-18 v1.5 ASTB 修复组 修复点选列表不缩放不高亮：
;             v1.1 整改误删 axlSetFindFilter 行使能 nets，导致 axlSingleSelectName
;             静默失败；恢复该行使能，并在缩放前 dehighlight/highlight 网络。
;   2026-07-18 v1.4 ASTB 修复组 根治 SPMHDX-10 真凶：extract 命令文件换行符。
;             outfile 在 Windows 上不做 CRLF 转换，字符串内 \n 写成纯 LF，
;             Windows 版 extracta 只认 CRLF，整个文件被读成一行导致非法视图名。
;             命令文件改为显式 \r\n 写入。
;   2026-07-17 v1.3 ASTB 修复组 根治 SPMHDX-10：axlExtractToFile 的 viewFile 参数
;             是按 TEXTPATH 查找的“名称”而非路径（传全路径被判非法视图名）。
;             改为：临时目录前置进 TEXTPATH，调用只传文件名；输出名不带扩展名
;             （a_extract 自动追加 .txt），避免生成 .txt.txt
;   2026-07-17 v1.2 ASTB 修复组 修复超级网络查找报 SPMHDX-10 非法视图名称：
;             axlExtractToFile 前把 <安装目录>/text/views 前置进 TEXTPATH，
;             保证 extracta 在任何会话环境下都能找到 NET 视图定义
;   2026-07-17 v1.1 ASTB 修复组 整改：
;             1) 删除 Update 调试残留 axlMsgPut("frgsdfgsdfg")
;             2) lgs_sn_* 全局变量补 boundp 保护（每次运行重置默认值）
;             3) 纯查询命令去除 ?undo t
;             4) extract/.form 临时文件由写 CWD 改为写临时目录，
;                axlExtractToFile/infile 增加返回值检查
;========================================================================

;===============REGIST COMMAND LINE=========================================================================================
;===========================================================================================================================

axlCmdRegister("super_net_finder" '_lgs_super_net_find ?cmdType "general")

;***************************************************************************************************************************
;        _lgs_super_net_find()
;***************************************************************************************************************************
;------------------------------------------------------------------------
; 模块全局变量（boundp 保护；_lgs_super_net_find 每次运行重置默认值）
;------------------------------------------------------------------------
unless(boundp('lgs_sn_length_min_sw) lgs_sn_length_min_sw = nil)
unless(boundp('lgs_sn_length_max_sw) lgs_sn_length_max_sw = nil)
unless(boundp('lgs_sn_pmanhattan_min_sw) lgs_sn_pmanhattan_min_sw = nil)
unless(boundp('lgs_sn_pmanhattan_max_sw) lgs_sn_pmanhattan_max_sw = nil)
unless(boundp('lgs_sn_via_min_sw) lgs_sn_via_min_sw = nil)
unless(boundp('lgs_sn_via_max_sw) lgs_sn_via_max_sw = nil)
unless(boundp('lgs_sn_length_min) lgs_sn_length_min = nil)
unless(boundp('lgs_sn_length_max) lgs_sn_length_max = nil)
unless(boundp('lgs_sn_pmanhattan_min) lgs_sn_pmanhattan_min = nil)
unless(boundp('lgs_sn_pmanhattan_max) lgs_sn_pmanhattan_max = nil)
unless(boundp('lgs_sn_via_min) lgs_sn_via_min = nil)
unless(boundp('lgs_sn_via_max) lgs_sn_via_max = nil)
unless(boundp('lgs_sn_mainlist) lgs_sn_mainlist = nil)
unless(boundp('lgs_sn_filter_list) lgs_sn_filter_list = nil)
unless(boundp('super_net_find_Form) super_net_find_Form = nil)
unless(boundp('lgs_netid) lgs_netid = nil)
unless(boundp('lgs_sn_last_hl) lgs_sn_last_hl = nil) ; v2.5 起存网络名字符串（不存 dbid：17.4 跨交互轮必失效为 dbid:removed）

(defun _lgs_super_net_find ()

; --- 每次运行重置默认筛选条件 ---
lgs_sn_length_min_sw = nil
lgs_sn_length_max_sw = nil
lgs_sn_pmanhattan_min_sw = nil
lgs_sn_pmanhattan_max_sw = nil
lgs_sn_via_min_sw = nil
lgs_sn_via_max_sw = nil

lgs_sn_length_min = 200
lgs_sn_length_max = 2000
lgs_sn_pmanhattan_min = 11
lgs_sn_pmanhattan_max = 1000
lgs_sn_via_min = 4
lgs_sn_via_max = 20

_lgs_build_super_net_find_form()
lgs_sn_mainlist = _lgs_sn_read_data()
lgs_sn_filter_list = lgs_sn_mainlist
_lgs_sn_setform()

);end (defun _lgs_super_net_find ()


;***************************************************************************************************************************
;        _lgs_match_net()
;***************************************************************************************************************************
(defun _lgs_match_net ( netbox)
(prog ()
    if(lgs_sn_length_min_sw
    then
        if(atof( nthelem(2 netbox)) < lgs_sn_length_min
        then
            return( nil)
        );end if
    );end if

    if(lgs_sn_length_max_sw
    then
        if(atof( nthelem(2 netbox)) > lgs_sn_length_max
        then
            return( nil)
        );end if
    );end if

    ;----------------------------------------------------------------
    if(lgs_sn_pmanhattan_min_sw
    then
        if(atof( nthelem(3 netbox)) == 0
        then
            return( nil)
        );end if

        if(100*atof( nthelem(2 netbox))/atof( nthelem(3 netbox)) < lgs_sn_pmanhattan_min
        then
            return( nil)
        );end if
    );end if

    if(lgs_sn_pmanhattan_max_sw
    then
        if(atof( nthelem(3 netbox)) == 0
        then
            return( t)
        );end if

        if(100*atof( nthelem(2 netbox))/atof( nthelem(3 netbox)) > lgs_sn_pmanhattan_max
        then
            return( nil)
        );end if
    );end if

    ;----------------------------------------------------------------
    if(lgs_sn_via_min_sw
    then
        if(atof( nthelem(4 netbox)) < lgs_sn_via_min
        then
            return( nil)
        );end if
    );end if

    if(lgs_sn_via_max_sw
    then
        if(atof( nthelem(4 netbox)) > lgs_sn_via_max
        then
            return( nil)
        );end if
    );end if


return( t)
));end (defun _lgs_match_net ( netbox)
;***************************************************************************************************************************
;        _lgs_super_net_find_callback()
;***************************************************************************************************************************
(defun _lgs_super_net_find_callback ( super_net_find_Form)

case(super_net_find_Form->curField

    ("lgs_min_length_SW"
        lgs_sn_length_min_sw = super_net_find_Form->curValue
    t)

    ("lgs_max_length_SW"
        lgs_sn_length_max_sw = super_net_find_Form->curValue
    t)

    ("lgs_min_Percent_SW"
        lgs_sn_pmanhattan_min_sw = super_net_find_Form->curValue
    t)

    ("lgs_max_Percent_SW"
        lgs_sn_pmanhattan_max_sw = super_net_find_Form->curValue
    t)

    ("lgs_min_Via_SW"
        lgs_sn_via_min_sw = super_net_find_Form->curValue
    t)

    ("lgs_max_Via_SW"
        lgs_sn_via_max_sw = super_net_find_Form->curValue
    t)

;---------------------------------------------------------------------------------------------------------------------------
    ("lgs_min_length"
        lgs_sn_length_min = super_net_find_Form->curValue
    t)

    ("lgs_max_length"
        lgs_sn_length_max = super_net_find_Form->curValue
    t)

    ("lgs_min_Percent"
        lgs_sn_pmanhattan_min = super_net_find_Form->curValue
    t)

    ("lgs_max_Percent"
        lgs_sn_pmanhattan_max = super_net_find_Form->curValue
    t)

    ("lgs_min_Via"
        lgs_sn_via_min = super_net_find_Form->curValue
    t)

    ("lgs_max_Via"
        lgs_sn_via_max = super_net_find_Form->curValue
    t)

    ("lgsdone"
        axlFormClose( super_net_find_Form)
        super_net_find_Form = nil
        deleteFile(strcat(axlTempDirectory() "/lgs_super_net_find_Form.form"))

    t)
;---------------------------------------------------------------------------------------------------------------------------
    ("Placed_List"
        ; 按名选择网络（先清空旧选择集，先选后取拆两行）
        ; 必须先让 Find 过滤器使能 nets，否则选择静默失败、无法缩放（v1.1 误删）
        axlSetFindFilter(?enabled '(noall nets) ?onButtons '(noall nets))
        axlClearSelSet()
        axlSingleSelectName("NET" super_net_find_Form->curValue)
        lgs_netid = axlGetSelSet()
        axlFormSetField(super_net_find_Form "lgs_length" atof( nthelem( 2 nthelem( super_net_find_Form->curValueInt+1 lgs_sn_filter_list))))
        if(atof( nthelem( 3 nthelem( super_net_find_Form->curValueInt+1 lgs_sn_filter_list))) == 0
        then
            axlFormSetField(super_net_find_Form "lgs_Percent" 0)
        else
            axlFormSetField(super_net_find_Form "lgs_Percent" 100*atof( nthelem( 2 nthelem( super_net_find_Form->curValueInt+1 lgs_sn_filter_list)))/atof( nthelem( 3 nthelem( super_net_find_Form->curValueInt+1 lgs_sn_filter_list))))
        );end if
        axlFormSetField(super_net_find_Form "lgs_Via" atof( nthelem( 4 nthelem( super_net_find_Form->curValueInt+1 lgs_sn_filter_list))))
        axlUIWPrint(super_net_find_Form
            sprintf(nil "网络： %s" super_net_find_Form->curValue))

        ; 高亮并缩放到网络（axlZoomToDbid 自动按对象范围居中，比手工 bBox 可靠）
        when( lgs_netid && car(lgs_netid)
            ; 先清掉上一次的高亮，再高亮当前网络。
            ; v2.5: lgs_sn_last_hl 改存网络名字符串（17.4 S039 跨交互轮后
            ; 旧 dbid 全部失效为 dbid:removed，直接去高亮必失败残留），
            ; 按名现场重解析、当轮即用即弃；去完重选当前网络恢复选择集
            when( lgs_sn_last_hl
                axlClearSelSet()
                axlSingleSelectName("NET" lgs_sn_last_hl)
                when( axlGetSelSet()
                    axlDehighlightObject(axlGetSelSet())
                )
                lgs_sn_last_hl = nil
                axlClearSelSet()
                axlSingleSelectName("NET" super_net_find_Form->curValue)
                lgs_netid = axlGetSelSet()
            )
            axlHighlightObject(lgs_netid)
            lgs_sn_last_hl = super_net_find_Form->curValue
            axlZoomToDbid(lgs_netid t)
        )

    t)

    ("lgs_update"
        _lgs_sn_update()

    t)



);end case
);end (defun _lgs_super_net_find_callback ( super_net_find_Form)

;***************************************************************************************************************************
;        _lgs_sn_update()
;***************************************************************************************************************************
(defun _lgs_sn_update ()
    lgs_sn_filter_list = nil
    foreach(netbox lgs_sn_mainlist
        if(_lgs_match_net( netbox)
        then
            lgs_sn_filter_list = nconc( lgs_sn_filter_list list( netbox))
         );end if
    );end foreach

    _lgs_sn_setform()


);end (defun _lgs_sn_update ()
;***************************************************************************************************************************
;        _lgs_sn_setform()
;***************************************************************************************************************************
(defun _lgs_sn_setform ()
let( ( lgs_name_list)
    lgs_name_list = nil

    foreach(lgs_temp lgs_sn_filter_list

        lgs_name_list = nconc( lgs_name_list list( car( lgs_temp)))
    );end for
    axlFormListDeleteAll( super_net_find_Form "Placed_List")
    axlFormSetField(super_net_find_Form "Placed_List" lgs_name_list)

    axlFormSetField(super_net_find_Form "lgs_min_length_SW" lgs_sn_length_min_sw)
    axlFormSetField(super_net_find_Form "lgs_max_length_SW" lgs_sn_length_max_sw)
    axlFormSetField(super_net_find_Form "lgs_min_Percent_SW" lgs_sn_pmanhattan_min_sw)
    axlFormSetField(super_net_find_Form "lgs_max_Percent_SW" lgs_sn_pmanhattan_max_sw)
    axlFormSetField(super_net_find_Form "lgs_min_Via_SW" lgs_sn_via_min_sw)
    axlFormSetField(super_net_find_Form "lgs_max_Via_SW" lgs_sn_via_max_sw)

    axlFormSetField(super_net_find_Form "lgs_min_length" lgs_sn_length_min)
    axlFormSetField(super_net_find_Form "lgs_max_length" lgs_sn_length_max)
    axlFormSetField(super_net_find_Form "lgs_min_Percent" lgs_sn_pmanhattan_min)
    axlFormSetField(super_net_find_Form "lgs_max_Percent" lgs_sn_pmanhattan_max)
    axlFormSetField(super_net_find_Form "lgs_min_Via" lgs_sn_via_min)
    axlFormSetField(super_net_find_Form "lgs_max_Via" lgs_sn_via_max)

    axlUIWPrint(super_net_find_Form sprintf(temp "共找到 %d 个网络" length( lgs_name_list)))

);end let
);end (defun _lgs_sn_setform ()

;***************************************************************************************************************************
;        _lgs_sn_read_data()
;***************************************************************************************************************************
(defun _lgs_sn_read_data ()
(prog (lgs_temp_list cmdFilePath dataFilePath extractCmdPort datafileport lgstemp line snTail snBangPos)
    lgs_temp_list = nil
    ; --- 临时文件写临时目录，禁止写 CWD ---
    cmdFilePath = strcat(axlTempDirectory() "/lgs_extract_command_file.txt")
    dataFilePath = strcat(axlTempDirectory() "/lgs_extract_data_file.txt")

    extractCmdPort = outfile(cmdFilePath "w")
    unless( extractCmdPort
        axlUIConfirm("无法创建临时 extract 命令文件，请检查临时目录权限")
        return(nil)
    )
    ; 显式 \r\n：Windows extracta 不认纯 LF 换行（SPMHDX-10 根因）
    fprintf( extractCmdPort "NET\r\n  NET_NAME\r\n  NET_ETCH_LENGTH\r\n  NET_MANHATTEN_LENGTH\r\n  NET_VIA_COUNT\r\nEND\r\n")
    close( extractCmdPort)

    ; --- SPMHDX-10 根治：axlExtractToFile 的 viewFile 是“名称”不是路径 ---
    ; a_extract 按 TEXTPATH 查找视图文件，传全路径会被判为非法视图名。
    ; 把临时目录前置进 TEXTPATH，调用时只传文件名（不带扩展名）。
    axlSetVariable("TEXTPATH" strcat(". " axlTempDirectory() " " (axlGetVariable("TEXTPATH") || "")))

    ; --- extract 失败时中止，避免对 nil 端口 gets 崩溃 ---
    ; 输出名不带扩展名：a_extract 自动追加 .txt
    dataFileNoExt = strcat(axlTempDirectory() "/lgs_extract_data_file")
    unless( axlExtractToFile("lgs_extract_command_file" dataFileNoExt)
        axlUIConfirm("网络数据提取失败(axlExtractToFile)，详见 extract.log")
        deleteFile(cmdFilePath)
        return(nil)
    )

    datafileport = infile(dataFilePath)
    unless( datafileport
        axlUIConfirm("无法读取 extract 结果文件")
        deleteFile(cmdFilePath)
        return(nil)
    )
    while(((lgstemp = gets(line datafileport)) != nil)

        ; v2.2：gets 剥 \r 留 \n（实测），用 \n 转义剥行尾 LF
        lgstemp = car(parseString( lgstemp "\n"))
        ; v1.8：空字段补 0（parseString 吞空字段；电源网无曼哈顿长度会少 token）
        ; index 对字符串是 strstr 语义（返回尾串），用 strlen 换算位置
        while( (snTail = index(lgstemp "!!"))
            snBangPos = strlen(lgstemp) - strlen(snTail) + 1
            lgstemp = strcat(substring(lgstemp 1 snBangPos-1) "!0!" substring(lgstemp snBangPos+2))
        )
        lgstemp = parseString( lgstemp "!")
        if((length( lgstemp) == 5) && (car( lgstemp) == "S")
        then
            lgs_temp_list = nconc( lgs_temp_list list( cdr( lgstemp)))
        );end if

    );end while
    close( datafileport)
    deleteFile(cmdFilePath)
    deleteFile(dataFilePath)
    return( lgs_temp_list)
));end (defun _lgs_sn_read_data ()

;***************************************************************************************************************************
;        _lgs_build_super_net_find_form()
;***************************************************************************************************************************
(defun _lgs_build_super_net_find_form ()
(prog (formFilePath formDefPort)
    ; --- 表单定义文件写临时目录，禁止写 CWD ---
    formFilePath = strcat(axlTempDirectory() "/lgs_super_net_find_Form.form")
    formDefPort = outfile(formFilePath "w")
    unless( formDefPort
        axlUIConfirm("无法创建临时表单文件，请检查临时目录权限")
        return(nil)
    )
    fprintf(formDefPort "FILE_TYPE=FORM_DEFN VERSION=2\n")
    fprintf(formDefPort "FORM\n")
    fprintf(formDefPort "FIXED\n")
    fprintf(formDefPort "PORT 24 20\n")
    fprintf(formDefPort "HEADER \"\263\254\274\266\315\370\302\347\262\351\325\322\"\n")
    fprintf(formDefPort "TILE\n")
    fprintf(formDefPort "GROUP \"\315\370\302\347\301\320\261\355\"\n")
    fprintf(formDefPort "FLOC 1 0\n")
    fprintf(formDefPort "FSIZE 23 22\n")
    fprintf(formDefPort "INFO group\n")
    fprintf(formDefPort "ENDGROUP  \n")
    fprintf(formDefPort "FIELD Placed_List\n")
    fprintf(formDefPort "FLOC 2 2\n")
    fprintf(formDefPort "LIST \"\" 21 10\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "###############################\n")
    fprintf(formDefPort "GROUP \"\263\244\266\310\311\270\321\241\"\n")
    fprintf(formDefPort "FLOC 1 22\n")
    fprintf(formDefPort "FSIZE 23 9\n")
    fprintf(formDefPort "INFO group\n")
    fprintf(formDefPort "ENDGROUP \n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_length\n")
    fprintf(formDefPort "FLOC 10 24\n")
    fprintf(formDefPort "REALFILLIN 10 10\n")
    fprintf(formDefPort "REALMIN 0\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_min_length_SW\n")
    fprintf(formDefPort "FLOC  2 26\n")
    fprintf(formDefPort "CHECKLIST \"\327\356\320\241\" \n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_min_length\n")
    fprintf(formDefPort "FLOC 10 26\n")
    fprintf(formDefPort "REALFILLIN 10 10\n")
    fprintf(formDefPort "REALMIN 0\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_max_length_SW\n")
    fprintf(formDefPort "FLOC  2 28\n")
    fprintf(formDefPort "CHECKLIST \"\327\356\264\363\" \n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_max_length\n")
    fprintf(formDefPort "FLOC 10 28\n")
    fprintf(formDefPort "REALFILLIN 10 10\n")
    fprintf(formDefPort "REALMIN 0\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "###############################\n")
    fprintf(formDefPort "GROUP \"\302\374\271\376\266\331\260\331\267\326\261\310\311\270\321\241\"\n")
    fprintf(formDefPort "FLOC 1 31\n")
    fprintf(formDefPort "FSIZE 23 9\n")
    fprintf(formDefPort "INFO group\n")
    fprintf(formDefPort "ENDGROUP \n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_Percent\n")
    fprintf(formDefPort "FLOC 10 33\n")
    fprintf(formDefPort "REALFILLIN 10 10\n")
    fprintf(formDefPort "REALMIN 0\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_min_Percent_SW\n")
    fprintf(formDefPort "FLOC  2 35\n")
    fprintf(formDefPort "CHECKLIST \"\327\356\320\241\" \n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_min_Percent\n")
    fprintf(formDefPort "FLOC 10 35\n")
    fprintf(formDefPort "REALFILLIN 10 10\n")
    fprintf(formDefPort "REALMIN 0\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_max_Percent_SW\n")
    fprintf(formDefPort "FLOC  2 37\n")
    fprintf(formDefPort "CHECKLIST \"\327\356\264\363\" \n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_max_Percent\n")
    fprintf(formDefPort "FLOC 10 37\n")
    fprintf(formDefPort "REALFILLIN 10 10\n")
    fprintf(formDefPort "REALMIN 0\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "###############################\n")
    fprintf(formDefPort "GROUP \"\271\375\277\327\312\375\311\270\321\241\"\n")
    fprintf(formDefPort "FLOC 1 40\n")
    fprintf(formDefPort "FSIZE 23 9\n")
    fprintf(formDefPort "INFO group\n")
    fprintf(formDefPort "ENDGROUP \n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_Via\n")
    fprintf(formDefPort "FLOC 10 42\n")
    fprintf(formDefPort "REALFILLIN 10 10\n")
    fprintf(formDefPort "REALMIN 0\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_min_Via_SW\n")
    fprintf(formDefPort "FLOC  2 44\n")
    fprintf(formDefPort "CHECKLIST \"\327\356\320\241\" \n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_min_Via\n")
    fprintf(formDefPort "FLOC 10 44\n")
    fprintf(formDefPort "REALFILLIN 10 10\n")
    fprintf(formDefPort "REALMIN 0\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_max_Via_SW\n")
    fprintf(formDefPort "FLOC  2 46\n")
    fprintf(formDefPort "CHECKLIST \"\327\356\264\363\" \n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_max_Via\n")
    fprintf(formDefPort "FLOC 10 46\n")
    fprintf(formDefPort "REALFILLIN 10 10\n")
    fprintf(formDefPort "REALMIN 0\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgs_update\n")
    fprintf(formDefPort "FLOC 1 50\n")
    fprintf(formDefPort "MENUBUTTON \"\270\374\320\302\" 5 3\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "\n")
    fprintf(formDefPort "FIELD lgsdone\n")
    fprintf(formDefPort "FLOC 9 50\n")
    fprintf(formDefPort "MENUBUTTON \"\315\313\263\366\" 5 3\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "FIELD help\n")
    fprintf(formDefPort "FLOC 17 50\n")
    fprintf(formDefPort "MENUBUTTON \"\260\357\326\372\" 5 3\n")
    fprintf(formDefPort "ENDFIELD\n")
    fprintf(formDefPort "ENDTILE\n")
    fprintf(formDefPort "ENDFORM\n")
    close(formDefPort)
    unless( isFile(formFilePath)
        axlUIConfirm("临时表单文件生成失败")
        return(nil)
    )
    super_net_find_Form = axlFormCreate( (gensym) formFilePath '(e outer) '_lgs_super_net_find_callback t)
    axlFormDisplay( super_net_find_Form)
    axlUIWPrint( super_net_find_Form "正在读取数据，请稍候！")
    formFilePath
));end (defun _lgs_build_super_net_find_form ()

