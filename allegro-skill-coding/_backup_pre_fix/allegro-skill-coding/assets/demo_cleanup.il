;========================================================================
; 文件名    : demo_cleanup.il
; 作者      : SkillGroup
; 创建日期  : 2024-06-15
; 版本      : 1.0
; 功能描述  : 演示模块，展示如何按 Allegro SKILL 编码规范编写可维护脚本
; 依赖模块  : core/logger.il
; 修改记录  :
;   2024-06-15 v1.0 SkillGroup 初始创建
;========================================================================

;------------------------------------------------------------------------
; 全局变量初始化
;------------------------------------------------------------------------
unless(boundp('g_demoCleanupVersion)
    g_demoCleanupVersion = "1.0"
)

unless(boundp('g_demoCleanupEnabled)
    g_demoCleanupEnabled = t
)

;------------------------------------------------------------------------
; 模块常量
;------------------------------------------------------------------------
C_MODULE_NAME = "DemoCleanup"

;------------------------------------------------------------------------
; 函数名  : Init_DemoCleanup
; 功能    : 模块初始化入口
; 参数    : 无
; 返回值  : t - 初始化成功
;------------------------------------------------------------------------
procedure( Init_DemoCleanup()
    printf("[%s] 模块初始化完成，版本 %s\n" C_MODULE_NAME g_demoCleanupVersion)
    t
)

;------------------------------------------------------------------------
; 函数名  : DemoCleanup_CheckVersion
; 功能    : 检查当前 Allegro 版本是否满足最低要求
; 参数    : 无
; 返回值  : t - 版本符合要求
;          nil - 版本不符合要求
;------------------------------------------------------------------------
procedure( DemoCleanup_CheckVersion()
    let((version major minor)
        version = axlVersion(1)
        major = atoi(car(parseString(version ".")))
        minor = atoi(cadr(parseString(version ".")))
        if( major >= 17 && minor >= 4 then
            t
        else
            axlUIConfirm("当前版本 %s 不支持此功能，需要 17.4 或更高版本" version)
            nil
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : DemoCleanup_DeleteSelectedShapes
; 功能    : 删除当前选择集中的所有 shape 对象（含事务保护）
; 参数    : 无
; 返回值  : t - 删除成功
;          nil - 删除失败或无可删除对象
; 副作用  : 修改当前设计数据库，建议先保存
;------------------------------------------------------------------------
procedure( DemoCleanup_DeleteSelectedShapes()
    let((selectSet deleteCount result)
        ; 检查运行环境
        unless( axlOKToProceed()
            axlUIConfirm("当前环境不允许执行删除操作")
            return(nil)
        )

        ; 检查版本
        unless( DemoCleanup_CheckVersion()
            return(nil)
        )

        ; 清空选择集并设置过滤器
        axlClearSelSet()
        axlSetFindFilter(
            ?enabled  '("NOALL" "SHAPES")
            ?onButton '("SHAPES")
        )
        axlSingleSelectPoint()
        selectSet = axlGetSelSet()

        ; 无选择对象时直接返回
        if( null(selectSet) then
            axlUIConfirm("未选择任何 shape 对象")
            return(nil)
        )

        ; 开启事务保护
        axlDBTransactionStart(nil)
        deleteCount = 0

        foreach(obj selectSet
            ; 验证 dbid 有效性
            when( obj && axlDBRefreshId(obj)
                ; 仅删除 shape 类型
                when( obj->objType == "shape"
                    result = axlDeleteObject(obj)
                    if( result then
                        deleteCount = deleteCount + 1
                    else
                        printf("删除对象失败: %L\n" obj)
                    )
                )
            )
        )

        ; 根据操作结果提交或回滚
        if( deleteCount > 0 then
            axlDBTransactionCommit(nil)
            printf("成功删除 %d 个 shape 对象\n" deleteCount)
            t
        else
            axlDBTransactionRollback(nil)
            printf("未删除任何对象，回滚事务\n")
            nil
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : DemoCleanup_CreateEtchPath
; 功能    : 在指定网络上创建一条示例走线（含事务保护）
; 参数    :
;   @param netName - 目标网络名称字符串
;   @param width   - 走线宽度（浮点数）
; 返回值  : dbid - 创建成功的路径对象
;          nil  - 创建失败
; 副作用  : 修改当前设计数据库，仅在 ETCH 层创建的路径会自动加入网络
;------------------------------------------------------------------------
procedure( DemoCleanup_CreateEtchPath( netName width )
    let((netId points result pathId)
        ; 检查运行环境
        unless( axlOKToProceed()
            axlUIConfirm("当前环境不允许创建对象")
            return(nil)
        )

        ; 查找网络
        netId = axlSelectByName("NET" netName)
        if( null(netId) then
            printf("未找到网络: %s\n" netName)
            return(nil)
        )

        ; 设置活动层
        axlSetCurrentLayer("ETCH/TOP")

        ; 定义路径坐标
        points = '(100:100 200:100 300:200)

        ; 创建路径（带事务）
        axlDBTransactionStart(nil)
        result = axlDBCreatePath(
            points
            "ETCH/TOP"
            'LINE
            width
            car(netId)
        )

        if( car(result) then
            axlDBTransactionCommit(nil)
            pathId = car(result)
            printf("创建路径成功: %L\n" pathId)
            pathId
        else
            axlDBTransactionRollback(nil)
            printf("创建路径失败\n")
            nil
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : Form_DemoCleanupCreate
; 功能    : 创建并显示演示表单
; 参数    : 无
; 返回值  : formHandle - 表单句柄
;------------------------------------------------------------------------
procedure( Form_DemoCleanupCreate()
    let((formHandle)
        formHandle = axlFormCreate(
            "demoCleanupForm"
            "Demo Cleanup"
            '(200 200 500 300)
            'FORM
            'CB_DemoCleanupForm
        )
        axlFormSetField(formHandle "version" g_demoCleanupVersion)
        axlFormDisplay(formHandle)
        formHandle
    )
)

;------------------------------------------------------------------------
; 函数名  : CB_DemoCleanupForm
; 功能    : 演示表单字段回调
; 参数    :
;   @param formHandle - 表单句柄
;   @param fieldName  - 字段名称
;   @param fieldValue - 字段值
; 返回值  : t - 事件处理完成
;------------------------------------------------------------------------
procedure( CB_DemoCleanupForm( formHandle fieldName fieldValue )
    case( fieldName
        ("done"
            Form_DemoCleanupClose(formHandle)
        )
        ("deleteShapes"
            DemoCleanup_DeleteSelectedShapes()
        )
        ("createPath"
            DemoCleanup_CreateEtchPath("NET1" 10.0)
        )
        (t
            printf("未处理的字段: %s\n" fieldName)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : Form_DemoCleanupClose
; 功能    : 关闭表单并释放相关资源
; 参数    :
;   @param formHandle - 表单句柄
; 返回值  : t - 关闭成功
;------------------------------------------------------------------------
procedure( Form_DemoCleanupClose( formHandle )
    when( formHandle
        axlDehighlightObject(nil)
        axlClearSelSet()
        axlFormClose(formHandle)
        formHandle = nil
    )
    t
)

;------------------------------------------------------------------------
; 私有函数
;------------------------------------------------------------------------

;------------------------------------------------------------------------
; 函数名  : _LogMessage
; 功能    : 统一日志输出（私有）
; 参数    :
;   @param level   - 日志级别 "INFO" / "WARN" / "ERROR"
;   @param message - 日志消息
; 返回值  : t
;------------------------------------------------------------------------
procedure( _LogMessage( level message )
    printf("[%s] %s\n" level message)
    t
)

; --- 自动初始化 ---
Init_DemoCleanup()
