; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		backload.asm
;		Purpose:	Backloader for Emulator
;		Created:	18th September 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;								Characters can be streamed in by $FFFA
;
; ************************************************************************************************

BackloadProgram:
		ldx 	#$FF
		lda 	$FFFA 						; read first byte
		bmi 	_BPExit
_BPCopy:
		inx  								; copy byte in
		sta 	lineBuffer,x
		stz 	lineBuffer+1,x
		lda 	$FFFA 						; read next byte
		bmi 	_BPEndLine 					; -ve = EOL
		cmp 	#9 							; handle TAB
		bne 	_BPNotTab
		lda 	#' '
_BPNotTab:		
		cmp 	#' ' 						; < ' ' = EOL
		bcs 	_BPCopy
_BPEndLine:		
		jsr 	TokeniseLine 				; tokenise the line.
		bra 	BackloadProgram
_BPExit:
		jmp 	WarmStart
		
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
