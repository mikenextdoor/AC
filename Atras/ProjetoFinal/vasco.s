.text
b        program
b       isr

program:
    ldr    sp, stack_top_addr
    b    main
    b   .

    stack_top_addr:
        .word    stack_top
	

 main:         ;permite interrupeçoes e ativa o FED
        push lr
        mov r0, #0xF1
        mov r1, #0x00
        bl  srand 
        mrs r0, cpsr 
        mov r1, #(1 << 4)
        orr r0, r0, r1
        msr cpsr, r0
        mov r1, #nCs_ExT1 & 0xFF
        movt r1, #(nCs_ExT1 >> 8) & 0xFF
        strb r1, [r1,#0]
        bl   inport_read
        mov r3, #1
        and r0, r0, r3
        mov  r5, r0 ; previous

main_loop:
	bl ler_roll
    bl lados_dado       ; lê lados do dado para r0
	mov r1, r0
	bl efeito_lancamento
    bl display_numero_aleatorio
    bl delay_10s
    b main_loop         ; repete para sempre

isr:
    push r0
    push r1
    push r2

    mov  r0, #nCS_EN1 & 0xFF
    movt r0, #(nCS_EN1 >> 8) & 0xFF
    strb r2, [r0, #0]
    ldr r0, sum_addr
    ldrb r1, [r0]
    add r1, r1, #1
    strb r1, [r0]

    pop r2
    pop r1
    pop r0
    movs pc, lr
sum_addr:
    .word sum
lados_dado:
	push lr
	push r4
	bl inport_read         ; r0 ← estado do SW1
	mov r4, #0x0C
	and	r0, r0, r4
	lsr	r0, r0, #2          ; r0 ← índice entre 0 e 3
	ldr	r1, sides_table_addr
	ldrb r0, [r1, r0]        ; r0 ← nº de lados
	pop r4
	pop lr 
	mov	pc, lr

    sides_table_addr:
        .word sides_table

ler_roll:
    push r4
    push r5
    push lr

    espera_subida:
        bl inport_read
        mov r4, #1
        and r5, r0, r4       
        cmp r5, r4
        bne espera_subida    ; ve se sobe

    espera_descida:
        bl inport_read
        mov r4, #1
        and r5, r0, r4
        mov r4, #0
        cmp r5, r4
        bne espera_descida   ; ve se desce
        mov r0, #1
        pop lr
        pop r5
        pop r4
        mov pc, lr

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

delay:
    push r7                 ; guardar r7 uma vez só
    MOV R1, #0xE8
    MOVt R1, #0x03
    delay_loop:
        mov r7, #0
        cmp r1, r7
        beq fim_delay
        sub r1, r1, #1
        b delay_loop

    fim_delay:
     pop r7                  ; restaurar r7
     mov pc, lr

delay_1s:
    push r6 
    push r7
    push lr

    mov r6, #1        ; Repetir 10 vezes o delay_curto
    delay_1s_loop:
        bl delay
        sub r6, r6, #1
        mov r7, #0
        cmp r6, r7
        bne delay_1s_loop
        pop lr
        pop r7
        pop r6
        mov pc, lr

efeito_lancamento:
    push lr
    push r6
    push r7
    mov r7, r1
    efeito:
        mov r1, r7
        bl animacao
        bl gerar_numero_aleatorio
        mov r0, r0 
        pop r7
        pop r6
        pop lr
        mov pc, lr

animacao:
    push lr
    mov     r2, #11        ; contador decrescente
    mov     r3, #0        ; limite inferior (0)
for:
    sub     r2, r2, #1
    ldr     r1, codigos_seg7_addr
    ldrb    r0, [r1,r2]
    bl      outport_write
    bl      delay_1s      ; <- adicionado para pausa de 1 segundo entre passos
    cmp     r2, r3
    beq     for_end
    b       for
for_end:
    pop     lr
    mov     pc, lr


    codigos_seg7_addr:
        .word display_codes

gerar_numero_aleatorio:
        push    lr
        bl      rand
        mov     r1, r7
        bl      divide
        add     r0, r0, #1
        pop     lr
        mov     pc, lr

divide:
        push lr
        push    r4
        push    r3
        mov    r3, #0        ; rest = 0;
        mov    r4, #0        ; quocient = 0;
        mov    r2, #16        ; uint16_t i = 16;
    div_while:            ; uint16 dividend_msb = dividend >> 15;
        lsl    r0, r0, #1    ; dividend <<= 1;
        adc    r3, r3, r3    ; rest <<= 1; rest += dividend_bit;
        lsl    r4, r4, #1    ; quotient <<= 1;
        cmp    r3, r1        ; if (rest >= divisor) {
        blo    div_if_end
        sub    r3, r3, r1    ; rest -= divisor;
        add    r4, r4, #1    ; quotient += 1;
    div_if_end:
        sub    r2, r2, #1    ; } while (--i > 0);
        bne    div_while
        mov    r0, r3        ; return rest;
        pop r3
        pop    r4
        pop lr
        mov    pc, lr

display_numero_aleatorio:
    push lr
    ldr r1, display_codes_addr
    sub r0, r0, #1              ; transformar [1, D] → [0, D-1]
    ldrb r0, [r1, r0]           ; buscar código correspondente
    mov r2, #0x80               ; ativar mostrador o bit 7
    orr r0, r0, r2              ; combinar com o código
    bl outport_write
    pop lr
    mov pc, lr

    display_codes_addr:
        .word display_codes

delay_10s:
    push r6
    push r7
    push lr

    mov r6, #30        ; Repetir 10 vezes o delay
    delay_10s_loop:
        bl delay
        sub r6, r6, #1
        mov r7, #0
        cmp r6, r7
        bne delay_10s_loop

        pop lr
        pop r6
        mov pc, lr

inport_read:
	mov	r1, #INPORT_ADDRESS & 0xFF
	movt	r1, #(INPORT_ADDRESS >> 8) & 0xFF
	ldrb	r0, [r1, #0]
	mov	pc, lr

outport_write:
	mov	r1, #OUTPORT_ADDRESS & 0xFF
	movt	r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	strb	r0, [r1, #0]
	mov	pc, lr

.data
    sides_table:
        .byte 4, 6, 8, 12

    display_codes:
        .byte 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39

    seed:
        .word 1
        .word 0
    sum:
        .byte 0

.equ    STACK_SIZE, 64
.equ    INPORT_ADDRESS, 0xFF80
.equ    OUTPORT_ADDRESS, 0xFFC0
.equ	RAND_MAX_L, 0xFFFF		; Corresponde ao maior valor inteiro
.equ	RAND_MAX_H, 0xFFFF
.equ    nCs_ExT1, 0xff40
.equ    nCS_EN1, 0xFF40

.stack
    .space  STACK_SIZE
stack_top:
