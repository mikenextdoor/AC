.equ	VAL_MIN, 5
;CODIGO

; umull
;-----------Gerador de numeros aleatorios--------
; Rotina:    umull32
; Descricao: Realiza a multiplicacao de dois numeros naturais codificados com
;            32 bits.
;            Interface exemplo: uint32_t umull( uint32_t M, uint32_t m );
; Entradas:  R1:R0 - Valor do multiplicando (M)
;            R3:R2 - Valor do multiplicador (m)
; Saidas:    R1:R0 - Valor do produto
; Efeitos:   R5:R4 - Parte alta (bits 63..32) do produto (p), pois R3:R2 contem
;                    a parte baixa (bits 31..0)
;            R6    - Mapeia a variavel p_1
;            R7    - guarda o valor da iteracao do ciclo for (i)
;            R8    - guarda valores temporariamente
;
umull32:
    ; Prologo
    push    r8
    push    r7
    push    r6
    push    r5
    push    r4

    ; Iniciar p fazendo a extensao de sinal aos 16 MSb
    asr    r4, r3, #15
    mov    r5, r4
    ; Inicia p_1
    mov    r6, #0
    ; Implementacao do ciclo for
    mov    r7, #0    ; Inicia i
umull32_loop:
    mov    r8, #32    ; Avaliar o limite maximo de i
    cmp    r7, r8
    bhs    umull32_ret
    ; Implementacao do if
    mov    r8, #1
    and    r8, r2, r8
    bzc    umull32_else
    mov    r8, #1
    cmp    r6, r8
    bne    umull32_loop_end
    add    r4, r4, r0    ; Atualizar o valor de p
    adc    r5, r5, r1
    b    umull32_loop_end
umull32_else:
    ; Implementacao otimizada do else
    mov    r8, #0
    cmp    r6, r8
    bne    umull32_loop_end
    sub    r4, r4, r0    ; Atualizar o valor de p
    sbc    r5, r5, r1
umull32_loop_end:
    mov    r8, #1    ; Definir o novo valor de p_1
    and    r6, r2, r8
    asr    r5, r5, #1
    rrx    r4, r4
    rrx    r3, r3
    rrx    r2, r2
    add    r7, r7, #1    ; Incrementar i
    b    umull32_loop

umull32_ret:
    ; Epilogo
    mov    r0, r2    ; Preparar o valor a devolver
    mov    r1, r3

    pop    r4
    pop    r5
    pop    r6
    pop    r7
    pop    r8
    mov    pc, lr


; r0 - val
; r1 - min
; r2 - max
clamp_value:
    push    lr
    cmp     r0, r1
    bhs     else_if
    mov     r0, r1
    b       clamp_return
    else_if:
    cmp     r2, r0
    bhs     clamp_return
    mov     r0, r2
    clamp_return:
    pop     lr
    mov     pc, lr

; r0 - v
; r1 - k
; r2 - s
; r3 - prod baixo
; r4 - prod alto
; r5 - k_ext
; r6 - prod_s
; r7 - prod_c
scale_value:
    push    lr
    push    r4
    push    r5
    push    r6
    push    r7
    push    r8
    mov     r8, #0xFF
    and     r5, r1, r8
    
    mov     r8, r2
    mov     r1, #0
    mov     r2, r5
    mov     r3, #0
    bl      umull32
    mov     r3, r0
    mov     r4, r1
    mov     r2, r8

    mov     r8, #0
    cmp     r2, r8
    beq     if_end
if_condition:
    mov     r8, #0xFF
    and     r2, r2, r8
    mov     r5, r2
    sub     r5, r2, #1
    lsl     r5, r5, #1
    add     r3, r3, r5
    mov     r8, #0
    adc     r4, r4, r8
shift_loop:
    mov     r8, #0
    cmp     r2, r8
    beq     if_end
    lsr     r4, r4, #1
    rrx     r3, r3
    sub     r2, r2, #1
    b       shift_loop
if_end:
    mov     r8, #0xFF
    and     r6, r3, r8
    mov     r0, r6
    mov     r1, #VAL_MIN
    mov     r2, r6
    bl      clamp_value

    pop     r7
    pop     r6
    pop     r5
    pop     r4
    pop     lr
    mov     pc, lr

; r0 - v_init
; r1 - v[]
; r2 - k[]
; r3 - s[]
build_sequence:
    push    lr
    push    r4
    push    r5
    mov     r4, #0
    ldr     r1, array_vals1_addr
    ldr     r2, array_vals2_addr
    ldr     r3, array_vals3_addr
    strb    r0, [r1, #0]
    ldrb    r5, [r3, r4]
    cmp     r5, r4
    beq     while_end    
while_loop:
    add     r5, r4, #1
    ldrb    r0, [r1, r4]
    ldrb    r2, [r2, r4]
    ldrb    r3, [r3, r4]
    bl      scale_value
    strb    r0, [r1, r5]
    add     r4, r4, #1
    b       while_loop
while_end:
    mov     r0, r4
    pop     r5
    pop     r4
    pop     lr
    mov     pc, lr

array_vals1_addr:
    .word array_vals1

array_vals2_addr:
    .word array_vals2
    
array_vals3_addr:
    .word array_vals3

;DATA
.data
;1
    array_k1:
        .byte 205, 154, 102, 51, 0

    array_s1:
        .byte 8, 8, 8, 8, 0

    array_vals1:
        .space 12

;2
    array_k2:
        .byte 35, 38, 42, 45, 0

    array_s2:
        .byte 5, 5, 5, 5, 0

    array_vals2:
        .space 12

;3
    array_k3:
        .byte 205, 154, 0, 45, 35, 0

    array_s3:
        .byte 8, 8, 0, 5, 5, 0

    array_vals3:
        .space 14

