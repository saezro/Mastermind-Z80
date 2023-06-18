        DEVICE ZXSPECTRUM48
        org $8000               ; Program starts from $8000 = 32768
; Project made by Alicia Custodia García, Marie Estelle Melaine Pamen, Rodrigo Sáez Escobar
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

        ld B, 4
        ld C, 7
        ld a, %10001101 ; blink property whith cian to the first arrow
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)

        ld B, 0
        ld C, 0
        ld a, %10001001 ; blue with blue background to dont show win or loose when restart
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)
        inc C
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)
        inc C
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)
        inc C
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)

        ld HL, $580A ; Aims to the first square where is going to print "MASTER MIND"
        ld C, %00001010
        ld B,11
increment: ld (HL), C
        inc HL
        djnz increment

        
        call print_title ; prints the title of the game 
        call print_arrows ; print the line of arrows
        call print_dots ;prints the line of dots
        call print_xs ; prints the line of xs

        ; end of printing the screen, is ready to start playing

        ;call generate_key
        
        
        ld B, 6
        ld C, 7
        ld a, %10001111 ; blue with blue background to dont show win or loose when restart
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)

        ld HL, $58C7
        ld IY, input ; aims to the input list, where it saves the colors of the actual try
        ld d, 0 ; d acts as a flag. is 0 when no key is pressed and 1 when a key is pressed. makes impossible to press to keys at the same time
        ld IX, seq ; aims to the list of the usable colors, doesnt use the blue of the background

pre_b2: jp key_x ; simulates to press 'X'. to force the iniciation of the colors

loop2: ; principal loop that reads the letters (Z, X, C) to control the game ( <-, ->, enter)
        ld bc, $FEFE
        in a,(c)
        and %00011111 ; ignore bits
        cp %00011111
        jp z, off1 ; goes of if no key is pressed
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

seq: db 0, %10001000, %10001010, %10001011, %10001100, %10001101, %10001110, %10001111, 0 ; usable colors, except blue
seqCpy: db 0, %10001000, %10001010, %10001011, %10001100, %10001101, %10001110, %10001111, 0 ; copy to restart the original
input: db 0, 0, 0, 0, 1 ; colors introduced in the try
key: db %00001000, %00001010, %00001011, %00001100, 1 ;colors of the key
trys: db 0 ; number of trys done

off1: ; changes to 0 when theres no key pressed
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

key_z: ; same as key_x, but backwards
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
        ld IX, seq+8 ; goes back to the color sequence
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
        call comprob2 ; verifies the elemts of the list of input which match the code with out taking in care the position, prints the white X
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
        ld a, %10001101 ; gives it the BLINK property
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
        ld B, 0
        ld C, 0
        ld a, %10001010
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color
        inc C
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color
        inc C
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color

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
        
        ld BC, $FEFE
        jp loop_fin ; wait to restart

loss: ; prints the loss screen

        ld B, 0
        ld C, 0
        ld a, %10001010
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)
        inc C
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)
        inc C
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)
        inc C
        call PixelYXC ; B=y (0-23), C=x(0-31), A=color(0-15)

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

xs:  ; prints an X where HL is aiming
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

dot:  ; prints a dot where HL is aiming
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

print_arrows: ; prints 10 arrows in alternate squares in a row
        ld HL, $4080
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

print_linedots: ; prints a line of dots
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
        call dot
        ld BC,2
        dec DE
        ld A,D
        or E
        jp nz, loop3_2
        ld DE,10 
        ret  

print_linexs: ; print the line of xs
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

print_R: ;Prints r
        ld A,%11011000 
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

print_W: 
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

print_i: ; 
        ld A,%00001100 ;
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

print_n: 
        add HL,BC
        ld A,%01101100 
        call print_down 
        ld A,%00110011
        call print_down
        call print_down
        call print_down
        call print_down
        ret
print_D:
        ld A,%00001110 
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

print_L: 
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

print_o: 
        ld A,%00000000
        call print_down
        ld A,%00111110 
        call print_down 
        ld A,%01100011
        call print_down
        call print_down
        call print_down
        ld A,%00111110
        call print_down
        ret

print_e: 
        add HL,BC
        ld A,%00111100 
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
        ld A,%00110000 
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

print_s: 
        add HL,BC
        ld A,%00111110
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
        ld HL, $400A
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
        call print_e 
        ld HL,IX
        inc HL
        ld IX,HL
        add HL,BC
        call print_R
        ld HL,IX
        inc HL
        inc HL
        ld IX,HL
        call print_M 
        ld HL,IX
        inc HL
        ld IX,HL
        call print_i 
        ld HL,IX
        inc HL
        ld IX,HL
        call print_n 
        ld HL,IX
        inc HL
        ld IX,HL
        call print_D
        ret


print_down: add HL,BC ; adds 1 to HL in a row inside a specific square and assigns the value of A to define his design
        ld (HL),A 
        ret

print_dots:
        ld HL, $40C0
        call print_linedots ; print the line of dots
        ld HL, $4800
        call print_linedots
        ld HL, $4840
        call print_linedots
        ld HL, $4880
        call print_linedots
        ret

print_xs:
        ld HL, $5000
        call print_linexs ; prints the line of xs
        ld HL, $5040
        call print_linexs
        ld HL, $5080
        call print_linexs
        ld HL, $50C0
        call print_linexs
        ret


PixelYXC: ; B=y (0-23), C=x(0-31), A=color(%COLOR %BACKGROUND)
        ;changes the color of the pixel
        push AF
        push DE
        push HL

        ld h, 0
        ld l, b 
        add hl, hl ;2*hl
        add hl, hl
        add hl, hl
        add hl, hl
        add hl, hl ;32*hl would be like y*32

        ld d, 0
        ld e, c
        add hl, de ; HL = 32*y + x
        ld de, $5800
        add hl, de ; HL = %5800 + 32*y +x
        
        ld (hl), a

        pop HL
        pop DE
        pop AF
        ret


