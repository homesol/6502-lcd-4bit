; Hello World with 4 bit operation
; note wiring changes:
; 01-mar-2021
;
; Connections:
; 65C22     PB7:PB6:PB5:PB4:PB3:PB2:PB1:PB0 
; LCD       ---:RW : E :RS :DB7:DB6:DB5:DB4

; LCD Display (2x16)
; Line 1 data address: $80+0   to $80+$27 ($0-$0f is viewable without shifting)
; Line 2 data address: $80+$40 to $80+$67 ($40-4f is viewable without shifting)


;Set up ports and RAM
PORTB = $6000
DDRB = $6002
HNIB = $24     ;RAM 0 page storage for lcdbusy

;LCD control lables
RW= %01000000  ;PB6 (0=W, 1=R)
E = %00100000  ;PB5 (1>0 for write to lcd, 0>1 for read from lcd_nib
RS= %00010000  ;PB4 (0=ins, 1=data)


   .org $8000
;main reset
reset:
   ldx #$ff    ;set stack pointer to $ff
   txs
   
;Set up 65C22
   lda #%01111111    ;(0x7F) Set lower 6 bits Port B to output
   sta DDRB
   lda #%00000000    ;Clear PORTB
   sta PORTB
   
;Set up LCD (as per data sheet)   
   jsr delay_15ms
   lda #%00000011    ;set 8-bit mode (needs to be done 3 times, with these delays)
   jsr delay_5ms
   jsr lcd_ins
   lda #%00000011    ;set 8-bit mode
   jsr lcd_ins
   lda #%00000011    ;set 8-bit mode
   jsr lcd_ins
   lda #%00000010    ;set 4-bit mode 
   jsr lcd_ins
   lda #%00101000    ;set 2-line display; 5x8 dot (now in 4 bit mode)
   jsr lcd_ins 
   lda #%00001111    ;(0x0E) Display on; cursor on; blink on
   jsr lcd_ins
   lda #%00000110    ;(0x06) Increment and shift cursor; don't shift display
   jsr lcd_ins
   
   jsr lcd_clear
   ldx #0            ;ensure x register is cleared

;Main program
   jsr lcd_L1
   jsr print
   jsr delay_500ms
   jsr delay_500ms
   jsr lcd_L2
   jsr print
   jsr done
print:
   lda message,x
   beq pdone          ;Exit when last char in message is $0 <null>         
   jsr lcd_data
   inx               ;sets up x register to get next character in "message"
   jsr print
pdone:   
   ldx #0
   rts
   
done:   
   jmp done

   message: .asciiz "Hello, Steve!"    ;places text in ROM terminated with a $0 (ascii null)   

;Routines   
;
; Clear Display
lcd_clear
   lda #%00000001    ;(0x01) Clear Display
   jsr lcd_ins
   jsr delay_5ms     ;Clear display requires 1.6ms delay
   rts
;Set cursor at Line 1
lcd_L1
   lda #%10000000     ;$80
   jsr lcd_ins
   rts
;Set Cursor at Line 2   
lcd_L2
   lda #%11000000    ;$C0 ($80+$40)
   jsr lcd_ins
   rts
   ; 
; set cursor

; Send a nibble to LCD (4bits)   
lcd_nib:              ; Enter with nibble & RS bit in A, & E false
   sta PORTB          ; Send to PORTB
   ora #E             ; set E 
   sta PORTB          ; Send nibble with E set
   and #%11011111     ; clear E
   sta PORTB          ; Send nibble but E clear
   rts 

; Check LCD busy flag  
lcdbusy:
   pha                  ;save contents of A register on stack
      lda #%01110000    ;set PA0-PA3 as input 
      sta DDRB
      check:
        lda #RW           ;set LCD to read
        sta PORTB
        ora #E            ;set enable
        sta PORTB          
        ;read higher nibble
        lda PORTB          ;read high nibble (LCD reads available on low to high E toggle)
        sta HNIB           ;store high nibble in RAM
        lda #RW            ;keep read, clear enable
        sta PORTB
        ora #E             ;set enable to get next nibble
        sta PORTB
        ;read lower nibble 
        lda PORTB          ;read the nibble, let it be overwritten. do not need it
        lda #RW            ;keep read, clear enable
        sta PORTB
        ;check flag    
        lda HNIB           ;recall the high nibble:0000Bxxx
        and #%00001000     ;check if lcd bit 7 is set
        bne check          ;branch if it is set
      ;busy has cleared
      lda #%01111111       ;restore PORTB as output
      sta DDRB
   pla                     ;restore orignal contents of A from stack
   rts

;Send an instuction to LCD   
lcd_ins:          ;Enter with 8-bit LCD command byte in A register: HHHHLLLL
   jsr delay_100us
   pha            ;save a copy of A to stack
      lsr A       ;Shift out low nibble (L) 
      lsr A
      lsr A
      lsr A       ;Result is:0000HHHH (RW,E,RS = 0 to write an instruction)
      jsr lcd_nib ;write upper nibble to LCD
   pla            ;bring back 8-bit command byte into A
   and #%00001111 ;Mask out high nibble, result is:0000LLLL (RW,E,RS = 0 to write an instruction))
   jmp lcd_nib    ;write lower nibble to ins register
   rts

;Send data to LCD   
lcd_data:         ;Enter with 8-bit data byte in A register
   jsr lcdbusy    ;check if LCD ready for new data
   pha            ;save a copy of A to stack
      sec         ;set the carry bit (to be able to rotate it as RS=1)
      ror A       ;shift all bits right by 1, brings in carry > 1HHHHLLL
      lsr A       ;shift out the rest of of the lower nibble 
      lsr A
      lsr A       ; result is 0001HHHH (RW,E=0, RS=1 to write to data)
      jsr lcd_nib
   pla            ;bring back 8-bit data byte into A
   and #%00001111 ;Mask out high nibble > 0000LLLL
   ora #%00010000 ;Set RS=1 for data > 0001LLLL
   jmp lcd_nib
   rts

;Delays (see 65C02 spreadsheet for details, 65C02 notes for algorithm)   
delay_500ms         ; 0.5 second delay
   pha
    lda #218
    ldy #100
    loop500:
      cpy #1
      dey
      sbc #0
      bcs loop500
    pla  
   rts

delay_15ms:         ;15ms delay
   pha
    lda #7
    ldy #255
    loop15:
      cpy #1
      dey
      sbc #0
      bcs loop15
    pla  
   rts

delay_5ms:         ;5ms delay
   pha
    lda #2
    ldy #60
    loop5:
      cpy #1
      dey
      sbc #0
      bcs loop5
    pla  
   rts  
 
delay_100us:         ;100us delay
   pha
    lda #0
    ldy #11
    loop100:
      cpy #1
      dey
      sbc #0
      bcs loop100
    pla  
   rts    
   .org $fffc
   .word reset
   .word $0000
