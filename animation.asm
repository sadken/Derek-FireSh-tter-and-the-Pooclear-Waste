.animdraw
{
	LDA #&00
	STA animcount
.animdrawloop
	LDX animcount
	LDA animspritetab, X
	STA xpos
	\LSR A
	CMP #&28
	BCC animxok
	SEC 
	SBC #&27
.animxok
	TAX
	LDA sintab, X
	CLC
	ASL A
	CLC
	ASL A
	CLC
	ADC #&7B
	TAY	
	LDX xpos
	JSR getaddr
	LDA #LO(SPRITE+&20)
	STA shape
	LDA #HI(SPRITE+&20)
	STA shape+1
	LDA #&04
	STA counter
	LDA #&08
	STA depth
	JSR doplot
	INC animcount
	LDA animcount
	CMP #&03
	BCC animdrawloop
	RTS
}

.initanim 
	LDA #&17
	STA animspritetab
	LDA #&2E
	STA animspritetab+1
	LDA #&45
	STA animspritetab+2
	RTS
	
.updateanim
{
	LDX #&00
.updateloop
	LDA animspritetab,X
	CLC
	ADC #&01
	CMP #&4C
	BCC allowright
	LDA #&00
.allowright
	STA animspritetab,X
	INX
	CPX #&03
	BCC updateloop
	RTS
}

.animspritetab
	EQUB 	&00, &00, &00
	
.sintab
EQUB &00
EQUB &02
EQUB &03
EQUB &05
EQUB &06
EQUB &07
EQUB &08
EQUB &09
EQUB &0A
EQUB &0A
EQUB &0A
EQUB &0A
EQUB &0A
EQUB &09
EQUB &08
EQUB &07
EQUB &06
EQUB &05
EQUB &03
EQUB &02
EQUB &00
EQUB &FE
EQUB &FD
EQUB &FB
EQUB &FA
EQUB &F9
EQUB &F8
EQUB &F7
EQUB &F6
EQUB &F6
EQUB &F6
EQUB &F6
EQUB &F6
EQUB &F7
EQUB &F8
EQUB &F9
EQUB &FA
EQUB &FB
EQUB &FD
EQUB &FE

.animcount		SKIP 1
