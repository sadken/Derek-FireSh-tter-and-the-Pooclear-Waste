
\check for wall collision
.checkhit
.checktopleft
	LDA #00
	STA hitstore
	STA collision
	LDX xpos	
	LDY ypos
	JSR collisiondetect
	LDA hitreturn
	AND #&0F
	BNE goodtopleft
	LDA hitreturn
	AND #&F0
	BNE badblock
	JMP checktopright
.goodtopleft
	LDA hitstore
	EOR #&01
	STA hitstore
.checktopright
	LDA xpos
	CLC
	ADC #&03
	TAX
	LDY ypos
	JSR collisiondetect
	LDA hitreturn
	AND #&0F
	BNE goodtopright
	LDA hitreturn
	AND #&F0
	BNE badblock
	JMP checkbottomleft
.goodtopright
	LDA hitstore
	EOR #&02
	STA hitstore
.checkbottomleft
	LDX	xpos
	LDA ypos
	SEC
	SBC #&07
	TAY
	JSR collisiondetect
	LDA hitreturn
	AND #&0F
	BNE goodbottomleft
	LDA hitreturn
	AND #&F0
	BNE badblock
	JMP checkbottomright
.goodbottomleft
	LDA hitstore
	EOR #&04
	STA hitstore
.checkbottomright
	LDA xpos
	CLC
	ADC #&03
	TAX
	LDA ypos
	SEC
	SBC #&07
	TAY
	JSR collisiondetect
	LDA hitreturn
	AND #&0F
	BNE goodbottomright
	LDA hitreturn
	AND #&F0
	BNE badblock
	RTS
.goodbottomright
	LDA hitstore
	EOR #&08
	STA hitstore
	RTS
.badblock
	LDA #00
	STA hitstore
	RTS
	
	
.updateplayer
	DEC plyacc
	LDA plyacc
	BPL calcvel
	CMP #&FF
	BCS calcvel
	LDA #&FF
	STA plyacc
.calcvel
	LDA plyacc
	CLC
	ADC plyvel
	BPL calcypos
	CMP #&FD
	BCS calcypos
	LDA #&FD
.calcypos
	STA plyvel
	LDA ypos
	CLC
	ADC plyvel
	CMP #&DC
	BCC allowup
	LDA #&DC
.allowup
	CMP #&0A
	BCS allowdown
	LDA #&0A
.allowdown
	STA ypos
	RTS
	
\*Check Keypress
.inkey
	LDY #&FF
	LDA #&81
	JSR OSBYTE
	CPX #&00
	RTS
	
\*Move Player Routine
.checkkeys

.checkright
	LDX #&BD
	LDY #&FF
	LDA #&81
	JSR OSBYTE
	CPX #&00
	BEQ checkleft
	INC xpos
.checkleft
	LDX #&9E
	LDY #&FF
	LDA #&81
	JSR OSBYTE
	CPX #&00
	BEQ checkup
	DEC xpos
.checkup
	LDX #&B7
	LDY #&FF
	LDA #&81
	JSR OSBYTE
	CPX #&00
	BEQ checkdown
	LDA #&02
	STA plyacc
	JSR thrustnoise
.checkdown
	LDX #&97
	LDY #&FF
	LDA #&81
	JSR OSBYTE
	CPX #&00
	BEQ nobutton
.nobutton
	LDX #&01
	LDA #&0F
	JSR OSBYTE
	RTS	