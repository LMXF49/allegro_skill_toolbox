;   2026-08-20 v1.6 ASTB Team 主命令注册补 ?undo t（17.4+ 支持系统
;                   撤销 Ctrl+Z；16.6 同步时由补丁脚本剥除）
;========================================================================
; 文件名    : text_renamerefdes.il
; 作者      : David J. Scheuring (Cadence)（原作）；ASTB（工具箱集成整改）
; 创建日期  : 1995-06-02
; 版本      : 1.6
; 功能描述  : 交互式批量重命名元件位号(RefDes)，支持前缀匹配高亮、起始编号、
;             Oops 单步回退（内部经 Allegro 脚本实现改名，重叠位号可能改错对象）；
;             Done/Reset 提交的批次可用 rename ref desu 命令逐批撤销
; 依赖模块  : 无
; 修改记录  :
;   1995-06-02 v1.0 David J. Scheuring 初始创建（原文件头中文已乱码，按代码语义重写）
;   2026-07-16 v1.1 ASTB 加规范文件头
;   2026-07-18 v1.2 ASTB 整改：axlShell 脚本改库不可撤销，去掉注册的 ?undo t；
;             shell(rm) 改 deleteFile；临时 .form/.scr 改写临时目录；
;             axlGetSelSet 0 参 API 误用拆两行；Start_Number 字段名大小写统一；
;             顶层全局加 boundp 保护；文件转 GBK 编码
;   2026-07-18 v1.3 ASTB 界面汉化：表单标题/标签/按钮/弹窗及提示译为中文
;   2026-08-20 v1.4 ASTB 新增撤销：Done/Reset 清计数列表前把本批改名
;             （旧位号+坐标+新位号，不存 dbid）压入 _RenameRefDes_undoStack；
;             新增 rename ref desu 命令逐批撤销——按坐标现场找回位号文本
;             核对后脚本回放改回旧位号（与改名同机制）
;   2026-08-20 v1.5 ASTB 接入统一撤销中枢 astbundo（core/trans.il
;             v1.4）：ASTB_RegisterUndo 注册 Rename_RefDes_Undo，批次入栈
;             同步 ASTB_UndoJournalPush；Done 提示改指 astbundo
;             （rename ref desu 命令保留为别名）
;========================================================================

; ###############################################################################
 
;                   Interactive Reference Designator renaming

;  This routine will open a form which allows the operator to specify the new prefix
;  and starting number to use when renaming components. By selecting "Begin Rename"
;  the form is replaced with a form which displays the "Next Number" that will be
;  used when a reference designator is selected. The next number will increment by
;  1 with each selection. The routine will also highlight all components whose name
;  matches the new pefix. This makes it much easier to determine which components
;  should be selected when viewing the whole board. As each ref des is selected it
;  is changed to the current "next number" and the component is de-highlighted. The
;  routine tracks the number of components that have been changed and compares the
;  the running talley against the number of components whose prefix matches the the
;  Match Prefix, when the last matching component is renamed the tracking form will
;  automatically close and the original Rename form will be displayed.

;  The action of the form is as follows:
;  > Match Prefix - This field is used to specify the ref des prefix to use when
;    highlighting components.
;  > New Prefix - This field is used to specify the ref des prefix to use when the
;    components are renamed.
;  > Start Number - This field is used to specify the starting number to use when
;    renaming the components.
;  > Begine Rename - This button closes the Rename Ref Des form and opens the Tracking
;    form. All components whose ref des matches the match prefix are highlighted and
;    the operator is prompted to "Enter selection point". With each ref des selected
;    the component is renamed to the current next number and the selected component
;    is de-highlighted. A middle mouse button push will display a popup containing
;    3 selections described below.
;  > Cancel Rename - This button closes the Rename Ref Des form and exits the routine.

;  The action of the Popup is as follows:
;  > Reset - Selecting reset closes the tracking form, de-highlights any comps still
;    highlighted, and re-opens the Rename Ref Des form allowing the operator to change
;    the new prefix and starting number so that a new group of components may be renamed.
;  > Oops - Selecting oops will change the previously changed ref des back to it's
;    original value. If no ref des renames have yet been made a "Nothing to Oops"
;    confirmer will be displayed. The Oops routine keeps track of all ref des changes
;    in a session (from Begine Rename to Done, Reset, or Cancel Rename) and may be used
;    to back all changed ref des to their original value. After the first change has
;    been converted back to it's original value pushing the Oops button will display a
;    "Nothing to Oops" confirmer.
;  > Done - Selecting done closes the tracking form, de-highlights any comps still
;    highlighted, and exits the routine.

;  NOTES:
;  > When making a selection select the reference designator not the component.
;  > Because there is no way to rename a component with skill this routine uses an
;    Allegro script to make the actual text change. Therefore if two or more ref des
;    share an X/Y location or overlap, the wrong component may be renamed. It is 
;    suggested that the rename routine not be run until the ref des have been
;    repositioned for readability.

;  To start the routine in Allegro type "rename ref des"
 
;  Written by David J. Scheuring
;  Sr. Applications Eng. Cadence Design Systems
;  June 2, 1995
 
axlCmdRegister( "rename ref des" 'Rename_Ref_Des_Routine ?cmdType "interactive")
 
; Set the global variables
; ########################
unless( boundp('Match_Prefix) Match_Prefix="U") ; This variable represents the prefix to match
unless( boundp('New_Prefix)   New_Prefix="U")   ; This variable represents the prefix to rename to
unless( boundp('Start_Number) Start_Number=1)   ; theis varible represents the first number to use when renaming
; 撤销批次栈：每批元素为 (旧位号 坐标 新位号) 列表，存定位信息不存 dbid
unless( boundp('_RenameRefDes_undoStack) _RenameRefDes_undoStack=nil)

; Define the routine to get things started
; ########################################
defun(Rename_Ref_Des_Routine ()

   ; Set the variables
   ; #################
   Finished=nil; this variable is used to determine when to stop requesting another selection
   Oops_On=nil; this variable is used to determine when an Oops has been pushed
   Oops_List=nil; This list keeps track of the old (pre-rename) ref des
   New_Name_List=nil; This list keeps track of the new (changed) ref des
   X_Y_Loc_List=nil; This list keeps track of the ref des locations so Oops can find them

   ; Run the routine to create the form
   ; ##################################
   Rename_Form_Routine()

   ; Display the form and set the fields
   ; ###################################
   Rename_Ref_Des_Form=axlFormCreate( (gensym) Rename_Form_File '(e inner) 'Rename_Form_Action t)
   axlFormDisplay(Rename_Ref_Des_Form)
   axlFormSetField(Rename_Ref_Des_Form "Match_Prefix_Field" upperCase(Match_Prefix))
   axlFormSetField(Rename_Ref_Des_Form "New_Prefix_Field" upperCase(New_Prefix))
   axlFormSetField(Rename_Ref_Des_Form "Start_Number_Field" Start_Number)
); end defun Rename_Ref_Des_Routine

; Create the Rename Ref Des form
; ##############################
defun(Rename_Form_Routine ()
   Rename_Form_File = strcat(axlTempFile() ".form")
   Rename_Ref_Des_Form=outfile(Rename_Form_File "w")
   fprintf(Rename_Ref_Des_Form "FILE_TYPE=FORM_DEFN VERSION=2\n")
   fprintf(Rename_Ref_Des_Form "FORM\n")
   fprintf(Rename_Ref_Des_Form "FIXED\n")
   fprintf(Rename_Ref_Des_Form "HEADER \"\326\330\303\374\303\373\316\273\272\305\"\n")
   fprintf(Rename_Ref_Des_Form "PORT 25 9\n")
   fprintf(Rename_Ref_Des_Form "TILE\n")
   fprintf(Rename_Ref_Des_Form "TEXT \"\306\245\305\344\307\260\327\272\243\272\"\n")
   fprintf(Rename_Ref_Des_Form "TLOC 1 1\n")
   fprintf(Rename_Ref_Des_Form "ENDTEXT\n")
   fprintf(Rename_Ref_Des_Form "FIELD Match_Prefix_Field\n")
   fprintf(Rename_Ref_Des_Form "FLOC 15 1\n")
   fprintf(Rename_Ref_Des_Form "STRFILLIN 6 30\n")
   fprintf(Rename_Ref_Des_Form "ENDFIELD\n")
   fprintf(Rename_Ref_Des_Form "TEXT \"\320\302  \307\260\327\272\243\272\"\n")
   fprintf(Rename_Ref_Des_Form "TLOC 1 4\n")
   fprintf(Rename_Ref_Des_Form "ENDTEXT\n")
   fprintf(Rename_Ref_Des_Form "FIELD New_Prefix_Field\n")
   fprintf(Rename_Ref_Des_Form "FLOC 15 4\n")
   fprintf(Rename_Ref_Des_Form "STRFILLIN 6 30\n")
   fprintf(Rename_Ref_Des_Form "ENDFIELD\n")
   fprintf(Rename_Ref_Des_Form "TEXT \"\306\360\312\274\261\340\272\305\243\272\"\n")
   fprintf(Rename_Ref_Des_Form "TLOC 1 7\n")
   fprintf(Rename_Ref_Des_Form "ENDTEXT\n")
   fprintf(Rename_Ref_Des_Form "FIELD Start_Number_Field\n")
   fprintf(Rename_Ref_Des_Form "FLOC 15 7\n")
   fprintf(Rename_Ref_Des_Form "INTFILLIN 6 30\n")
   fprintf(Rename_Ref_Des_Form "ENDFIELD\n")
   fprintf(Rename_Ref_Des_Form "FIELD Begin_Rename_Field\n")
   fprintf(Rename_Ref_Des_Form "FLOC 5 10\n")
   fprintf(Rename_Ref_Des_Form "MENUBUTTON \"\277\252\312\274\326\330\303\374\303\373\" 15 3\n")
   fprintf(Rename_Ref_Des_Form "ENDFIELD\n")
   fprintf(Rename_Ref_Des_Form "FIELD Cancel_Field\n")
   fprintf(Rename_Ref_Des_Form "FLOC 5 13\n")
   fprintf(Rename_Ref_Des_Form "MENUBUTTON \"\310\241\317\373\326\330\303\374\303\373\" 15 3\n")
   fprintf(Rename_Ref_Des_Form "ENDFIELD\n")
   fprintf(Rename_Ref_Des_Form "ENDTILE\n")
   fprintf(Rename_Ref_Des_Form "ENDFORM\n")
   close(Rename_Ref_Des_Form)
); end defun Rename_Form_Routine

; Define action of the form buttons in the Rename_Ref_Des_Form
; ############################################################
defun(Rename_Form_Action (Rename_Ref_Des_Form)
  case(Rename_Ref_Des_Form->curField

     ("Match_Prefix_Field"
        Match_Prefix=(Rename_Ref_Des_Form->curValue)
        t
     ); end "Match_Prefix_Field"

     ("New_Prefix_Field"
        New_Prefix=(Rename_Ref_Des_Form->curValue)
        t
     ); end "New_Prefix_Field"

     ("Start_Number_Field"
        Start_Number=(Rename_Ref_Des_Form->curValue)
        t
     ); end "Start_Number_Field"

     ("Begin_Rename_Field"
        Finished=nil

        ; Close the rename form
        ; #####################
        axlFormClose(Rename_Ref_Des_Form)

        ; Start the next number counter and build the new ref des
        ; #######################################################
        Next_Number=Start_Number; This variable is used to increment the ref des number
        New_Name=sprintf(dummy "%s%d" upperCase(New_Prefix) Next_Number); This variable is the new ref des

        ; Build and display the tracking form
        ; ###################################
        Rename_Tracking_Form_Routine()
        Rename_Tracking_Form=axlFormCreate( (gensym) Rename_Tracking_File '(e inner) nil t)
        axlFormDisplay(Rename_Tracking_Form)

        ; Define the pop up
        ; #################
        Rename_Popup=axlUIPopupDefine(nil
            list(
            list("重置" 'Reset_Rename_Prefix_Routine)
            list("回退" 'Rename_Oops_Routine)
            list("完成" 'Rename_Done_Routine)))

        ; Build the List of all placed symbols
        ; ####################################
        axlSetFindFilter(?enabled '(noall symbols) ?onButtons '(noall symbols))
        axlAddSelectAll()
        Symbols=axlGetSelSet()

        ; Parse the list and keep the ref des that match the match prefix
        ; ###############################################################
        Component_List=nil; This variable represents the components that match
        Last_Number=1; This varable represents the total number of components that match
        Pattern=strcat(upperCase(Match_Prefix) "[0-9]+"); This variable represents the match criteria
        foreach(Symbol Symbols
           if(Symbol->refdes && rexMatchp(Pattern Symbol->refdes) then
              Component_List=cons(Symbol Component_List)
              Last_Number=Last_Number+1
           ); end if Symbol->refdes && rexMatchp(Pattern Symbol->refdes)
        ); end foreach Symbol Symbols

        ; Highlight all components that match the Match_Prefix
        ; ####################################################
        axlClearSelSet()
        axlHighlightObject(Component_List)

        ; Run the interactive ref des selection routine
        ; #############################################
        Interactive_Rename_Routine()
        t
     ); end "Begin_Rename_Field"

     ("Cancel_Field"
        axlCancelEnterFun()
        axlFormClose(Rename_Ref_Des_Form)
        when( isFile(Rename_Form_File) errset(deleteFile(Rename_Form_File)))
        t
     ); end "Cancel_Field"
  ); end case Rename_Ref_Des_Form->curField
); end defun Rename_Form_Action

; Define the Interactive_Rename_Routine
; #####################################
defun(Interactive_Rename_Routine ()
   while(Finished == nil; This loop allows the continual selection of ref des

      ; Set the pop up and the tracking form field
      ; ##########################################
      axlUIPopupSet(Rename_Popup)
      axlFormSetField(Rename_Tracking_Form "Next_Number_Field" New_Name)

      ; Select the ref des to rename
      ; ############################
      axlSetFindFilter(?enabled '(noall text) ?onButtons '(noall text))
      axlSingleSelectPoint()
      Text=car(axlGetSelSet()); This variable represent the ref des to be renamed
 
      ; Check if Reset, Done, or Oops were pushed
      ; #########################################
      if(Oops_On == nil then
         if(Finished == nil then

            ; Check if any text was selected
            ; ##############################
            if(Text != nil then

               ; Add to the tally lists
               ; #####################
               Oops_List=cons(Text->text Oops_List)
               New_Name_List=cons(New_Name New_Name_List)
               Next_Number=Next_Number+1
               X_Y_Loc_List=cons(Text->xy X_Y_Loc_List)

               ; Determine where the ref des actually is located
               ; ###############################################
               X_Loc=car(car(X_Y_Loc_List))
               Y_Loc=car(cdr(car(X_Y_Loc_List)))

               ; Dehighlight the selected component, write and replay the script
               ; ###############################################################
               axlDehighlightObject(Text->parent)
               Script_File_Name = strcat(axlTempFile() ".scr")
               Script_File=outfile(Script_File_Name "w")
               fprintf(Script_File "setwindow pcb\ntext edit\n")
               fprintf(Script_File "pick %f %f\ntext %s\n" X_Loc Y_Loc New_Name)
               fprintf(Script_File "done\n")
               close(Script_File)
               axlShell(strcat("replay " Script_File_Name))
               when( isFile(Script_File_Name) errset(deleteFile(Script_File_Name)))
 
               ; Check if you got them all
               ; #########################
               if((Next_Number-Start_Number)+1 == Last_Number then
                  Reset_Rename_Prefix_Routine()
               ); end if (Next_Number-Start_Number)+1 == Last_Number

               ; Increment the new ref des and update the tracking form
               ; ######################################################
               New_Name=sprintf(dummy "%s%d" upperCase(New_Prefix) Next_Number)
               axlFormSetField(Rename_Tracking_Form "Next_Number_Field" New_Name)

            ); end if Text != nil

         else; if Finished == nil
            axlUIPopupSet(nil)

         ); end if Finished == nil

      else; if Oops_On == nil

         ; Check if there is anything to Oops
         ; ##################################
         if(Oops_List==nil then
            axlUIConfirm("没有可回退的位号")
            Finished=nil
            Oops_On=nil

         else; if Oops_List==nil

            ; Get the component at the top of Oops list
            ; #########################################
            axlClearSelSet()
            axlCancelEnterFun()
            axlSetFindFilter(?enabled '(noall symbols) ?onButtons '(noall symbols))
            axlSingleSelectName("SYMBOL" car(New_Name_List))
            Oppsed_Component=car(axlGetSelSet())
            axlClearSelSet()

            ; If it is a matching prefix component re-highlight it
            ; ####################################################
            if(car(Oops_List)&& rexMatchp(Pattern car(Oops_List)) then
               axlHighlightObject(Oppsed_Component)
            ); end if car(Oops_List)&& rexMatchp(Pattern car(Oops_List))

            ; Determine where the Oops'd ref des was actually located
            ; #######################################################
            X_Loc=car(car(X_Y_Loc_List)) 
            Y_Loc=car(cdr(car(X_Y_Loc_List)))

            ; Write and replay the rename script
            ; ##################################
            Script_File_Name = strcat(axlTempFile() ".scr")
            Script_File=outfile(Script_File_Name "w")
            fprintf(Script_File "setwindow pcb\ntext edit\n")
            fprintf(Script_File "pick %f %f\ntext %s\n" X_Loc Y_Loc car(Oops_List))
            fprintf(Script_File "done\n")
            close(Script_File)
            axlShell(strcat("replay " Script_File_Name))
            when( isFile(Script_File_Name) errset(deleteFile(Script_File_Name)))

            ; Update the tally lists
            ; ######################
            Oops_List=cdr(Oops_List)
            X_Y_Loc_List=cdr(X_Y_Loc_List)
            New_Name=car(New_Name_List)
            Next_Number=Next_Number-1
            New_Name_List=cdr(New_Name_List)

            ; Reset the Oops_on and Finished variables
            ; ########################################
            Oops_On=nil
            Finished=nil

         ); end if Oops_List == nil
      ); end if Oops_On==nil
   ); end while Finished=nil
);end Interactive_Rename_Routine

; Define the rename tracking form
; ###############################
defun(Rename_Tracking_Form_Routine ()
   Rename_Tracking_File = strcat(axlTempFile() ".form")
   Rename_Tracking_Form=outfile(Rename_Tracking_File "w")
   fprintf(Rename_Tracking_Form "FILE_TYPE=FORM_DEFN VERSION=2\n")
   fprintf(Rename_Tracking_Form "FORM\n")
   fprintf(Rename_Tracking_Form "FIXED\n")
   fprintf(Rename_Tracking_Form "HEADER \"\326\330\303\374\303\373\270\372\327\331\"\n")
   fprintf(Rename_Tracking_Form "PORT 17 3\n")
   fprintf(Rename_Tracking_Form "TILE\n")
   fprintf(Rename_Tracking_Form "TEXT \"\317\302\322\273\270\366\261\340\272\305\"\n")
   fprintf(Rename_Tracking_Form "TLOC 3 1\n")
   fprintf(Rename_Tracking_Form "ENDTEXT\n")
   fprintf(Rename_Tracking_Form "FIELD Next_Number_Field\n")
   fprintf(Rename_Tracking_Form "FLOC 1 3\n")
   fprintf(Rename_Tracking_Form "STRFILLIN 12 30\n")
   fprintf(Rename_Tracking_Form "ENDFIELD\n")
   fprintf(Rename_Tracking_Form "ENDTILE\n")
   fprintf(Rename_Tracking_Form "ENDFORM\n")
   close(Rename_Tracking_Form)
); end defun Rename_Tracking_Form
 
; Define "Reset" for the popup
; ############################
defun(Reset_Rename_Prefix_Routine ()

   ; Stop the select function
   ; ########################
   Finished=t
   axlClearSelSet()
   axlCancelEnterFun()

   ; De-highlight any components still highlighted
   ; #############################################
   axlSetFindFilter(?enabled '(noall symbols) ?onButtons '(noall symbols))
   axlAddSelectName("SYMBOL" sprintf(dummy "%s*" Match_Prefix))
   Component_List=axlGetSelSet()
   axlClearSelSet()
   axlDehighlightObject(Component_List)

   ; 本批改名入撤销栈（必须在清空计数列表之前；Reset 后已改的位号仍留在数据库）
   ; ##########################################################################
   Rename_RefDes_PushUndoBatch()

   ; Update the tally lists
   ; ######################
   Oops_List=nil
   New_Name_List=nil
   X_Y_Loc_List=nil
   Start_Number=Next_Number

   ; Close the tracking form
   ; #######################
   axlFormClose(Rename_Tracking_Form)
   when( isFile(Rename_Tracking_File) errset(deleteFile(Rename_Tracking_File)))
   Form=axlFormCreate( (gensym) Rename_Form_File '(e inner) 'Rename_Form_Action t)

   ; Display the rename form and set the fields
   ; ##########################################
   axlFormDisplay(Form)
   axlFormSetField(Form "Match_Prefix_Field" upperCase(Match_Prefix))
   axlFormSetField(Form "New_Prefix_Field" upperCase(New_Prefix))
   axlFormSetField(Form "Start_Number_Field" Start_Number)
   axlShell("redisplay")
); defun end Reset_Rename_Prefix_Routine

; Define "Oops" for the popup
; ###########################
defun(Rename_Oops_Routine ()

   ; Stop the select function
   ; ########################
   axlCancelEnterFun()
   Finished=t

   ; Let the rename routine know you want to Oops
   ; ############################################
   Oops_On=t
); end defun Rename_Oops_Routine

; Define "Done" for the popup
; ###########################
defun(Rename_Done_Routine ()

   ; Stop the select function   
   ; ########################
   Finished=t
   axlCancelEnterFun()

   ; De-highlight any components still highlighted
   ; #############################################
   axlClearSelSet()
   axlSetFindFilter(?enabled '(noall symbols) ?onButtons '(noall symbols))
   axlAddSelectName("SYMBOL" sprintf(dummy "%s*" Match_Prefix))
   Component_List=axlGetSelSet()
   axlClearSelSet()
   axlDehighlightObject(Component_List)

   ; 本批改名入撤销栈（必须在清空计数列表之前），记录是否有改名供后面提示
   ; ##########################################################################
   Batch_Pushed=Rename_RefDes_PushUndoBatch()

   ; Update the tally lists
   ; ######################
   Oops_List=nil
   New_Name_List=nil
   X_Y_Loc_List=nil

   ; Close the tracking form
   ; #######################
   axlFormClose(Rename_Tracking_Form)
   when( isFile(Rename_Tracking_File) errset(deleteFile(Rename_Tracking_File)))
   when( isFile(Rename_Form_File) errset(deleteFile(Rename_Form_File)))
   axlShell("redisplay")

   ; 完成提示：有改名时告知撤销命令
   ; ###############################
   if( Batch_Pushed then
      axlUIWPrint(nil "完成。输入 astbundo 可撤销本次修改")
   else
      axlUIWPrint(nil "完成。本次没有修改")
   )
); end defun Rename_Done_Routine

; 将当前计数列表中的本批改名压入撤销栈
; #####################################
; 每条记录为 (旧位号 坐标 新位号)——只存定位信息，绝不存 dbid
; （dbid 跨命令失效成 dbid:removed）。计数列表表头是最新改名，
; 遍历 cons 后 batch 为时间正序（最旧在表头）直接入栈；
; 撤销时 reverse 回"最新优先"逐条处理。
; 返回本批条目数；无改名时返回 nil。
defun(Rename_RefDes_PushUndoBatch ()
   prog( (batch ol nl xl)
      unless( boundp('_RenameRefDes_undoStack) _RenameRefDes_undoStack=nil)
      batch=nil
      ol=Oops_List
      nl=New_Name_List
      xl=X_Y_Loc_List
      while( and(ol nl xl)
         batch=cons(list(car(ol) car(xl) car(nl)) batch)
         ol=cdr(ol)
         nl=cdr(nl)
         xl=cdr(xl)
      )
      when( batch
         _RenameRefDes_undoStack=cons(batch _RenameRefDes_undoStack)
         ASTB_UndoJournalPush("text_renamerefdes")
         return(length(batch))
      )
      return(nil)
   )
); end defun Rename_RefDes_PushUndoBatch

; Define the undo command "rename ref desu"
; #########################################
; 撤销最近一次 Done/Reset 提交的那一批改名：批内按"最新改名优先"
; 逐条处理。每条记录（旧位号 坐标 新位号），先按坐标点选 TEXT
; 现场找回新鲜 dbid 并核对当前文本确为新位号（防用户事后手改被误回退），
; 再脚本回放（text edit + pick 坐标）改回旧位号——与改名同机制。
defun(Rename_RefDes_Undo ()
   prog( (batch item Old_Name X_Y_Loc New_Name X_Loc Y_Loc Found Text
          n m Script_File_Name Script_File)
      unless( boundp('_RenameRefDes_undoStack) _RenameRefDes_undoStack=nil)
      unless( _RenameRefDes_undoStack
         axlUIWPrint(nil "没有可撤销的记录")
         return(nil)
      )
      batch=car(_RenameRefDes_undoStack)
      _RenameRefDes_undoStack=cdr(_RenameRefDes_undoStack)
      n=0
      m=0
      foreach( item reverse(batch)
         Old_Name=car(item)
         X_Y_Loc=cadr(item)
         New_Name=caddr(item)
         X_Loc=car(X_Y_Loc)
         Y_Loc=cadr(X_Y_Loc)

         ; 按坐标现场找回当前位号文本（新鲜 dbid，不依赖存储 dbid）
         ; ##########################################################
         axlClearSelSet()
         axlSetFindFilter(?enabled '(noall text) ?onButtons '(noall text))
         Found=nil
         when( axlSingleSelectPoint(X_Y_Loc)
            foreach( Text axlGetSelSet()
               when( and(null(Found) equal(Text->text New_Name))
                  Found=Text
               )
            )
         )
         axlClearSelSet()

         if( Found then

            ; Write and replay the rename script (same mechanism as rename)
            ; #############################################################
            Script_File_Name = strcat(axlTempFile() ".scr")
            Script_File=outfile(Script_File_Name "w")
            fprintf(Script_File "setwindow pcb\ntext edit\n")
            fprintf(Script_File "pick %f %f\ntext %s\n" X_Loc Y_Loc Old_Name)
            fprintf(Script_File "done\n")
            close(Script_File)
            axlShell(strcat("replay " Script_File_Name))
            when( isFile(Script_File_Name) errset(deleteFile(Script_File_Name)))
            n=n+1

         else
            m=m+1
            axlUIWPrint(nil "  警告： (%f %f) 处未找到位号 %s，已跳过"
               X_Loc Y_Loc New_Name)
         )
      )
      axlShell("redisplay")
      axlUIWPrint(nil "撤销完成： 恢复 %d 个位号， 失败 %d 个" n m)
      return(t)
   )
); end defun Rename_RefDes_Undo

; 撤销命令与主命令同样用裸 axlCmdRegister 注册（本模块不走 ASTB_RegisterCommand；
; 不要加 ?undo 参数，16.6 不认）
axlCmdRegister( "rename ref desu" 'Rename_RefDes_Undo ?cmdType "interactive")

; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("text_renamerefdes" 'Rename_RefDes_Undo)
