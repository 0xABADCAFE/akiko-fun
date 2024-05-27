
		;include	lvo/dos_lib.i
		include	lvo/exec_lib.i
		include	lvo/timer_lib.i
		;include	lvo/graphics_lib.i
		;include	lvo/intuition_lib.i
		;include	lvo/misc_lib.i
		;include	lvo/potgo_lib.i


		xdef _test_akiko_c2p
		
		xdef _bench_akiko_rw
		
		xref _SysBase;

		section .text,code

; single 32-byte span conversion for validation
; a0 ULONG* from
; a1 ULONG* to
; trashes d0

_test_akiko_c2p:

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

	xdef _bench_start_ul
	xdef _bench_end_ul

	align 4

_bench_start_ul:
	ds.l	2

_bench_end_ul:
	ds.l	2

; estimates read/write bandwidth
; count in d0
_bench_akiko_rw:

	movem.l	d2/a6,-(sp)
	move.l	d0,d2

	move.l	_SysBase,a6
	jsr		_LVOForbid(a6)
	jsr		_LVODisable(a6)
	;jsr _LVOSuperState(a6)

	move.l	#$00B80038,a0

.loop:
	move.l	d0,(a0)
	move.l	d0,(a0)
	move.l	d0,(a0)
	move.l	d0,(a0)
	move.l	d0,(a0)
	move.l	d0,(a0)
	move.l	d0,(a0)
	move.l	d0,(a0)

	move.l	(a0),d0
	move.l	(a0),d0
	move.l	(a0),d0
	move.l	(a0),d0
	move.l	(a0),d0
	move.l	(a0),d0
	move.l	(a0),d0
	move.l	(a0),d0

	subq.l	#1,d2
	bgt.s	.loop

	;jsr	_LVOUserState(a6)
	jsr _LVOEnable(a6)
	jsr _LVOPermit(a6)

.done:
	movem.l	(sp)+,d2/a6
	rts

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
	jsr		_LVOForbid(a6)
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
	jsr _LVOPermit(a6)

    movem.l (sp)+,a2/a3/a6
    rts
