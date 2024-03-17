;
; AssemblerApplication_Test_PWM_and_Input.asm
;
; Created: 24.08.2020 23:22:08
; Author : Michael
;

;;
; LED_Display.asm
;
; Created: 10.08.2020 15:20:15
; Author : Michael
;
; Written for 8 MHz

;###### Includes #######
.include "m8def.inc"

;###### Definitions ######
.def Temp = r16 ; Temporary registers
.def Temp_SREG = r17

.def CountH =r21
.def CountL =r22

;Use Port B for LED Display...
.equ PORT_LED = PORTC
.equ DDR_LED = DDRC

; ************* Definitions for Servo - PWM ******************
; core registers used:
.def PWM = r23
.def PWM_state = r24
.def PWM_Channel = r25

;if not already defined in main program:
;.def Temp = r16		; Temporary register
;.def Temp_SREG = r17	; Temporyry register to save SREG to in interrupt routines --> saves some time for a push/pop (4 cycles)

.def PWMx1 = r0
.def PWMx2 = r1
.def PWMx3 = r2
.def PWMx4 = r3
.def PWMx5 = r4
; Output registers used:
.equ DDR_PWM1 = DDRC
.equ DDR_PWM2 = DDRC
.equ DDR_PWM3 = DDRC
.equ DDR_PWM4 = DDRC
.equ DDR_PWM5 = DDRC
.equ PORT_PWM1 = PORTC
.equ PORT_PWM2 = PORTC
.equ PORT_PWM3 = PORTC
.equ PORT_PWM4 = PORTC
.equ PORT_PWM5 = PORTC
.equ BIT_PWM1 = 0
.equ BIT_PWM2 = 1
.equ BIT_PWM3 = 2
.equ BIT_PWM4 = 3
.equ BIT_PWM5 = 4
; ****** END ****** Definitions for Servo - PWM ******* END ******


; Interrupt table
.CSEG
.org 0000
RJMP RESET
RETI ;ISERVICE_EXT_INT0
RETI ;ISERVICE_EXT_INT1
RETI ;ISERVICE_TIM2_COMP
RETI ;ISERVICE_TIM2_OVF
RETI ;ISERVICE_TIM1_CAP
RETI ;ISERVICE_TIM1_COMP_A
RETI ;ISERVICE_TIM1_COMP_B
RETI ;RJMP ISERVICE_TIM1_OVF
RJMP ISERVICE_TIM0_OVF
RETI ;RJMP ISERVICE_SPI_STC
RETI ;RJMP ISERVICE_USART_RXC
RETI ;ISERVICE_USART_UDRE
RETI ;ISERVICE_USART_TXC
RETI ;ISERVICE_ADC
RETI ;ISERVICE_EE_RDY
RETI ;ISERVICE_ANA_COMP
RETI ;ISERVICE_TWSI
RETI ;ISERVICE_SPM_RDY


RESET:
;init stack pointer
	ldi Temp,low(RAMEND)
	out	SPL,Temp
	ldi Temp,high(RAMEND)
	out	SPH,Temp

;init input output pins (1 = Out,  0 = In)
	;     Bit# 76543210
	ldi Temp,0b00111111		;C0 .. C5 = Output
	out DDR_LED,Temp		
	ldi Temp,0b00000000
	out DDRB,Temp	

	ldi Temp,0
	out SPCR,Temp
	out TCCR2,Temp
	out TCCR1A,Temp
	out TCCR1B,Temp

	ldi	Temp,254		;LED #1 ein
	out PORT_LED,Temp

	rcall PWM_Init

	ldi	CountH,0
	ldi CountL,0

	sei		;allow interrupts in general
main_loop:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	dec		CountL		;1
	brne	main_loop	;2
	dec		CountH		;1
	brne	main_loop	;2
	tst		Temp
	breq	main_loop2
	clr		Temp
	cbi		PORT_LED,5
	RJMP	main_loop
main_loop2:
	ser		Temp
	sbi		PORT_LED,5
	RJMP	main_loop

; ************* Initialization for Servo - PWM ******************
PWM_Init:
;initialize output pins (1 = Out,  0 = In)

	in Temp,DDR_PWM1
	ori	Temp, (1 << BIT_PWM1)
	out DDR_PWM1,Temp
	in Temp,DDR_PWM2
	ori	Temp, (1 << BIT_PWM2)
	out DDR_PWM2,Temp
	in Temp,DDR_PWM3
	ori	Temp, (1 << BIT_PWM3)
	out DDR_PWM3,Temp
	in Temp,DDR_PWM4
	ori	Temp, (1 << BIT_PWM4)
	out DDR_PWM4,Temp
	in Temp,DDR_PWM5
	ori	Temp, (1 << BIT_PWM5)
	out DDR_PWM5,Temp

;initialize PWM-variables
	ldi	PWM_state,0
	ldi PWM_channel,5
	ldi PWM,65

	ldi	Temp,0
	mov	PWMx1,Temp
	ldi Temp,120
	mov	PWMx2,Temp
	ldi	Temp,40
	mov	PWMx3,Temp
	ldi Temp,80
	mov	PWMx4,Temp
	ldi Temp,60
	mov	PWMx5,Temp

;Initialize Timer 0
	;ldi Temp,0b00000101	; Prescaler 1024 for DEBUG mode
	ldi Temp,0b00000001	; Prescaler 1
	out	TCCR0, Temp
	ldi	Temp,0
	out TCNT0, Temp
	ldi temp, 1 << TOIE0	;Timer0 Interrupt enable
	out TIMSK, temp			;allow Timer0 interrupt
	ret
; ***** END ***** Initialization for Servo - PWM ****** END ******


; ************* Interrupt Service for Servo - PWM ***************
; max. 37 Cycles per interrupt
; average 27 (when PWM active)
ISERVICE_TIM0_OVF:	
	in		Temp_SREG,SREG
	push	Temp			
							
	cpi		PWM_channel, 3	
	brlo	PWM_p012		
	cpi		PWM_channel, 5	
	brlo	PWM_p34			
	rjmp	PWM_P5			
PWM_p012:
	cpi		PWM_channel,2	
	breq	PWM_P2			
	cpi		PWM_channel,0	
	brne	PWM_P1			
;*** No PWM
	cbi		PORT_PWM1,BIT_PWM1	
	cbi		PORT_PWM2,BIT_PWM2
	cbi		PORT_PWM3,BIT_PWM3
	cbi		PORT_PWM4,BIT_PWM4
	cbi		PORT_PWM5,BIT_PWM5

	rjmp	PWM_1exit		

;*** PWM1
PWM_P1:						
	tst		PWM_state		
	brne	PWM1_W1			
	dec		PWM				
	brne	PWM_1exit		
	inc		PWM_state		
	sbi		PORT_PWM1,BIT_PWM1
	ldi		PWM,91			
	add		PWM,PWMx1		
PWM1_W1:	
	cpi		PWM_state,1		
	brne	PWM_1W2			
	ldi		Temp,198		;Counts = 80 --> Timer Startwert = 256-80   +22 Zyklen (die bis hierher schon verbraucht wurden!)
	out		TCNT0, Temp
	dec		PWM				
	brne	PWM_1exit		
	inc		PWM_state		
	cbi		PORT_PWM1,BIT_PWM1
	ldi		PWM,121			
	sub		PWM,PWMx1		
PWM_1W2:
	ldi		Temp,199		;1   Counts = 80 --> Timer Startwert = 256-80   +23 Zyklen (die bis hierher schon verbraucht wurden!
	out		TCNT0, Temp		
	dec		PWM				
	brne	PWM_1exit		
	clr		PWM_state
	ldi		PWM,64			
	dec		PWM_channel		
	brne	PWM_1exit
	ldi		Temp,5
	mov		PWM_channel,Temp	
PWM_1exit:	
	pop		Temp			
	out		SREG,Temp_SREG
	RETI

;*** PWM2
PWM_P2:	
	tst		PWM_state		
	brne	PWM2_W1			
	dec		PWM				
	brne	PWM_1exit
	inc		PWM_state
	sbi		PORT_PWM1,BIT_PWM2
	ldi		PWM,91	
	add		PWM,PWMx2
PWM2_W1:
	cpi		PWM_state,1
	brne	PWM_1W2		
	ldi		Temp,197		;Counts = 80 --> Timer Startwert = 256-80   +21 Zyklen (die bis hierher schon verbraucht wurden!)
	out		TCNT0, Temp
	dec		PWM			
	brne	PWM_1exit	
	inc		PWM_state	
	cbi		PORT_PWM2,BIT_PWM2
	ldi		PWM,121
	sub		PWM,PWMx2
	rjmp	PWM_1W2

; This part needs to be here in order to be within the jump range of the branch instruction
PWM_p34:					
	cpi		PWM_channel, 4	
	breq	PWM_P4			

;*** PWM3
PWM_P3:						
	tst		PWM_state		
	brne	PWM3_W1			
	dec		PWM				
	brne	PWM_1exit		
	inc		PWM_state		
	sbi		PORT_PWM3,BIT_PWM3
	ldi		PWM,91			
	add		PWM,PWMx3		
PWM3_W1:
	cpi		PWM_state,1
	brne	PWM_1W2
	ldi		Temp,197		;1      Counts = 80 --> Timer Startwert = 256-80   +21 Zyklen (die bis hierher schon verbraucht wurden!)
	out		TCNT0, Temp
	dec		PWM
	brne	PWM_1exit
	inc		PWM_state
	cbi		PORT_PWM3,BIT_PWM3
	ldi		PWM,121
	sub		PWM,PWMx3
	rjmp	PWM_1W2

;*** PWM4
PWM_P4:
	tst		PWM_state
	brne	PWM4_W1
	dec		PWM
	brne	PWM_4exit
	inc		PWM_state
	sbi		PORT_PWM4,BIT_PWM4
	ldi		PWM,91			
	add		PWM,PWMx4
PWM4_W1:	
	cpi		PWM_state,1		
	brne	PWM_4W2			
	ldi		Temp,198		;Counts = 80 --> Timer Startwert = 256-80   +22 Zyklen (die bis hierher schon verbraucht wurden!)
	out		TCNT0, Temp		
	dec		PWM				
	brne	PWM_4exit		
	inc		PWM_state		
	cbi		PORT_PWM4,BIT_PWM4
	ldi		PWM,121			
	sub		PWM,PWMx4		
PWM_4W2:
	ldi		Temp,199		;Counts = 80 --> Timer Startwert = 256-80   +23 Zyklen (die bis hierher schon verbraucht wurden!
	out		TCNT0, Temp		
	dec		PWM				
	brne	PWM_4exit		
	clr		PWM_state
	ldi		PWM,64			
	dec		PWM_channel		
	brne	PWM_4exit
	ldi		Temp,5
	mov		PWM_channel,Temp
PWM_4exit:	
	pop		Temp			
	out		SREG,Temp_SREG	
	RETI					

;*** PWM5
PWM_P5:
	tst		PWM_state		
	brne	PWM5_W1			
	dec		PWM				
	brne	PWM_4exit		
	inc		PWM_state		
	sbi		PORT_PWM5,BIT_PWM5
	ldi		PWM,91			
	add		PWM,PWMx5		
PWM5_W1:
	cpi		PWM_state,1		
	brne	PWM_4W2			
	ldi		Temp,196		; Counts = 80 --> Timer Startwert = 256-80   +20 Zyklen (die bis hierher schon verbraucht wurden!)
	out		TCNT0, Temp		
	dec		PWM				
	brne	PWM_4exit		
	inc		PWM_state		
	cbi		PORT_PWM5,BIT_PWM5
	ldi		PWM,121			
	sub		PWM,PWMx5		
	rjmp	PWM_4W2			
; ****** END ******* Interrupt Service for Servo - PWM ****** END ******