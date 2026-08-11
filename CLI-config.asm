;--------------------------------------------------------------------------
;
;	CONFIG section
;
;	Note that the configuration during operation is stored at various
;	locations and not only in the config record
;
;	configtype		located
;	----------		-------
;	systemflags		config record
;	bootflags		config record
;	logflags		FLAGS_LOG
;	unitflags		ucb_log
;
;
;
;	Show current configuration
;
;	
;


configshow:
	call	print
	.db	CR, LF
	.db	"Device Register Address ........:", NULL
	lds	r18, config+usr_systemflags
	sbrc	r18, usr__alt
	rjmp	configshow010
	call	print
	.db	" Primary ", NULL
	rjmp	configshow020
configshow010:
	call	print
	.db	" Secondary ", NULL
configshow020:
	call	logstatusprint
	call	bootrom_showc
	clc
	ret
;
;	Save current configuration to USERROW
;
configsave:
	in	r18, FLAGS_LOG
	sts	config+usr_logflags, r18
	
	lds	r18, unittable+ucb_size*0+ucb_log
	sts	config+usr_unitflags+0, r18
	lds	r18, unittable+ucb_size*1+ucb_log
	sts	config+usr_unitflags+1, r18
	lds	r18, unittable+ucb_size*2+ucb_log
	sts	config+usr_unitflags+2, r18
	lds	r18, unittable+ucb_size*3+ucb_log
	sts	config+usr_unitflags+3, r18
		
	rcall	userrowerase
	rcall	userrowwrite
	clc
	ret

configerase:
	rcall	userrowerase
	clc
	ret
;
;
;
userrowerase:
;
userrowerase010:
	lds	r18, NVMCTRL_STATUS
	sbrc	r18, NVMCTRL_FBUSY_bp
	rjmp	userrowerase010

	ldi	r18, CPU_CCP_SPM_gc
	sts	CPU_CCP, r18
	ldi	r18, NVMCTRL_CMD_FLPER_gc	; Page Erase Enable
	sts	NVMCTRL_CTRLA, r18
	sts	USERROW_base+0x11, zero

userrowerase020:
	lds	r18, NVMCTRL_STATUS
	sbrc	r18, NVMCTRL_FBUSY_bp
	rjmp	userrowerase020
	ret

userrowwrite:
	ldi	r18, CPU_CCP_SPM_gc
	sts	CPU_CCP, r18
	ldi	r18, NVMCTRL_CMD_FLWR_gc	; Flash Write Enable
	sts	NVMCTRL_CTRLA, r18

	ldi	xl, low(config+2)
	ldi	xh, high(config+2)
	ldi	zl, low(USERROW_base)
	ldi	zh, high(USERROW_base)
	ldi	r18, 0x55
	ldi	r19, 0xAA
	st	Z+, r18
	st	Z+, r19
	ldi	r16, usr_size-2
	sts	USERROW_base+1, r19

userrowwrite010:
	ld	r17, X+
	st	Z+, r17
	dec	r16
	brne	userrowwrite010

userrowwrite020:
	lds	r18, NVMCTRL_STATUS
	sbrc	r18, NVMCTRL_FBUSY_bp
	rjmp	userrowwrite020
	ret

;--------------------------------------------------------------------------
;
;	Primary/Secondary Device Register Address
;

devprimary:
	lds	r17, config+usr_systemflags
	cbr	r17, (1<<usr__alt)
	sts	config+usr_systemflags, r17
	clr	r17				; assume default
	lds	r16, config+usr_bootflags	; get boot ROM flags
	bst	r16, usr__bootrom		; 0=disable, 1=enable
	bld	r17, cpld__bootrom		; copy to CPLD register	
	rjmp	deviceaddress

devsecondary:
	lds	r17, config+usr_systemflags
	sbr	r17, (1<<usr__alt)
	sts	config+usr_systemflags, r17
	clr	r17				; assume default
	lds	r16, config+usr_bootflags	; get boot ROM flags
	bst	r16, usr__bootrom		; 0=disable, 1=enable
	bld	r17, cpld__bootrom		; copy to CPLD register	
	sbr	r17, (1<<cpld__alt)

deviceaddress:
	cli
	#if	cpldif==22
	ldi	r16, 7
	out	dataportout, r16
	sbi	b_ALEW
	cbi	b_ALEW
	out	dataportout, r17		; Write CPLD Register
	sbi	b_WR
	cbi	b_WR
	#endif

	#if	cpldif==40
	cbi	b_RS0
	sbi	b_RS1
	sbi	b_RS2
	out	dataportout, r17		; Write CPLD Register
	ldi	r16, 0xff
	out	dataportdir, r16
	sbi	b_WR
	cbi	b_WR
	#endif	
	sei
	clc
	ret



