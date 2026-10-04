;========================================================================
; 文件名    : util_quicksavebytime.il
; 作者      : gpxknk（原始作者）/ ASTB 修复组（规范化整改）
; 创建日期  : 2012-08-22
; 版本      : 1.1
; 功能描述  : 按时间自动另存设计文件，支持 日期/时间 两种后缀模式
; 依赖模块  : 无
; 修改记录  :
;   2012-08-22 v1.0 gpxknk 初始创建，统一格式 XXX_MMdd_hhmm.brd
;   2012-08-24 v1.0 gpxknk 增加模式参数：sd=日期+时间，sf=仅时间
;   2026-07-17 v1.1 ASTB 修复组 整改：
;             1) 原文件中文注释双重乱码损毁，按代码功能重写文件头
;                与全部注释（GBK 编码）
;             2) 保存类命令不得声明 undo，去除 ?undo t
;             3) axlSaveDesign 增加返回值检查，失败时明确提示
;========================================================================

;------------------------------------------------------------------------
; 命令注册：保存操作不支持 undo（规范 8.2），不挂 ?undo
;   用法：wxsf       - 另存为 XXX_MMdd_hhmm.brd（默认 date 模式）
;        wxsf time   - 另存为 XXX_hhmm.brd（仅时间）
;------------------------------------------------------------------------
axlCmdRegister("wxsf" 'wxSaveFileBT ?cmdType "general")

;------------------------------------------------------------------------
; 函数名  : wxSaveFileBT
; 功能    : 按当前日期时间生成后缀，将设计另存为新文件；
;           若文件名已带同类时间后缀，则替换为新时间后缀
; 参数    :
;   @param mode - "date"（默认，_MMdd_hhmm 后缀）或 "time"（_hhmm 后缀）
; 返回值  :
;   t   - 保存成功
;   nil - 参数错误或保存失败
; 副作用  : 在当前工作目录生成新的 .brd 文件
; 说明    : sD1/sD2/sT1/sT2 为前后缀定制变量（当前置空，即默认格式）：
;             sD1 日期前缀  sD2 日期后缀
;             sT1 时间前缀  sT2 时间后缀
;           命名约定：分隔符统一用 "_" 或 "-"；日期时间中间不用 ".",
;           不要混入空格、'\'、':'、'?' 等非法文件名字符。
;           零填充实现：sprintf 的 %2d 产生空格对齐，再用 rexReplace
;           把空格替换为 "0"（等效 %02d）。
; 示例    : wxSaveFileBT()        => demo_0717_2035.brd
;           wxSaveFileBT("time")  => demo_2035.brd
;------------------------------------------------------------------------
procedure( wxSaveFileBT(@optional (mode "date"))
    prog((tm sDate sTime sDName sDNameNew sPre sPost pt
          sD1 sD2 sT1 sT2 saveName saveResult)
        sD1 = ""
        sD2 = ""
        sT1 = ""
        sT2 = ""
        sDName = axlCurrentDesign()
        tm = timeToTm(stringToTime(getCurrentTime()))
        sTime = sprintf(nil "_%s%2d%2d%s" sT1 tm->tm_hour tm->tm_min sT2)
        sDate = sprintf(nil "_%s%2d%2d%s%s"
            sD1 tm->tm_mon + 1 tm->tm_mday sD2 sTime)
        ; %2d 空格对齐转零填充（等效 %02d）
        rexCompile(" ")
        sTime = rexReplace(sTime "0" 0)
        sDate = rexReplace(sDate "0" 0)
        case(mode
            ("time"
                pt = strcat("^\\(.+\\)[-_]+" sT1
                    "[0-2][0-9]\\.*[0-5][0-9]" sT2 "$")
                sPost = sTime
            )
            ("date"
                pt = strcat("^\\(.+\\)[-_]+" sD1 "[0-1][0-9][0-3][0-9]" sD2
                    "[-_]+" sT1 "[0-2][0-9]\\.*[0-5][0-9]" sT2 "$")
                sPost = sDate
            )
            (t
                printf("ERROR: wxSaveFileBT: bad argument '%s', use date|time\n"
                    mode)
                return(nil)
            )
        )
        ; 已带同类时间后缀则替换，否则追加
        rexCompile(pt)
        if( rexExecute(sDName) then
            sPre = rexSubstitute("\\1")
            sDNameNew = strcat(sPre sPost)
        else
            sDNameNew = strcat(sDName sPost)
        )
        saveName = strcat(sDNameNew ".brd")
        saveResult = axlSaveDesign(?design saveName)
        if( saveResult then
            printf("Save: [ %s ] --> [ %s ]\n" sDName sDNameNew)
            axlMsgPut(sprintf(nil "Saved: %s" saveName))
            t
        else
            printf("ERROR: wxSaveFileBT: save failed -> %s\n" saveName)
            axlUIConfirm(sprintf(nil
                "\261\243\264\346\312\247\260\334\243\272%s\n\307\353\274\354\262\351\304\277\302\274\310\250\317\336\273\362\264\305\305\314\277\325\274\344" saveName))
            nil
        )
    )
)
