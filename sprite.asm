\* XY acurate sprite drawing. 
\* Mode 2 resolution
\* TEXT - 20 x 32
\* Graphics - 160 x 256
\* level 5 bytes of 14 rows
\* which gives 10 x 2 char blocks by 14 x 2 char blocks
\* 4 char rows blank at the top for score etc (32 pixels)
\* Level covers 160 pixels x 112 pixels
\* To calculate Y char = (y SHR 3) - 4
\* To Calculate X char = x SHR 3
\* AND x char with &01 If 0 check High nibble, if 1 check Low nibble of x shr 1



OSBYTE = &FFF4
OSWORD = &FFF1
OSWRCH = &FFEE
SPRITE = &2000
TILES = &2100
LEVEL = &2200
SCREEN = &3000
MAXTILE = &04
STARTX = &0A
STARTY = &C8
STARTACC = &02
STARTVEL = &00


ORG &0070
.addr			SKIP 2
.addrtemp		SKIP 2
.temp			SKIP 1
.temp2			SKIP 1
.depth			SKIP 1
.offset			SKIP 1
.leveltemp		SKIP 2	
.rowcounter		SKIP 1
.shape			SKIP 2
.counter		SKIP 1
.xpos			SKIP 1
.ypos			SKIP 1
.oxpos			SKIP 1
.oypos			SKIP 1
.restartx		SKIP 1
.plyacc			SKIP 1
.plyvel			SKIP 1
.currenttile	SKIP 2
.levelpos		SKIP 1
.leveladdr		SKIP 2
.tilecolumn		SKIP 1
.collision		SKIP 1
.colloffset		SKIP 1
.framecount		SKIP 1
.sysirq			SKIP 2
.time			SKIP 1

org &1100
.START
.init
	\SEI
	\LDA &204
	\STA sysirq
	\LDA &205
	\STA sysirq+1
	\LDA #LO(irq)
	\STA &204
	\LDA #HI(irq)
	\STA &205
	\LDA #&08
	\STA time
	CLI
	JSR initscreen
	JSR clearlevel
	JSR initgame
	JSR drawlevel
.gameloop
	LDA xpos
	STA oxpos
	LDA ypos
	STA oypos
	INC framecount
	LDA framecount
	CMP #&03
	BNE skipupdate
	JSR updateplayer
	LDA #00
	STA framecount
.skipupdate
	JSR checkkeys
	JSR checkhit
	LDA collision
	BNE	playerdead
.redraw
	JSR vsync
	LDX oxpos
	LDY oypos
	JSR drawsprite
	LDX xpos
	LDY ypos
	JSR drawsprite	
	LDA ypos
	CMP #&0A
	BEQ bottomlevelexit
	JMP gameloop
.bottomlevelexit
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
	JSR restartlevel
	JMP gameloop
	
.restartlevel
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
	
.playerdead
	JSR dienoise
	LDA restartx
	STA xpos
	JSR restartlevel
	JMP gameloop

.checkhit
	LDA #00
	STA collision
	LDX xpos	
	LDY ypos
	JSR collisiondetect
	LDA xpos
	CLC
	ADC #&03
	TAX
	LDY ypos
	JSR collisiondetect
	LDX	xpos
	LDA ypos
	SEC
	SBC #&07
	TAY
	JSR collisiondetect
	LDA xpos
	CLC
	ADC #&03
	TAX
	LDA ypos
	SEC
	SBC #&07
	TAY
	JSR collisiondetect
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
	RTS

	\* Sprite Drawing Routine 
.erasesprite
	JSR getaddr
	LDA #LO(SPRITE)
	STA shape
	LDA #HI(SPRITE)
	STA shape+1
	LDA #&20
	STA counter
	LDA #&08
	STA depth
	JSR doplot
	RTS
\* Sprite Drawing Routine 
.drawsprite
	JSR getaddr
	LDA #LO(SPRITE)
	STA shape
	LDA #HI(SPRITE)
	STA shape+1
	LDA #&04
	STA counter
	LDA #&08
	STA depth
	JSR doplot
	RTS
\* Calculate start address for sprite
.getaddr
	LDA #&00
	STA addr+1
	TYA
	EOR #&FF
	PHA
	LSR A
	LSR A
	LSR A
	TAY
	LSR A
	STA temp
	LDA #&00
	ROR A
	ADC #LO(SCREEN)
	PHP
	STA addr
	TYA
	ASL A
	ADC temp
	PLP
	ADC #HI(SCREEN)
	STA addr+1
	LDA #&00
	STA temp
	TXA
	ASL A
	ROL temp
	ASL A
	ROL temp
	ASL A
	ROL temp
	ADC addr
	STA addr
	LDA temp
	ADC addr+1
	BPL ok
	SEC
	SBC #&50
.ok
	STA addr+1
	PLA
	AND #&07
	ORA addr
	STA addr
	RTS
\* Sprite Plotting Routine	
.doplot
	LDY #&00
	LDA addr+1
	PHA
	LDA addr
	PHA
	LDA depth
	STA rowcounter
	LDA addr
	AND #&07
	STA offset
	LDA addr
	AND #&F8
	STA addr
	STY temp
.innerloop
	LDY temp
	LDA (shape), Y
	INY
	STY temp
	LDY offset
	EOR (addr), Y
	STA (addr), Y
	INY
	CPY #&08
	BEQ block
.noblock
	STY offset
	DEC rowcounter
	BNE innerloop
.nextblock
	LDA shape
	CLC
	ADC depth
	STA shape
	BCC nohi
	INC shape+1
.nohi
	CLC
	PLA
	ADC #&08
	STA addr
	PLA
	ADC #&00
	BPL nobound1
	SEC
	SBC #&50
.nobound1
	STA addr+1
	DEC counter
	BNE doplot
	RTS
.block
	LDY #&00
	LDA addr
	CLC
	ADC #&80
	STA addr
	LDA addr+1
	ADC #&02
	BPL noboundary
	SEC
	SBC #&50
.noboundary
	STA addr+1
	BNE noblock
	
\* VSYNC Routine
.vsync
	LDA #&13
	JSR OSBYTE	
	RTS
	
\***************************
\* 		Draw Level		*
\***************************
.clearlevel
	LDY #&00
	LDA #LO(SCREEN+2560)
	STA addr
	LDA #HI(SCREEN+2560)
	STA addr+1
.clearloop
	LDA #&00
	STA (addr),Y
	INY
	CPY #32
	BNE clearloop
	LDY #&00
	CLC
	LDA addr
	ADC #32
	STA addr
	LDA addr+1
	ADC #&00
	STA addr+1
	CMP #&80
	BNE clearloop
	RTS
	
.drawlevel
	LDY #&00			\\reset registers
	LDX #&00
	LDA #&00
	STA levelpos		\\reset to first tile of level
	LDX levelpos		\\load first level byte
	LDA #LO(SCREEN+2560)		\\reset screen address (Low Byte)
	STA addr
	LDA #HI(SCREEN+2560)		\\reset screen address (high byte)
	STA addr+1
	LDY #&00 
	LDA #&00
	STA tilecolumn		\\reset tile column count
.levelloop
	STY levelpos		\\load level position
	LDA (leveltemp),Y		\\load byte from level table at levelpos
	AND #&F0			\\mask high nibble
	LSR A	
	LSR A
	LSR A
	LSR A				\\shift right 4 bits
	BNE drawblock1		\\check for non zero tile, and draw 4 tiles if not blank (4 copies of read tile to reduce level memory)
	JSR nexttile		\\skip forward 2 tiles (to compensate for non drawn tiles)
	JSR nexttile
	JMP startblock2		\\skip block drawing
.drawblock1
	TAX					\\move tile number to X
	JSR settileaddr		\\calculate sprite address 
	JSR drawtile		\\draw 2 vertical tiles
	JSR nexttile
	JSR drawtile		\\repeat 2 vertical tiles
	JSR nexttile
.startblock2
	LDY levelpos		\\re-load level position
	LDA (leveltemp),Y			\\grab tile byte
	AND #&0F			\\mask low nibble
	BNE drawblock2		\\check for zero tile
	JSR nexttile		\\skip forward 2 tiles (to compensate for non drawn tiles)
	JSR nexttile
	JMP finishtile		\\skip block drawing
.drawblock2
	TAX					\\move tile number to X
	JSR settileaddr		\\calculate sprite address
	JSR drawtile		\\draw 2 vertical blocks
	JSR nexttile
	JSR drawtile		\\repeat 2 vertical tiles
	JSR nexttile
.finishtile
	LDY tilecolumn		\\load tile column count
	INY
	INY					\\+2 (for each set of tiles)
	STY tilecolumn		\\save tile column count for later
	CPY #&0A			\\check for complete row
	BNE nojump			\\move on to next level position if not
	LDA addr			\\Move down 2 rows by running a 16 bit addition of &280 to the current screen writing address - load low byte
	CLC					\\clear carry for 16 bit addition
	ADC #&80			
	STA addr
	LDA addr+1			\\load high byte
	ADC #&02			\\add &05 to high byte (and any carry)
	STA addr+1			\\store number
	LDA #&00			\\reset tile column
	STA tilecolumn		
.nojump
	LDY levelpos		\\move to next level byte
	INY
	CPY #&46			\\check for end of level data
	BNE levelloop		\\loop if not done drawing
	RTS
.drawtile				\\tile drawing routine
	LDA addr			\\load low byte of screen address into A
	CLC
	ADC #&80			\\add &280 to give us the address of the row below
	STA addrtemp
	LDA addr+1
	ADC #&02
	STA addrtemp+1
	LDY #&00
.tileloop
	LDA (currenttile),Y	\\load in sprite data
	STA (addr),Y		\\store sprite byte in screen memory
	STA (addrtemp),Y	\\store again in character below
	INY
	CPY #&20			\\check for &20 bytes
	BNE tileloop		\\repeat until all sprite data is written to memory
	RTS
.settileaddr
	TXA					\\sprite number is stored in X, copy to A to
	BEQ tilezero		\\check for zero sprite
	LDA #&00			\\reset sprite address offset
.loop
	ADC #&20			\\add &20 to move to next block of sprite data
	DEX					\\decrease X 
	BNE loop			\\repeat until X=0
	STA offset			\\store offset
	LDA #LO(TILES)		\\16 bit addition to base sprite address
	CLC
	ADC offset
	STA currenttile
	LDA #HI(TILES)
	ADC #&00
	STA currenttile+1
	RTS					\\future change - increase offset to a 16 bit number to allow more than 7 sprites per base address
.tilezero
	LDA #LO(TILES)		\\if spritenumber = 0 then set to base sprite address
	STA currenttile
	LDA #HI(TILES)
	STA currenttile+1
	RTS
.nexttile
	LDA addr			\\add &20 to address to move forward one character block
	CLC
	ADC #&20
	STA addr
	LDA addr+1
	ADC #&00
	STA addr+1
	RTS	

\\sound playing routine 
.dienoise
	LDA #&34
	STA diesnd+4
	LDA #&08
	STA temp
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
	DEC temp
	LDA temp
	BNE dienoiseloop
	RTS
	
.thrustnoise
	LDX #LO(thrustsnd)
	LDY #HI(thrustsnd)
	LDA #&07
	JSR OSWORD
	RTS

.levelnoise
	LDA #&34
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
	LDA #&17
	STA levelsnd+4
	LDX #LO(levelsnd)
	LDY #HI(levelsnd)
	LDA #&07
	JSR OSWORD
	RTS
	
\* Level covers 160 pixels x 112 pixels
\* To calculate Y char = (y SHR 3) - 4
\* To Calculate X char = x SHR 3
\* AND x char with &01 If 0 check High nibble, if 1 check Low nibble of x shr 1
\* X reg and Y reg hold X,Y position
\* 
.collisiondetect
	LDA #00
	STA temp			\\Clear Temp var
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
.finishcollision
	BEQ nocollision
	INC collision
.nocollision
	RTS
	
\* initialise screen 	
.initscreen
	LDA #22
	JSR OSWRCH
	LDA #02		
	JSR OSWRCH		\\Set Mode 2
	LDA #23
	JSR OSWRCH
	LDA #01
	JSR OSWRCH
	LDA #00
	JSR OSWRCH
	JSR OSWRCH
	JSR OSWRCH
	JSR OSWRCH
	JSR OSWRCH
	JSR OSWRCH
	JSR OSWRCH
	JSR OSWRCH
	RTS
	
.initgame
	LDA #00
	STA framecount
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
	
.irq
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
	JSR updateplayer
	LDA #&08
	STA time
	JMP exit
	
.diesnd
	EQUB	&01, &00		\\Channel	1
	EQUB 	&F1, &FF		\\Amplitude	-15
	EQUB	&34, &00		\\Pitch	52
	EQUB	&01, &00		\\Duration 1
	
.thrustsnd
	EQUB	&10, &00		\\Channel 16
	EQUB 	&F1, &FF		\\Amplitude -15
	EQUB	&06, &00		\\Pitch 800
	EQUB	&03, &00		\\Duration 1
	
.levelsnd
	EQUB	&03, &00		\\Channel 3
	EQUB 	&F1, &FF		\\Amplitude -15
	EQUB	&06, &00		\\Pitch 800
	EQUB	&01, &00		\\Duration 1
	
org SPRITE
INCBIN ".\sprites\ship.bin"			\\sprite data
	
ORG TILES
INCBIN ".\sprites\wall.bin"		\\sprite data

ORG LEVEL
INCBIN ".\levels\level1.bin"	\\level data
	
.END

SAVE "CODE" , START, END 

PUTBASIC "loader.bas", "LOADER"

PRINT "Start Address", ~START
PRINT "Tile Address", ~TILES
PRINT "Level Address", ~LEVEL
PRINT "Sprite Address", ~SPRITE
PRINT "End Address", ~END