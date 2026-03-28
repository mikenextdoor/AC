.text
        ldr     sp,stack_top_addr
        bl      main
        b       .
stack_top_addr:
        .word   stack_top

umull32: 
        push    lr                      
        push    r4
        push    r5
        push    r6
        push    r7
        push    r8
        push    r9
        push    r10
        push    r11
        mov     r8, r0              ; M_ext (parte baixa)
        mov     r9, r1              ; M_ext (parte alta)
        mov     r0, r2              ; p (parte baixa)
        mov     r1, r3              ; p (parte alta)
        mov     r7, #0              ; p_1 = 0 
        mov     r10, #0             ; #0
        mov     r11, #1             ; #1
        mov     r5, #0              ; i = 0
        mov     r2, #0              ; reset parte baixa
        mov     r3, #0              ; reset parte alta
for_loop:
        mov     r6, #32             ; #32
        cmp     r5, r6              ; i < 32
        bhs     for_end
        add     r5, r5, #1          ; i++
        and     r4, r0, r11         ; p & 0x1
        cmp     r4, r10             ; p & 0x1 == 0
        bne     check_if
        cmp     r7, r11             ; p_1 == 1
        bne     if_end

add_condition:
        add     r2, r2, r8          ; p += M_ext(parte baixa)
        adc     r3, r3, r9          ; p += M_ext(parte alta) + carry
        b       if_end

sub_condition:
        sub     r2, r2, r8          ; p -= M_ext(parte baixa)
        sbc     r3, r3, r9          ; p -= M_ext(parte alta) + carry
        b       if_end

check_if:
        cmp     r7, r10             ; p_1 == 0
        beq     sub_condition

if_end:
        and     r7, r0, r11         ; p_1 = p & 0x1
        asr     r3, r3, #1          ; p >>= 1
        rrx     r2, r2
        rrx     r1, r1
        rrx     r0, r0
        b       for_loop

for_end:
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     r7
        pop     r6
        pop     r5
        pop     r4
        pop     lr
        mov     pc, lr

srand:
        ldr     r3, seed_addr
        str     r0, [r3]            ; seed[0]
        str     r1, [r3, #2]        ; seed[1]
        mov     pc, lr
        
rand: 
        push    lr
        push    r4
        push    r5 
        push    r6
        ldr     r3, seed_addr
        ldr     r0, [r3]            ; seed[0]
        ldr     r1, [r3, #2]        ; seed[1]
        mov     r2, #0xFD           ; 214013: r3 = #0x3; r2 = #0x43; r2 = #0xFD
        movt    r2, #0x43
        mov     r3, #0x3
        bl      umull32
        mov     r3, #0xC3           ; 2531011: r3 = #0x26; r2 = #0x9E; r2 = #0xC3
        movt    r3, #0x9E
        mov     r4, #0x26
        add     r0, r0, r3          ; umull32( seed, 214013 ) + 2531011 (parte baixa)
        adc     r1, r1, r4          ; umull32( seed, 214013 ) + 2531011 (parte alta)
        mov     r5, #0xFF           ; RAND_MAx
        movt    r5, #0xFF           ; RAND_MAx
        cmp     r0, r5
        bne     if_condition
        cmp     r1, r5
        bne     if_condition
        mov     r0, #0              ; reset
        mov     r1, #0              ; reset
if_condition:
        ldr     r3, seed_addr
        str     r0, [r3]            ; seed[0]
        str     r1, [r3, #2]        ; seed[1]
        mov     r0, r1
        pop     r6
        pop     r5
        pop     r4
        pop     lr
        mov     pc, lr

seed_addr:
        .word   seed

main:
        push    lr
        push    r4
        push    r5
        push    r6
        push    r7
        push    r8
        
        ;mov     r0, #6
        ;mov     r1, #0
        ;mov     r2, #4
        ;mov     r3, #0
        ;bl      umull32
        
        mov     r0, #0x2F
        movt    r0, #0x15
        mov     r1, #0
        bl      srand               ; srand(5423)
        
        ldr     r4, results_addr
        mov     r5, #0              ; i = 0
        mov     r6, #5              ; N = 5
        mov     r7, #0              ; error = 0
main_loop:
        cmp     r5, r6              ; i < N
        bhs     main_end
        
        bl      rand                ; rand_number = rand()
        add     r8, r5, r5          ; calcula offset (i*2)
        ldr     r3, [r4, r8]        ; results[i]
        cmp     r0, r3              ; cmp com valores do result
        bne     set_error
        
        add     r5, r5, #1          ; i++
        b       main_loop

set_error:
        mov     r7, #1              ; error = 1

main_end:
        mov     r0, r7              ; error (0 ou 1)
        pop     r8
        pop     r7
        pop     r6
        pop     r5
        pop     r4
        pop     lr
        mov     pc, lr

results_addr:
        .word   results

.data
seed:
        .word   1, 0

results: 
        .word   17747, 2055, 3664, 15611, 9816

.stack
        .space  1000

stack_top:
