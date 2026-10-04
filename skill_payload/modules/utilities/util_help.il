;========================================================================
; 文件名    : util_help.il
; 作者      : ASTB Team
; 创建日期  : 2026-08-22
; 版本      : 1.1
; 功能描述  : System/Help 菜单实现：读 core/help_map.dat（GBK，每行
;             菜单命令名|功能|步骤|实现），按 ASTB_GetMenuStructure
;             的分类顺序拼成临时文本，axlUIViewFileCreate 弹出文件
;             查看器对话框显示（与 route_automatchgroup.il 的 Help
;             按钮同款）
; 依赖模块  : core/utils.il（ASTB_StringTrim/ASTB_StringSplit）、
;             core/menu.il（菜单结构与标签查询）、core/help_map.dat
; 编码      : GBK（含中文字符串）
; 修改记录  :
;   2026-08-22 v1.0 ASTB Team 初始创建（用户要求：系统菜单加帮助，
;                   写明各命令的实现步骤与方法，走命令行不弹窗）
;   2026-08-22 v1.1 ASTB Team 改为弹窗显示（用户要求：像 Auto Match
;                   Group 的 Help 一样弹对话框，不再刷命令行）；
;                   查看器调用失败时回退命令行输出
;========================================================================

;------------------------------------------------------------------------
; 函数名  : ASTB_HelpLoadMap
; 功能    : 解析 core/help_map.dat 为表：命令名 -> (功能 步骤 实现)
; 返回值  : 表；文件缺失/不可读返回 nil
;------------------------------------------------------------------------
procedure( ASTB_HelpLoadMap()
  prog((mapPath port line parts tbl)
    mapPath = strcat(ASTB_GLOBAL->CorePath "/help_map.dat")
    unless( isFile(mapPath)
      axlUIWPrint(nil strcat("[ASTB] \260\357\326\372\312\375\276\335\310\261\312\247: " mapPath))
      return(nil)
    )
    port = infile(mapPath)
    unless( port
      axlUIWPrint(nil "[ASTB] \260\357\326\372\312\375\276\335\262\273\277\311\266\301")
      return(nil)
    )
    tbl = makeTable('ASTB_HELP_MAP nil)
    while( gets(line port)
      line = ASTB_StringTrim(line)
      when( and(strlen(line) > 0
                not(equal(substring(line 1 1) ";"))
                not(equal(substring(line 1 1) "#")) )
        parts = ASTB_StringSplit(line "|")
        when( and(parts length(parts) >= 4 strlen(car(parts)) > 0)
          tbl[car(parts)] = list(cadr(parts) caddr(parts) cadddr(parts))
        )
      )
    )
    close(port)
    return(tbl)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_HelpPrintOne
; 功能    : 向已打开端口输出一条命令的帮助文本
;------------------------------------------------------------------------
procedure( ASTB_HelpPrintOne(p label cmd parts)
  if( parts
  then
    fprintf(p "  %s (%s)\n" label cmd)
    fprintf(p "    \271\246\304\334: %s\n" car(parts))
    fprintf(p "    \262\275\326\350: %s\n" cadr(parts))
    fprintf(p "    \312\265\317\326: %s\n\n" caddr(parts))
  else
    fprintf(p "  %s (%s) \324\335\316\336\260\357\326\372\312\375\276\335\n\n" label cmd)
  )
)

;------------------------------------------------------------------------
; 函数名  : ASTB_Help
; 功能    : System/Help 菜单命令：弹文件查看器显示全部命令帮助
; 返回值  : t
; 备注    : axlUIViewFileCreate 第三参 t 与 AMG Help 一致（调用后即可
;           删临时文件）；查看器不可用时回退命令行逐条输出
;------------------------------------------------------------------------
procedure( ASTB_Help()
  prog((tbl menuList item cmd label parts f p ret)
    tbl = ASTB_HelpLoadMap()
    menuList = ASTB_GetMenuStructure()
    f = axlTempFile()
    p = outfile(f "w")
    unless( p
      axlUIWPrint(nil "[ASTB] \316\336\267\250\264\264\275\250\260\357\326\372\301\331\312\261\316\304\274\376")
      return(nil)
    )
    fprintf(p "allegro_skill \303\374\301\356\260\357\326\372\243\250\271\246\304\334 / \262\331\327\367\262\275\326\350 / \312\265\317\326\267\275\267\250\243\251\n")
    fprintf(p "============================================================\n\n")
    foreach( item menuList
      cond(
        ( ASTB_MenuIsPopup(item)
          fprintf(p "\241\276%s\241\277\n" ASTB_MenuGetPopupLabel(item))
        )
        ( ASTB_MenuIsCommand(item)
          cmd = ASTB_MenuGetCommand(item)
          label = ASTB_MenuGetCommandLabel(item)
          parts = and(tbl tbl[cmd])
          ASTB_HelpPrintOne(p label cmd parts)
        )
        ( t nil )  ;; separator / end 不输出
      )
    )
    close(p)
    ret = errset(axlUIViewFileCreate(f "allegro_skill \303\374\301\356\260\357\326\372" t) t)
    if( and(ret car(ret))
    then
      deleteFile(f)
    else
      ;; 查看器不可用时回退命令行
      axlUIWPrint(nil "[ASTB] \316\304\274\376\262\351\277\264\306\367\262\273\277\311\323\303\243\254\260\357\326\372\270\304\327\337\303\374\301\356\320\320\243\272")
      p = infile(f)
      when( p
        while( gets(cmd p)
          axlUIWPrint(nil cmd)
        )
        close(p)
      )
      deleteFile(f)
    )
    return(t)
  )
)

printf("[ASTB] utilities/util_help.il loaded, command: ASTB_Help (System/Help)\n")
