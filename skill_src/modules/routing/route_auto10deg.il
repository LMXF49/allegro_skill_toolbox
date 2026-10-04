;   2026-08-20 v1.7 ASTB Team 撤销命令注册补 ?undo nil（防系统撤销把
;                   撤销命令本身入栈，17.4+）
;========================================================================
; 文件名    : route_auto10deg.il
; 作者      : Allegro SKILL Toolbox
; 创建日期  : 2026-07-16
; 版本      : 1.7
; 功能描述  : 自动10度走线，对选中的cline进行10度蛇形走线
; 依赖模块  : core/menu.il, core/utils.il
; 修改记录  :
;   2026-07-16 v1.0 Allegro SKILL Toolbox 初始创建
;   2026-07-17 v1.1 增加 ASTB_DBTransactionMark 事务保护
;   2026-07-17 v1.2 Allegro SKILL Toolbox 整改：
;                   1) length 改名 len 并补 let 绑定（修复覆盖内置 length 函数
;                      导致第二次框选必崩的 Lisp-1 问题）
;                   2) 主过程约 60 个隐式全局变量全部纳入 let 绑定
;                   3) axlUIPrompt 输入判空判零（取消/非正数不再崩溃或除零）
;                   4) 12 处 axlDBCreatePath 显式挂接原线段网络并检查返回值
;                   5) 收集线段信息时逐轮重置 ylist 并记录各线段网络名
;   2026-08-20 v1.3 ASTB Team 右键菜单项规范：MyDone/MyUndo/MyCancel
;                   改名 Done/Undo/Cancel 且 Done 置顶（用户约定）
;   2026-08-20 v1.4 ASTB Team 新增撤销命令 ASTB_Route_Auto10degu：
;                   每次框选处理记为一批压入 _ASTB_A10_undoStack，记录
;                   (层+原线段起终点+线宽+网络+新线bBox)，绝不存 dbid
;                   （跨命令失效）；撤销时按起点现场查找蛇形新线删除，
;                   再按记录重建原直线段（rviau 实证模式）
;   2026-08-20 v1.5 ASTB Team 接入统一撤销中枢 astbundo（core/trans.il
;                   v1.4）：ASTB_RegisterUndo 注册 ASTB_Route_Auto10deg_Undo，
;                   批次入栈同步 ASTB_UndoJournalPush；Done 提示改指
;                   astbundo（ASTB_Route_Auto10degu 保留为别名）
;   2026-08-20 v1.6 ASTB Team 撤销重建后 axlChangeWidth 显式压回记录
;                   原宽（挂网络建线约束管理器会覆盖宽度入参）
;========================================================================


/*
################################################################################
#                                                                              #
#                      Command: tune                                           #
#                   Skill File: tune.il                                        #
#                  How To Load: Command> (load("tune.il"))                     #
#               How To Execute: Command> tune                                  #
#                                                                         #
#                                                                          #
################################################################################
*/
;###############################################################
;#           DISCLAIMER:      routing 10 degree cline for user.#
;#                                                      #  
;#                                                               #
;###############################################################


;------------------------------------------------------------------------
; 弹窗回调：顶层定义一次，避免每次调用重复 defun 覆盖全局函数
;------------------------------------------------------------------------
procedure( _ASTB_A10_MyCancel()
    axlClearDynamics()
    axlCancelEnterFun()
    axlUIPopupSet(nil)
)

procedure( _ASTB_A10_MyDone()
    axlClearDynamics()
    axlFinishEnterFun()
    axlUIPopupSet(nil)
)

;------------------------------------------------------------------------
; 撤销批次栈（v1.4）：_ASTB_A10_undoStack 为批次栈，每次框选处理完
; 成一批入栈；批内记录 = (层 原x1 原y1 原x2 原y2 线宽 网络名 新线bBox)。
; 只存定位数据，绝不存 dbid——跨命令失效成 dbid:removed
; （rviau 实证模式，pitfalls 2.6 扩展）；_ASTB_A10_curBatch 为当前
; 框选批次的记录累积；_ASTB_A10_isHoriz 标记本批走线方向
;------------------------------------------------------------------------
unless( boundp('_ASTB_A10_undoStack) _ASTB_A10_undoStack = nil )
unless( boundp('_ASTB_A10_curBatch)  _ASTB_A10_curBatch  = nil )
unless( boundp('_ASTB_A10_isHoriz)   _ASTB_A10_isHoriz   = t )

;------------------------------------------------------------------------
; 函数名  : _ASTB_A10_CreatePath
; 功能    : 创建走线路径并显式挂接原线段网络，检查返回值；
;           同时把本段原始走线的定位信息记入 _ASTB_A10_curBatch
;           （v1.4 撤销记录；建线成功时顺带取新线 bBox 存为定位数据，
;           bBox 为普通坐标数据可跨命令，dbid 本身不存）
; 参数    : path  - axlPath 路径；layer - 目标层
;           rout  - 线段信息表 (坐标 坐标 坐标 width netName)，网络名为 nth(4)
; 返回值  : axlDBCreatePath 返回值；失败时打印告警
;------------------------------------------------------------------------
procedure( _ASTB_A10_CreatePath(path layer rout)
    let( (cret mnet bb x1 y1 x2 y2)
        mnet = nth(4 rout)
        cret = axlDBCreatePath(path layer mnet)
        if( car(cret) then
            bb = errset( car(cret)->bBox nil )
            bb = and(bb car(bb))
        else
            bb = nil
            axlUIWPrint(nil "** Error. Failed to create path on layer %s. **" layer)
        )
        ; 原线段坐标：水平批 rout=(y xleft xright width net)，
        ; 垂直批 rout=(x yup ydown width net)，由 _ASTB_A10_isHoriz 区分
        if( _ASTB_A10_isHoriz then
            x1 = nth(1 rout)  y1 = nth(0 rout)
            x2 = nth(2 rout)  y2 = nth(0 rout)
        else
            x1 = nth(0 rout)  y1 = nth(1 rout)
            x2 = nth(0 rout)  y2 = nth(2 rout)
        )
        _ASTB_A10_curBatch = cons(list(layer x1 y1 x2 y2 nth(3 rout) mnet bb)
            _ASTB_A10_curBatch)
        cret
    )
)

procedure( ASTB_Route_Auto10deg();set main function
    prog( (mypopup design len design_dbid1 layer startEnd1 a b xa ya xb yb
          xminmax xmaxmin yminup ymaxdown lineType ylist allylist l mei_db staEnd
          width ma mb mxa mxb mxleft mxright my mnet paixudy d add_str add_x m firstx
          rout qishiy qishix zhongx xcank x0 wy1 wy2 path k wx1 wx2 lasty1 lasty2 xlast
          q chushiy chushix spac xmm dty mya myb myup mydown mx firsty ycank y0 zhongy
          ymm dtx lastx1 lastx2 ylast)
        unless( axlOKToProceed()
            axlUIConfirm("当前环境不允许执行该操作")
            return(nil)
        )
mypopup = axlUIPopupDefine( nil (list (list "Done" '_ASTB_A10_MyDone)
                                      (list "Undo" 'ASTB_SystemUndo)
                                      (list "Cancel" '_ASTB_A10_MyCancel)))
            axlUIPopupSet( mypopup)

         axlSetFindFilter(?enabled list( "noall" "clinesegs") ?onButtons list("noall" "clinesegs"))
               axlClearSelSet(); set done and cancle cammand
               _ASTB_A10_curBatch = nil; v1.4 撤销：命令开始清空当前批次累积

    while(axlSingleSelectBox()
         design=axlGetSelSet()
         len=length(design)
         ;design_dbid1=car(axlGetSelSet())
         design_dbid1=nth(0 design)
         layer=design_dbid1->layer
         startEnd1=design_dbid1->startEnd
         a=nth(0 startEnd1)
         b=nth(1 startEnd1)
         xa=nth(0 a)
         ya=nth(1 a)
         xb=nth(0 b)
         yb=nth(1 b)
         xminmax=min(xa xb);left
             xmaxmin=max(xa xb);right
         yminup=max(ya yb);up
         ymaxdown=min(ya yb);down

        lineType=design_dbid1->lineType
            ; get need to route cline
        case(lineType

                 ;;the below is cline is horrizontal
            (horizontal 
            ylist='()
            allylist='() 
        for(l 1 len
                  mei_db=nth(l-1 design)
              staEnd=mei_db->startEnd
                  width=mei_db->width
            ma=nth(0 staEnd)
            mb=nth(1 staEnd)
            mxa=nth(0 ma)
            mxb=nth(0 mb)
            mxleft=min(mxa mxb)
            mxright=max(mxa mxb)
            xminmax=max(mxleft  xminmax)
            xmaxmin=min(mxright xmaxmin)
            my=nth(1 ma)
            mnet=mei_db->net->name
            ylist='()
            ylist=cons(mnet ylist)
            ylist=cons(width ylist)
            ylist=cons(mxright ylist)
            ylist=cons(mxleft ylist)
            ylist=cons(my ylist)
            allylist=cons(ylist allylist)
        );end for 
            ;get all need to route 10 degree information
            paixudy=sortcar(allylist 'greaterp)
            
            d=abs(xmaxmin-xminmax)-50
            
            
            add_str=axlUIPrompt("please enter addx_distance" "125")
            if( null(add_str) then
                axlUIWPrint(nil "-- Cancelled. --")
                axlUIPopupSet(nil)
                return(nil)
            )
            add_x=atof(add_str)
            when( add_x<=0
                axlUIConfirm("addx_distance 必须为正数，本次按默认值 125 处理")
                add_x=125.0
            )
            
            m=(floor d/(2*add_x)) ;route how much cycle
            

            firstx=nth(1 nth(0 paixudy));get max y coodrinate clines x information 

            _ASTB_A10_isHoriz = t; v1.4 撤销：本批为水平走线
            axlDeleteObject(design)

    if(firstx==xminmax
            then


                rout=nth(0 paixudy)
                qishiy=nth(0 rout)
                qishix=nth(1 rout)
                zhongx=nth(2 rout)
                width=nth(3 rout)
                xcank=xminmax+20
                x0=xcank
                     wy1=qishiy-(add_x /5)
                     wy2=qishiy
                    path=axlPathStart(list(qishix:qishiy) width)
                    ;axlDBCreateLine(list(qishix:qishiy x0:qishiy) width layer)
                    axlPathLine( path, width, x0:qishiy)

                     for(k 1 m
                      wx1=x0+add_x
                     wx2=wx1+add_x
                        ; path=axlPathStart(list(x0:qishiy) width)
                        ;axlDBCreateLine(list(x0:qishiy wx1:wy1) width layer)
                       ; axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
                     axlPathLine( path, width, wx1:wy1)
                    axlPathLine( path, width, wx2:wy2)

                x0=wx2
                );for
                          ; path=axlPathStart(list(wx2:wy2) width)
                        ;axlDBCreateLine(list(wx2:wy2 zhongx:wy2) width layer)
                    axlPathLine( path, width, zhongx:wy2)
                _ASTB_A10_CreatePath(path layer rout)

                lasty1=wy1
                lasty2=wy2
                    ;x0=xminmax+5
                xlast=wx2
         

        for(q 1 len-1
           if((m==1) then
                
            rout=nth(q paixudy)
            chushiy=nth(0 rout)
            chushix=nth(1 rout)
            zhongx=nth(2 rout)
            width=nth(3 rout)
            spac=abs(qishiy-chushiy)
            xcank=xcank-(sqrt(26)-5)*spac-0.01
            x0=xcank
            xmm=xminmax+20
            wx1=xmm+add_x
             wx2=wx1+add_x
            dty=sqrt(26)*spac/5+0.002
            wy1=lasty1-dty
             wy2=lasty2-dty
            path=axlPathStart(list(chushix:chushiy) width)
            axlPathLine( path, width, x0:chushiy)  
              axlPathLine( path, width, wx1:wy1)
            axlPathLine( path, width, (xlast+(sqrt(26)-5)*spac+0.01):chushiy)
            axlPathLine( path, width, zhongx:chushiy)
            _ASTB_A10_CreatePath(path layer rout)
            qishiy=chushiy
            lasty1=wy1
            lasty2=wy2
            xlast=wx2
        else

            rout=nth(q paixudy)
            chushiy=nth(0 rout)
            chushix=nth(1 rout)
            zhongx=nth(2 rout)
            width=nth(3 rout)
            spac=abs(qishiy-chushiy)
            xcank=xcank-(sqrt(26)-5)*spac-0.01
            x0=xcank
            xmm=xminmax+20
                 ;x0=xminmax+5
             wx1=xmm+add_x
             wx2=wx1+add_x

            dty=sqrt(26)*spac/5+0.002
             wy1=lasty1-dty
             wy2=lasty2-dty
                path=axlPathStart(list(chushix:chushiy) width)
                    ;axlDBCreateLine(list(chushix:chushiy x0:chushiy) width layer)
                    ;axlDBCreateLine(list(x0:chushiy wx1:wy1) width layer)
                    ;axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
                axlPathLine( path, width, x0:chushiy)  
                 axlPathLine( path, width, wx1:wy1)
                 axlPathLine( path, width, wx2:wy2)

            x0=wx2
                for(k 1 m-2

                 wx1=x0+add_x
                 wx2=wx1+add_x

                    ;path=axlPathStart(list(x0:wy2) width)
                    ;axlDBCreateLine(list(x0:wy2 wx1:wy1) width layer)
                    ;axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
                axlPathLine( path, width, wx1:wy1)
                axlPathLine( path, width, wx2:wy2)

            x0=wx2
            );for
                 wx1=x0+add_x
                 wx2=xlast+(sqrt(26)-5)*spac+0.01
                     ;path=axlPathStart(list(x0: wy2) width)
                    ;axlDBCreateLine(list(x0:wy2 wx1:wy1) width layer)
                    ;axlDBCreateLine(list(wx1:wy1 wx2:chushiy) width layer)
                    ;axlDBCreateLine(list(wx2:chushiy zhongx:chushiy) width layer)
                axlPathLine( path, width, wx1:wy1)  
                 axlPathLine( path, width, wx2:chushiy)
                axlPathLine( path, width, zhongx:chushiy)
             _ASTB_A10_CreatePath(path layer rout)


            qishiy=chushiy
            lasty1=wy1
            lasty2=wy2
            xlast=wx2
            );if
              );for
        
        else

            

            paixudy=reverse(paixudy)
            rout=nth(0 paixudy)
            qishiy=nth(0 rout)
            qishix=nth(1 rout)
            zhongx=nth(2 rout)
            width=nth(3 rout)
            xcank=xminmax+20
            x0=xcank
                 wy1=qishiy+(add_x /5)
                 wy2=qishiy
                path=axlPathStart(list(qishix:qishiy) width)
                   ; axlDBCreateLine(list(qishix:qishiy x0:qishiy) width layer)
                axlPathLine( path, width, x0:qishiy)
             for(k 1 m
                 wx1=x0+add_x
                 wx2=wx1+add_x
                    ; path=axlPathStart(list(x0:qishiy) width)
                    ;axlDBCreateLine(list(x0:qishiy wx1:wy1) width layer)
                    ;axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
                axlPathLine( path, width, wx1:wy1)
                axlPathLine( path, width, wx2:wy2)


            x0=wx2
            );for
                    ;path=axlPathStart(list(wx2:wy2) width)
                    ; axlDBCreateLine(list(wx2:wy2 zhongx:wy2) width layer)
                    axlPathLine( path, width, zhongx:wy2)
                 _ASTB_A10_CreatePath(path layer rout)
            lasty1=wy1
            lasty2=wy2
            ;x0=xminmax+5
            xlast=wx2


        for(q 1 len-1
          if((m==1) then
                
            rout=nth(q paixudy)
            chushiy=nth(0 rout)
            chushix=nth(1 rout)
            zhongx=nth(2 rout)
            width=nth(3 rout)
            spac=abs(qishiy-chushiy)
            xcank=xcank-(sqrt(26)-5)*spac-0.01
            x0=xcank
            xmm=xminmax+20
            wx1=xmm+add_x
             wx2=wx1+add_x
            dty=sqrt(26)*spac/5+0.002
            wy1=lasty1+dty
             wy2=lasty2+dty
            path=axlPathStart(list(chushix:chushiy) width)
            axlPathLine( path, width, x0:chushiy)  
              axlPathLine( path, width, wx1:wy1)
            axlPathLine( path, width, (xlast+(sqrt(26)-5)*spac+0.01):chushiy)
            axlPathLine( path, width, zhongx:chushiy)
            _ASTB_A10_CreatePath(path layer rout)
            qishiy=chushiy
            lasty1=wy1
            lasty2=wy2
            xlast=wx2
        else


            
                
                rout=nth(q paixudy)
                chushiy=nth(0 rout)
                chushix=nth(1 rout)
                zhongx=nth(2 rout)
                width=nth(3 rout)
                spac=abs(qishiy-chushiy)
                xcank=xcank-(sqrt(26)-5)*spac-0.01
                x0=xcank
                xmm=xminmax+20
                 ;x0=xminmax+5
                 wx1=xmm+add_x
                 wx2=wx1+add_x

                dty=sqrt( 26)*spac/5+0.002
                     wy1=lasty1+dty
                     wy2=lasty2+dty
                    path=axlPathStart(list(chushix:chushiy) width)
                    ;axlDBCreateLine(list(chushix:chushiy x0:chushiy) width layer)
                    ;axlDBCreateLine(list(x0:chushiy wx1:wy1) width layer)
                    ;axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
                    axlPathLine( path, width, x0:chushiy)
                    axlPathLine( path, width, wx1:wy1)
                    axlPathLine( path, width, wx2:wy2)




                x0=wx2
                for(k 1 m-2

                         wx1=x0+add_x
                         wx2=wx1+add_x

                           ; path=axlPathStart(list(x0:wy2) width)
                            ;axlDBCreateLine(list(x0:wy2 wx1:wy1) width layer)
                            ;axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
                        axlPathLine( path, width, wx1:wy1)
                        axlPathLine( path, width, wx2:wy2)

                    x0=wx2
                );for
                     wx1=x0+add_x
                     wx2=xlast+(sqrt(26)-5)*spac+0.01
                    ;path=axlPathStart(list(x0: wy2) width)
                    ;axlDBCreateLine(list(x0:wy2 wx1:wy1) width layer)
                    ;axlDBCreateLine(list(wx1:wy1 wx2:chushiy) width layer)
                    ;axlDBCreateLine(list(wx2:chushiy zhongx:chushiy) width layer)
                    axlPathLine( path, width, wx1:wy1)
                    axlPathLine( path, width, wx2:chushiy)
                    axlPathLine( path, width, zhongx:chushiy)
                _ASTB_A10_CreatePath(path layer rout)

            qishiy=chushiy
            lasty1=wy1
            lasty2=wy2
            xlast=wx2
            );if
            );for lengthe-1


            );if first==xminmax



);horizontal 








             (vertical


            ylist='()
            allylist='() 
        for(l 1 len
                  mei_db=nth(l-1 design)
            staEnd=mei_db->startEnd
              width=mei_db->width
          ma=nth(0 staEnd)
          mb=nth(1 staEnd)
          mya=nth(1 ma)
            myb=nth(1 mb)
            myup=max(mya myb)
            mydown=min(mya myb)
            yminup=min(myup  yminup);qu up min
            ymaxdown=max(mydown ymaxdown);qu down max
            mx=nth(0 ma)
            mnet=mei_db->net->name
            ylist='()
            ylist=cons(mnet ylist)
            ylist=cons(width ylist)
            ylist=cons(mydown ylist)
            ylist=cons(myup ylist)
            ylist=cons(mx ylist)
            allylist=cons(ylist allylist)
            );for
        paixudy=sortcar(allylist 'greaterp)
        d=abs(yminup-ymaxdown)-50
        ;mm=(floor d/add_x)
        ;m=(floor mm/2)
        add_str=axlUIPrompt("please enter addx_distance" "125")
        if( null(add_str) then
            axlUIWPrint(nil "-- Cancelled. --")
            axlUIPopupSet(nil)
            return(nil)
        )
        add_x=atof(add_str)
        when( add_x<=0
            axlUIConfirm("addx_distance 必须为正数，本次按默认值 125 处理")
            add_x=125.0
        )
        m=(floor d/(2*add_x))

        firsty=nth(1 nth(0 paixudy))

        _ASTB_A10_isHoriz = nil; v1.4 撤销：本批为垂直走线
        axlDeleteObject(design)

        if((firsty==yminup)
        then

            rout=nth(0 paixudy)
            qishix=nth(0 rout)
            qishiy=nth(1 rout)
            zhongy=nth(2 rout)
            width=nth(3 rout)
            ycank=yminup-10
            y0=ycank
                 wx1=qishix-(add_x /5)
                 wx2=qishix
                path=axlPathStart(list(qishix:qishiy) width)
                
                axlPathLine( path, width, qishix:y0)
     for(k 1 m
         wy1=y0-add_x
         wy2=wy1-add_x
             
            axlPathLine( path, width, wx1:wy1)
            axlPathLine( path, width, wx2:wy2)

        y0=wy2
    );for
           
            axlPathLine( path, width, wx2:zhongy)
        _ASTB_A10_CreatePath(path layer rout)

        lastx1=wx1
        lastx2=wx2
        
        ylast=wy2


        for(q 1 len-1
            if((m==1) then
                rout=nth(q paixudy)
                chushix=nth(0 rout)
                chushiy=nth(1 rout)
                zhongy=nth(2 rout)
                width=nth(3 rout)
                spac=abs(qishix-chushix)
                ycank=ycank+(sqrt(26)-5)*spac+0.01
                y0=ycank
                ymm=yminup-10
                 wy1=ymm-add_x
                 wy2=wy1-add_x
                 dtx=sqrt(26)*spac/5+0.002
                wx1=lastx1-dtx
                 wx2=lastx2-dtx
                path=axlPathStart(list(chushix:chushiy) width)
                axlPathLine( path, width, chushix:y0)
                axlPathLine( path, width, wx1:wy1)
                axlPathLine( path, width, chushix:(ylast-(sqrt(26)-5)*spac-0.01))
                axlPathLine( path, width, chushix:zhongy)
                _ASTB_A10_CreatePath(path layer rout)
                qishix=chushix
                lastx1=wx1
                lastx2=wx2
                ylast=wy2

                    
        else    

            rout=nth(q paixudy)
            chushix=nth(0 rout)
            chushiy=nth(1 rout)
            zhongy=nth(2 rout)
            width=nth(3 rout)
            spac=abs(qishix-chushix)
            ycank=ycank+(sqrt(26)-5)*spac+0.01
            y0=ycank
            ymm=yminup-10
             ;x0=xminmax+5
             wy1=ymm-add_x
             wy2=wy1-add_x

        dtx=sqrt(26)*spac/5+0.002
             wx1=lastx1-dtx
             wx2=lastx2-dtx
                path=axlPathStart(list(chushix:chushiy) width)
                    
                axlPathLine( path, width, chushix:y0)  
                axlPathLine( path, width, wx1:wy1)
                axlPathLine( path, width, wx2:wy2)
            
            

            y0=wy2
            for(k 1 m-2

                 wy1=y0-add_x
                 wy2=wy1-add_x

               ; path=axlPathStart(list(wx2:y0) width)
               ;axlDBCreateLine(list(wx2:y0 wx1:wy1) width layer)
                ;axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
                axlPathLine( path, width, wx1:wy1)
                axlPathLine( path, width, wx2:wy2)


            y0=wy2
        );for
                 wy1=y0-add_x
                 wy2=ylast-(sqrt(26)-5)*spac-0.01
                ; path=axlPathStart(list(wx2:y0) width)
                ;axlDBCreateLine(list(wx2:y0 wx1:wy1) width layer)
               ; axlDBCreateLine(list(wx1:wy1 chushix:wy2) width layer)
                ;axlDBCreateLine(list(chushix:wy2 chushix:zhongy) width layer)
                 axlPathLine( path, width, wx1:wy1)  
                axlPathLine( path, width, chushix:wy2)
                 axlPathLine( path, width, chushix:zhongy)
             _ASTB_A10_CreatePath(path layer rout)


            qishix=chushix
            lastx1=wx1
            lastx2=wx2
            ylast=wy2
            );if
        );for length-1
            
    else


        paixudy=reverse(paixudy)
        rout=nth(0 paixudy)
        qishix=nth(0 rout)
        qishiy=nth(1 rout)
        zhongy=nth(2 rout)
        width=nth(3 rout)
        ycank=yminup-10
        y0=ycank
             wx1=qishix+(add_x /5)
             wx2=qishix
            path=axlPathStart(list(qishix:qishiy) width)
            ;axlDBCreateLine(list(qishix:qishiy qishix:y0) width layer)
            axlPathLine( path, width, qishix:y0)
         for(k 1 m
             wy1=y0-add_x
             wy2=wy1-add_x
            ; path=axlPathStart(list(qishix:y0) width)
            ;axlDBCreateLine(list(qishix:y0 wx1:wy1) width layer)
            ;axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
            axlPathLine( path, width, wx1:wy1)
            axlPathLine( path, width, wx2:wy2)
        y0=wy2
        );for
            ;path=axlPathStart(list(wx2:wy2) width)
            ;axlDBCreateLine(list(wx2:wy2 wx2:zhongy) width layer)
            axlPathLine( path, width, wx2:zhongy)
        _ASTB_A10_CreatePath(path layer rout)

        lastx1=wx1
        lastx2=wx2
        ;x0=xminmax+5
        ylast=wy2


        for(q 1 len-1
            if((m==1) then
                      rout=nth(q paixudy)
                chushix=nth(0 rout)
                chushiy=nth(1 rout)
                zhongy=nth(2 rout)
                width=nth(3 rout)
                spac=abs(qishix-chushix)
                ycank=ycank+(sqrt(26)-5)*spac+0.01
                y0=ycank
                ymm=yminup-10
                 wy1=ymm-add_x
                 wy2=wy1-add_x
                dtx=sqrt(26)*spac/5+0.002
                wx1=lastx1+dtx
                 wx2=lastx2+dtx
                path=axlPathStart(list(chushix:chushiy) width)
                axlPathLine( path, width, chushix:y0)
                axlPathLine( path, width, wx1:wy1)
                axlPathLine( path, width, chushix:wy2+(ylast-(sqrt(26)-5)*spac-0.01))
                axlPathLine( path, width, chushix:zhongy)
                _ASTB_A10_CreatePath(path layer rout)
                qishix=chushix
                lastx1=wx1
                lastx2=wx2
                ylast=wy2


              else 
                rout=nth(q paixudy)
                chushix=nth(0 rout)
                chushiy=nth(1 rout)
                zhongy=nth(2 rout)
                width=nth(3 rout)
                spac=abs(qishix-chushix)
                ycank=ycank+(sqrt(26)-5)*spac+0.01
                y0=ycank
                ymm=yminup-10
                 ;x0=xminmax+5
                 wy1=ymm-add_x
                 wy2=wy1-add_x

            dtx=sqrt(26)*spac/5+0.002
             wx1=lastx1+dtx
             wx2=lastx2+dtx
                path=axlPathStart(list(chushix:chushiy) width)
               ; axlDBCreateLine(list(chushix:chushiy chushix:y0) width layer)
                ;axlDBCreateLine(list(chushix:y0 wx1:wy1) width layer)
                ;axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
                axlPathLine( path, width, chushix:y0)
                axlPathLine( path, width, wx1:wy1)
                axlPathLine( path, width, wx2:wy2)
            y0=wy2
            
    for(k 1 m-2

                 wy1=y0-add_x
                 wy2=wy1-add_x

               ; path=axlPathStart(list(wx2:y0) width)
               ; axlDBCreateLine(list(wx2:y0  wx1:wy1) width layer)
                ;axlDBCreateLine(list(wx1:wy1 wx2:wy2) width layer)
                axlPathLine( path, width, wx1:wy1)
                axlPathLine( path, width, wx2:wy2)



        y0=wy2
        );for
                 wy1=y0-add_x
                 wy2=ylast-(sqrt(26)-5)*spac-0.01
                ; path=axlPathStart(list(wx2:y0 ) width)
               ; axlDBCreateLine(list(wx2:y0  wx1:wy1) width layer)
                ;axlDBCreateLine(list(wx1:wy1 chushix:wy2) width layer)
                ;axlDBCreateLine(list(chushix:wy2 chushix:zhongy) width layer)
                axlPathLine( path, width, wx1:wy1)
                axlPathLine( path, width, chushix:wy2)
                axlPathLine( path, width, chushix:zhongy)
            _ASTB_A10_CreatePath(path layer rout)


        qishix=chushix
        lastx1=wx1
        lastx2=wx2
        ylast=wy2
         );if m=1
        );for
        

    );if



);vertical



);case

            ; v1.4 撤销：一次框选处理完毕记为一批入栈，并提示撤销命令
            when( _ASTB_A10_curBatch
                _ASTB_A10_undoStack = cons(reverse(_ASTB_A10_curBatch) _ASTB_A10_undoStack)
                ASTB_UndoJournalPush("route_auto10deg")
                axlUIWPrint(nil "完成: 本批次处理 %d 段走线。输入 astbundo 可撤销本次修改"
                    length(_ASTB_A10_curBatch))
                _ASTB_A10_curBatch = nil
            )

);while

))

;------------------------------------------------------------------------
; 函数名  : ASTB_Route_Auto10deg_Undo
; 功能    : 撤销最近一次框选批次的 10 度蛇形走线（ASTB_Route_Auto10degu
;           命令，Done 后仍可用）：按批次记录的原线段起点+层+网络+线宽
;           (+新线 bBox) 现场查找蛇形新线（选择集返回新鲜 dbid，不依赖
;           存储 dbid——跨命令后失效成 dbid:removed），删除后按记录的
;           原线段坐标/线宽/网络重建原直线段。
; 备注    : 新线找不到（已被手动删除/改动）时视为已达删除目标，直接重建；
;           栈为空时提示"没有可撤销的记录"
;------------------------------------------------------------------------
procedure( ASTB_Route_Auto10deg_Undo()
    prog( (batch item lay x1 y1 x2 y2 w netName bb hit v vbb matchBb rr delOK n m)
        unless( _ASTB_A10_undoStack
            axlUIWPrint(nil "没有可撤销的记录")
            return(nil)
        )
        batch = car(_ASTB_A10_undoStack)
        _ASTB_A10_undoStack = cdr(_ASTB_A10_undoStack)
        axlSetFindFilter(?enabled '("noall" "clines") ?onButtons '("noall" "clines"))
        n = 0
        m = 0
        foreach( item batch
            lay     = nth(0 item)
            x1      = nth(1 item)
            y1      = nth(2 item)
            x2      = nth(3 item)
            y2      = nth(4 item)
            w       = nth(5 item)
            netName = nth(6 item)
            bb      = nth(7 item)
            ; 按原线段起点（新蛇形线必过该点）现场查找新线，拿新鲜 dbid
            axlClearSelSet()
            hit = nil
            when( axlSingleSelectPoint(x1:y1)
                foreach( v axlGetSelSet()
                    when( and(null(hit)
                              equal(v->layer lay)
                              equal(v->net->name netName)
                              abs(v->width - w) < 0.001)
                        matchBb = t
                        when( bb
                            vbb = errset( v->bBox nil )
                            vbb = and(vbb car(vbb))
                            if( vbb then
                                matchBb = and(
                                    abs(car(car(vbb))   - car(car(bb)))   < 0.01
                                    abs(cadr(car(vbb))  - cadr(car(bb)))  < 0.01
                                    abs(car(cadr(vbb))  - car(cadr(bb)))  < 0.01
                                    abs(cadr(cadr(vbb)) - cadr(cadr(bb))) < 0.01)
                            else
                                matchBb = nil
                            )
                        )
                        when( matchBb
                            hit = v
                        )
                    )
                )
            )
            delOK = t
            when( hit
                rr = errset( axlDeleteObject(hit) t )
                delOK = and(rr car(rr))
                unless( delOK
                    axlUIWPrint(nil "  警告: %L 处蛇形走线删除失败, 不重建原线(防重叠)" x1:y1)
                )
            )
            if( delOK then
                rr = errset( axlDBCreateLine(list(x1:y1 x2:y2) w lay netName) t )
                if( and(rr car(rr) car(car(rr))) then
                    n = n + 1
                    ;; 挂网络建线时约束管理器可能覆盖线宽——压回记录的原宽
                    when( and(w numberp(w))
                        errset( axlChangeWidth(list(car(car(rr))) w) t )
                    )
                else
                    m = m + 1
                    axlUIWPrint(nil "  警告: %L 处原始走线重建失败" x1:y1)
                )
            else
                m = m + 1
            )
        )
        axlClearSelSet()
        axlFlushDisplay()
        axlUIWPrint(nil "撤销完成: 恢复 %d 条原始走线, %d 个失败" n m)
        return(t)
    )
)

ASTB_RegisterCommand("ASTB_Route_Auto10degu" "ASTB_Route_Auto10deg_Undo" ?cmdType "general" ?undo nil)
; 统一撤销中枢注册（core/trans.il v1.4）：astbundo 按 LIFO 分发到本函数
ASTB_RegisterUndo("route_auto10deg" 'ASTB_Route_Auto10deg_Undo)

; 事务保护包装：主入口函数通过 ASTB_DBTransactionMark 调用实际执行逻辑
procedure( ASTB_Route_Auto10deg_Entry()
  ASTB_DBTransactionMark('ASTB_Route_Auto10deg nil)
)

; 注册命令指向带事务保护的入口
ASTB_RegisterCommand("ASTB_Route_Auto10deg" "ASTB_Route_Auto10deg_Entry" ?cmdType "interactive")

printf("[ASTB] route_auto10deg.il loaded.\n")
