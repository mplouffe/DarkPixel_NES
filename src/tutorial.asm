.segment "HEADER"

	.byte "NES"
	.byte $1a
	.byte $02			; 4 	2*16k PRG ROM
	.byte $01			; 5		8k CHR ROM
	.byte %00000001		; 6		mapper - horizontal miroring (todo: reevalute this when implementng scrolling)
	.byte $00			; 7
	.byte $00			; 8
	.byte $00			; 9 	NTSC
	.byte $00
	; Filler
	.byte $00,$00,$00,$00,$00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.include "VariNConst.asm"

.segment "CODE"

RESET:
	SEI        ; disable IRQs
	CLD        ; disable decimal mode
	LDX #$40
	STX $4017
	LDX #$FF
	TXS
	INX
	STX $2000
	STX $2001
	STX $4010

vblankwait1:
	BIT $2002
	BPL vblankwait1

clrmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0200, x
	INX
	BNE clrmem

vblankwait2:
	BIT $2002
	BPL vblankwait2

LoadPalettes:
	LDA $2002
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006
	LDX #$00
LoadPalettesLoop:
	LDA palette, x
	STA $2007
	INX
	CPX #$20
	BNE LoadPalettesLoop

LoadSprites:
	LDA #$80
	STA sprite_RAM
	STA sprite_RAM+3

	LDA #$3A
	STA sprite_RAM+1
	LDA #$37
	STA sprite_RAM+5
	LDA #$3B
	STA sprite_RAM+9
	LDA #$3C
	STA sprite_RAM+13

	LDA #.LOBYTE(player_sprites)
	STA playerGraphicsPtr
	LDA #.HIBYTE(player_sprites)
	STA playerGraphicsPtr+1

	LDA #$00
	STA playerDirection
	STA animationFrame
	STA animationCounter
	STA sleeping

	LDA #$00
	STA gameState
	STA gameStateOld
	JSR GameStateUpdate

	LDA #%10010000   ; enable NMI, sprites from Pattern Table 0
	STA $2000

	LDA #%00010000   ; enable sprites
	STA $2001

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-------------- GAME LOOP --------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Forever:
	INC sleeping
loop:
	LDA sleeping
	BNE loop


	LDA #$01
	STA updatingBackground

	JSR StrobeController
	JSR GameStateIndirect

	LDA gameState
	CMP gameStateOld
	BEQ next
	JSR GameStateUpdate

next:
	LDA #$00
	STA updatingBackground
	INC sanityCheck
	JMP Forever     ;infinite loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-------------- GAME STATE ENGINE ----------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NMI:
	PHA							; save the current state of the stack and then
	TXA							; reload it back onto the stack to prevent
	PHA							; the NMI from doing something bad if/when it
	TYA							; interrupts something in progress
	PHA

NMIStart:
	;LDA updatingBackground		; if I uncomment this, the game loop can prevent the
	;BNE SkipGraphicsUpdates	; NMI from doing anything - use if need to make sure game state completes

	LDA #$02
	STA $4014

	JSR GameStateNMIIndirect

	LDA #$00
	STA $2005
	STA $2005

	LDA #%00010110
	STA $2001

	LDA #$00					; sets sleeping to zero to let the game loop
	STA sleeping
	
	;STA updatingBackground+1
	;LDA updatingBackground+1	; this is disabled right now cause I'm not using CPUUsageBar
	;BNE SkipGraphicsUpdates
	;JSR ShowCPUUsageBar

SkipGraphicsUpdates:
	PLA							; this is undoing the pushes onto the stack that started the NMI
	TAY							; still not sure what the point of this action is
	PLA							; but I understand what it's doing (just not why)
	TAX
	PLA

	RTI


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------ END GAME STATE ENGINE --------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------ STROBE CONTROLLER ------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StrobeController:
	LDA controller1
	STA controller1_old
ReadController1:
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016
	LDX #$08
ReadControllerLoop:
	LDA $4016
	LSR A
	ROL controller1
	DEX
	BNE ReadControllerLoop

	LDA controller1_old
	EOR #$FF
	AND controller1
	STA controller1_pressed

	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------ STROBE CONTROLLER END --------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-------------- GAME STATE LOADER ----------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameStateNMIIndirect:
	JMP (nmiPointer)

GameStateIndirect:
	JMP (mainPointer)

GameStates:
	.word GameState0, GameState1

GameStateNMIs:
	.word GameStateNMI0, GameStateNMI1

GameStateUpdate:
	LDA gameState				; store the current game state into the old one for comparisons
	STA gameStateOld
	ASL A						; multiply by 2 (not sure why)
	TAX

	LDA GameStates,x			; load the game state from the table
	STA mainPointer
	LDA GameStates+1,x
	STA mainPointer+1

	LDA GameStateNMIs,x			; load the NMI from the table
	STA nmiPointer
	LDA GameStateNMIs+1,x
	STA nmiPointer+1
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- END GAME STATE LOADER -------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------ GAME STATE 0 (PLAYING) -------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; GAME STATE
GameState0:
	LDA #$00
	STA $2003

	JSR ProcessController0
	JSR UpdateSprite
	JSR PlayerAnimation
	JSR PlayerSpriteLoading
	RTS

;;;;;;;;;; NMI
GameStateNMI0:
	RTS

;;;;;;;;; CONTROLLER HANDLING
ProcessController0:
	; bit: 		7	6	5	4	3	2	1	0
	; button:	A	B	sel	str	up	dwn	lft	rgt
ReadA:
	LDA controller1
	AND #%10000000
	BEQ ReadADone
ReadADone:

ReadB:
	LDA controller1
	AND #%01000000
	BEQ ReadBDone
ReadBDone:

ReadStart:
	LDA controller1_pressed
	AND #%00010000
	BEQ ReadStartDone
StartPressed:
	LDA gameState
	STA gameState+1

	LDA #pauseState
	STA gameState	
ReadStartDone:

ReadUp:
	LDA controller1
	AND #%00001000
	BEQ ReadUpDone
UpPressed:
	LDA sprite_RAM
	SEC
	SBC #$01
	STA sprite_RAM
ReadUpDone:

ReadDown:
	LDA controller1
	AND #%00000100
	BEQ ReadDownDone
DownPressed:
	LDA sprite_RAM
	CLC
	ADC #$01
	STA sprite_RAM
ReadDownDone:

ReadLeft:
	LDA controller1
	AND #%00000010
	BEQ ReadLeftDone
LeftPressed:
	LDA sprite_RAM+3
	SEC
	SBC #$01
	STA sprite_RAM+3
	LDA playerDirection
	CMP #$01
	BEQ ReadLeftDone

	LDA #$01
	STA playerDirection
ReadLeftDone:

ReadRight:
	LDA controller1
	AND #%00000001
	BEQ ReadRightDone
RightPressed:
	LDA sprite_RAM+3
	CLC
	ADC #$01
	STA sprite_RAM+3
	LDA playerDirection
	BEQ ReadRightDone

	LDA #$00
	STA playerDirection
ReadRightDone:
	RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------- GAME STATE 0 END ---------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- GAME STATE 1 (PAUSED) -------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameState1:
	LDA controller1_pressed				; handling controller processing inline becuase
	AND #%00010000						; that's all that the paused game state does
	BEQ ReadStartState1Done

	LDA gameState+1
	STA gameState

ReadStartState1Done:
	RTS

GameStateNMI1:
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------- GAME STATE 1 END ---------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------- PLAYER SPRITE ANIMATION -------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; SPRITE MOVEMENT

UpdateSprite:
	INC animationCounter
	LDA sprite_RAM
	STA sprite_RAM+4
	CLC
	ADC #$08
	STA sprite_RAM+8
	STA sprite_RAM+12

	LDA sprite_RAM+3
	STA sprite_RAM+11
	CLC
	ADC #$08
	STA sprite_RAM+7
	STA sprite_RAM+15
	RTS

; SPRITE ANIMATION

PlayerAnimation:
	LDA animationCounter
	CMP #animationFrame1
	BEQ Animation1
	CMP #animationFrame2
	BEQ Animation2
	CMP #animationFrame3
	BEQ Animation1
	CMP #animationFrame4
	BEQ Animation3
	JMP AnimationDone

Animation1:
	LDA #$00
	STA animationFrame
	JMP AnimationDone
Animation2:
	LDA #$01
	STA animationFrame
	JMP AnimationDone
Animation3:
	LDA #$02
	STA animationFrame
	JMP AnimationDone

AnimationDone:
	LDA animationCounter
	CMP #animationFrame4
	BNE AnimationFinished
	SEC
	SBC #animationFrame4
	STA animationCounter
AnimationFinished:
	RTS

PlayerSpriteLoading:
	LDA playerDirection
	BEQ facingRight
	JMP facingLeft
facingRight:
	LDA animationFrame
	TAX
	LDA NM_right, x
	TAY
	JMP PlayerSpriteUpdate
facingLeft:
	LDA animationFrame
	TAX
	LDA NM_left, x
	TAY
	JMP PlayerSpriteUpdate

PlayerSpriteUpdate:
	LDA (playerGraphicsPtr),y
	STA sprite_RAM+1
	INY
	LDA (playerGraphicsPtr),y
	STA sprite_RAM+5
	INY
	LDA (playerGraphicsPtr),y
	STA sprite_RAM+9
	INY
	LDA (playerGraphicsPtr),y
	STA sprite_RAM+13
	INY

	LDA (playerGraphicsPtr),y
	STA sprite_RAM+2
	INY
	LDA (playerGraphicsPtr),y
	STA sprite_RAM+6
	INY
	LDA (playerGraphicsPtr),y
	STA sprite_RAM+10
	INY
	LDA (playerGraphicsPtr),y
	STA sprite_RAM+14
	INY

	RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------- END PLAYER SPRITE ANIMATION ----------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
player_sprites:
	.byte $3A, $37, $3B, $3C, %00000000, %00000000, %00000000, %00000000		; RIGHT, Frame 1 + 3
	.byte $36, $37, $38, $39, %00000000, %00000000, %00000000, %00000000		; RIGHT, Frame 2
	.byte $32, $33, $34, $35, %00000000, %00000000, %00000000, %00000000		; RIGHT, Frame 4
	.byte $37, $3A, $3C, $3B, %01000000, %01000000, %01000000, %01000000		; LEFT, Frame 1 + 3
	.byte $37, $36, $39, $38, %01000000, %01000000, %01000000, %01000000		; LEFT, Frame 2
	.byte $33, $32, $35, $34, %01000000, %01000000, %01000000, %01000000		; LEFT, Frame 4

palette:
	.byte $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
	.byte $0F,$15,$27,$07,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

NM_right:
	.byte $00, $08, $10
NM_left:
	.byte $18, $20, $28

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "VECTORS"
	.word NMI        ;when an NMI happens (once per frame if enabled) the 
	               ;processor will jump to the label NMI:
	.word RESET      ;when the processor first turns on or is reset, it will jump
	               ;to the label RESET:
	.word 0          ;external interrupt IRQ is not used in this tutorial

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "CHARS"
	.incbin "mario.chr"