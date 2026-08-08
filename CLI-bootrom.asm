;--------------------------------------------------------------------------
;
;	BOOTROM using ROMEN in CPLD
;
;	bootrom enable		enable boot ROM
;	bootrom disable		disable boot ROM
;	bootrom ro		set boot ROM read-only for PDP-11
;	bootrom rw		allow PDP-11 to write to boot ROM
;	bootrom load <filename>	load boot ROM image from SD-Card
;	bootrom internal	set boot ROM to internal
;	bootrom show		show current boot ROM statu
;
;
;
;
;
;--------------------------------------------------------------------------


bootrom_enable:

	cbi	b_RS0
	sbi	b_RS1
	sbi	b_RS2
	lds	r16, config+usr_bootflags
	sbr	r16, 0x01
	sts	config+usr_bootflags, r16
	out	dataportout, r16
	ldi	r16, 0xff
	out	dataportdir, r16
	sbi	b_WR
	cbi	b_WR
	clc
	ret

bootrom_disable:

	cbi	b_RS0
	sbi	b_RS1
	sbi	b_RS2
	lds	r16, config+usr_bootflags
	cbr	r16, 0x01
	out	dataportout, r16
	sts	config+usr_bootflags, r16
	ldi	r16, 0xff
	out	dataportdir, r16
	sbi	b_WR
	cbi	b_WR
	clc
	ret

bootrom_rw:
	lds	r16, config+usr_bootflags
	sbr	r16, 0x02
	sts	config+usr_bootflags, r16
	clc
	ret

bootrom_ro:
	lds	r16, config+usr_bootflags
	cbr	r16, 0x02
	sts	config+usr_bootflags, r16
	clc
	ret
	
bootrom_intern:
#ifdef rlv12emulation
	ldi	zl, low(dlboot+4)		; RLV12 Bootstrap
	ldi	zh, high(dlboot+4)
#endif
#ifdef	mscpemulation
	ldi	zl, low(duboot+4)		; MSCP Bootstrap
	ldi	zh, high(duboot+4)
#endif
	ldi	xl, low(bootromimage)
	ldi	xh, high(bootromimage)
	
	ldi	r16, 128
bootrom_intern010:
	ld	r17, Z+
	st	X+, r17
	dec	r16
	brne	bootrom_intern010
	clc
	ret

bootrom_show:
	lds	r16, config+usr_bootflags
	sbrc	r16, 0
	rjmp	bootrom_show010
	call	print
	.db	CR, LF
	.db	"BOOTROM is disabled", CR, LF, 0
	clc
	ret

bootrom_show010:
	sbrs	r16, 1
	rjmp	bootrom_show020
	call	print
	.db	CR, LF
	.db	"BOOTROM is enabled read/write", CR, LF, 0
	clc
	ret
	
bootrom_show020:
	call	print
	.db	CR, LF
	.db	"BOOTROM is enabled read only", CR, LF, 0, 0
	clc
	ret

	clc
	ret


;--------------------------------------------------------------------------
;
;	New "type <filename>" command that makes use of the new file IO
;	primitives.
;
bootrom_naf:
	call	mprint
	.dw	msgtypenaf
	clc
	ret
bootrom_fnf:
	call	mprint
	.dw	msgtypefnf
	clc
	ret
bootrom_open:
	sts	pprint+0, r24
	call	mprint
	.dw	msgtypeerr
	clc
	ret
;
bootrom_load:
	lds	yl, volqueue+0
	lds	yh, volqueue+1		; get current volume
	sbiw	yh:yl, 0
	brne	bootrom_load10
	call	mprint
	.dw	msgnovolume
	clc
	clc
	ret
bootrom_load10:
	lds	xl, cdstring+2
	lds	xh, cdstring+3
	st	X, zero			; Zero Terminate the string
	lds	r22, cdstring+0
	lds	r23, cdstring+1
	movw	r25:r24, yh:yl
	call	Name2DirEntry
	tst	r24
	brne	bootrom_fnf
	ldd	zl, Y+Vol_DirPointer+0
	ldd	zh, Y+Vol_DirPointer+1
	sbiw	zh:zl, 0
	breq	bootrom_naf
	ldd	r18, Z+D_Attr
	sbrc	r18, A_Directory
	rjmp	bootrom_naf
	movw	r25:r24, yh:yl
	call	ReadFileOpen
	movw	yh:yl, r25:r24
	tst	r25
	breq	bootrom_open
	ldi	r16, 128
	ldi	xl, low(bootromimage)
	ldi	xh, high(bootromimage)
bootrom_load20:
	push	r16
	push	xl
	push	xh
	movw	r25:r24, yh:yl
	call	ReadFileByte
	pop	xh
	pop	xl
	pop	r16
	ldd	r25, Y+fcb_flag
	sbrc	r25, F__ERR
	rjmp	bootrom_load60		; End-of-file reached
	st	X+, r24
;	sts	pprint+0, r24
;	call	print
;	.db	0x80, CR, LF, 0
	dec	r16
	brne	bootrom_load20
bootrom_load60:
	movw	r25:r24, yh:yl
	call	ReadFileClose
	clc
	ret
