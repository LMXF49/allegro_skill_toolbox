# Allegro SKILL（AXL）编码规范

**版本**：1.0  
**适用范围**：基于 Cadence SPB 17.4-2019 的 Allegro PCB Editor SKILL（AXL）二次开发  
**文件编码**：`.il` 源文件无中文注释时使用 UTF-8；含中文注释时建议使用 GBK，避免 Allegro 加载乱码  
**文档依据**：《Allegro SKILL Reference 中英对照手册（Cadence SPB 17.4-2019）》

---

## 1. 总则

### 1.1 设计目标

- **可读性**：代码结构和命名应能直观表达意图，降低跨团队协作成本。
- **可维护性**：模块边界清晰，公共接口稳定，私有实现可独立演进。
- **稳定性**：所有数据库操作必须可预测、可回滚，避免静默破坏设计数据。
- **兼容性**：代码应能在 17.4 及以上版本稳定运行，关键依赖需做版本校验。

### 1.2 适用范围

本规范覆盖使用 AXL-SKILL 为 Allegro PCB Editor 编写菜单、表单、命令、数据库操作脚本及插件接口时的编码活动。

### 1.3 术语定义

| 术语 | 含义 |
|------|------|
| AXL | Allegro PCB Editor 扩展层，所有 AXL 函数以 `axl` 开头。 |
| dbid | 数据库对象标识符，用于与 Allegro 数据库交互。 |
| Select Set | 当前选择对象集合，本质上是 `dbid` 列表。 |
| Figure | 通过 `axlDBCreate*` 系列函数创建的几何对象。 |

---

## 2. 文件组织规范

### 2.1 推荐目录结构

```
project/
├── main.il                    # 主入口：加载所有模块并注册命令
├── core/
│   ├── config.il              # 全局配置常量
│   ├── loader.il              # 模块自动加载器
│   ├── logger.il              # 日志输出封装
│   ├── error_handler.il       # 统一错误处理
│   └── utils.il               # 通用工具函数
├── modules/
│   ├── cleanup.il             # 功能模块
│   ├── replace_via.il
│   └── ...
├── forms/
│   └── cleanup.form           # 表单定义文件
├── menus/
│   └── cleanup.men            # 菜单定义文件
└── lib/
    └── third_party/           # 第三方库
```

### 2.2 文件命名

| 类型 | 命名规则 | 示例 |
|------|---------|------|
| 主入口文件 | `main.il` | `main.il` |
| 配置文件 | `config.il` | `config.il` |
| 功能模块 | `{module_name}.il` | `cleanup.il` |
| 工具库 | `{category}_utils.il` | `string_utils.il` |
| 菜单文件 | `{module}_menu.men` | `cleanup_menu.men` |
| 表单文件 | `{module}.form` | `cleanup.form` |

### 2.3 文件编码

- 无中文注释的 `.il` 文件：建议使用 UTF-8 保存。
- 含中文注释的 `.il` 文件：建议使用 GBK 保存，确保 Allegro 加载时不乱码。
- 菜单（`.men`）和表单（`.form`）文件：使用 ASCII 或 GBK，避免使用 UTF-8 BOM。

---

## 3. 命名规范

### 3.1 变量命名

| 变量类型 | 前缀/风格 | 示例 | 说明 |
|----------|-----------|------|------|
| 局部变量 | 小驼峰 | `layerName`, `objList` | 作用域限于 `let` / `prog` 内。 |
| 全局变量 | `g_` + 小驼峰 | `g_designName`, `g_toolboxVersion` | 必须通过 `boundp` 初始化，避免污染。 |
| 常量 | `C_` 或全大写下划线 | `C_PI`, `C_MAX_LAYER_COUNT` | 不可在运行时修改。 |
| 参数变量 | 小驼峰 | `inputDbid`, `options` | 语义清晰。 |

### 3.2 函数命名

| 函数类型 | 命名风格 | 示例 | 说明 |
|----------|----------|------|------|
| 公共函数 | `模块名_动词_名词` 或 `模块名_名词_动词` | `Cleanup_DeleteDynamicShapes` | 模块前缀 + 帕斯卡命名，避免命名冲突。 |
| 私有函数 | 下划线前缀 | `_GetSelectedObjects` | 仅在模块内部使用。 |
| 回调函数 | `CB_` 或 `Callback_` 前缀 | `CB_FormCallback`, `Callback_OnClose` | 明确回调身份。 |
| 初始化函数 | `Init_模块名` | `Init_CleanupModule` | 每个模块提供统一初始化入口。 |

### 3.3 对象与特定变量命名

| 对象类型 | 命名建议 | 示例 |
|----------|----------|------|
| dbid | 以 `Id` 或 `Obj` 结尾 | `shapeId`, `viaObj` |
| dbid 列表 | 复数或 `List` 后缀 | `shapeList`, `selectedIds` |
| 边界框 | `BBox` 或 `bbox` 后缀 | `objBBox`, `designBBox` |
| 层名 | `Layer` 后缀 | `etchLayer`, `outlineLayer` |
| 属性 | `Prop` 后缀 | `widthProp`, `netNameProp` |
| 表单句柄 | `Form` 后缀 | `configForm`, `mainForm` |

### 3.4 全局变量保护

所有全局变量必须在初始化时检查是否已绑定，避免重复加载时覆盖。

```skill
; 推荐
unless(boundp('g_designName)
    g_designName = nil
)

; 禁止
; g_designName = nil  ; 可能覆盖用户已有值
```

---

## 4. 编码风格规范

### 4.1 缩进与空白

- 使用 **4 个空格**缩进，禁止使用 Tab。
- 左括号后、右括号前各保留一个空格（传统 SKILL 风格）。
- 运算符两侧保留一个空格。
- 逗号/分号分隔符后保留一个空格。

```skill
; 推荐
procedure( Cleanup_DeleteShapesByNet( netName )
    let((objList result)
        objList = axlSelectByName("NET" netName)
        foreach(obj objList
            axlDeleteObject(obj)
        )
        result = length(objList) + 1
        result
    )
)
```

### 4.2 括号风格

- 采用 Allegro 传统风格：函数名与左括号之间留一个空格。
- `if` / `when` / `unless` 使用 `then` / `else` 关键字。
- 循环体、条件体必须换行缩进。

```skill
; 推荐
if( condition then
    trueBody
else
    falseBody
)

foreach( item itemList
    when( item->isValid
        process(item)
    )
)
```

### 4.3 行长度与换行

- 单行不超过 100 个字符。
- 长参数列表或长表达式应换行并对齐。

```skill
; 推荐
axlFormCreate(
    "myForm"
    "My Form Title"
    '(150 150 450 400)
    'FORM
    'callbackFunc
)

result = axlMathDistance(
    car(startPoint)
    cadr(startPoint)
    car(endPoint)
    cadr(endPoint)
)
```

---

## 5. 注释规范

### 5.1 文件头注释

每个 `.il` 文件必须包含以下文件头注释：

```skill
;========================================================================
; 文件名    : cleanup.il
; 作者      : [作者名]
; 创建日期  : 2024-01-15
; 版本      : 1.0
; 功能描述  : 清理模块，提供 dynamic shape 与 static shape 的批量删除功能
; 依赖模块  : core/utils.il, core/logger.il
; 修改记录  :
;   2024-01-15 v1.0 [作者] 初始创建
;   2024-02-01 v1.1 [作者] 新增 static shape 删除支持
;========================================================================
```

### 5.2 函数注释

公共函数必须包含函数注释，说明功能、参数、返回值和副作用。

```skill
;------------------------------------------------------------------------
; 函数名  : Cleanup_DeleteDynamicShapes
; 功能    : 批量删除所有 dynamic shape
; 参数    :
;   @param layerFilter - 图层过滤字符串，nil 表示所有层
;   @param confirmFlag - 是否弹出确认对话框 (t/nil)
; 返回值  :
;   t - 删除成功
;   nil - 删除失败或被用户取消
; 副作用  : 修改当前设计数据库，建议先保存
; 示例    : Cleanup_DeleteDynamicShapes("ETCH/TOP" t)
;------------------------------------------------------------------------
procedure( Cleanup_DeleteDynamicShapes( layerFilter confirmFlag )
    ...
)
```

### 5.3 代码内注释

- 在复杂逻辑块前使用分段注释。
- 避免对显而易见的内容加注释。

```skill
; --- 阶段 1: 设置查找过滤器 ---
axlSetFindFilter(
    ?enabled  '("NOALL" "SHAPES")
    ?onButton '("SHAPES")
)

; 仅过滤 dynamic shape
foreach(shape shapeList
    when( shape->type == "dynamic"
        deleteList = cons(shape deleteList)
    )
)
```

---

## 6. API 使用规范

### 6.1 数据库操作规范

- 读取数据库对象前，必须验证 `dbid` 是否有效。
- 对数据库进行修改时，必须包裹在事务（Transaction）中。
- 创建函数返回值通常是列表：`(car)` 为创建的 dbid，`(cadr)` 为 DRC 标志。

```skill
; --- 读取操作（安全）---
let((objProp)
    when( objId && objId->objType
        objProp = axlDBGetProp(objId "NET_NAME")
    )
)

; --- 创建操作（需事务保护）---
let((result)
    axlDBTransactionStart(nil)  ; 开始事务

    result = axlDBCreatePath(
        points
        "ETCH/TOP"
        'LINE
        width
        netId
    )

    if( car(result) then
        axlDBTransactionCommit(nil)  ; 提交事务
        printf("创建成功: %L\n" car(result))
    else
        axlDBTransactionRollback(nil)  ; 回滚事务
        printf("创建失败\n")
    )
)
```

### 6.2 dbid 有效性规则

- 调用 `axlShell` 或切换数据库后，所有已获取的 `dbid` 会失效。
- 使用 `axlDBRefreshId` 检查 `dbid` 是否仍有效；无效返回 `nil`。
- 对可能失效的 `dbid` 进行属性访问前，必须检查 `objId->objType` 是否存在。

```skill
when( shapeId && axlDBRefreshId(shapeId)
    printf("对象仍有效: %L\n" shapeId->objType)
)
```

### 6.3 选择集操作规范

- 操作选择集前应先清空旧选择集。
- 设置 `FindFilter` 时应显式启用和禁用对象类型，避免意外选择。

```skill
; 标准选择流程
procedure( SelectObjects_ByFilter( filterType )
    let((selectSet)
        ; 1. 重置选择集
        axlClearSelSet()

        ; 2. 设置查找过滤器
        axlSetFindFilter(
            ?enabled  '("NOALL" filterType)
            ?onButton '(filterType)
        )

        ; 3. 获取选择结果
        selectSet = axlGetSelSet()

        selectSet
    )
)
```

### 6.4 创建 Figure 的规范

- 使用 `axlSetCurrentLayer` 设置当前活动层后再创建图形。
- 只有在蚀刻层（etch layer）上创建的图形才会被自动加入网络。
- 创建函数返回列表，需检查 `car(result)` 是否为 `nil`。

```skill
let((result)
    axlSetCurrentLayer("ETCH/TOP")
    result = axlDBCreatePath(
        '(100:100 200:200 300:100)
        "ETCH/TOP"
        'LINE
        10.0
        netId
    )
    if( car(result) then
        car(result)  ; 返回新创建对象的 dbid
    else
        nil
    )
)
```

---

## 7. 表单与界面规范

### 7.1 表单文件组织

- 表单定义文件（`.form`）通过 `FORMPATH` 环境变量查找。
- 表单字段类型建议首字母大写，避免与未来 Allegro 版本字段冲突。
- 表单可嵌入 SKILL 代码中，但推荐独立文件管理。

### 7.2 表单创建规范

```skill
procedure( Form_CreateMain()
    let((formHandle)
        formHandle = axlFormCreate(
            "mainForm"
            "Allegro Toolbox"
            '(200 200 600 500)
            'FORM
            'CB_FormMain
        )

        axlFormSetField(formHandle "version" g_toolboxVersion)
        axlFormDisplay(formHandle)

        formHandle
    )
)
```

### 7.3 回调函数规范

- 回调函数接收 `formHandle`、`fieldName`、`fieldValue` 参数。
- 使用 `case` 分支处理字段事件，默认分支记录未处理字段。

```skill
procedure( CB_FormMain( formHandle fieldName fieldValue )
    case( fieldName
        ("done"
            Form_Close(formHandle)
        )
        ("apply"
            Form_ApplySettings(formHandle)
        )
        (t
            printf("未处理的字段: %s\n" fieldName)
        )
    )
)
```

---

## 8. 命令注册与交互规范

### 8.1 命令注册

- 使用 `axlCmdRegister` 注册命令到 Allegro shell。
- 数据库修改类命令使用 `interactive` 类型。
- 非数据库操作或查看类命令使用 `general` 类型。

```skill
axlCmdRegister(
    "myCleanup"
    'MyCleanup_Callback
    ?cmdType "interactive"
    ?doneCmd 'MyCleanup_Done
    ?cancelCmd 'MyCleanup_Cancel
    ?undo t
)
```

### 8.2 撤销/重做支持

支持撤销的命令必须满足：

- 数据库更改包裹在 `axlDBTransaction*` 中。
- 不执行保存或打开数据库操作。
- 不调用带重新加载数据库选项的 `axlRunBatchDBProgram`。
- 不使用 `axlShell`。
- 避免单次操作产生大量数据库变更。

**撤销实现步骤：**
1. 使用 `axlDBTransactionStart(nil)` 开始事务
2. 执行数据库修改操作
3. 使用 `axlDBTransactionCommit(nil)` 提交事务（支持撤销）
4. 或使用 `axlDBTransactionRollback(nil)` 回滚事务（撤销本次操作）

**快捷键绑定撤销支持：**
当使用 `axlCmdRegister` 注册命令时，添加 `?undo t` 参数：
```skill
axlCmdRegister(
    "myCommand"
    'MyCommand_Callback
    ?cmdType "interactive"
    ?undo t
)
```

**注意：** 仅当命令内部使用 `axlDBTransactionStart/Commit` 时，`?undo t` 才有效。纯查询类命令无需此参数。

### 8.3 环境模式检查

在启动需要选择集或数据库创建的操作前，检查当前环境是否允许。

```skill
unless( axlOKToProceed()
    axlUIConfirm("当前环境不允许执行该操作")
    return(nil)
)
```

---

## 9. 属性字典与用户属性

### 9.1 创建属性字典条目

- 使用 `axlDBCreatePropDictEntry` 创建用户定义属性字典。
- 属性名必须唯一。
- 属性类型合法值包括 `BOOLEAN`、`INTEGER`、`REAL`、`STRING` 等。

### 9.2 字符串检查

- 使用 `axlCheckString` 检查字符串合法性。
- 对 `PROPVALUE` 外的类型，输入字符串可能被转换为大写并去除前后空白。

```skill
let((checkedName)
    checkedName = axlCheckString(inputName "NET")
    if( checkedName then
        checkedName
    else
        nil
    )
)
```

---

## 10. 错误处理与调试

### 10.1 错误处理原则

- 不要忽略 `axl*` 函数的返回值。
- 关键操作成功后打印日志，失败后打印错误信息。
- 使用统一的错误处理函数，避免在业务逻辑中直接弹窗。

```skill
procedure( ErrorHandler_Report( message level )
    case( level
        ("ERROR"
            printf("[ERROR] %s\n" message)
            axlUIConfirm(message)
        )
        ("WARN"
            printf("[WARN] %s\n" message)
        )
        (t
            printf("[INFO] %s\n" message)
        )
    )
)
```

### 10.2 调试辅助

- 使用 `axlPrintDbid` 简洁打印 dbid 信息。
- 使用 `axlDebug(t)` 开启失败调试信息。
- 复杂逻辑中可临时使用 `printf` 输出中间变量。

### 10.3 日志级别

建议至少支持 `INFO`、`WARN`、`ERROR` 三级日志，统一由 `core/logger.il` 封装。

---

## 11. 性能与资源管理

### 11.1 避免在循环中重复获取全局数据

```skill
; 推荐
procedure( Process_LargeObjectList( objList )
    let((designBBox totalCount)
        designBBox = axlDBGetDesign()->bBox
        totalCount = length(objList)
        foreach(obj objList
            when( _Obj_IsInsideBBox(obj designBBox)
                _Obj_Process(obj)
            )
        )
        totalCount
    )
)
```

### 11.2 资源释放

表单关闭或命令结束时，必须释放相关资源：

```skill
procedure( Form_Close( formHandle )
    when( formHandle
        axlDehighlightObject(nil)
        axlClearSelSet()
        axlFormClose(formHandle)
        formHandle = nil
    )
)
```

### 11.3 大循环优化

- 对大量对象进行遍历前，先使用选择集或过滤器减少处理范围。
- 避免在循环中创建临时文件或频繁刷新界面。

---

## 12. 版本兼容性

### 12.1 版本检测

```skill
procedure( Version_CheckCompatibility()
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
```

### 12.2 特性隔离

对新版本 API 使用条件包装，避免旧版本加载失败。

```skill
when( g_versionMajor >= 17 && g_versionMinor >= 4
    procedure( Use_NewFeature()
        ...
    )
)
```

---

## 13. 检查清单

### 13.1 提交前自检

- [ ] 文件头注释完整（作者、日期、版本、功能描述）。
- [ ] 所有公共函数包含函数注释。
- [ ] 变量命名符合规范（前缀、驼峰/帕斯卡）。
- [ ] 全局变量通过 `boundp` 初始化。
- [ ] 无 Tab 缩进，使用 4 空格缩进。
- [ ] 行长度不超过 100 字符。
- [ ] 所有 `axl*` 函数返回值已检查。
- [ ] 数据库修改有事务包裹（`axlDBTransactionStart/Commit/Rollback`）。
- [ ] 选择集操作前有 `axlClearSelSet`。
- [ ] 资源释放逻辑完整（表单、高亮、选择集）。
- [ ] 无硬编码版本号或路径。
- [ ] 错误处理覆盖所有异常分支。
- [ ] 代码在 Allegro 中加载测试无报错。

### 13.2 禁止事项

| 禁止行为 | 风险说明 | 推荐做法 |
|----------|----------|----------|
| 使用裸 `set` | 可能创建全局变量 | 使用 `let` 局部绑定 |
| 忽略 `axl*` 返回值 | 导致静默失败 | 始终检查 `car(result)` |
| 硬编码坐标 | 设计变更后失效 | 使用相对坐标或动态计算 |
| 直接操作内部 `dbid->` 属性 | 可能损坏数据库 | 使用 `axlDBGetProp` / `axlDBSetProp` |
| 在循环内重复 `axlDBGetDesign` | 性能问题 | 循环外获取一次 |
| 无事务保护的数据库修改 | 无法回滚 | 使用 `axlDBTransactionStart` |
| 表单关闭未清理资源 | 内存泄漏 | 统一 `Form_Close` 函数 |
| 不检查 `dbid` 有效性 | 使用失效 dbid 导致异常 | 使用 `axlDBRefreshId` |
| 文件名含空格 | 旧版本 Allegro 不支持 | 使用无空格路径 |

---

## 附录 A：代码模板

### A.1 新模块模板

```skill
;========================================================================
; 文件名    : {module_name}.il
; 作者      : [作者名]
; 创建日期  : [日期]
; 版本      : 1.0
; 功能描述  : [模块功能简述]
;========================================================================

; --- 模块常量 ---
C_MODULE_NAME = "{ModuleName}"

; --- 全局变量初始化 ---
unless(boundp('g_{ModuleName}Enabled)
    g_{ModuleName}Enabled = t
)

;------------------------------------------------------------------------
; 函数名  : Init_{ModuleName}
; 功能    : 模块初始化
; 参数    : 无
; 返回值  : t - 初始化成功
;------------------------------------------------------------------------
procedure( Init_{ModuleName}()
    printf("[%s] 模块初始化完成\n" C_MODULE_NAME)
    t
)

; --- 公共函数 ---

; --- 私有函数 ---

; --- 自动初始化 ---
Init_{ModuleName}()
```

### A.2 带表单的模块模板

```skill
;========================================================================
; 文件名    : {module_name}.il
; 功能描述  : 带 GUI 的功能模块
;========================================================================

; --- 表单定义 ---
; 表单文件: forms/{module_name}.form

;------------------------------------------------------------------------
; 函数名  : CB_{ModuleName}Form
; 功能    : 表单字段回调
;------------------------------------------------------------------------
procedure( CB_{ModuleName}Form( formHandle fieldName fieldValue )
    case( fieldName
        ("done"
            Form_{ModuleName}Close(formHandle)
        )
        ("apply"
            {ModuleName}_Apply(formHandle)
        )
        (t
            printf("未处理字段: %s\n" fieldName)
        )
    )
)

;------------------------------------------------------------------------
; 函数名  : Form_{ModuleName}Create
; 功能    : 创建并显示表单
;------------------------------------------------------------------------
procedure( Form_{ModuleName}Create()
    let((formHandle)
        formHandle = axlFormCreate(
            "{moduleName}Form"
            "{Module Name}"
            '(200 200 500 400)
            'FORM
            'CB_{ModuleName}Form
        )
        axlFormDisplay(formHandle)
        formHandle
    )
)

;------------------------------------------------------------------------
; 函数名  : Form_{ModuleName}Close
; 功能    : 关闭表单并释放资源
;------------------------------------------------------------------------
procedure( Form_{ModuleName}Close( formHandle )
    when( formHandle
        axlDehighlightObject(nil)
        axlClearSelSet()
        axlFormClose(formHandle)
    )
)

; --- 业务逻辑 ---
procedure( {ModuleName}_Apply( formHandle )
    let((result)
        axlDBTransactionStart(nil)
        result = {ModuleName}_Execute()
        if( result then
            axlDBTransactionCommit(nil)
            axlUIConfirm("操作成功")
        else
            axlDBTransactionRollback(nil)
            axlUIConfirm("操作失败")
        )
    )
)
```

---

**文档说明**：本规范基于《Allegro SKILL Reference 中英对照手册（Cadence SPB 17.4-2019）》提取整理，实际项目中应结合团队需求进一步细化。
