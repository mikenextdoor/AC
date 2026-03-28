.equ INPORT_ADDRESS, 0xFF80
.equ OUTPORT_ADDRESS, 0xFFC0
.equ MASK_2_3, 0x0C    ; bits 2 e 3 (0b00001100)

.data
array:
    .byte 4, 6, 8 ,12


inport_read:
    mov    r1, #INPORT_ADDRESS & 0xFF
    movt    r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
    ldrb    r0, [r1, #0]
    mov    pc, lr

outport_write:
    mov    r1, #INPORT_ADDRESS & 0xFF
    movt    r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
    strb    r0, [r1, #0]
    mov    pc, lr


read_bits_2_3:
    push lr
    push r5
    bl inport_read    ; chama função para ler byte do porto, resultado em r0´
    
    mov r5, #MASK_2_3
    and r0, r0, r5  ; isola bits 2 e 3
    mov r1, r0         ; copia resultado para r1
    lsr r1, r1, #2         ; desloca bits para posição 0 e 1
    
    ldr r2, array    ; carrega o endereço do array
    ldrb r0, [r2, r1]  ; lê o valor do array correspondente aos bits 2 e 3
    pop r5
    pop lr
    mov pc, lr
