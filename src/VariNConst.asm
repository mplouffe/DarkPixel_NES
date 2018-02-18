
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- VARIABLES ----------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "STARTUP"

.segment "ONCE"

.segment "ZEROPAGE"			; page zero - pointers

playerGraphicsPtr:			.res 2
mainPointer:				.res 2
nmiPointer:					.res 2


;.segment "STACK"			; stack

;.segment "SPRTIES"			; sprites

;.segment "SOUND"			; sound

;.segment "VARS"				; other variables

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




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- END VARIABLES ------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------- CONSTANTS ----------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

animationFrame1 = $0C
animationFrame2 = $18
animationFrame3 = $24
animationFrame4 = $30

sprite_RAM = $0200

mainGameState = $00
pauseState = $01
