# axlExtractToFile / extracta 排障实战手册

> 来源：2026-07-18 超级网络查找器（28_lgs_super_net_finder.il）SPMHDX-10 连环排障，全部结论均在 Allegro 17.4 S039 实机验证。

## 一、核心结论速查

| # | 结论 | 错误现象 |
|---|------|----------|
| 1 | `axlExtractToFile(t_viewFile ...)` 的 viewFile 是**按 TEXTPATH 查找的"名称"**，传全路径会被判成视图名 | `ERROR(SPMHDX-10): 非法的视图名称` |
| 2 | `outfile` 在 Windows **不做 CRLF 转换**，字符串内 `\n` 写成纯 LF；Windows 版 extracta **只认 CRLF**，LF-only 的命令文件被整篇读成一行 | 同上（视图名变成 `NET NET_NAME ... END` 整行） |
| 3 | `gets` 读 extracta 输出文件：**剥 `\r` 留 `\n`**，每条记录末尾多一个 `"\n"` token | 解析丢记录 |
| 4 | `parseString` **吞空字段**（连续分隔符不产空 token） | 含空字段的记录 token 数对不上被误杀 |
| 5 | `index(字符串 子串)` 是 **strstr 语义**（返回匹配点开始的尾串），不是位置 | `difference: can't handle ("..." - 1)` |
| 6 | `rexReplace(t_str t_pattern x_pos)` 第 3 参数是**整数位置**，不是替换串 | `rexReplace: argument #3 should be an integer` |
| 7 | `axlDehighlightObject()` **至少需 1 个参数**，无参调用报错 | `too few arguments (at least 1 expected, 0 given)` |
| 8 | `axlSingleSelectName` 前必须 `axlSetFindFilter` 使能对应类型，否则**静默失败** | 点选无反应（无缩放无高亮） |
| 9 | NET dbid 的 `->bBox` 不可靠；缩放用 `axlZoomToDbid(dbid t)` 自动按对象范围居中 | 缩放位置不对 |

## 二、正确的 extract 代码模板

```skill
; --- 命令文件：显式 \r\n 写入（纯 LF 会 SPMHDX-10）---
cmdFilePath = strcat(axlTempDirectory() "/my_view.txt")
port = outfile(cmdFilePath "w")
fprintf(port "NET\r\n  NET_NAME\r\n  NET_ETCH_LENGTH\r\nEND\r\n")
close(port)

; --- 临时目录前置进 TEXTPATH，调用只传"名称"不带扩展名 ---
axlSetVariable("TEXTPATH" strcat(". " axlTempDirectory() " " (axlGetVariable("TEXTPATH") || "")))
unless( axlExtractToFile("my_view" strcat(axlTempDirectory() "/my_data"))  ; 输出自动追加 .txt
    axlUIConfirm("提取失败，详见板子目录 extract.log")
    return(nil)
)

; --- 解析：gets 剥 \r 留 \n，行尾用 \n 转义剥掉；空字段先补 0 ---
dataPort = infile(strcat(axlTempDirectory() "/my_data.txt"))
while( ((textLine = gets(line dataPort)) != nil)
    textLine = car(parseString(textLine "\n"))       ; 剥行尾 LF（实测必需）
    while( (tail = index(textLine "!!"))              ; index 是 strstr 语义
        pos = strlen(textLine) - strlen(tail) + 1     ; 用 strlen 换算位置
        textLine = strcat(substring(textLine 1 pos-1) "!0!" substring(textLine pos+2))
    )
    tokens = parseString(textLine "!")
    when( length(tokens) == 5 && car(tokens) == "S"
        ; tokens = ("S" name field1 field2 field3)
    )
)
```

## 三、排障方法论（按此顺序，不要猜）

1. **读 extract.log**：在**当前板子（.brd）所在目录**，不在临时目录。视图文件内容会被原样回显，一眼看出"整行化"等格式问题。
2. **独立复现**：命令行直接跑 `tools/bin/extracta.exe <brd> <cmdfile> <outfile>`。独立环境成功而会话内失败 → 差异在 axlExtractToFile 的语义（名称查找）而非文件内容。
3. **判别测试**：`skill axlExtractToFile("net_bv" "D:/Temp/test_out")`（官方标准视图）。返回 `t` → extract 机制完好，问题在自定义视图文件/参数。
4. **验证环境真值**：`axlGetVariable("TEXTPATH")` / `axlGetVariable("ALLEGRO_INSTALL_DIR")` / `axlTempDirectory()`，不要凭 env 文件推断（会话内可能被 axlSetVariable 改过）。
5. **统计锚点**：提取全量但列表残缺时，用"独立提取记录数"对比"解析后记录数"，并找出**幸存记录的共同特征**（本例：13 个电源网恰好是唯一 token 数对得上的记录）。
6. **hexdump 定长度**：命令文件字节数能对上"纯 LF"还是"CRLF"，一行命令排除换行符猜想。

## 四、本例完整根因链（三连坑叠加）

1. v1.1 整改把 `axlExtractToFile` 参数从文件名改成全路径 → SPMHDX-10（表层）
2. 命令文件纯 LF 写入，extracta 只认 CRLF → 同样 SPMHDX-10（真凶）
3. 修复提取后解析只剩 13 个电源网：`gets` 留 `\n` 多 1 token + `parseString` 吞空字段，普通记录 6 token 被 `length==5` 误杀，空曼哈顿字段的电源网恰好 5 token 存活

## 五、相关易错点

- `axlExtractToFile` 输出文件名**不要带扩展名**，a_extract 自动追加 `.txt`，否则得到 `.txt.txt`。
- 修改含中文的 GBK .il 文件时，补丁脚本中的 `\r\n` 等转义经命令通道多层解码易变成真实控制字符写入源码，注释被截断会产生裸文本行（加载报 `unbound variable`）。建议用 `chr(92)` 拼接构造反斜杠序列，写盘后必须：括号平衡扫描 + 残留 CR 扫描 + iconv 核对。
- `boundp` 保护全局变量；高亮类功能用全局变量记录上次高亮对象，先 dehighlight 旧对象再 highlight 新对象。
