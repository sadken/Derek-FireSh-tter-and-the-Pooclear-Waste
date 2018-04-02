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
	
\Player Sprite Update Routine
.updatesprite
	LDA plyacc
	CLC 
	SBC #&01
	BPL	goingup
	LDA #LO(playerdowntab)
	STA spritetabaddr
	LDA #HI(playerdowntab)
	STA spritetabaddr+1
	JMP runspriteupdate
.goingup
	LDA #LO(playeruptab)
	STA spritetabaddr
	LDA #HI(playeruptab)
	STA spritetabaddr+1
.runspriteupdate
	LDA framecount
	BNE skipspriteupdate
	INC spritetabindex
	LDA spritetabindex
	CMP #&02
	BCC tabok
	LDA #&00
	STA spritetabindex
.tabok
	TAY
	LDA (spritetabaddr),y
	STA spriteaddr
	INY
	LDA #&20
	STA spriteaddr+1
.skipspriteupdate
	RTS

\* Sprite Drawing Routine 
.drawsprite
	JSR getaddr
	LDA spriteaddr
	STA shape
	LDA spriteaddr+1
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
	
	
\***************************
\* 		Draw Level		   *
\***************************

\Clear Level Contents
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
	DEX
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
	DEX
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
	JSR printzone
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
	LDA #&00
	STA offset
	STA offset+1
	TXA					\\sprite number is stored in X, copy to A to
	BEQ tilezero		\\check for zero sprite
	LDA #&00			\\reset sprite address offset
.loop
	LDA offset
	CLC
	ADC #&20			\\add &20 to move to next block of sprite data
	STA offset
	LDA offset+1
	ADC #&00
	STA offset+1
	DEX					\\decrease X 
	BNE loop			\\repeat until X=0
	LDA #LO(TILES)		\\16 bit addition to base sprite address
	CLC
	ADC offset
	STA currenttile
	LDA #HI(TILES)
	ADC offset+1
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

.updateradiation
{
	LDA #LO(RADSTART)
	STA addr
	LDA #HI(RADSTART)
	STA addr+1
	LDA radiation
	CMP #&10
	BCC radiationok
	LDA #&10
	STA radiation
.radiationok
	LDX #&00
.radiationloop
	LDY #00
.fillradiationcolumn
	LDA #&33
	CPX radiation
	BCC nochange
	LDA #&00
.nochange	
	STA (addr),y
	INY
	CPY #&08
	BCC fillradiationcolumn
	LDA addr
	CLC
	ADC #08
	STA addr
	LDA addr+1
	ADC #00
	STA addr+1
	INX
	CPX #&10
	BCC radiationloop
.updateradiationexit
	RTS
}
	
\setup poo positions
.poosetup
	LDA #LO(POOPOS)
	STA addr
	LDA #HI(POOPOS)
	STA addr+1
	LDA levelcount
	ASL A
	ASL A
	ASL A
	TAY
	\1st poo
	LDA (addr),y
	ASL A
	ASL A
	STA poopostab
	INY
	LDA (addr),y
	ASL A
	ASL A
	ASL A
	EOR #&FF
	STA poopostab+1
	INY
	\2nd poo
	LDA (addr),y
	ASL A
	ASL A
	STA poopostab+4
	INY
	LDA (addr),y
	ASL A
	ASL A
	ASL A
	EOR #&FF
	STA poopostab+5
	INY
	\3rd poo
	LDA (addr),y
	ASL A
	ASL A
	STA poopostab+8
	INY
	LDA (addr),y
	ASL A
	ASL A
	ASL A
	EOR #&FF
	STA poopostab+9
	INY
	\4th poo
	LDA (addr),y
	ASL A
	ASL A
	STA poopostab+12
	INY
	LDA (addr),y
	ASL A
	ASL A
	ASL A
	EOR #&FF
	STA poopostab+13
	\first poo
	LDA &00
	STA addr
	STA addr+1
	LDX poopostab
	LDY poopostab+1
	JSR getaddr
	LDA addr
	STA poopostab+2
	LDA addr+1
	STA poopostab+3
	\second poo
	LDA &00
	STA addr
	STA addr+1
	LDX poopostab+4
	LDY poopostab+5
	JSR getaddr
	LDA addr
	STA poopostab+6
	LDA addr+1
	STA poopostab+7
	\third poo
	LDA &00
	STA addr
	STA addr+1
	LDX poopostab+8
	LDY poopostab+9
	JSR getaddr
	LDA addr
	STA poopostab+10
	LDA addr+1
	STA poopostab+11
	\fourth poo
	LDA &00
	STA addr
	STA addr+1
	LDX poopostab+12
	LDY poopostab+13
	JSR getaddr
	LDA addr
	STA poopostab+14
	LDA addr+1
	STA poopostab+15
	JSR poospriteupdate
	LDA #&0F
	STA poostatus
	STA oldpoostatus
	JSR drawpoo1
	RTS

.poospriteupdate	
	INC pootabindex
	LDA pootabindex
	CMP #&04
	BCC pootabok
	LDA #&00
	STA pootabindex
.pootabok
	TAY
	LDA (pootabaddr),y
	STA poospriteaddr
	INY
	LDA #HI(POOP)
	STA poospriteaddr+1
	RTS
	
.pooupdate
	JSR poohitcheck
	LDA framecount
	BNE skippooupdate
	LDA poostatus
	PHA
	LDA oldpoostatus
	STA poostatus
	JSR drawpoo1
	JSR poospriteupdate
	PLA
	STA poostatus
	JSR drawpoo1
	LDA poostatus
	STA oldpoostatus
	JSR printpooclear
.skippooupdate
	RTS
	
.drawpoo1
	LDA poostatus
	AND #&01
	BEQ drawpoo2
	LDA poospriteaddr
	STA shape
	LDA poospriteaddr+1
	STA shape+1
	LDA #&04
	STA counter
	LDA #&08
	STA depth
	LDA poopostab+2
	STA addr
	LDA poopostab+3
	STA addr+1
	JSR doplot
.drawpoo2
	LDA poostatus
	AND #&02
	BEQ drawpoo3
	LDA poospriteaddr
	STA shape
	LDA poospriteaddr+1
	STA shape+1
	LDA #&04
	STA counter
	LDA #&08
	STA depth
	LDA poopostab+6
	STA addr
	LDA poopostab+7
	STA addr+1
	JSR doplot
.drawpoo3
	LDA poostatus
	AND #&04
	BEQ drawpoo4
	LDA poospriteaddr
	STA shape
	LDA poospriteaddr+1
	STA shape+1
	LDA #&04
	STA counter
	LDA #&08
	STA depth
	LDA poopostab+10
	STA addr
	LDA poopostab+11
	STA addr+1
	JSR doplot
.drawpoo4
	LDA poostatus
	AND #&08
	BEQ skippoo
	LDA poospriteaddr
	STA shape
	LDA poospriteaddr+1
	STA shape+1
	LDA #&04
	STA counter
	LDA #&08
	STA depth
	LDA poopostab+14
	STA addr
	LDA poopostab+15
	STA addr+1
	JSR doplot
.skippoo
	RTS
	
\Print Level Number
.printzone 
{
	LDX #&09
	LDY #&02
	JSR movecursor
	LDA #&30
	STA temp
	LDA zonecount
	AND #&F0
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC temp
	STA zonetext
	LDA #&30 
	STA temp
	LDA zonecount
	AND #&0F
	CLC
	ADC temp
	STA zonetext+1
.outputtext
	LDA zonetext
	JSR OSWRCH
	LDA zonetext+1
	JSR OSWRCH
	RTS
}

.printzoneold
{
	LDX #&09
	LDY #&02
	JSR movecursor
	LDA #&30
	STA temp
	LDA levelcount
	AND #&F0
	LSR A
	LSR A
	LSR A
	LSR A
	CMP #&0A
	BCC lessthan
	LDA #&41
	STA temp
.lessthan
	CLC
	ADC temp
	STA zonetext
	LDA #&30 
	STA temp
	LDA levelcount
	AND #&0F
	CMP #&0A
	BCC lessthan2
	LDA #&41
	STA temp
.lessthan2
	CLC
	ADC temp
	STA zonetext+1
.outputtext
	LDA zonetext
	JSR OSWRCH
	LDA zonetext+1
	JSR OSWRCH
	RTS
}

\13 & 14 pooclear waste
.printpooclear
{
	LDX #&0D
	LDY #&02
	JSR movecursor
	LDA #&30
	STA temp
	LDA poocount
	AND #&F0
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC temp
	STA zonetext
	LDA #&30 
	STA temp
	LDA poocount
	AND #&0F
	CLC
	ADC temp
	STA zonetext+1
.outputtext
	LDA zonetext
	JSR OSWRCH
	LDA zonetext+1
	JSR OSWRCH
	RTS
}

.movecursor
	LDA #31
	JSR OSWRCH
	TXA
	JSR OSWRCH
	TYA
	JSR OSWRCH
	RTS
	
\Sprite Tables

.playeruptab
	EQUB	LO(SPRITE)
	EQUB	LO(SPRITE+&20)
.playerdowntab
	EQUB	LO(SPRITE+&40)
	EQUB	LO(SPRITE+&60)
.playerdietab
	EQUB	LO(SPRITE+&80)
	EQUB	LO(SPRITE+&A0)
	EQUB	LO(SPRITE+&C0)
	EQUB	LO(SPRITE+&E0)
.pootab
	EQUB	LO(POOP)
	EQUB 	LO(POOP+&20)
	EQUB 	LO(POOP+&40)
	EQUB	LO(POOP+&60)
.poopostab
	EQUB	&12, &20
	EQUB	&00, &00
	EQUB	&30, &60
	EQUB	&00, &00
	EQUB	&30, &A0
	EQUB	&00, &00
	EQUB	&15, &60
	EQUB	&00, &00
