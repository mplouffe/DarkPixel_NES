
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- DATA STRUCTURES ----------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.scope EntityType
	NoEntity = 0
	PlayerType = 1
	Death = 2
.endscope

.struct Entity
	xvel .byte
	xpos .byte
	yvel .byte
	ypos .byte
	type .byte
.endstruct

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------ END DATA STRUCTURES -------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- VARIABLES ----------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "STARTUP"

.segment "ONCE"

.segment "ZEROPAGE"			; page zero - pointers

playerGraphicsPtr:			.res 2
mainPointer:				.res 2
nmiPointer:					.res 2

backgroundPtr:				.res 2
counterPtr:					.res 2


;.segment "STACK"			; stack

;.segment "SPRTIES"			; sprites

;.segment "SOUND"			; sound

.segment "DATA"				; other variables

controller1:				.res 1
controller1_old:			.res 1
controller1_pressed:		.res 1
updatingBackground:			.res 1
sanityCheck:				.res 1

animationFrame:				.res 1
animationCounter:			.res 1
playerDirection:			.res 1
gameState:					.res 2
gameStateOld:				.res 1
sleeping:					.res 1



MAXENTITIES = 5
entities:					.res .sizeof(Entity) * MAXENTITIES
TOTALENTITIES = .sizeof(Entity) * MAXENTITIES


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- END VARIABLES ------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- CONSTANTS ----------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

animationFrame1 = $24	; 1
animationFrame2 = $27	; 19
animationFrame3 = $70	; 20
animationFrame4 = $73	; 38

sprite_RAM = $0200

mainGameState = $00
pauseState = $01

playerMovement = $02

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- END CONSTANTS ------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;