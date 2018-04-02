
\\sound playing routine 
.dienoise
	LDA #LO(playerdietab)
	STA spritetabaddr
	LDA #HI(playerdietab)
	STA spritetabaddr+1
	LDA #&34
	STA diesnd+4
	LDA #&0F
	STA noisetemp
.dienoiseloop
	LDX #LO(diesnd)
	LDY #HI(diesnd)
	LDA #&07
	JSR OSWORD
	LDX diesnd+4
	DEX
	DEX
	DEX
	STX diesnd+4
	JSR vsync
	JSR vsync
	LDX oxpos
	LDY oypos
	JSR drawsprite
	LDA noisetemp
	LSR A
	LSR A
	TAY
	LDA (spritetabaddr),y
	STA spriteaddr
	LDA #&20
	STA spriteaddr+1
	LDX xpos
	LDY ypos
	JSR drawsprite		
	LDA xpos
	STA oxpos
	LDA ypos
	STA oypos
	DEC noisetemp
	LDA noisetemp
	BNE dienoiseloop
	RTS
	
.thrustnoise
	LDX #LO(thrustsnd)
	LDY #HI(thrustsnd)
	LDA #&07
	JSR OSWORD
	RTS
	
.ticknoise
	LDX #LO(ticksnd)
	LDY #HI(ticksnd)
	LDA #&07
	JSR OSWORD
	RTS
	
.poonoise
	LDX #LO(poosnd)
	LDY #HI(poosnd)
	LDA #&07
	JSR OSWORD
	RTS

.levelnoise
	LDA #&22
	STA levelsnd+4
	LDX #LO(levelsnd)
	LDY #HI(levelsnd)
	LDA #&07
	JSR OSWORD
	LDA #&44
	STA levelsnd+4
	LDX #LO(levelsnd)
	LDY #HI(levelsnd)
	LDA #&07
	JSR OSWORD
	LDA #&88
	STA levelsnd+4
	LDX #LO(levelsnd)
	LDY #HI(levelsnd)
	LDA #&07
	JSR OSWORD
	RTS	
	
.setupenvelope
	LDX #LO(pooenv)
	LDY #HI(pooenv)
	LDA #&08
	JSR OSWORD
	RTS

.playmusic
	LDA playnote
	CMP #&FF
	BNE musicdone
	LDA #&00
	STA playnote
	LDY note
	LDA pitchtab,Y
	STA music+4
	LDX #LO(music)
	LDY #HI(music)
	LDA #&07
	JSR OSWORD
	LDY note
	LDA pitchtab2,Y
	STA music1+4
	LDX #LO(music1)
	LDY #HI(music1)
	LDA #&07
	JSR OSWORD
	LDY note
	LDA pitchtab3,Y
	STA music2+4
	LDX #LO(music2)
	LDY #HI(music2)
	LDA #&07
	JSR OSWORD
	INC note
	LDA note
	CMP #&3F
	BNE musicdone
	LDA #00
	STA note
.musicdone
	RTS 
	
\music tables	
.music
	EQUB	&01, &02
	EQUB 	&F1, &FF		\\Amplitude	-15
	EQUB	&01, &00		\\Pitch	52
	EQUB	&03, &00		\\Duration 1
		
.music1
	EQUB	&02, &02
	EQUB 	&F1, &FF		\\Amplitude	-15
	EQUB	&01, &00		\\Pitch	52
	EQUB	&03, &00		\\Duration 1
	
.music2
	EQUB	&03, &02
	EQUB 	&F1, &FF		\\Amplitude	-15
	EQUB	&01, &00		\\Pitch	52
	EQUB	&03, &00		\\Duration 1
	
\Sound Tables
	
.diesnd
	EQUB	&01, &00		\\Channel	1
	EQUB 	&F1, &FF		\\Amplitude	-15
	EQUB	&34, &00		\\Pitch	52
	EQUB	&01, &00		\\Duration 1
	
.thrustsnd
	EQUB	&10, &00		\\Channel 16
	EQUB 	&F8, &FF		\\Amplitude -15
	EQUB	&06, &00		\\Pitch 800
	EQUB	&03, &00		\\Duration 1
	
.levelsnd
	EQUB	&03, &00		\\Channel 3
	EQUB 	&F1, &FF		\\Amplitude -15
	EQUB	&06, &00		\\Pitch 800
	EQUB	&01, &00		\\Duration 1
	
.ticksnd
	EQUB	&01, &00
	EQUB 	&F1, &FF		\\Amplitude	-15
	EQUB	&01, &00		\\Pitch	52
	EQUB	&01, &00		\\Duration 1
	
.poosnd
	EQUB	&02, &00
	EQUB 	&01, &00		\\Amplitude	-15
	EQUB	&0F, &00		\\Pitch	52
	EQUB	&04, &00		\\Duration 1
	
.pooenv
	EQUB	&01, &80, &FC, &04, &FC, &03, &03, &03, &7E, &00, &00, &F9, &7E, &7E
