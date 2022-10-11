; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		main.asm
;		Purpose:	Graphics main entry point.
;		Created:	6th October 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Graphics Plot Routine
;
; ************************************************************************************************

GraphicDraw:
		cmp 	#$10*2 						; instructions 00-0F don't use 
		bcs 	_GDCoordinate
		;
		;		Non coordinate functions
		;
		stx 	gzTemp0 					; save X/Y
		sty 	gzTemp0+1
		bra 	_GDExecuteA 				; and execute
		;
		;		Coordinate functions
		;
_GDCoordinate:
		pha 								; save AXY
		phx 
		phy		
		ldx 	#3 							; copy currentX to lastX
_GDCopy1:		
		lda 	gxCurrentX,x
		sta 	gxLastX,x
		dex
		bpl 	_GDCopy1
		;
		pla 								; update Y
		sta 	gxCurrentY
		stz 	gxCurrentY+1
		;
		pla 
		sta 	gxCurrentX
		pla 								; get A (command+X.1) back
		pha
		and 	#1 							; put LSB as MSB of Current.X
		sta 	gxCurrentX+1
		;
		ldx 	#7 							; copy current and last to gxXY/12 work area
_GDCopy2:
		lda 	gxCurrentX,x
		sta 	gxX0,x
		dex
		bpl 	_GDCopy2		
		pla 								; get command back
		;
		;		Execute command X
		;		
_GDExecuteA:
		and 	#$FE 						; lose LSB
		tax
		jmp 	(GRVectorTable,x)

GXMove: ;; [16:Move]
		rts

GRUndefined:
		.debug	

; ************************************************************************************************
;											DRAWING MODES
; ************************************************************************************************
;
;		Mode 0: AND 0 EOR Colour 				Sets Colour
;		Mode 1: AND $FF EOR Colour 				Exclusive Or Colour
; 		Mode 2: And Colour:EOR 0 				AND with Colour.
;		Mode 3: AND ~Colour EOR Colour 			Or Colour
;
; ************************************************************************************************

		.send code

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
;
; ************************************************************************************************
