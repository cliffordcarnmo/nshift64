	rasterline1 = 0
	rasterline2 = 118

	!address{
		characterindex = $64
		rowindex = $65
		cursorcolorindex = $66
		delayindex = $67
		colormempointer = $80
		screenmempointer = $82
		textcolorpointer = $84
		textpointer = $86
		screenmem = $0400
		textscreenmem = screenmem + 10 * 40
		line1 = screenmem + 9 * 40
		line2 = screenmem + 24 * 40
		sid = $1000
		sidplay = $1003
		logobitmap = $2000
		logocolors = $3000
		logoscreen = $33eb
		charset = $3800
		sprites = $3e00
		textcolors = $4000
		linecolors = $4281
		cursorcolors = $42aa
		spriteposx = $4310
		spriteposy = $4320
		spritespeed = $4330
		text = $4440
		spritesposmem = $d000
		colormem = $d800
		line1colormem = colormem + 9 * 40
		line2colormem = colormem + 24 * 40
		textcolormem = $d990
	}

	*= $0801

	jsr $e544

	lda #$00
	sta $d020
	sta $d021

	lda #$7f
	sta delayindex

	jsr sid
	jsr initsprites
	jsr setspritepointers
	jsr resetpointers

logo:
	ldx #$00
-
	lda logocolors,x
	sta colormem,x

	lda logoscreen,x
	sta screenmem,x

	inx
	;cpx #$ff
	bne -

	ldx #$00
-
	lda logocolors + 256,x
	sta colormem + 256,x

	lda logoscreen + 256,x
	sta screenmem + 256,x

	inx
	cpx #$40
	bne -

horizontallines:
	ldx #$00
-
	lda #$63
	sta line1,x
	sta line2,x

	inx
	cpx #40
	bne -

main:
	sei

	lda #%00110101
	sta $01

	lda #%01111111
	sta $dc0d
	sta $dd0d

	lda #%00000001
	sta $d01a

	lda #rasterline1
	sta $d012

	lda #<gfxirq 
	sta $fffe
	lda #>gfxirq
	sta $ffff

	cli

	jmp *

initsprites:
	lda #%11111111
	sta $d015
	sta $d01b

	lda #%00000000
	sta $d017
	sta $d01c
	sta $d01d

	lda #$0c
	sta $d027

	lda #$0b
	sta $d028

	lda #$01
	sta $d029

	lda #$0c
	sta $d02a

	lda #$01
	sta $d02b

	lda #$0c
	sta $d02c

	lda #$0c
	sta $d02d

	lda #$0b
	sta $d02e
	rts

gfxirq:
	asl $d019

	jsr sidplay
	jsr starfield

	lda #%00111011
	sta $d011

	lda #%00011000
	sta $d016

	lda #%00011110
	sta $d018

	lda #rasterline2
	sta $d012

	lda #<txtirq
	sta $fffe
	lda #>txtirq
	sta $ffff
	rti

txtirq:
	asl $d019

	lda #%11001000
	sta $d016

	lda #%00011011
	sta $d011

	lda #%00011110
	sta $d018

	jsr colorcycle
	jsr textwriter

	lda #rasterline1
	sta $d012

	lda #<gfxirq
	sta $fffe
	lda #>gfxirq
	sta $ffff
	rti

starfield:
	ldx #$00
-
	lda spriteposy,x
	sta spritesposmem + 1,x

	lda spriteposx,x
	asl
	ror $d010
	sta spritesposmem,x

	lda spriteposx,x
	clc
	sbc spritespeed,x
	sta spriteposx,x

	inx
	inx
	cpx #$10
	bne -
	rts

colorcycle:
	lda linecolors
	sta linecolors + 40

	ldx #$00
-	lda linecolors + 1,x
	sta linecolors,x
	sta line1colormem,x
	sta line2colormem,x

	inx
	cpx #40
	bne -
	rts

textwriter:
	lda cursorcolorindex
	cmp #19
	beq resetcursorcolor

	inc cursorcolorindex

	lda delayindex
	cmp #$00
	beq dotext
	bcs pause
	rts

pause:
	jsr writecursor

	dec delayindex

	lda delayindex
	cmp #$00
	beq clearscreen
	rts

clearscreen:
	lda #$20
	ldx #$00
-
	sta textscreenmem,x
	sta textscreenmem + 255,x

	inx
	;cpx #$ff
	bne -

	ldx #$00
-
	sta textscreenmem + 255 * 2,x

	inx
	cpx #50
	bne -

	jsr clearindices
	jsr setcolorpointer
	jsr settextcolorpointer
	jsr setscreenpointer
	rts

dotext:
	jsr writecharacter
	jsr writecursor
	rts

resetcursorcolor:
	lda #$00
	sta cursorcolorindex
	rts

writecursor:
	ldx cursorcolorindex
	ldy characterindex
	lda cursorcolors,x
	sta (colormempointer),y

	lda #$7f
	sta (screenmempointer),y
	rts

writecharacter:
	ldy characterindex
	lda (textcolorpointer),y
	sta (colormempointer),y

	lda (textpointer),y
	cmp #$ff
	beq resetpointers

	sta (screenmempointer),y

	cpy #39
	beq nextrow

	inc characterindex
	rts

pushoffsets:
	clc

	lda colormempointer
	adc #40
	sta colormempointer
	lda colormempointer + 1
	adc #$00
	sta colormempointer + 1

	lda textcolorpointer
	adc #40
	sta textcolorpointer
	lda textcolorpointer + 1
	adc #$00
	sta textcolorpointer + 1

	lda screenmempointer
	adc #40
	sta screenmempointer
	lda screenmempointer + 1
	adc #$00
	sta screenmempointer + 1
	rts

pushoffsets2:
	clc

	lda textpointer
	adc #40
	sta textpointer
	lda textpointer + 1
	adc #$00
	sta textpointer + 1
	rts

nextrow:
	jsr pushoffsets2

	lda rowindex
	cmp #12
	beq nextscreen

	jsr pushoffsets

	lda #$00
	sta characterindex

	inc rowindex
	rts

nextscreen:
	lda #$ff
	sta delayindex
	rts

resetpointers:
	jsr clearindices
	jsr setcolorpointer
	jsr setscreenpointer
	jsr settextcolorpointer
	jsr settextpointer
	rts

clearindices:
	lda #$00
	sta characterindex
	sta rowindex
	sta cursorcolorindex
	rts

setcolorpointer:
	lda #<textcolormem
	sta colormempointer
	lda #>textcolormem
	sta colormempointer + 1
	rts

setscreenpointer:
	lda #<textscreenmem
	sta screenmempointer
	lda #>textscreenmem
	sta screenmempointer + 1
	rts

settextcolorpointer:
	lda #<textcolors
	sta textcolorpointer
	lda #>textcolors
	sta textcolorpointer + 1
	rts

settextpointer:
	lda #<text
	sta textpointer
	lda #>text
	sta textpointer + 1
	rts

setspritepointers:
	lda #$f8
	sta $07f8
	lda #$f9
	sta $07f9
	lda #$fa
	sta $07fa
	lda #$f8
	sta $07fb
	lda #$f9
	sta $07fc
	lda #$fa
	sta $07fd
	lda #$f8
	sta $07fe
	lda #$f9
	sta $07ff
	rts

	*= sid
	!binary "data/Glitter_in_the_Dark.sid",,$7e

	*= logobitmap
	!binary "data/logo.kla",2590,2

	*= logoscreen
	!binary "data/logo.kla",320,8002

	*= logocolors
	!binary "data/logo.kla",320,9002

	*= charset
	!byte $3c,$66,$6e,$6e,$60,$62,$3c,$00,$3e,$03,$7f,$63,$3f,$00,$00,$00
	!byte $60,$7e,$63,$63,$7f,$00,$00,$00,$1f,$30,$60,$60,$7f,$00,$00,$00
	!byte $03,$3f,$63,$63,$7f,$00,$00,$00,$3e,$63,$7f,$60,$7c,$00,$00,$00
	!byte $3f,$60,$7e,$60,$60,$00,$00,$00,$3f,$63,$63,$63,$3f,$03,$7e,$00
	!byte $60,$7e,$63,$63,$63,$00,$00,$00,$18,$00,$18,$18,$18,$00,$00,$00
	!byte $0c,$0c,$0c,$0c,$0c,$0c,$f8,$00,$63,$63,$7e,$63,$63,$00,$00,$00
	!byte $60,$60,$60,$60,$3f,$00,$00,$00,$7e,$6b,$6b,$63,$63,$00,$00,$00
	!byte $7c,$66,$63,$63,$63,$00,$00,$00,$7e,$63,$63,$63,$3f,$00,$00,$00
	!byte $3f,$63,$63,$63,$7f,$60,$60,$00,$7f,$63,$63,$67,$7f,$00,$00,$00
	!byte $7e,$63,$63,$7e,$63,$00,$00,$00,$3f,$60,$7f,$03,$7e,$00,$00,$00
	!byte $30,$3e,$30,$30,$1f,$00,$00,$00,$63,$63,$63,$63,$3f,$00,$00,$00
	!byte $63,$63,$63,$36,$1c,$00,$00,$00,$63,$63,$6b,$6b,$3f,$00,$00,$00
	!byte $63,$63,$3e,$63,$63,$00,$00,$00,$63,$63,$63,$63,$3f,$03,$7e,$00
	!byte $7f,$03,$7f,$60,$7f,$00,$00,$00,$3c,$30,$30,$30,$30,$30,$3c,$00
	!byte $0c,$12,$30,$7c,$30,$62,$fc,$00,$3c,$0c,$0c,$0c,$0c,$0c,$3c,$00
	!byte $00,$18,$3c,$7e,$18,$18,$18,$18,$00,$10,$30,$7f,$7f,$30,$10,$00
	!byte $00,$00,$00,$00,$00,$00,$00,$00,$18,$18,$18,$18,$00,$00,$18,$00
	!byte $66,$66,$66,$00,$00,$00,$00,$00,$66,$66,$ff,$66,$ff,$66,$66,$00
	!byte $18,$3e,$60,$3c,$06,$7c,$18,$00,$62,$66,$0c,$18,$30,$66,$46,$00
	!byte $3c,$66,$3c,$38,$67,$66,$3f,$00,$06,$0c,$18,$00,$00,$00,$00,$00
	!byte $0c,$18,$30,$30,$30,$18,$0c,$00,$30,$18,$0c,$0c,$0c,$18,$30,$00
	!byte $00,$66,$3c,$ff,$3c,$66,$00,$00,$00,$18,$18,$7e,$18,$18,$00,$00
	!byte $00,$00,$00,$00,$00,$18,$18,$30,$00,$00,$00,$7e,$00,$00,$00,$00
	!byte $00,$00,$00,$18,$18,$00,$00,$00,$00,$03,$06,$0c,$18,$30,$60,$00
	!byte $3e,$63,$6b,$63,$3e,$00,$00,$00,$38,$18,$18,$18,$3c,$00,$00,$00
	!byte $7e,$03,$7f,$60,$7f,$00,$00,$00,$7e,$03,$7f,$03,$7f,$00,$00,$00
	!byte $63,$63,$63,$7f,$03,$00,$00,$00,$7f,$60,$7f,$03,$7f,$00,$00,$00
	!byte $3e,$60,$7f,$63,$7e,$00,$00,$00,$7e,$03,$1f,$03,$03,$00,$00,$00
	!byte $3f,$63,$7f,$63,$7e,$00,$00,$00,$7e,$63,$63,$7f,$03,$00,$00,$00
	!byte $00,$00,$18,$00,$00,$18,$00,$00,$00,$00,$18,$00,$00,$18,$18,$30
	!byte $0e,$18,$30,$60,$30,$18,$0e,$00,$00,$00,$7e,$00,$7e,$00,$00,$00
	!byte $70,$18,$0c,$06,$0c,$18,$70,$00,$3c,$66,$06,$0c,$18,$00,$18,$00
	!byte $00,$00,$00,$ff,$ff,$00,$00,$00,$08,$1c,$3e,$7f,$7f,$1c,$3e,$00
	!byte $18,$18,$18,$18,$18,$18,$18,$18,$00,$00,$00,$ff,$ff,$00,$00,$00
	!byte $00,$00,$ff,$ff,$00,$00,$00,$00,$00,$ff,$ff,$00,$00,$00,$00,$00
	!byte $00,$00,$00,$00,$ff,$ff,$00,$00,$30,$30,$30,$30,$30,$30,$30,$30
	!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$00,$00,$00,$e0,$f0,$38,$18,$18
	!byte $18,$18,$1c,$0f,$07,$00,$00,$00,$18,$18,$38,$f0,$e0,$00,$00,$00
	!byte $c0,$c0,$c0,$c0,$c0,$c0,$ff,$ff,$c0,$e0,$70,$38,$1c,$0e,$07,$03
	!byte $03,$07,$0e,$1c,$38,$70,$e0,$c0,$ff,$ff,$c0,$c0,$c0,$c0,$c0,$c0
	!byte $ff,$ff,$03,$03,$03,$03,$03,$03,$00,$3c,$7e,$7e,$7e,$7e,$3c,$00
	!byte $00,$00,$00,$00,$00,$ff,$ff,$00,$36,$7f,$7f,$7f,$3e,$1c,$08,$00
	!byte $60,$60,$60,$60,$60,$60,$60,$60,$00,$00,$00,$07,$0f,$1c,$18,$18
	!byte $c3,$e7,$7e,$3c,$3c,$7e,$e7,$c3,$00,$3c,$7e,$66,$66,$7e,$3c,$00
	!byte $18,$18,$66,$66,$18,$18,$3c,$00,$06,$06,$06,$06,$06,$06,$06,$06
	!byte $08,$1c,$3e,$7f,$3e,$1c,$08,$00,$18,$18,$18,$ff,$ff,$18,$18,$18
	!byte $c0,$c0,$30,$30,$c0,$c0,$30,$30,$18,$18,$18,$18,$18,$18,$18,$18
	!byte $00,$00,$03,$3e,$76,$36,$36,$00,$ff,$7f,$3f,$1f,$0f,$07,$03,$01
	!byte $00,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	!byte $00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00
	!byte $00,$00,$00,$00,$00,$00,$00,$ff,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
	!byte $cc,$cc,$33,$33,$cc,$cc,$33,$33,$03,$03,$03,$03,$03,$03,$03,$03
	!byte $00,$00,$00,$00,$cc,$cc,$33,$33,$ff,$fe,$fc,$f8,$f0,$e0,$c0,$80
	!byte $03,$03,$03,$03,$03,$03,$03,$03,$18,$18,$18,$1f,$1f,$18,$18,$18
	!byte $00,$00,$00,$00,$0f,$0f,$0f,$0f,$18,$18,$18,$1f,$1f,$00,$00,$00
	!byte $00,$00,$00,$f8,$f8,$18,$18,$18,$00,$00,$00,$00,$00,$00,$ff,$ff
	!byte $00,$00,$00,$1f,$1f,$18,$18,$18,$18,$18,$18,$ff,$ff,$00,$00,$00
	!byte $00,$00,$00,$ff,$ff,$18,$18,$18,$18,$18,$18,$f8,$f8,$18,$18,$18
	!byte $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
	!byte $07,$07,$07,$07,$07,$07,$07,$07,$ff,$ff,$00,$00,$00,$00,$00,$00
	!byte $ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff
	!byte $03,$03,$03,$03,$03,$03,$ff,$ff,$00,$00,$00,$00,$f0,$f0,$f0,$f0
	!byte $0f,$0f,$0f,$0f,$00,$00,$00,$00,$18,$18,$18,$f8,$f8,$00,$00,$00
	!byte $f0,$f0,$f0,$f0,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$00,$00,$00

	*= sprites
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00011000,%00000000
	!byte %00000000,%00011000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000

	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00010000,%00000000
	!byte %00000000,%00111000,%00000000
	!byte %00000000,%00010000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000

	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00010000,%00000000
	!byte %00000000,%00101000,%00000000
	!byte %00000000,%00010000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000
	!byte %00000000,%00000000,%00000000

	*= textcolors
	!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
	!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	!byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
	!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b

	*= linecolors
	!byte $0b,$0b,$0b,$0b,$0c,$0c,$0c,$0c,$0f,$0f,$05,$05,$07,$07,$03,$03,$01,$01,$01,$01,$01,$01,$01,$01,$03,$03,$07,$07,$05,$05,$0f,$0f,$0c,$0c,$0c,$0c,$0b,$0b,$0b,$0b

	*= cursorcolors
	!byte $00,$00,$0b,$02,$02,$04,$04,$0a,$0a,$0a,$0a,$0a,$0a,$04,$04,$02,$02,$0b,$00,$00

*= spriteposx
	!byte 30
	!byte $00
	!byte 60
	!byte $00
	!byte 90
	!byte $00
	!byte 120
	!byte $00
	!byte 150
	!byte $00
	!byte 180
	!byte $00
	!byte 210
	!byte $00
	!byte 240

*= spriteposy
	!byte 130
	!byte $00
	!byte 150
	!byte $00
	!byte 165
	!byte $00
	!byte 180
	!byte $00
	!byte 195
	!byte $00
	!byte 200
	!byte $00
	!byte 210
	!byte $00
	!byte 220

*= spritespeed
	!byte $01
	!byte $00
	!byte $00
	!byte $00
	!byte $03
	!byte $00
	!byte $01
	!byte $00
	!byte $02
	!byte $00
	!byte $01
	!byte $00
	!byte $01
	!byte $00
	!byte $00

	*= text
	!scr "                                        "
	!scr "        speed up, costs down            "
	!scr "        --------------------            "
	!scr "                                        "
	!scr "  save your business time and money by  "
	!scr "    automating the shipping process.    "
	!scr "                                        "
	!scr "        no more hours wasted.           "
	!scr "       no more costly slip-ups.         "
	!scr "                                        "
	!scr "   nshift makes delivery frictionless   "
	!scr "        from start to finish.           "
	!scr "                                        "

	!scr "                                        "
	!scr "      create happy customers            "
	!scr "      ----------------------            "
	!scr "                                        "
	!scr "     flexible delivery options.         "
	!scr "        live order updates.             "
	!scr "      quick and easy returns.           "
	!scr "                                        "
	!scr "    todays online shoppers have         "
	!scr "       sky-high expectations.           "
	!scr "                                        "
	!scr "       we help you meet them            "
	!scr "       every step of the way.           "

	!scr "                                        "
	!scr "       do more with your data           "
	!scr "       ----------------------           "
	!scr "                                        "
	!scr "   nshift lets you view and analyze     "
	!scr "    all your data in one place.         "
	!scr "                                        "
	!scr " so you can track tariffs and invoices, "
	!scr " gain insight into carrier performance, "
	!scr " and spot opportunities for improvement "
	!scr "                                        "
	!scr "         wherever they are.             "
	!scr "                                        "

	!scr "                                        "
	!scr "          own the last mile             "
	!scr "          -----------------             "
	!scr "                                        "
	!scr "   no need to hand control over to      "
	!scr "           a third party.               "
	!scr "                                        "
	!scr "manage and tailor every element of your "
	!scr "        delivery experience.            "
	!scr "                                        "
	!scr "  from label design to text alerts.     "
	!scr "                                        "
	!scr "       https://www.nshift.com           "

	!byte $ff