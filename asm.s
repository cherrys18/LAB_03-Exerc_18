        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

; System Control definitions
SYSCTL_RCGCGPIO_R       EQU     0x400FE608
SYSCTL_PRGPIO_R		EQU     0x400FEA08
PORTF_BIT               EQU     0000000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     0000000100000000b ; bit  8 = Port J
PORTN_BIT               EQU     0001000000000000b ; bit 12 = Port N

; GPIO Port definitions
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C


; PROGRAMA PRINCIPAL

__iar_program_start
        
main:   MOV R0, #(PORTN_BIT | PORTF_BIT | PORTJ_BIT)
	BL GPIO_enable ; habilita clock ao port N
        
	LDR R0, =GPIO_PORTN_BASE
        MOV R1, #00000011b ; bits 0 e 1 como saída (LEDs D1 e D2)
        BL GPIO_digital_output
        
        LDR R0, =GPIO_PORTF_BASE
        MOV R1, #00010001b ; bits 0 e 1 como saída (LEDs D3 e D4)
        BL GPIO_digital_output
        
        LDR R0, =GPIO_PORTJ_BASE
        MOV R1, #00000011b ; bits 0 e 1 como entrada
        BL GPIO_digital_input

 	LDR R0, =GPIO_PORTN_BASE
        MOV R1, #00000011b ; máscara dos LEDs D1 e D2
        MOV R2, #00000000b ; padrão de acionamento

        LDR R3, =GPIO_PORTF_BASE
        MOV R4, #00010001b ; máscara dos LEDs D3 e D4
        MOV R5, #00010001b ; padrão de acionamento
        MOV R6, #0000b ; contador

        MOV R9, #00000010b
        MOV R10, #00000001b


loop:   BL GPIO_write; aciona LEDs D1, D2, D3 e D4

        //PUSH {R0}
        //MOVT R0, #0x003F
        //BL SW_delay ; atraso (determina frequência de acionamento)
        //POP {R0}
        
        LDR R0, =GPIO_PORTJ_BASE
        LDR R0, [R0, #0x3FC]
        PUSH {R0}
        MOVT R0, #0x000D
        BL SW_delay ; atraso (determina frequência de acionamento)
        POP {R0}
        cmp R0, R9
        IT EQ
            ADDEQ R6, R6, #1
        
        
        cmp R0, R10
        IT EQ
            SUBEQ R6, R6, #1
        
        
        AND R7, R6, #1b ; led 3 e 4
        AND R8, R5, R6, LSL #3 ; led 3 e 4
        ORR R7, R7, R8

        AND R2, R1, R6, LSR #2 ; led 1 e 2
        LDR R0, =GPIO_PORTN_BASE
        //EOR R2, R2, #11b ; inverte o padrão de acionamento
        //EOR R5, R5, #00010001b ; inverte o padrão de acionamento
        B loop


; SUB-ROTINAS

; GPIO_enable: habilita clock para os ports de GPIO selecionados em R0
; R0 = padrão de bits de habilitação dos ports
GPIO_enable:
        LDR R2, =SYSCTL_RCGCGPIO_R
	LDR R1, [R2]
	ORR R1, R0 ; habilita ports selecionados
	STR R1, [R2]

        LDR R2, =SYSCTL_PRGPIO_R
wait	LDR R0, [R2]
	TEQ R0, R1 ; clock dos ports habilitados?
	BNE wait

        BX LR

; GPIO_digital_output: habilita saídas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como saídas digitais
GPIO_digital_output:
	LDR R2, [R0, #GPIO_DIR]
	ORR R2, R1 ; configura bits de saída
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_write: escreve nas saídas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits a serem escritos
GPIO_write:
        STR R2, [R0, R1, LSL #2] ; escreve bits com máscara de acesso
        STR R7, [R3, R4, LSL #2]
        BX LR

; GPIO_digital_input: habilita entradas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como entradas digitais
GPIO_digital_input:
	LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1 ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1 ; habilita resitor de pull-up
	STR R2, [R0, #GPIO_PUR]

        BX LR

; GPIO_read: lê as entradas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits lidos
GPIO_read:
        LDR R2, [R0, R1, LSL #2] ; lê bits com máscara de acesso
        BX LR

; SW_delay: atraso de tempo por software
; R0 = valor do atraso
SW_delay:
        CBZ R0, out_delay
        SUB R0, R0, #1
        B SW_delay        
out_delay:
        BX LR


; TABELA DE VETORES DE INTERRUPÇÂO

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
