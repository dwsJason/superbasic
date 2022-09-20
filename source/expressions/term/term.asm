; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		term.asm
;		Purpose:	Evaluate a term
;		Created:	20th September 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;					   			Evaluate a term on the stack at X
;
;		This can be:
;			a number (in ASCII)			$30-$39 	(0-9)
;			a quoted string 			$FF 		
;			a variable 					$40-$7F
; 			a text unary function 		defined by constants
;			a punctuation unary 		@ ?\!$ & ( -
;
; ************************************************************************************************

EvaluateTerm:
		.cget 								; look at first character
		bmi 	_ETCheckUnary 				; unary function ? (text ones)
		cmp 	#$40 						; 40-7F => identifier reference
		bcs 	_ETVariable
		cmp 	#'0' 						; is it a number
		bcc 	_ETPuncUnary 				; if not it might be a punctuation unary.
		cmp 	#'9'+1 	
		bcs 	_ETPuncUnary

		; ----------------------------------------------------------------------------------------
		;
		;		A number 0-9 found
		;
		; ----------------------------------------------------------------------------------------

		jsr 	EncodeNumberStart 			; can't fail as it's 0-9 !
_ETNumber:
		iny 								; keep encoding until we have the numbers
		.cget
		jsr 	EncodeNumberContinue
		bcs 	_ETNumber 					; go back if accepted.
		rts

		; ----------------------------------------------------------------------------------------
		;
		;		Token found - check it's a unary function (non punctuation) like LEFT$
		;
		; ----------------------------------------------------------------------------------------

_ETCheckUnary:		
		cmp 	#KWC_STRING 				; string token
		beq 	_ETString
		cmp 	#KWC_FIRST_UNARY 			; check it actually is a unary function
		bcc 	_ETSyntaxError
		cmp 	#KWC_LAST_UNARY+1
		bcs 	_ETSyntaxError
		;
		phx 								; push X on the stack
		asl 	a 							; put vector x 2 into X
		tax
		jmp 	(VectorSet0,x) 				; and do it.

_ETSyntaxError:
		jmp 	SyntaxError

		; ----------------------------------------------------------------------------------------
		;
		;		String $FF <total length> <text> $00
		;		
		; ----------------------------------------------------------------------------------------

_ETString:
		iny 								; look at length
		.cget 								; push length on stack.
		pha
		iny 								; first character
		jsr 	MemoryInline 				; put address of string at (codePtr),y on stack
											; (may have to duplicate into soft memory)
		pla 								; restore count and save
		sta 	zTemp0 

		tya 								; add length to Y to skip it.
		clc
		adc 	zTemp0
		tay

		lda 	#NSTString 					; mark as string
		sta 	NSStatus,x
		rts

		; ----------------------------------------------------------------------------------------
		;
		;		Variable reference 40-7F
		;
		; ----------------------------------------------------------------------------------------

_ETVariable:
		.debug 
		jmp 	$FFFF

		; ----------------------------------------------------------------------------------------
		;
		;		Punctuation Unary these are @ (deref) ?!$ (indirection) ( (parenthesis)
		;		and - (negation)
		;
		; ----------------------------------------------------------------------------------------

_ETPuncUnary:
		iny 								; consume the unary character
		cmp 	#KWD_MINUS 					; unary minus
		beq 	_ETUnaryNegate
		cmp 	#KWD_AT 					; @ reference -> constant
		beq 	_ETDereference
		cmp 	#KWD_LPAREN 				; parenthesis
		beq 	_ETParenthesis
		cmp 	#KWD_DOLLAR
		beq 	_ETStringReference
		stz 	zTemp0 						; zTemp0 is the indirection level.
		cmp 	#KWD_QMARK 					; byte indirection (0) ?
		beq 	_ETIndirection
		inc 	zTemp0
		cmp 	#KWD_PLING					; word indirection (1) \
		bne 	_ETSyntaxError

		; ----------------------------------------------------------------------------------------
		;
		;		Indirection, ind count-1 is in zTemp0 - does unary ? (byte) ! (word)
		;
		; ----------------------------------------------------------------------------------------

_ETIndirection:
		lda 	zTemp0 						; push indirection amount (0-1) => (1-2) on the stack
		inc 	a
		pha
		jsr 	EvaluateTerm				; evaluate the term
		jsr 	Dereference 				; dereference it.
		lda 	NSStatus,x 					; must be a +ve integer.
		bne 	_ETTypeMismatch
		pla 								; indirection 1-2
		ora 	#NSBIsReference 			; make it a reference.
		sta 	NSStatus,x 
		rts
_ETTypeMismatch:
		jmp 	TypeError		

		; ----------------------------------------------------------------------------------------
		;
		;		Unary negation (-)
		;
		; ----------------------------------------------------------------------------------------

_ETUnaryNegate:
		jsr 	EvaluateTerm				; evaluate the term
		jsr 	Dereference 				; dereference it.
		lda 	NSStatus,x 					; must be a number
		and 	#NSTString 	
		bne 	_ETTypeMismatch
		jmp 	NSMNegate  					; just toggles the sign bit.

		; ----------------------------------------------------------------------------------------
		;
		;		Dereference a reference to a constant address (@)
		;
		; ----------------------------------------------------------------------------------------

_ETDereference:
		jsr 	EvaluateTerm				; evaluate the term
		lda 	NSStatus,x 					; must be a reference
		and 	#NSBIsReference
		beq 	_ETTypeMismatch
		stz 	NSStatus,x 					; make it an integer address
		rts

		; ----------------------------------------------------------------------------------------
		;
		;		Converts an address to a string there, so if you do $256 his refers to the
		;		ASCIIZ string at 256.
		;
		; ----------------------------------------------------------------------------------------

_ETStringReference:		
		jsr 	EvaluateTerm				; evaluate the term
		jsr 	Dereference 				; dereference it.
		lda 	NSStatus,x 					; must be a +ve integer.
		bne 	_ETTypeMismatch
		lda 	#NSTString 					; make it a string
		sta 	NSStatus,x
		rts

		; ----------------------------------------------------------------------------------------
		;
		;		Expression in parenthesis.
		;
		; ----------------------------------------------------------------------------------------

_ETParenthesis:
		.debug
		; ** TODO **
		bra 	_ETParenthesis

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
