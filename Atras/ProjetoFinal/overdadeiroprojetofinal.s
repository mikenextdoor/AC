.equ    INPORT_ADDRESS, 0xFF80
.equ    OUTPORT_ADDRESS, 0xFFC0
.equ    MASK_2_3, 0x0C
.equ	STACK_SIZE, 64			; Dimensao do stack, em bytes
.equ	RAND_MAX_L, 0xFFFF		; Corresponde ao maior valor inteiro
.equ	RAND_MAX_H, 0xFFFF		; sem sinal codificavel com 32 bits
.equ	N, 5
.equ    FED_ADDRESS, 0xFF40
.equ    VAR_INIT_VAL, 0 
.equ    ENABLE_EXTINT, 0x10

.text
	b	program
	b	isr		; Reservado para a ISR
program:
	ldr	sp, stack_top_addr
	bl	main
	b	.

stack_top_addr:
	.word	stack_top


;;------------IMPORTS
inport_read:
	mov	    r1, #INPORT_ADDRESS & 0xFF
	movt	r1, #(INPORT_ADDRESS >> 8) & 0xFF
	ldrb	r0, [r1, #0]
	mov	    pc, lr

outport_write:
	mov	    r1, #OUTPORT_ADDRESS & 0xFF
	movt	r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	strb	r0, [r1, #0]
	mov	    pc, lr


;;------------LER SIDES
read_sides:
    push    lr
    push    r4
    push    r5
    push    r6

    bl      inport_read

    mov     r4, #MASK_2_3
    and     r5, r0, r4
    lsr     r5, r5, #2
    mov     r0, r5

    pop     r6
    pop     r5
    pop     r4
    pop     lr
    mov     pc, lr

starting_7seg:
	push 	lr
    push 	r4
    bl      read_sides
    mov     r0, r0
    bl      display_side
    pop     r4
	pop 	lr
    mov     pc, lr

roll_animation:
    push    lr
    push    r4
    push    r5
    push    r6
    push    r7
    push    r8

    mov     r4, #0
    mov     r5, #5
    mov     r7, #0
    mov     r8, #4
animation_for:
    mov     r0, #0
    bl      outport_write
	ldr 	r6, seven_seg_effect_addr
	ldrb	r0, [r6, r4]
    bl      outport_write
    cmp     r4, r5
    bhs     re_animate
    cmp     r7, r8
    beq     end_animation
    add     r4, r4, #1
    mov     r0, #1
    bl      delay
    b       animation_for
re_animate:
    mov     r4, #0
    add     r7, r7, #1
    b       animation_for
end_animation:
    pop     r8
    pop     r7
    pop     r6
    pop     r5
    pop     r4
    pop     lr
    mov     pc, lr

display_side:
    push    lr
	ldr 	r3, array_addr
	ldrb	r3, [r3, r0]
	mov  	r0, r3
    bl      outport_write
    pop     lr

display_number:
    push    lr
    sub     r0, r0, #1
	ldr 	r3, seven_seg_map_addr
	ldrb	r3, [r3, r0]
	mov  	r0, r3
    bl      outport_write
    pop     lr

isr:
    push    r1
    push    r0
    mov    r0, #FED_ADDRESS & 0xFF
    movt    r0, #(FED_ADDRESS >> 8) & 0xFF
    strb    r2, [r0, #0]
    ldr    r0, var_addr_isr
    ldrb    r1, [r0, #0]
    add    r1, r1, #1
    strb    r1, [r0, #0]
    pop    r0
    pop    r1
    movs    pc, lr

var_addr_isr:
    .word    var

delay:
    push lr 
    ldr     r3, var_addr           ; Carrega o endereço da variável var
    ldrb    r1, [r3]           ; Carrega o valor de var (contador de tempo)
delay_loop:
    ldrb    r2 , [r3]
    sub     r2, r2, r1         ; Subtrai 1 de r1 (valor da variável var)
    cmp     r2,r0            ; Compara novamente o valor de var com 10
    blo     delay_loop 
    b       delay_done        ; Se não for 10, continua o loop
delay_done:
    pop lr
    mov pc,lr                 ; Sai da função e retorna

var_addr:
    .word var
    
seven_seg_effect_addr:
        .word   seven_seg_effect

array_addr:
        .word   array

seven_seg_map_addr:
        .word   seven_seg_map

generate_random:
    push    lr
    push    r4
    push    r5

    bl      read_sides
    mov     r5, r0

    bl      inport_read
    mov     r4, r0

    bl      rand
    mov     r5, r7

    and     r0, r7, r5
    add     r0, r0, #1

    pop     r5
    pop     r4
    pop     lr
    mov     pc, lr

roll_transition:
    push    lr
    push    r4
    push    r5
    push    r6
    push    r7

roll_switch_loop:
    bl      inport_read
    mov     r4, r0
    mov     r5, #1
    and     r4, r4, r5

    ldr     r5, previous_roll_addr
    ldrb    r6, [r5]

    cmp     r4, r6
    beq     equal_roll

	cmp 	r4, r6
	bhs 	roll_off	

	ldr 	r5, previous_roll_addr
    strb    r4, [r5]
    bl      roll_animation
    bl      generate_random
    bl      display_number

	pop 	r5
	pop 	lr
	mov 	pc, lr
roll_off:
	ldr 	r5, previous_roll_addr
	strb    r4, [r5]
	bl  	roll_switch_loop
equal_roll:
	bl 		roll_switch_loop


array_addr_roll:
        .word   array

previous_roll_addr:
        .word   previous_roll

srand:
	ldr	r2, seed_addr_srand
	str	r0, [r2, #0]
	str	r1, [r2, #2]
	mov	pc, lr

seed_addr_srand:
	.word	seed

rand:
	push	lr
	; Obter o valor atual de seed
	ldr	r2, seed_addr_rand
	ldr	r0, [r2, #0]
	ldr	r1, [r2, #2]
	; Calcular a multiplicacao a 32 bits
	mov	r2, #( 0x43FD >> 0 ) & 0xFF	; Carregar o valor 214013
	movt	r2, #( 0x43FD >> 8 ) & 0xFF
	mov	r3, #( 0x0003 >> 0 ) & 0xFF
	movt	r3, #( 0x0003 >> 8 ) & 0xFF
	bl	umull32
	; Calcular a adicao a 32 bits
	mov	r2, #( 0x9EC3 >> 0 ) & 0xFF	; Carregar o valor 2531011
	movt	r2, #( 0x9EC3 >> 8 ) & 0xFF
	mov	r3, #( 0x0026 >> 0 ) & 0xFF
	movt	r3, #( 0x0026 >> 8 ) & 0xFF
	add	r0, r0, r2
	adc	r1, r1, r3
	mov	r2, #( RAND_MAX_L >> 0 ) & 0xFF
	movt	r2, #( RAND_MAX_L >> 8 ) & 0xFF
	cmp r0, r2
	bne rand_save_seed
	mov	r3, #( RAND_MAX_H >> 0 ) & 0xFF
	movt	r3, #( RAND_MAX_H >> 8 ) & 0xFF
	cmp r1, r3
	bne rand_save_seed
	mov r0, #0  	; Atribuir a seed o valor 0
	mov r1, #0

rand_save_seed:
	; Atualizar o valor de seed
	ldr	r2, seed_addr_rand
	str	r0, [r2, #0]
	str	r1, [r2, #2]
	mov	r0, r1	; Preparar o valor a devolver (16 MSb do valor)
	pop	pc

seed_addr_rand:
	.word	seed

seed_addr:
    .word seed

umull32:
	; Prologo
	push	r8
	push	r7
	push	r6
	push	r5
	push	r4

	; Iniciar p fazendo a extensao de sinal aos 16 MSb
	asr	r4, r3, #15
	mov	r5, r4
	; Inicia p_1
	mov	r6, #0
	; Implementacao do ciclo for
	mov	r7, #0	; Inicia i
umull32_loop:
	mov	r8, #32	; Avaliar o limite maximo de i
	cmp	r7, r8
	bhs	umull32_ret
	; Implementacao do if
	mov	r8, #1
	and	r8, r2, r8
	bzc	umull32_else
	mov	r8, #1
	cmp	r6, r8
	bne	umull32_loop_end
	add	r4, r4, r0	; Atualizar o valor de p
	adc	r5, r5, r1
	b	umull32_loop_end
umull32_else:
	; Implementacao otimizada do else
	mov	r8, #0
	cmp	r6, r8
	bne	umull32_loop_end
	sub	r4, r4, r0	; Atualizar o valor de p
	sbc	r5, r5, r1
umull32_loop_end:
	mov	r8, #1	; Definir o novo valor de p_1
	and	r6, r2, r8
	asr	r5, r5, #1
	rrx	r4, r4
	rrx	r3, r3
	rrx	r2, r2
	add	r7, r7, #1	; Incrementar i
	b	umull32_loop

umull32_ret:
	; Epilogo
	mov	r0, r2	; Preparar o valor a devolver
	mov	r1, r3

	pop	r4
	pop	r5
	pop	r6
	pop	r7
	pop	r8
	mov	pc, lr

main2:
    mov     r0, #VAR_INIT_VAL
    ldr     r1, var_addr_main
    strb    r0, [r1, #0]
    bl      outport_write
    mov     r0, #FED_ADDRESS & 0xFF
    movt    r0, #(FED_ADDRESS >> 8) & 0xFF
    strb    r0, [r0, #0]
    mrs     r0, cpsr
    mov     r1, #ENABLE_EXTINT
    orr     r0, r0, r1
    msr     cpsr, r0
main_loop2:
    push    lr
    bl      starting_7seg
    repeat_loop2:
    bl      roll_transition
    mov     r0, #10
    bl      delay
    b       repeat_loop2

    pop     lr
    mov     pc, lr

main:
    mov     r0, #VAR_INIT_VAL
    ldr     r1, var_addr_main
    strb    r0, [r1, #0]
    bl      outport_write
    mov     r0, #FED_ADDRESS & 0xFF
    movt    r0, #(FED_ADDRESS >> 8) & 0xFF
    strb    r0, [r0, #0]
    mrs     r0, cpsr
    mov     r1, #ENABLE_EXTINT
    orr     r0, r0, r1
    msr     cpsr, r0
main_loop:
    push    lr
    bl      starting_7seg

    pop     lr
    mov     pc, lr

var_addr_main:
    .word    var

.data

    seed:
        .word 1, 0

    previous_roll:
        .byte 1

    array:
        .byte 0x66, 0x7D, 0x7F, 0x39

    seven_seg_effect:
        .byte 0x03, 0x06, 0x0C, 0x18, 0x30, 0x21

    seven_seg_map: 
        .byte 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67, 0x77, 0x7C, 0x3E
        
    var:
        .space 1

.stack
    .space STACK_SIZE
stack_top:
