        DEVICE ZXSPECTRUM48
        org $8000               ; Programa ubicado a partir de $8000 = 32768

start:  ld C, %00001111;
        ld A, 1
        out ($FE), A ;Borde en azul
        ld HL, $5800
        ld DE, 768
loop1:  ld (HL), C ; Bucle que pinta toda la pantalla con PAPER azul y INK blanco
        inc HL
        dec DE
        ld A, D
        or E
        jr NZ, loop1 ; fin del bucle de pintar pantalla
        ld HL, $5887 ; asigna la propiedad blink al cuadrado donde se dibujara la primera flecha
        ld C, %10001111
        ld (HL), C
        ld HL, $5800 ; se cambia el valor de INK a azul para los tres primeros cuadrados, donde se dibujan los mensajes "Win" y "Lose", para ocultarlos al reiniciar el juego
        ld (HL), %00001001
        ld HL, $5801
        ld (HL), %00001001
        ld HL, $5802
        ld (HL), %00001001
        ld HL, $5803
        ld (HL), %00001001

        ld HL, $580A ; apunta al cuadrado donde se escribira la primera 'M' del titulo. Asigna INK rojo a los 11 cuadrados donde se escribira
        ld C, %00001010
        ld B,11
increment: ld (HL), C
        inc HL
        djnz increment

        ld HL, $400A
        call print_title ; imprime el titulo del juego
        ld HL, $4080
        call print_line1 ; imprime la linea de flechas

        ld HL, $40C0
        call print_line2 ; imprime las lineas de circulos
        ld HL, $4800
        call print_line2
        ld HL, $4840
        call print_line2
        ld HL, $4880
        call print_line2

        ld HL, $5000
        call print_line3 ; imprime las lineas de xs
        ld HL, $5040
        call print_line3
        ld HL, $5080
        call print_line3
        ld HL, $50C0
        call print_line3

        ; fin de imprimir pantalla. el tablero esta listo para jugar

        ;call generate_key
        
        ld HL, $58C7 ; apunta al primer circulo de la primera columna y le asigna BLINK
        ld (HL), %10001111

        ld IY, input ; apunta a la lista de input, donde se almacenaran los colores introducidos por el jugador para el intento actual
        ld d, 0 ; d actuara como flag. se establecera a 0 cuando no haya ninguna tecla pulsada y a 1 cuando se pulse una tecla. impedira que se lea una segunda tecla antes de soltar la primera
        ld IX, seq ; apunta a la lista que contiene todos los colores introducibles, descartando el azul por ser el fondo

pre_b2: jp key_x ; simula la pulsacion de la tecla 'X'. esto es para forzar la inicializacion de la secuencia de colores, que contiene como primer elemento un delimitador que debe ser ignorado

loop2: ; bucle principal del juego, se encarga de leer las teclas 'X', 'Z' y 'C' (alante, atras y enter)
        ld bc, $FEFE
        in a,(c)
        and %00011111 ; mascara para ignorar los bits adicionales que pueda haber
        cp %00011111
        jp z, off1 ; si las teclas no estan pulsadas pasa a off, cambia D a cero y vuelve al comienzo del bucle
        bit 0, d
        jp nz, loop2 ; si D es 1 significa que ya se ha pulsado una tecla y no se puede leer otra hasta que se suelte la primera. vuelve al inicio del bucle
        ld a,a 
        cp %11011
        jp z, key_x ; si se pulsa 'X' salta a key_x
        ld a,a 
        cp %11101 
        jp z, key_z ; si se pulsa 'Z' salta a key_z
        ld a,a 
        cp %10111  
        jp z, key_ent ; si se pulsa 'C' salta a key_ent
        jp loop2 ; si se ha pulsado 'V' o 'Caps shift' vuelve al inicio del bucle sin ejecutar nada

seq: db 0, %10001000, %10001010, %10001011, %10001100, %10001101, %10001110, %10001111, 0 ; Secuencia de colores introducibles, excluye el azul
seqCpy: db 0, %10001000, %10001010, %10001011, %10001100, %10001101, %10001110, %10001111, 0 ; Copia de la secuancia de colores usada para restablecerl la original, puesto que esta es editada durante un intento
input: db 0, 0, 0, 0, 1 ; Lista donde se almacenan los colores introducidos por el jugador para el intento actual
key: db %00001000, %00001010, %00001011, %00001100, 1 ; Lista donde se almacenan los colores de la clave
trys: db 0 ; Lleva cuenta de la columna actual para mostrar la pantalla de "Lose" si se llega a 10 intentos fallidos

off1: ; reestablece el valor de D a 0 al detectar ninguna tecla pulsada y vuelve al inicio del bucle
        ld d, 0
        jp loop2

key_x: ; establece D a 1, avanza en uno la secuencia de colores y asigna el color al circulo actual. si se llega al final de la secuencia, se vuelve al principio
        ld d, 1
        inc IX
        ld a, (ix)
        cp 0
        jp z, res_x
        ld a, (ix)
        cp 1
        jp z, key_x ; si se encuentra con un valor de 1, lo salta y pasa al siguiente, pues significa que el color ya ha sido usado en el intento actual
        ld (HL), A
        jp loop2
res_x: ; vuelve al comienzo de la secuencia de colores y al inicio del bucle
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
        ld d, 1 ; establece D a 1 para que no se lean mas teclas hasta que se suelte la actual
        ld a, 1
        ld (IX), a ; substituye el valor del color seleccionado por 1 en la secuencia para que sea saltado

        ld a, (HL) 
        and %01111111 ; toma el color directamente del valor del circulo, aplicando una mascara para ignorar el bit de BLINK
        ld (HL), a ; quita el BLIK del circulo actual antes de pasar al siguiente
        ld (IY), a ; almacena el color en la lista de input
        inc IY ; avanza en la lista de input para el siguiente input

        ld a, (IY) ; la lista de input tiene un delimitador de valor 1 al final. si se llega a este, se han introducido ya los cuatro colores
        cp 1
        jp z, reset_line ; realiza la comprobacion de intento, pinta las xs blancas y rojas, restaura la secuencia de colores y maneja el blink de las flechas

        push bc
        ld bc, $40 ; avanza HL desde el circulo actual hasta el siguiente
        add HL, bc 
        pop bc
        ld a, %10001111 ; asigna BLINK al nuevo circulo
        ld (HL), a
        jp pre_b2 ; vuelve a esperar el input del usuario

reset_line:
        push bc
        push af
        push iy

        call comprob2 ; comprueba cuantos elementos de la lista de input coinciden con la de la clave, sin tomar en cuenta posicion. colorea las xs correspondientes de blanco
        call comprob ; comprueba cuantos elementos de la lista de input coinciden con la de la clave, tomando en cuenta posicion. colorea las xs correspondientes de rojo

        ld bc, $100 ; apunta a la flecha de la columna recien completada
        sub HL, BC 
        ld a, %00001110 ; le quita el BLINK y la colorea de amarillo para marcarla como completada
        ld (HL), a

        ld IY, trys ; 
        inc (IY) ; aumenta la cuenta de intentos
        ld a, (IY)
        cp 10
        jp z, lose ; si se ha llegado a diez intentos, se salta a la pantalla de "Lose"

        inc HL
        inc HL ; apunta a la flecha de la siguiente columna
        ld a, %10001111 ; le asigna BLINK
        ld (HL), a
        ld bc, $40 ; pasa al primer circulo y le asigna BLINK tambien
        add HL, BC
        ld a, %10001111
        ld (HL), a

        pop bc
        pop af
        pop iy

        call reset_color ; reestablece la secuencia de colores a la original

        jp pre_b2 ; vuelve a esperar el input del usuario

reset_color: ; copia los valores de seqCpy en seq de uno en uno para reestablecer la secuencia de colores
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

comprob:
        ;compara los contenidos de key e input y pinta las xs rojas

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
        jp nz, loop

        ; en este punto, D contiene el numero de xs rojas a colorear. se llama a la funcion draw_reds para ello
        call draw_reds

        ld d, 1 ; se reestablece D a 1 para que no se lean mas teclas hasta que se suelte la actual
        ret

comprob2:
        ;compara cada elemento de input con cada elemento de key, y por cada coincidencia incrementa D

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
        jp nz, loop2_1

        ; en este punto, D contiene el numero de xs blancas a colorear. se llama a la funcion draw_whites para ello
        call draw_whites

        ld d, 1 ; se reestablece D a 1 para que no se lean mas teclas hasta que se suelte la actual
        ret

draw_whites: ; puesto que las xs ya son blancas, esta funcion borra las xs sobrantes
        ld BC, HL
        push HL ; guarda HL para no interceder con las proximas funciones de dibujo
        ld HL, BC
        ld BC, $140
        add HL, BC ; apunta a la ultima xs de la columna
        ld BC, $40
loop_d: 
        ld A, d
        cp 4
        jp z, cero ; si D es 4, significa que no hace falta borrar ninguna xs, puesto que todas seran blancas
        ld A, %01001001 ; a las xs borradas se les asigna FLASH para mostrar su ausencia
        ld (HL), A
        sub HL, BC
        inc D
        ld A, D
        cp 4
        jp nz, loop_d
cero:   pop HL ; si D es igual a 4 al comenzar, esta funcion no hace nada. restaura HL y sale
        ret

draw_reds: ; pinta las xs rojas, empezando por arriba. si se dan cuatro xs rojas, se salta a la pantalla de "Win"
        ld BC, HL
        push HL ; guarda HL para no interceder con las proximas funciones de dibujo
        ld HL, BC
        ld BC, $80
        add HL, BC ; situa HL en la primera xs de la columna
        ld BC, $40
        ld E, D
loop_d2: 
        ld A, d
        cp 0 ; comprueba que hay xs rojas a pintar. de lo contrario, salta a cero2 donde se comprueba si se ha ganado
        jp z, cero2
        ld A, %01001010
        ld (HL), A ; pinta una xs de rojo y pasa a la siguiente
        add HL, BC
        dec D
        ld A, D
        cp 0
        jp nz, loop_d2
cero2:  pop HL ; restaura HL oara su uso por otras funciones
        ld A, e
        cp 4 
        jp z, win ; si se han pintado cuatro xs rojas, se salta a la pantalla de "Win"
        ret

win: ; imprime la pantalla de victoria
        ld HL, $4000 ; se situa al comienzo de la pantalla y se llama a las funciones de impresion de la palabra "Win"
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

        ld HL, $5800 ; asigna FLASH e INK rojo a los cuadrados de la palabra "Win" 
        ld (HL), %11001010
        ld HL, $5801
        ld (HL), %11001010
        ld HL, $5802
        ld (HL), %11001010

        ld BC, $FEFE
        jp loop_fin ; funcion que espera a que se pulse 'V' para reiniciar el juego

lose: ; imprime la pantalla de derrota
        ld HL, $4000 ; se situa al comienzo de la pantalla y se llama a las funciones de impresion de la palabra "Lose"
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
        call print_e

        ld HL, $5800 ; asigna FLASH e INK rojo a los cuadrados de la palabra "Lose" 
        ld BC, $100
        ld (HL), %11001010
        ld HL, $5801
        ld (HL), %11001010
        ld HL, $5802
        ld (HL), %11001010
        ld HL, $5803
        ld (HL), %11001010
        
        ld BC, $FEFE
        jp loop_fin ; funcion que espera a que se pulse 'V' para reiniciar el juego

loop_fin: ; espera a que se pulse 'V' para restaurar la secuencia de colores y volver a la primera linea del codigo, permitiendo jugar otra vez
        in a, (c)
        bit 4, A
        jp nz, loop_fin
        call reset_color
        jp start

        halt

arrow: ; dibuja una flecha en el cuadrado al que apunta HL
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

print_line1: ; imprime diez flechas en cuadrados alternos en una fila
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

print_title: ; imprime las palabras "Master Mind" en once cuadrados consecutivos de una fila comenzando desde el cuadrado al que apunta HL

        ld IX,HL
        ld BC,$100
        call print_M ;Escribe M
        ld HL,IX
        inc HL
        ld IX,HL
        add HL,BC
        ld A,%00111100 ;Escribe a
        call print_down 
        ld A,%00000110
        call print_down
        ld A,%00111110
        call print_down
        ld A,%01100110
        call print_down
        ld A,%00111011
        call print_down
        ld HL,IX
        inc HL
        ld IX,HL
        call print_s ;Escribe s
        ld HL,IX
        inc HL
        ld IX,HL 
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
        ld HL,IX
        inc HL
        ld IX,HL
        call print_e ;Escribe e
        ld HL,IX
        inc HL
        ld IX,HL
        add HL,BC
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
        ld A,%00001110 ;Escribe d
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


print_down: add HL,BC ; aumenta HL en una fila dentro de un cuadrado especifico y le asigna el valor de A para definir su disenio
        ld (HL),A
        ret
        