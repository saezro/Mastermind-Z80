        DEVICE ZXSPECTRUM48
        org $8000               ; Program starts from $8000 = 32768

start:  ld C, %00001111;
        ld A, 1
        out ($FE), A ;Blue border
        ld HL, $5800
        ld DE, 768
loop1:  ld (HL), C ; loop that prints all the screen with blue
        inc HL
        dec DE
        ld A, D
        or E
        jr NZ, loop1 ; end of the loop that prints in blue
        ld HL, $5887 ; gives the blink property to the square of the first arrow 
        ld C, %10001111
        ld (HL), C
        ld HL, $5800 ; Changes the color to BLUE of the first 4 squares to hide th WIN and loss messages after restarting the game
        ld (HL), %00001001
        ld HL, $5801
        ld (HL), %00001001
        ld HL, $5802
        ld (HL), %00001001
        ld HL, $5803
        ld (HL), %00001001

        ld HL, $580A ; Aims to the first square where is going to print "MASTER MIND"
        ld C, %00001010
        ld B,11
increment: ld (HL), C
        inc HL
        djnz increment

        ld HL, $400A
        call print_title ; prints the title of the game
        ld HL, $4080
        call print_line1 ; print the line of arrows
        ld HL, $40C0
        call print_line2 ; print the line of dots
        ld HL, $4800
        call print_line2
        ld HL, $4840
        call print_line2
        ld HL, $4880
        call print_line2
        ld HL, $5000
        call print_line3 ; prints the line of xs
        ld HL, $5040
        call print_line3
        ld HL, $5080
        call print_line3
        ld HL, $50C0
        call print_line3

        ; end of printing the screen, is ready to start playing

        ;call generate_key
        
        ld HL, $58C7 ; apunta al primer circulo de la primera columna y le asigna BLINK
        ld (HL), %10001111

        ld IY, input ; apunta a la lista de input, donde se almacenaran los colores introducidos por el jugador para el intento actual
        ld d, 0 ; d actuara como flag. se establecera a 0 cuando no haya ninguna tecla pulsada y a 1 cuando se pulse una tecla. impedira que se lea una segunda tecla antes de soltar la primera
        ld IX, seq ; apunta a la lista que contiene todos los colores introducibles, descartando el azul por ser el fondo

pre_b2: jp key_x ; simula la pulsacion de la tecla 'X'. esto es para forzar la inicializacion de la secuencia de colores, que contiene como primer elemento un delimitador que debe ser ignorado

loop2: ; principal loop that reads the letters (Z, X, C) to control the game ( <-, ->, enter)
        ld bc, $FEFE
        in a,(c)
        and %00011111 ; ignore bits
        cp %00011111
        jp z, off1 ; goes of is no key is press
        bit 0, d
        jp nz, loop2 ; if d is 1 it means theres a key pressed
        ld a,a 
        cp %11011
        jp z, key_x ; detects x key
        ld a,a 
        cp %11101 
        jp z, key_z ;  detects z key
        ld a,a 
        cp %10111  
        jp z, key_ent ;  detects v key
        jp loop2 ; if v is pressed goes back

seq: db 0, %10001000, %10001010, %10001011, %10001100, %10001101, %10001110, %10001111, 0 ; Secuencia de colores introducibles, excluye el azul
seqCpy: db 0, %10001000, %10001010, %10001011, %10001100, %10001101, %10001110, %10001111, 0 ; Copia de la secuancia de colores usada para restablecerl la original, puesto que esta es editada durante un intento
input: db 0, 0, 0, 0, 1 ; Lista donde se almacenan los colores introducidos por el jugador para el intento actual
key: db %00001000, %00001010, %00001011, %00001100, 1 ; Lista donde se almacenan los colores de la clave
trys: db 0 ; Lleva cuenta de la columna actual para mostrar la pantalla de "loss" si se llega a 10 intentos fallidos

off1: ; reestablece el valor de D a 0 al detectar ninguna tecla pulsada y vuelve al inicio del bucle
        ld d, 0
        jp loop2

key_x: ;  changes d to 1, meaning theres a key pressed, adds 1 to the sequence to go to the next color if the value is 1 means its beign use so goes to the next one
        ld d, 1
        inc IX
        ld a, (ix)
        cp 0
        jp z, res_x
        ld a, (ix)
        cp 1
        jp z, key_x ;if finds the value 1 goes to the next color
        ld (HL), A
        jp loop2
res_x: ; goes back to to the beginning
        ld IX, seq
        jp key_x

key_z: ; el funcionamiento es el mismo que key_x, pero en vez de avanzar en la secuencia, retrocede
        ld d, 1
        dec IX ; resta en vez de sumar
        ld a, (ix)
        cp 0
        jp z, res_z
        ld a, (ix)
        cp 1
        jp z, key_z
        ld (HL), A
        jp loop2
res_z:
        ld IX, seq+8 ; vuelve al final de la secuencia de colores
        jp key_z

key_ent:
        ld d, 1 ; gives d the value of 1 to express that a key is being pressed
        ld a, 1
        ld (IX), a ; changes the value in sequence to 1 to and the color to the sequence

        ld a, (HL) 
        and %01111111 ; removes the BLINK property
        ld (HL), a 
        ld (IY), a ; adds the color to the sequence
        inc IY ; moves to the next value of the sequence

        ld a, (IY) ; detects if is the end of the sequence, if the value is 1 is the end
        cp 1
        jp z, reset_line ; verifies the attempt

        push bc
        ld bc, $40 ; goes to the next dot
        add HL, bc 
        pop bc
        ld a, %10001111 ; gives the BLINK property to the dot
        ld (HL), a
        jp pre_b2 ; waits for input

reset_line:
        push bc
        push af
        push iy
        call comprob2 ; verifies the elemts of the list of input which match the code with out taking in care the position, prits the white X
        call comprob ; verifies the elemts of the list of input which match the code taking in care the position, prits the red X

        ld bc, $100 ; aims to the arrow of the column
        sub HL, BC 
        ld a, %00001110 ; takes out the BLINK prperty and change the color to yellow, meaning that column is done
        ld (HL), a

        ld IY, trys ; 
        inc (IY) ; adds 1 to the trys
        ld a, (IY)
        cp 10
        jp z, loss ; if theres 10 trys starts the loss 
        inc HL
        inc HL ; aims to the next arrow
        ld a, %10001111 ; gives it the BLINK property
        ld (HL), a
        ld bc, $40 ; aims to the next dot and gives it the blink property
        add HL, BC
        ld a, %10001111
        ld (HL), a
        pop bc
        pop af
        pop iy
        call reset_color ; resets the colors of the sequence
        jp pre_b2 ; waits the input

reset_color: ;copy the colors from seqCpy to seq, to restart the sequence
        push BC
        ld IX, seq
        ld IY, seqCpy
        ld B, 9
loop_c: ld c, (IY)
        ld (IX), c
        inc IX
        inc IY
        dec B
        jp nz, loop_c
        ld IY, input
        ld IX, seq
        pop BC
        ret
comprob:  ;compares key and input to know how many red x needs to be printed, the prints it
        ld b, 4
        ld d, 0
        ld IY, input
        ld IX, key
loop:   
        ld a, (IY)
        ld c, (IX)
        cp A, C
        jp nz, no_match
        inc D
no_match: 
        inc IY
        inc IX
        dec B
        jp nz, loop  ;now d have the number of red x 
        call draw_reds
        ld d, 1 ; give the value 1 to d that was the value before
        ret

comprob2: ;compares the elements of key and input to know have many white x needs to be printed
        ld b, 4
        ld d, 0
        ld IY, input
loop2_1: 
        ld a, (IY)
        ld IX, key
        push BC
        ld B, 4
loop2_2:   
        ld c, (IX)
        cp A, C
        jp nz, no_match2
        inc D
no_match2: 
        inc IX
        dec B
        jp nz, loop2_2
        inc IY
        pop BC
        dec b
        jp nz, loop2_1 ;now d have the number of white x 
        call draw_whites
        ld d, 1 ; give the value 1 to d that was the value before
        ret

draw_whites: ; draw wites just remove the X that left over
        ld BC, HL
        push HL ; saves hl to dont loose it
        ld HL, BC
        ld BC, $140
        add HL, BC ; aims to the last X in the column
        ld BC, $40
loop_d: 
        ld A, d
        cp 4
        jp z, cero ; if d is 4 means it doesnt need to remove any X
        ld A, %01001001 ; gives Flash property to the one it removes
        ld (HL), A
        sub HL, BC
        inc D
        ld A, D
        cp 4
        jp nz, loop_d
cero:   pop HL 
        ret

draw_reds: ; prints the red X and goes to the WIN phase if theres 4
        ld BC, HL
        push HL ;saves hl to dont loose it
        ld HL, BC
        ld BC, $80
        add HL, BC ; aims to the first X of the column
        ld BC, $40
        ld E, D
loop_d2: 
        ld A, d
        cp 0 ; if theres 4 red X goes to the win phase directly
        jp z, cero2
        ld A, %01001010
        ld (HL), A ; prints red the X
        add HL, BC
        dec D
        ld A, D
        cp 0
        jp nz, loop_d2
cero2:  pop HL ; gives the original value of HL
        ld A, e
        cp 4 
        jp z, win ; goes to the win phase
        ret

win: ; prints the victory screen
        ld HL, $4000 ;aims at the top left corner
        ld IX, HL
        ld BC, $100
        call print_W
        ld HL,IX
        inc HL
        ld IX,HL
        call print_i
        ld HL,IX
        inc HL
        ld IX,HL
        call print_n

        ld HL, $5800 ; changes to red color
        ld (HL), %11001010
        ld HL, $5801
        ld (HL), %11001010
        ld HL, $5802
        ld (HL), %11001010

        ld BC, $FEFE
        jp loop_fin ; wait to restart

loss: ; prints the loss screen
        ld HL, $4000 ; aims to the top left corner
        ld IX, HL
        ld BC, $100
        call print_L
        ld HL,IX
        inc HL
        ld IX,HL
        call print_o
        ld HL,IX
        inc HL
        ld IX,HL
        call print_s
        ld HL,IX
        inc HL
        ld IX,HL
        call print_s
        ld HL, $5800 ; gives the red color and the Flash property
        ld BC, $100
        ld (HL), %11001010
        ld HL, $5801
        ld (HL), %11001010
        ld HL, $5802
        ld (HL), %11001010
        ld HL, $5803
        ld (HL), %11001010

        ld BC, $FEFE
        jp loop_fin ; waits for the restart

loop_fin: ;waits to press v and then restarts the game
        in a, (c)
        bit 4, A
        jp nz, loop_fin
        call reset_color
        ld IY, trys ; 
        ld (IY),0 
        jp start

        halt

arrow: ; print the arrow with high definition
        ld BC, $100 
        ld A, %00011000
        ld (HL), A
        add HL,BC
        ld A, %00011000
        ld (HL), A
        add HL,BC
        ld A, %00011000
        ld (HL), A
        add HL,BC
        ld A, %10011001
        ld (HL), A
        add HL,BC
        ld A, %11011011
        ld (HL), A
        add HL,BC
        ld A, %01111110
        ld (HL), A
        add HL,BC
        ld A, %00111100
        ld (HL), A
        add HL,BC
        ld A, %00011000
        ld (HL), A
        ret

xs:  ; dibuja una equis en el cuadrado al que apunta HL
        ld BC, $700
        ld A, %11000011
        ld (HL), A
        add HL,BC
        ld (HL), A
        ld A, %11100111
        ld BC, $600
        sub HL,BC
        ld (HL), A
        ld BC, $500
        add HL,BC
        ld (HL), A
        ld A, %01111110
        ld BC,$400
        sub HL,BC
        ld (HL), A 
        ld BC,$300
        add HL,BC
        ld (HL), A
        ld A, %00111100
        ld BC,$200
        sub HL,BC
        ld (HL), A 
        ld BC,$100
        add HL,BC
        ld (HL), A
        ret

punto:  ; dibuja un punto en el cuadrado al que apunta HL
        ld BC, $700
        ld A, %00111100
        ld (HL), A
        add HL,BC
        ld (HL), A
        ld A, %01111110
        ld BC, $600
        sub HL,BC
        ld (HL), A
        ld BC, $500
        add HL,BC
        ld (HL), A
        ld A, %11111111
        ld BC,$400
        sub HL,BC
        ld (HL), A 
        ld BC,$300
        add HL,BC
        ld (HL), A
        ld A, %11111111
        ld BC,$200
        sub HL,BC
        ld (HL), A 
        ld BC,$100
        add HL,BC
        ld (HL), A
        ret

print_line1: ; prints 10 arrows in alternate squares in a row
        inc HL
        inc HL
        inc HL
        inc HL

        ld IX,HL
        ld BC,2
        ld DE,10
        inc IX
loop3_1: ld HL,IX
        add HL,BC
        ld IX,HL
        call arrow
        ld BC,2
        dec DE
        ld A,D
        or E
        jp nz, loop3_1
        ld DE,10 
        ret  

print_line2: ; imprime diez circulos en cuadrados alternos en una fila
        inc HL
        inc HL
        inc HL
        inc HL

        ld IX,HL
        ld BC,2
        ld DE,10
        inc IX
loop3_2: ld HL,IX
        add HL,BC
        ld IX,HL
        call punto
        ld BC,2
        dec DE
        ld A,D
        or E
        jp nz, loop3_2
        ld DE,10 
        ret  

print_line3: ; imprime diez xs en cuadrados alternos en una fila
        inc HL
        inc HL
        inc HL
        inc HL

        ld IX,HL
        ld BC,2
        ld DE,10
        inc IX
loop3_3: ld HL,IX
        add HL,BC
        ld IX,HL
        call xs
        ld BC,2
        dec DE
        ld A,D
        or E
        jp nz, loop3_3
        ld DE,10 
        ret  

print_M: ; Draws a "M" where the HL aims
        ld A,%01100011
        ld (HL),A
        ld A,%01110111
        add HL,BC
        ld (HL),A
        ld A,%01111111
        add HL,BC
        ld (HL),A 
        add HL,BC
        ld (HL),A
        ld A,%01101011
        add HL,BC
        ld (HL),A
        ld A,%01100011
        add HL,BC
        ld (HL),A 
        add HL,BC
        ld (HL),A
        ret
print_A:
        add HL,BC
        ld A,%00111100 ; prints A
        call print_down 
        ld A,%00000110
        call print_down
        ld A,%00111110
        call print_down
        ld A,%01100110
        call print_down
        ld A,%00111011
        call print_down
        ret

print_R:
        ld A,%11011000 ;Escribe r
        call print_down 
        ld A,%01101100
        call print_down
        ld A,%01100000
        call print_down
        ld A,%01100000
        call print_down
        ld A,%11110000
        call print_down
        ret

print_W: ; dibuja una 'W' mayuscula en el cuadrado al que apunta HL
        ld A,%01100011
        add HL,BC
        ld (HL),A 
        add HL,BC
        ld (HL),A
        add HL,BC
        ld (HL),A
        ld A,%01101011
        add HL,BC
        ld (HL),A
        ld A,%01111111
        add HL,BC
        ld (HL),A
        ld A,%01110111
        add HL,BC
        ld (HL),A
        ld A,%01100011
        ld (HL),A
        
        ret

print_i: ; dibuja una 'i' en el cuadrado al que apunta HL
        ld A,%00001100 ;Escribe i
        ld (HL),A
        ld A,%00000000
        call print_down
        ld A,%00011100
        call print_down
        ld A,%00001100
        call print_down
        call print_down
        call print_down
        ld A,%00011110
        call print_down
        ret

print_n: ; dibuja una 'n' en el cuadrado al que apunta HL
        add HL,BC
        ld A,%01101100 ;Escribe n
        call print_down 
        ld A,%00110011
        call print_down
        call print_down
        call print_down
        call print_down
        ret
print_D:
        ld A,%00001110 ;prints d
        ld (HL),A
        ld A,%00000110
        call print_down
        ld A,%00111110
        call print_down
        ld A,%01100110
        call print_down
        call print_down
        call print_down
        ld A,%00111011
        call print_down
        ret

print_L: ; dibuja una 'L' mayuscula en el cuadrado al que apunta HL
        ld A,%01100000
        add HL,BC
        ld (HL),A 
        add HL,BC
        ld (HL),A
        add HL,BC
        ld (HL),A
        add HL,BC
        ld (HL),A
        add HL,BC
        ld (HL),A
        ld A,%01111111
        add HL,BC
        ld (HL),A
        ld A,%01111111
        ld (HL),A
        ret

print_o: ; dibuja una 'o' en el cuadrado al que apunta HL
        add HL,BC
        ld A,%00111110 ;Escribe n
        call print_down 
        ld A,%01100011
        call print_down
        call print_down
        call print_down
        ld A,%00111110
        call print_down
        ret

print_e: ; dibuja una 'e' en el cuadrado al que apunta HL
        add HL,BC
        ld A,%00111100 ;Escribe e
        call print_down 
        ld A,%01100110
        call print_down
        ld A,%01111110
        call print_down
        ld A,%01100000
        call print_down
        ld A,%00111100
        call print_down
        ret

print_T:
        ld A,%00110000 ;Escribe t
        ld (HL), A
        ld A,%00110000
        call print_down
        ld A,%01111100
        call print_down
        ld A,%00110000
        call print_down
        ld A,%00110000
        call print_down
        ld A,%00110111
        call print_down
        ld A,%00011110
        call print_down
        ret

print_s: ; dibuja una 's' en el cuadrado al que apunta HL
        add HL,BC
        ld A,%00111110 ;Escribe s
        call print_down 
        ld A,%01100000
        call print_down
        ld A,%00111110
        call print_down
        ld A,%00000011
        call print_down
        ld A,%00111110
        call print_down
        ret

print_title: ; prints the title "MASTER MIND" where HL is aiming
        ld IX,HL
        ld BC,$100
        call print_M ; prints M
        ld HL,IX
        inc HL
        ld IX,HL
        call print_A
        ld HL,IX
        inc HL
        ld IX,HL
        call print_s
        ld HL,IX
        inc HL
        ld IX,HL 
        call print_T
        ld HL,IX
        inc HL
        ld IX,HL
        call print_e ;Escribe e
        ld HL,IX
        inc HL
        ld IX,HL
        add HL,BC
        call print_R
        ld HL,IX
        inc HL
        inc HL
        ld IX,HL
        call print_M ;Escribe M
        ld HL,IX
        inc HL
        ld IX,HL
        call print_i ;Escribe i
        ld HL,IX
        inc HL
        ld IX,HL
        call print_n ;Escribe n
        ld HL,IX
        inc HL
        ld IX,HL
        call print_D
        ret


print_down: add HL,BC ; adds 1 to HL in a row inside a specific square and assigns the value of A to define his design
        ld (HL),A 
        ret
        