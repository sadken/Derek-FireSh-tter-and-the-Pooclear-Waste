.startscreen
{
	LDA #00
	STA note
	JSR initmusicirq
	JSR clearlevel
	JSR printtitletext
	JSR printkeys
	JSR printrestart
	JSR initanim
	JSR animdraw
.startloop
	JSR playmusic
	JSR vsync
	JSR animdraw
	JSR updateanim
	JSR animdraw
	JSR checkspace
	CPX #&00
	BEQ startloop
	JSR clearlevel
	JSR initgame
	JSR drawlevel
	JSR poosetup
	JSR startplay
	RTS 
}

.printtitletext
	\line 1
	LDX #&01
	LDY #&06
	JSR movecursor
	LDX #&00
.titletext1loop
	LDA titletext1,X
	JSR OSWRCH
	INX
	CPX #&12
	BCC titletext1loop
	\line 2
	LDX #&06
	LDY #&08
	JSR movecursor
	LDX #&00
.titletext2loop
	LDA titletext2,X
	JSR OSWRCH
	INX
	CPX #&07
	BCC titletext2loop
	\line 3
	LDX #&03
	LDY #&0A
	JSR movecursor
	LDX #&00
.titletext3loop
	LDA titletext3,X
	JSR OSWRCH
	INX
	CPX #&0E
	BCC titletext3loop
	RTS

.titletext1
EQUS "Derek Flameshitter"	\18 chars

.titletext2
EQUS "and the"				\7 chars

.titletext3
EQUS "Pooclear Waste"		\14 chars

