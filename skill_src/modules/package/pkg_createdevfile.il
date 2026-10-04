;========================================================================
; 文件名    : pkg_createdevfile.il
; 作者      : deargds / ASTB 整改组
; 创建日期  : 2026-07-16
; 版本      : 1.1
; 功能描述  : 为当前目录下所有 package 类型的 .dra 封装批量生成 device 文件
; 依赖模块  : core
; 备注      : 本功能通过 axlOpenDesign 逐个打开 .dra 并 replay 脚本生成 device，
;             会切换当前设计且调用 axlShell，无法事务化、不可 undo；
;             依赖 Allegro 内部表单名 crdevice，16.6/17.4/24.1 间需实机验证
; 修改记录  :
;   2026-07-16 v1.0 deargds 初始创建
;   2026-07-17 v1.1 ASTB 整改：重写损坏文件头；修复 axlDesignType 大小写比较
;                    （"PACKAGE" -> "package"，手册确认返回小写）；删除裸
;                    axlCmdRegister(FYED)；局部变量补绑定；运行前提示保存、
;                    结束后恢复原设计；补处理汇总日志
;========================================================================

;------------------------------------------------------------------------
; 函数名  : FanySkill_Export_Device
; 功能    : 遍历当前目录 .dra，对 package 类型逐个 replay create device 脚本
; 参数    : 无
; 返回值  : 无
; 副作用  : 切换当前设计（结束后尝试恢复）；在 .dra 旁生成 device 文件；调用 axlShell
;------------------------------------------------------------------------
procedure( FanySkill_Export_Device()
    prog((draList p scriptFileName scriptFile runScript origDesign cnt)
        cnt = 0
        unless( axlUIYesNo("本命令将逐个打开当前目录下的 .dra 并切换设计，请先保存当前工作。是否继续？")
            return(nil)
        )
        origDesign = axlCurrentDesign()
        draList = rexMatchList("\\.dra$" getDirFiles(".\\"))
        foreach( p draList
            when( axlOpenDesign(?design p ?mode "wf")
                when( axlDesignType(t) == "package"
                    scriptFileName = axlTempFile()
                    scriptFile = axlDMOpenFile("TEMP" scriptFileName "w")
                    when( scriptFile
                        fprintf(scriptFile "scriptmode +i\n\n")
                        fprintf(scriptFile "setwindow pcb \n")
                        fprintf(scriptFile "create device \n")
                        fprintf(scriptFile "setwindow form.crdevice \n")
                        fprintf(scriptFile "FORM crdevice done \n")
                        fprintf(scriptFile "setwindow pcb \n")
                        axlDMClose(scriptFile)
                        ; 路径加引号，防止含空格时 replay 解析失败
                        sprintf(runScript "replay \"%s\"" scriptFileName)
                        axlShell(runScript)
                        cnt++
                    )
                )
            )
        )
        ; 恢复用户原设计
        when( origDesign && stringp(origDesign)
            axlOpenDesign(?design origDesign ?mode "wf")
        )
        printf("[ASTB] CreateDevFile 完成：扫描 %d 个 .dra，生成 %d 个 device 文件\n"
            length(draList) cnt)
    )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Pkg_CreateDevFile
; 功能    : ASTB 框架入口（不可事务化，见文件头备注）
;------------------------------------------------------------------------
procedure( ASTB_Pkg_CreateDevFile()
    FanySkill_Export_Device()
)

ASTB_RegisterCommand("ASTB_Pkg_CreateDevFile" "ASTB_Pkg_CreateDevFile"
    ?cmdType "interactive" ?undo nil)

printf("[ASTB] pkg_createdevfile.il loaded.\n")
