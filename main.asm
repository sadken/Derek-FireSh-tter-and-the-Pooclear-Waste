
\CONSTANTS

OSBYTE = &FFF4
OSWORD = &FFF1
OSWRCH = &FFEE
SPRITE = &2000
POOP = &2100
TILES = &2200
POOPOS = &2300
LEVEL = &2400
SCREEN = &3000
MAXTILE = &04
STARTX = &0A
STARTY = &DC
STARTACC = &02
STARTVEL = &00
RADSTART = &3540
DELAY = &0F

\Zero Page Variables

ORG &0070
.addr			SKIP 2
.addrtemp		SKIP 2
.temp			SKIP 1
.temp2			SKIP 1
.depth			SKIP 1
.offset			SKIP 2
.leveltemp		SKIP 2	
.rowcounter		SKIP 1
.shape			SKIP 2
.counter		SKIP 1
.xpos			SKIP 1
.ypos			SKIP 1
.oxpos			SKIP 1
.oypos			SKIP 1
.collision		SKIP 1
.colloffset		SKIP 1
.framecount		SKIP 1
.updatecount	SKIP 1
.time			SKIP 1
.currenttile	SKIP 2
.spriteaddr		SKIP 2
.spritetabaddr	SKIP 2
.pootabaddr		SKIP 2



org &1200
.START
.init
	SEI
	LDA &204
	STA sysirq
	LDA &205
	STA sysirq+1
	CLI
	JSR startscreen
	JSR initgameirq
.gameloop
	LDA radiation
	CMP #&10
	BNE	notfinished
	JSR gameover
.notfinished
	LDA xpos
	STA oxpos
	LDA ypos
	STA oypos
	INC framecount
	LDA framecount
	CMP #&09
	BNE updatecheck
	LDA #00
	STA framecount
.updatecheck
	INC updatecount
	LDA updatecount
	CMP #&02
	BNE skipupdate
	JSR updateplayer
	LDA #&00
	STA updatecount
.skipupdate
	JSR checkkeys
	JSR checkhit
	LDA collision
	BEQ	redraw
	LDA hitstore
	BNE land
	JMP playerdead
.land
	LDA oxpos
	STA xpos
	LDA oypos
	STA ypos
	LDA #00
	STA plyacc
	STA plyvel
.redraw
	JSR vsync
	LDX oxpos
	LDY oypos
	JSR drawsprite
	JSR updatesprite
	LDX xpos
	LDY ypos
	JSR drawsprite	
	JSR pooupdate
	JSR updateradiation
	LDA ypos
	CMP #&0A
	BEQ bottomlevelexit
	JMP gameloop

\* VSYNC Routine
.vsync
	LDA #&13
	JSR OSBYTE	
	RTS
	
.bottomlevelexit
	INC levelcount
	SED 
	LDA zonecount
	CLC
	ADC #01
	STA zonecount
	CLD
	LDA xpos
	STA restartx
	JSR levelnoise
	LDA leveltemp
	CLC
	ADC #&46
	STA leveltemp
	LDA leveltemp+1
	ADC #&00
	STA leveltemp+1
	LDA #00
	STA radiation
	JSR updateradiation
	JSR restartlevel
	JSR poosetup
	JMP gameloop

.playerdead
	JSR stopplay
	JSR dienoise
	LDA restartx
	STA xpos
	JSR restartlevel
	LDA poostatus
	JSR drawpoo1
	JSR startplay
	JMP gameloop
	
	
.restartlevel
	LDA #LO(playerdowntab)
	STA spritetabaddr
	LDA #HI(playerdowntab)
	STA spritetabaddr+1	
	LDA #00
	STA framecount
	STA spritetabindex
	TAY
	LDA (spritetabaddr),y
	STA spriteaddr
	INY
	LDA #&20
	STA spriteaddr+1
	LDA #STARTACC
	STA plyacc
	LDA #STARTVEL
	STA plyvel
	LDA #STARTY
	STA ypos
	JSR clearlevel
	JSR drawlevel
	LDX xpos
	LDY ypos
	JSR drawsprite
	RTS 

	
.initgameirq
	SEI
	LDA #LO(gameirq)
	STA &204
	LDA #HI(gameirq)
	STA &205
	LDA #&FF
	STA time
	CLI	
	RTS
	
.initmusicirq
	LDA #&00
	STA playnote
	SEI
	LDA #LO(musicirq)
	STA &204
	LDA #HI(musicirq)
	STA &205
	LDA #01
	STA time
	CLI	
	RTS
	
\IRQ handler (Tick Timer)
.gameirq
{
	SEI
	TXA 
	PHA
	TYA
	PHA
	LDA #&40
	BIT &FE4D
	BNE irq1
.exit
	PLA
	TAY
	PLA
	TAX
	JMP (sysirq)
.irq1
	DEC time
	BNE exit
	LDA tickstatus
	BEQ exit
	INC radiation
	JSR ticknoise
	LDA tickspeed
	STA time
	JMP exit
}
	
\IRQ handler (Tick Timer)
.musicirq
{
	SEI
	PHA
	TXA 
	PHA
	TYA
	PHA
	LDA #&40
	BIT &FE4D
	BNE musicirq1
.musicexit
	PLA
	TAY
	PLA
	TAX
	PLA
	JMP (sysirq)
.musicirq1
	DEC time
	BNE musicexit
	LDA #&FF
	STA playnote
	LDA #DELAY
	STA time
	JMP musicexit
}
	
\* Level covers 160 pixels x 112 pixels
\* To calculate Y char = (y SHR 3) - 4
\* To Calculate X char = x SHR 3
\* AND x char with &01 If 0 check High nibble, if 1 check Low nibble of x shr 1
\* X reg and Y reg hold X,Y position
\* 
.collisiondetect
	LDA #00
	STA temp			\\Clear Temp var
	STA hitreturn
	TXA
	LSR A
	LSR A
	LSR A
	STA temp
	LSR A
	TAX
	TYA 
	EOR #&FF
	LSR A
	LSR A
	LSR A
	LSR A
	SEC
	SBC #&02
	TAY
	ASL A
	ASL A
	CLC
	STY temp2
	ADC temp2
	STA colloffset
	TXA
	CLC
	ADC colloffset
	STA colloffset
	LDA temp
	AND #01
	BEQ highnibble
	LDY colloffset
	LDA (leveltemp), Y
	AND #&0F	
	JMP finishcollision
.highnibble
	LDY colloffset
	LDA (leveltemp), Y
	AND #&F0
	LSR A
	LSR A
	LSR A
	LSR A
.finishcollision
	BEQ nocollision
	INC collision
	CMP #&08
	BCC badhit
	LDA #&0F
	STA hitreturn
	RTS
.badhit
	LDA #&F0
	STA hitreturn
.nocollision
	RTS
	
.poohitcheck
.checkpoo1
	LDA poostatus
	AND #&01
	BEQ checkpoo2
	LDA xpos
	CLC
	ADC #&04
	STA temp
	LDA poopostab
	CMP temp
	BCS checkpoo2
	LDA poopostab
	CLC
	ADC #&09
	CMP temp
	BCC checkpoo2
	LDA ypos
	CLC
	ADC #&04
	STA temp
	LDA poopostab+1
	CMP temp
	BCS checkpoo2
	LDA poopostab+1
	CLC
	ADC #&09
	CMP temp
	BCC checkpoo2
	LDA poostatus
	AND #&0E
	STA poostatus
	DEC radiation
	SED 
	LDA poocount
	CLC
	ADC #01
	STA poocount
	CLD
	JSR poonoise
	JMP poohitdone
.checkpoo2
	LDA poostatus
	AND #&02
	BEQ checkpoo3
	LDA xpos
	CLC
	ADC #&04
	STA temp
	LDA poopostab+4
	CMP temp
	BCS checkpoo3
	LDA poopostab+4
	CLC
	ADC #&09
	CMP temp
	BCC checkpoo3
	LDA ypos
	CLC
	ADC #&04
	STA temp
	LDA poopostab+5
	CMP temp
	BCS checkpoo3
	LDA poopostab+5
	CLC
	ADC #&09
	CMP temp
	BCC checkpoo3
	LDA poostatus
	AND #&0D
	STA poostatus
	DEC radiation
	SED 
	LDA poocount
	CLC
	ADC #01
	STA poocount
	CLD
	JSR poonoise
	JMP poohitdone
.checkpoo3
	LDA poostatus
	AND #&04
	BEQ checkpoo4
	LDA xpos
	CLC
	ADC #&04
	STA temp
	LDA poopostab+8
	CMP temp
	BCS checkpoo4
	LDA poopostab+8
	CLC
	ADC #&09
	CMP temp
	BCC checkpoo4
	LDA ypos
	CLC
	ADC #&04
	STA temp
	LDA poopostab+9
	CMP temp
	BCS checkpoo4
	LDA poopostab+9
	CLC
	ADC #&09
	CMP temp
	BCC checkpoo4
	LDA poostatus
	AND #&0B
	STA poostatus
	DEC radiation
	SED 
	LDA poocount
	CLC
	ADC #01
	STA poocount
	CLD
	JSR poonoise
	JMP poohitdone
.checkpoo4
	LDA poostatus
	AND #&08
	BEQ poohitdone
	LDA xpos
	CLC
	ADC #&04
	STA temp
	LDA poopostab+12
	CMP temp
	BCS poohitdone
	LDA poopostab+12
	CLC
	ADC #&09
	CMP temp
	BCC poohitdone
	LDA ypos
	CLC
	ADC #&04
	STA temp
	LDA poopostab+13
	CMP temp
	BCS poohitdone
	LDA poopostab+13
	CLC
	ADC #&09
	CMP temp
	BCC poohitdone
	LDA poostatus
	AND #&07
	STA poostatus
	DEC radiation
	SED 
	LDA poocount
	CLC
	ADC #01
	STA poocount
	CLD
	JSR poonoise
.poohitdone
	LDA radiation
	BPL radok
	LDA #00
	STA radiation
.radok
	RTS
	
.initgame
	LDA #&3F
	STA tickspeed
	JSR setupenvelope
	LDA #LO(playeruptab)
	STA spritetabaddr
	LDA #HI(playeruptab)
	STA spritetabaddr+1
	LDA #LO(SPRITE)
	STA spriteaddr
	LDA #HI(SPRITE)
	STA spriteaddr+1
	LDA #LO(pootab)
	STA pootabaddr
	LDA #HI(pootab)
	STA pootabaddr+1
	LDA #00
	STA poocount
	STA zonecount
	STA radiation
	STA spritetabindex
	STA framecount
	STA updatecount
	STA levelcount
	LDA #LO(LEVEL)
	STA leveltemp
	LDA #HI(LEVEL)
	STA leveltemp+1
	LDA #STARTACC
	STA plyacc
	LDA #STARTVEL
	STA plyvel
	LDA #STARTX
	STA xpos
	STA restartx
	LDA #STARTY
	STA ypos
	LDX xpos
	LDY ypos
	JSR drawsprite
	RTS

.stopplay
	LDA #&00
	STA tickstatus
	LDA #&FF
	STA time
	RTS

.startplay
	LDA tickspeed
	STA tickstatus
	STA time
	RTS



INCLUDE "playermovement.asm"
INCLUDE "sounds.asm"
INCLUDE "sprite.asm"
INCLUDE "gameover.asm"
INCLUDE "startscreen.asm"
INCLUDE "animation.asm"

\Variables
.sysirq			SKIP 2
.restartx		SKIP 1
.plyacc			SKIP 1
.plyvel			SKIP 1
.levelpos		SKIP 1
.leveladdr		SKIP 2
.tilecolumn		SKIP 1
.noisetemp		SKIP 1
.hitstore 		SKIP 1
.hitreturn		SKIP 1
.radiation		SKIP 1
.poocount		SKIP 1
.pootabindex	SKIP 1
.poospriteaddr	SKIP 2
.poostatus		SKIP 1
.oldpoostatus	SKIP 1
.spritetabindex	SKIP 1
.zonetext		SKIP 2
.zonecount		SKIP 1
.levelcount		SKIP 1
.tickstatus		SKIP 1
.tickspeed		SKIP 1
.note			SKIP 1
.playnote		SKIP 1
	
.pitchtab
	INCBIN ".\music\song.bin"
	
.pitchtab2
	INCBIN ".\music\song2.bin"
	
.pitchtab3
	INCBIN ".\music\song3.bin"

.endasm
	
org SPRITE
INCBIN ".\sprites\player2.bin"	\\Player sprite data
.endsprite

org POOP
INCBIN ".\sprites\poop.bin"		\\Poop sprite data
.endpoop

ORG TILES
INCBIN ".\sprites\wall.bin"		\\Level sprite data
.endtiles

ORG POOPOS
INCBIN ".\levels\level1poop.bin" \\Poop Data
.endpoopos

ORG LEVEL
INCBIN ".\levels\level1.bin"	\\level data

ORG SCREEN
INCBIN ".\sprites\banner.bin"	\\Top Banner



.END

SAVE "CODE" , START, END 

PUTBASIC "loader.bas", "LOADER"
PUTFILE ".\screens\title.bin", "TITLE", 3000
PUTFILE "boot.txt", "!BOOT", 0000

PRINT " "
PRINT "Start Address", ~START
PRINT "ASM End", ~endasm
PRINT " "

PRINT "Character Address", ~SPRITE
PRINT "Character End", ~endsprite
PRINT "Poop Address", ~POOP
PRINT "Poop End", ~endpoop
PRINT "Tile Address", ~TILES
PRINT "Tile End", ~endtiles
PRINT "Poopos Address", ~POOPOS
PRINT "Poopos End", ~endpoopos
PRINT "Level Address", ~LEVEL