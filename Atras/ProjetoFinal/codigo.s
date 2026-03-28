.equ INPORT_ADDRESS, 0xFF80
.equ OUTPORT_ADDRESS, 0xFFC0
.equ MASK_2_3, 0x0C    ; bits 2 e 3 (0b00001100)


.data
array:
    .byte 4, 6, 8 ,12

roll:
        .word   1, 0


.text
inport_read:
	mov	r1, #INPORT_ADDRESS & 0xFF
	movt	r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	ldrb	r0, [r1, #0]
	mov	pc, lr

outport_write:
	mov	r1, #INPORT_ADDRESS & 0xFF
	movt	r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	strb	r0, [r1, #0]
	mov	pc, lr


read_sides:
    push lr
    push r5
    bl inport_read    ; chama função para ler byte do porto, resultado em r0
    mov r5,MASK_2_3
    and r0, r0, r5  ; isola bits 2 e 3
    mov r1, r0         ; copia resultado para r1
    lsr r1, r1, #2         ; desloca bits para posição 0 e 1
    ldr r2, array_addr    ; carrega o endereço do array
    ldrb r0, [r2, r1]  ; lê o valor do array correspondente aos bits 2 e 3
    pop r5
    pop lr


roll_func:
    push lr
    push r6
    and r6,roll_addr
    ldr r6,[r6]
    cmp r6,#0
    beq rol_condition0
    rol_condition1
    read_bits_2_3

rol_condition0:
    outport_write

array_addr:
        .word   array


roll_addr:
        .word   roll

.equ PREV_ADDR, previous_value



.data
previous_value: .byte 1     ; Estado inicial do ROLL (bit 0 em 1 - OFF)

.text
check_roll:
    push r4
    push r5
    push r7

    bl inport_read          ; r0 ← valor atual do INPORT
    mov r4, r0              ; guarda valor atual em r4

    ldr r5, PREV_ADDR ; r5 ← endereço da variável previous_value
    ldrb r1, [r5]           ; r1 ← valor anterior

    ; Isolar bit 0 do valor anterior
    and r2, r1, #1
    cmp r2, #1
    bne end_check_roll      ; se anterior não era 1 → sair

    ; Isolar bit 0 do valor atual
    and r2, r0, #1
    cmp r2, #0
    bne end_check_roll      ; se atual não é 0 → sair

    ; Se chegou aqui, houve transição 1 → 0 (ROLL ativado)
    bl roll_dado

end_check_roll:
    strb r4, [r5]           ; atualizar previous_value ← valor atual

    pop r7
    pop r5
    pop r4
    bx lr
























rand:
	; Prologo
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

    ; Nao e necessario implementar a divisao modulo, pois a operacao realizada
    ; com valores de 32 bits nunca ultrapassa o valor RAND_MAX (0xFFFFFFFF).
    ; No entanto, a operacao % RAND_MAX deve devolver 0 quando o novo valor de
    ; seed e exatamente igual a RAND_MAX. Assim, e suficiente verificar este
    ; caso e forcar seed a zero.
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
	; Epilogo
	mov	r0, r1	; Preparar o valor a devolver (16 MSb do valor)
	pop	pc

seed_addr_rand:
	.word	seed


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



gerarnumero:
bl rand         ; r0 ← valor pseudoaleatório entre 0 e 65535

mov r2, r0      ; preparar multiplicando
mov r3, r4      ; r4 contém o número de faces do dado
bl umull32      ; r1:r0 = r2 × r3

mov r0, r1      ; usa parte alta do produto → (rand × N) >> 16
add r0, r0, #1  ; ajusta para obter intervalo [1, N]


 sleep:
	and	r0, r0, r0
	beq	sleep_end
sleep_outer_loop:
	mov	r1, #0x3E
	movt	r1, #0x03
sleep_inner_loop:
	sub	r1, r1, #1
	bne	sleep_inner_loop
	sub	r0, r0, #1
	bne	sleep_outer_loop
sleep_end: 
	mov	pc, lr

showdisplay:
    mov r5, #10          ; repetir 10 vezes (10 números)

roll_loop:
    bl read_sides    ; r0 ← número de faces
    mov r4, r0       ; guardar em r4

    bl gerarnumero   ; r0 ← número aleatório [1, N]
    bl display_num   ; mostrar no display

    mov r0, #100     ; delay de ~100ms
    bl sleep

    sub r5, r5, #1
    bne roll_loop   
    