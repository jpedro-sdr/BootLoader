org 0x7e00
jmp 0x0000:start

data:
    Lose db 'Voce perdeu, Tente outra vez!', 0x00
    Win db 'Voce ganhou, Parabéns!', 0x00

	VID equ 0B800h
    Colunas equ 80 ; largura
    Linhas equ 25 ; altura
    Vitoria equ 10 ; condição de vitoria
    CorFundo equ 9020h ; AZUL
    CorSnake equ 2020h ; VERDE
    CorMaca equ 4020h; VERMELHO
    TIMER equ 046Ch ; Expecifica uma parte da BIOS responsavel pelo relogio
    ARRAYX equ 1000h
    ARRAYY equ 2000h
    Cima equ 0
    Baixo equ 1
    Direita equ 2
    Esquerda equ 3

    ; posição de inicio:
    SnakeX: dw 40
    SnakeY: dw 13
    MacaX: dw 30
    MacaY: dw 5
    Movimento: db 2
    Tamanho: dw 1

print:
    mov ah, 0Eh
    
    .run: 
    lodsb
    cmp al, 0x00
    je .done
    int 10h
    jmp .run
    
    .done:
    ret

start:

    xor ax, ax
    mov ds, ax
    mov es, ax

    mov bl, 15
    mov al, 10h
    int 10h
  	call PRINT_LOGO

    mov ah, 2
    mov bh, 0
    mov dh, 14
    mov dl, 17
   	int 10h

    mov si, welcome
    call PRINT

    call READ

    ;; INICIO
    mov ax, 0003h ; Modo de video VGA 03h (80x25, 16 cores, modo de texto)
    int 10h 
    
    mov ax, VID ; pq es n pode receber VID diretamente
    mov es, ax ; ES:DI <- memoria de video

    ;Inicia a Snake
    mov ax, 40
    mov word [ARRAYX], ax
    mov ax, 13
    mov word [ARRAYY], ax

    ;; LOOP JOGO
    LOOP:
        ; Limpa a tela
        mov ax, CorFundo
        mov di, 0 ; xor di, di
        mov cx, Colunas*Linhas
        rep stosw ; mov [ES:DI], AX e inc di
    
        ;; Coloca a Snake na tela
        xor bx, bx ; mov bx, 0
        mov cx, [Tamanho] ; CONTADOR DO LOOP
        mov ax, CorSnake
        .Snake:
            imul di, [ARRAYY + bx], Colunas*2 ; Posição Y(Linhas) da Snake, 2 bytes por caracter(por isso Colunas*2)
            imul dx, [ARRAYX + bx], 2 ; Posição X(Coluna) da Snake
            Add di, dx
            stosw
            add bx, 2
        loop .Snake
        
        ;; Coloca a maçã na tela
        imul di, [MacaY], Colunas*2
        imul dx, [MacaX], 2
        add di, dx
        mov ax, CorMaca
        stosw

        ;; Mover a Snake
        mov al, [Movimento]
        cmp al, Cima
        je move_Cima
        cmp al, Baixo
        je move_Baixo
        cmp al, Direita
        je move_Direita
        cmp al, Esquerda
        je move_Esquerda 
        
        jmp atualiza_Snake
        
        move_Cima:
            dec word [SnakeY]; descrescente para cima(0 = canto superior esquerdo), logo temos q subtrair do valor de y atual para ela subir
            jmp atualiza_Snake
        
        move_Baixo:
            inc word [SnakeY] ; uma linha para baixo
            jmp atualiza_Snake

        move_Direita:
            inc word [SnakeX] ; uma coluna para a Direita
            jmp atualiza_Snake
        
        move_Esquerda:
            dec word [SnakeX] ;uma coluna para a esquerda
            jmp atualiza_Snake

        atualiza_Snake:
        ; atualiza a posição da Snake a partir da posição anterior da cabeça(Ex: 3->2, 2->1, 1->nova_posição), n altera a posição da cabeça pois isso ja foi feito, as mudanças começam do final para o começo da snake
            imul bx, [Tamanho], 2
            .snake_loop:
                mov ax, [ARRAYX - 2 + bx]
                mov word [ARRAYX + bx], ax
                mov ax, [ARRAYY - 2 + bx]
                mov word [ARRAYY + bx], ax
                sub bx, 2
            jnz .snake_loop
            
        mov ax, [SnakeX]
        mov word [ARRAYX], ax
        mov ax, [SnakeY]
        mov word [ARRAYY], ax
        
        ;; CONDIÇOES DE DERROTA
        ;; encostar nas bordas
        cmp word [SnakeY], -1 ; Topo da tela
        je perdeu
        cmp word [SnakeY], 25 ; Parte de baixo da tela 
        je perdeu
        cmp word [SnakeX], -1 ; limite esquerdo
        je perdeu
        cmp word [SnakeX], 80 ; limite direito
        je perdeu

        ;; encostar nela msm
        cmp word [Tamanho], 1
        je Entradas_Jogador

        mov bx, 2 ; posiçoes do Array(começa em 2 pois n queremos comparar o primeiro elemento, a cabeça)
        mov cx, [Tamanho] ; tamanho do loop
        bateu:
            mov ax, [SnakeX]
            cmp ax, [ARRAYX + bx]
            jne .incrementa
            mov ax, [SnakeY]
            cmp ax, [ARRAYY + bx]
            je perdeu
            
            .incrementa:
                inc bx ; tbm podia ser add bx, 2
                inc bx
        
        loop bateu
        ;; ler os movimentos do teclado e vira a Snake na direção pressionada(WASD)
        Entradas_Jogador:
            mov bl, [Movimento] ; Salva a direção atual

            mov ah, 1
            int 16h ; pega um caractere do reclado 
            jz Morde_maca ; Caso nada seja pressionado
            
            xor ah, ah
            int 16h ; al = char pressionado
            
            cmp al, 'w' ; Cima
            je w
            cmp al, 's' ; Baixo
            je s
            cmp al, 'a' ; Esquerda
            je a
            cmp al, 'd' ; Direita
            je d
            
            jmp Morde_maca
            
            w:
                mov bl, Cima
                jmp Morde_maca
            
            s:
                mov bl, Baixo
                jmp Morde_maca
            
            a:
                mov bl, Esquerda
                jmp Morde_maca

            d:
                mov bl, Direita
                jmp Morde_maca

        Morde_maca: 
        mov byte [Movimento], bl ; Atualiza Movimento com base no q o jogado apertou
        
        mov ax, [SnakeX]
        cmp ax, [MacaX]
        jne delay_loop

        mov ax, [SnakeY]
        cmp ax, [MacaY]
        jne delay_loop

        ; Se pegar a maça, então incrementa  1 ao tamanho da Snake
        inc word [Tamanho]
        cmp word [Tamanho], Vitoria
        je ganhou 

        Nova_maca:
        ;Posição x "aleatoria"
        xor ah, ah
        int 1Ah
        mov ax, dx
        xor dx, dx
        mov cx, Colunas
        div cx ; dx = Resto (0-79)
        mov word [MacaX], dx
        
        ;Posição y "aleatoria"
        xor ah, ah
        int 1Ah
        mov ax, dx
        xor dx, dx
        mov cx, Linhas
        div cx ; dx = Resto (0-24)
        mov word [MacaY], dx
        
        ;verifica se a maça n nasceu dentro da Snake
        xor bx, bx
        mov cx, [Tamanho]
        .loop_Verifica:
        mov ax, [MacaX]
        cmp ax, [ARRAYX + bx]
        jne .incrementa
        
        mov ax, [MacaY]
        cmp ax, [ARRAYY]
        je Nova_maca
        
        .incrementa:
        inc bx
        inc bx

        ;; Dalay do jogo
        delay_loop: 
            mov bx, [TIMER]
            add bx, 2
            .delay:
                cmp [TIMER], bx
                jl .delay
    jmp LOOP
    ganhou:
        mov si, Win
        call print
        jmp recomecar

    perdeu: 
        mov si, Lose
        call print
        jmp recomecar
    
    recomecar:
        xor ah, ah
        int 16h
        int 19h
jmp $

PRINT_COLOR:
    lodsb
    cmp al, 0
    je .done

    mov ah, 0xe
    mov bl, 2
    int 10h

    jmp PRINT_COLOR

    .done:
        ret
PRINT:
    lodsb
    cmp al, 0
    je .done

    mov ah, 0xe
    mov bl, 15
    int 10h

    jmp PRINT
    .done:
        ret


var:
    menos db '-', 0
    welcome db ' Seja bem vindo, pressione ENTER para comecar a jogar ', 0
    line1  db  ' ----------------------------- SNAKE -------------------------------',0
    line2  db  ' Teclas : W, A, S, D', 0
PRINT_LOGO:
 	mov ah, 2
    mov bh, 0
    mov dh, 2
    mov dl, 7
   	int 10h

	mov si, line1
	call PRINT_COLOR

	mov ah, 2
    mov bh, 0
    mov dh, 3
    mov dl, 7
   	int 10h
    
    mov si, line2
	call PRINT_COLOR

	mov ah, 2
    mov bh, 0
    mov dh, 3
    mov dl, 7
   	int 10h

	ret

end:
    jmp $

READ:
    xor cx, cx
    mov bl, 15

    .for1:
        mov ah, 0
        int 16h
        
        je .end
        cmp al, 0x08
      
        mov ah, 0x0e
        
        stosb
        jmp .for1
    .end:
        mov al, 0
        stosb

        mov ah, 0x0e
        mov al, 10
        

        ret