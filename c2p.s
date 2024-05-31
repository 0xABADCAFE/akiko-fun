
        ;include	lvo/dos_lib.i
        include	lvo/exec_lib.i
        include	lvo/timer_lib.i
        ;include	lvo/graphics_lib.i
        ;include	lvo/intuition_lib.i
        ;include	lvo/misc_lib.i
        ;include	lvo/potgo_lib.i

        xref _SysBase;

        section .text,code


    align 4
; single 32-byte span conversion for validation
; a0 ULONG* from
; a1 ULONG* to
; trashes d0

    xdef _verify_akiko_c2p
_verify_akiko_c2p:

    move.l	a1,d0
    move.l	#$00B80038,a1

    move.l	(a0)+,(a1)
    move.l	(a0)+,(a1)
    move.l	(a0)+,(a1)
    move.l	(a0)+,(a1)
    move.l	(a0)+,(a1)
    move.l	(a0)+,(a1)
    move.l	(a0)+,(a1)
    move.l	(a0)+,(a1)

    move.l	d0,a0

    move.l	(a1),(a0)+
    move.l	(a1),(a0)+
    move.l	(a1),(a0)+
    move.l	(a1),(a0)+
    move.l	(a1),(a0)+
    move.l	(a1),(a0)+
    move.l	(a1),(a0)+
    move.l	(a1),(a0)+

    rts

    xdef _verify_akiko_c2p_cacr_fix
_verify_akiko_c2p_cacr_fix:
    ; Run this with the caches on plx
    movem.l a2/a3/a6,-(sp)

    move.l  a0,a2
    move.l  a1,a3
    move.l  _SysBase,a6

    jsr _LVODisable(a6)
    jsr _LVOSuperState(a6)

    movec   cacr,d1
    move.l  d1,d0
    bclr.l  #13,d0 ; disable write allocation
    movec  d0,cacr

    move.l	#$00B80038,a1

    move.l	(a2)+,(a1)
    move.l	(a2)+,(a1)
    move.l	(a2)+,(a1)
    move.l	(a2)+,(a1)
    move.l	(a2)+,(a1)
    move.l	(a2)+,(a1)
    move.l	(a2)+,(a1)
    move.l	(a2)+,(a1)

    move.l	(a1),(a3)+
    move.l	(a1),(a3)+
    move.l	(a1),(a3)+
    move.l	(a1),(a3)+
    move.l	(a1),(a3)+
    move.l	(a1),(a3)+
    move.l	(a1),(a3)+
    move.l	(a1),(a3)+

    movec  d1,cacr; restore the previous value

    jsr     _LVOUserState(a6)
    jsr     _LVOEnable(a6)

    movem.l (sp)+,a2/a3/a6

    rts


    align 4

; #############################################################################

    align 4

; Performs a straight 8-longword loop copy as the theoretical best possible
; data transfer case. No transformation is applied at all.

    xref _test_copy_320x256
_test_copy_320x256:
    movem.l a2/a3/a6,-(sp)

    ; back up the inputs
    move.l  a0,a2
    move.l  a1,a3

    move.l	_SysBase,a6
    jsr		_LVODisable(a6)

    move.w  #2560-1,d0

.loop:
    move.l  (a2)+,(a3)+
    move.l  (a2)+,(a3)+
    move.l  (a2)+,(a3)+
    move.l  (a2)+,(a3)+
    move.l  (a2)+,(a3)+
    move.l  (a2)+,(a3)+
    move.l  (a2)+,(a3)+
    move.l  (a2)+,(a3)+

    dbra    d0,.loop

    jsr _LVOEnable(a6)

    movem.l (sp)+,a2/a3/a6
    rts

; #############################################################################

    align 4

; Performs no C2P but does separate out the writes to simulate planar writing

    xref _test_null_c2p_320x256
_test_null_c2p_320x256:

    movem.l a2/a3/a6,-(sp)

    ; back up the inputs
    move.l  a0,a2
    move.l  a1,a3

    move.l	_SysBase,a6
    jsr		_LVODisable(a6)

    move.w  #2560-1,d0
    move.l  a3,a1

    ; a0 akiko
    ; a2 source
    ; a3
.loop:
    move.l  (a2)+,(a1)
    add.w   #10240,a1

    move.l  (a2)+,(a1)
    add.w   #10240,a1

    move.l  (a2)+,(a1)
    add.w   #10240,a1

    move.l  (a2)+,(a1)
    add.w   #10240,a1

    move.l  (a2)+,(a1)
    add.w   #10240,a1

    move.l  (a2)+,(a1)
    add.w   #10240,a1

    move.l  (a2)+,(a1)
    add.w   #10240,a1
    add.w   #4,a3

    move.l  (a2)+,(a1)
    move.l  a3,a1
    dbra    d0,.loop

    jsr _LVOEnable(a6)

    movem.l (sp)+,a2/a3/a6
    rts

; #############################################################################

    xdef _test_akiko_rw_320x256

; Ignores source/destination and just tests how quickly we can write and read
; Akiko via a data register.

_test_akiko_rw_320x256:

    movem.l	a6,-(sp)
    move.l	_SysBase,a6
    jsr		_LVODisable(a6)

    move.l	#$00B80038,a0
    move.w  #2560-1,d0

.loop:
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)

    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1

    dbra    d0,.loop

    jsr _LVOEnable(a6)

.done:
    movem.l	(sp)+,a6
    rts

; #############################################################################

    xdef _test_akiko_rw_320x256_cacr_fix

; Ignores source/destination and just tests how quickly we can write and read
; Akiko via a data register.

_test_akiko_rw_320x256_cacr_fix:

    movem.l	d2/a6,-(sp)
    move.l	_SysBase,a6
    jsr		_LVODisable(a6)
    jsr     _LVOSuperState(a6)

    movec   cacr,d2
    move.l  d2,d0
    bclr.l  #13,d0 ; disable write allocation
    movec  d0,cacr

    move.l	#$00B80038,a0
    move.w  #2560-1,d0

.loop:
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)
    move.l	d1,(a0)

    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1
    move.l	(a0),d1

    dbra    d0,.loop

    movec   d2,cacr
    jsr _LVOUserState(a6)
    jsr _LVOEnable(a6)

.done:
    movem.l	(sp)+,d2/a6
    rts

; #############################################################################

    align 4

; Version 1
; Source in a0
; Dest in a1
; Assumes planar buffer is 320x256, contiguously allocated
    xref _test_akiko_c2p_320x256_v1

_test_akiko_c2p_320x256_v1:

    movem.l a2/a3/a6,-(sp)

    ; back up the inputs
    move.l  a0,a2
    move.l  a1,a3

    move.l	_SysBase,a6
    jsr		_LVODisable(a6)

    move.l  #$00B80038,a0
    move.w  #2560-1,d0
    move.l  a3,a1

    ; a0 akiko
    ; a2 source
    ; a3
.loop:
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)

    ; write plane 0
    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1
    add.w   #4,a3

    move.l  (a0),(a1)
    move.l  a3,a1
    dbra    d0,.loop

    jsr _LVOEnable(a6)

    movem.l (sp)+,a2/a3/a6
    rts

; #############################################################################

    align 4

; Version 1
; Source in a0
; Dest in a1
; Assumes planar buffer is 320x256, contiguously allocated
    xref _test_akiko_c2p_320x256_v1_cacr_fix

_test_akiko_c2p_320x256_v1_cacr_fix:

    movem.l d2/a2/a3/a6,-(sp)

    ; back up the inputs
    move.l  a0,a2
    move.l  a1,a3

    move.l	_SysBase,a6
    jsr		_LVODisable(a6)
    jsr     _LVOSuperState(a6)

    movec   cacr,d2
    move.l  d2,d0
    bclr.l  #13,d0 ; disable write allocation
    movec   d0,cacr

    move.l  #$00B80038,a0
    move.w  #2560-1,d0
    move.l  a3,a1

    ; a0 akiko
    ; a2 source
    ; a3
.loop:
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)
    move.l  (a2)+,(a0)

    ; write plane 0
    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1

    move.l  (a0),(a1)
    add.w   #10240,a1
    add.w   #4,a3

    move.l  (a0),(a1)
    move.l  a3,a1
    dbra    d0,.loop

    movec  d2,cacr

    jsr _LVOUserState(a6)
    jsr _LVOEnable(a6)

    movem.l (sp)+,d2/a2/a3/a6
    rts

; #############################################################################

    align 4

; Version 1
; Source in a0
; Dest in a1
; Assumes planar buffer is 320x256, contiguously allocated
    xref _test_akiko_c2p_320x256_v2

_test_akiko_c2p_320x256_v2:

    movem.l d1-d7/a2/a3/a4/a6,-(sp)

    ; back up the inputs
    move.l  a0,a2
    move.l  a1,a3

    move.l	_SysBase,a6
    jsr		_LVODisable(a6)

    move.l  #$00B80038,a0
    move.w  #2560-1,d0
    move.l  a3,a1

    ; a0 akiko
    ; a2 source
    ;
.loop:
    movem.l (a2)+,d1-d7/a4
    move.l  d1,(a0)
    move.l  d2,(a0)
    move.l  d3,(a0)
    move.l  d4,(a0)
    move.l  d5,(a0)
    move.l  d6,(a0)
    move.l  d7,(a0)
    move.l  a4,(a0)

    move.l  (a0),d1
    move.l  (a0),d2
    move.l  (a0),d3
    move.l  (a0),d4
    move.l  (a0),d5
    move.l  (a0),d6
    move.l  (a0),d7
    move.l  (a0),a4

    ; write plane 0
    move.l  d1,(a1)
    add.w   #10240,a1

    move.l  d2,(a1)
    add.w   #10240,a1

    move.l  d3,(a1)
    add.w   #10240,a1

    move.l  d4,(a1)
    add.w   #10240,a1

    move.l  d5,(a1)
    add.w   #10240,a1

    move.l  d6,(a1)
    add.w   #10240,a1

    move.l  d7,(a1)
    add.w   #10240,a1
    add.w   #4,a3

    move.l  a4,(a1)
    move.l  a3,a1
    dbra    d0,.loop

    jsr _LVOEnable(a6)

    movem.l (sp)+,d1-d7/a2/a3/a4/a6
    rts

; #############################################################################


; #############################################################################

    align 4

; Version 1
; Source in a0
; Dest in a1
; Assumes planar buffer is 320x256, contiguously allocated
    xref _test_akiko_c2p_320x256_v2_cacr_fix

_test_akiko_c2p_320x256_v2_cacr_fix:

    movem.l d1-d7/a2/a3/a4/a6,-(sp)

    ; back up the inputs
    move.l  a0,a2
    move.l  a1,a3

    move.l	_SysBase,a6
    jsr		_LVODisable(a6)
    jsr     _LVOSuperState(a6)

    movec   cacr,d1
    move.l  d1,d0
    bclr.l  #13,d0 ; disable write allocation
    movec   d0,cacr
    move.l  d1,-(sp)


    move.l  #$00B80038,a0
    move.w  #2560-1,d0
    move.l  a3,a1

    ; a0 akiko
    ; a2 source
    ;
.loop:
    movem.l (a2)+,d1-d7/a4
    move.l  d1,(a0)
    move.l  d2,(a0)
    move.l  d3,(a0)
    move.l  d4,(a0)
    move.l  d5,(a0)
    move.l  d6,(a0)
    move.l  d7,(a0)
    move.l  a4,(a0)

    move.l  (a0),d1
    move.l  (a0),d2
    move.l  (a0),d3
    move.l  (a0),d4
    move.l  (a0),d5
    move.l  (a0),d6
    move.l  (a0),d7
    move.l  (a0),a4

    ; write plane 0
    move.l  d1,(a1)
    add.w   #10240,a1

    move.l  d2,(a1)
    add.w   #10240,a1

    move.l  d3,(a1)
    add.w   #10240,a1

    move.l  d4,(a1)
    add.w   #10240,a1

    move.l  d5,(a1)
    add.w   #10240,a1

    move.l  d6,(a1)
    add.w   #10240,a1

    move.l  d7,(a1)
    add.w   #10240,a1
    add.w   #4,a3

    move.l  a4,(a1)
    move.l  a3,a1
    dbra    d0,.loop

    move.l  (sp)+,d1
    movec   d1,cacr

    jsr _LVOUserState(a6)
    jsr _LVOEnable(a6)

    movem.l (sp)+,d1-d7/a2/a3/a4/a6
    rts

; #############################################################################

    align 4

    xdef _init_kalms_c2p_030_320x256

; d0.w	chunkyx [chunky-pixels]
; d1.w	chunkyy [chunky-pixels]
; d2.w	(scroffsx) [screen-pixels]
; d3.w	scroffsy [screen-pixels]
; d4.l	(rowlen) [bytes] -- offset between one row and the next in a bpl
; d5.l	(bplsize) [bytes] -- offset between one row in one bpl and the next bpl
; d6.l	(chunkylen) [bytes] -- offset between one row and the next in chunkybuf

    xref c2p1x1_8_c5_030_2_init

_init_kalms_c2p_030_320x256:
    movem.l d2-d6,-(sp)

    move.l  #320,d0
    move.l  #256,d1
    clr.l   d2
    clr.l   d3
    move.l  #320/8,d4
    move.l  #320*256/8,d5
    move.l  #320,d6
    jsr     c2p1x1_8_c5_030_2_init

    movem.l (sp)+,d2-d6
    rts

; #############################################################################

    align 4

    xdef _test_kalms_c2p_030_320x256

    xref c2p1x1_8_c5_030_2

_test_kalms_c2p_030_320x256:
    movem.l a2/a3/a6,-(sp)

    move.l  a0,a2
    move.l  a1,a3
    move.l	_SysBase,a6
    jsr		_LVODisable(a6)

    move.l  a2,a0
    move.l  a3,a1
    jsr     c2p1x1_8_c5_030_2

    jsr		_LVOEnable(a6)

    movem.l (sp)+,a2/a3/a6
    rts
