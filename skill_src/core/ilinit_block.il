;; >>> ASTB TOOLBOX BEGIN >>>
;; allegro_skill auto-load entry (written by ASTB installer)
;; Encoding: ASCII
ASTB_INSTALL_DIR = "@INSTALL_DIR@"
errset(
  prog((cur v)
    foreach( v list("FORMPATH" "BITMAPPATH" "BMPPATH")
      cur = axlGetVariableList(v)
      when( stringp(cur) cur = list(cur) )
      unless( and(cur member(strcat(ASTB_INSTALL_DIR "/forms") cur))
        axlSetVariable(v cons(strcat(ASTB_INSTALL_DIR "/forms") cur))
      )
    )
  )
  t
)
setSkillPath(cons(ASTB_INSTALL_DIR getSkillPath()))
load(strcat(ASTB_INSTALL_DIR "/main.il"))
;; <<< ASTB TOOLBOX END <<<
