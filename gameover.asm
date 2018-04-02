
.gameover
{
	LDA #00
	STA note
	JSR initmusicirq
	JSR stopplay
	JSR clearlevel
	JSR printtitletext
	JSR printgameover
	JSR printkeys
	JSR printrestart
	JSR initanim
	JSR animdraw
.gameoverloop
	JSR playmusic
	JSR vsync
	JSR animdraw
	JSR updateanim
	JSR animdraw
	JSR checkspace
	CPX #&00
	BEQ gameoverloop
	JSR clearlevel
	JSR initgame
	JSR drawlevel
	JSR poosetup
	JSR startplay
	JSR initgameirq
	JMP gameloop
}
	
.printgameover
	LDX #&05
	LDY #&10
	JSR movecursor
	LDX #&00
.gotextloop
	LDA gameovertext,X
	JSR OSWRCH
	INX
	CPX #&09
	BCC gotextloop
	RTS
	
.printrestart
	LDX #&04
	LDY #&1D
	JSR movecursor
	LDX #&00
.restarttext1loop
	LDA pressspacetext,X
	JSR OSWRCH
	INX
	CPX #&0B
	BCC restarttext1loop
	RTS
	
.printkeys
	\line1
	LDX #&01
	LDY #&19
	JSR movecursor
	LDX #&00
.keytext1loop
	LDA keytext,X
	JSR OSWRCH
	INX
	CPX #&12
	BCC keytext1loop
	\line2
	LDX #&04
	LDY #&1B
	JSR movecursor
	LDX #&00
.keytext2loop
	LDA keytext2,X
	JSR OSWRCH
	INX
	CPX #&0B
	BCC keytext2loop
	RTS
	
.checkspace
	LDX #&9D
	LDY #&FF
	LDA #&81
	JSR OSBYTE
	RTS

.gameovertext	
EQUS "GAMEOVER!"

.keytext
EQUS "Z - LEFT X - RIGHT"
.keytext2
EQUS "* -  THRUST"

.pressspacetext
EQUS "PRESS SPACE" \11	x = 5



