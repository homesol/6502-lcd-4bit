# 6502-lcd-4bit

This project is based on [Ben Eaters 6502 kit](https://eater.net/6502), and carries on from video #9 which is the completed "Hello World" program.  From that point this project describes the changes in hardware and software required to operate the LCD in "4-bit mode" allowing for its control using only one (1) port of the 6522  (3 control bits, 4 data bits, 1 unused).

# Hardware:
The pin rewiring is documneted at the top of the code, and in these images:

## ![test](https://github.com/homesol/6502-lcd-4bit/blob/main/images/6502-4bit.png)

## ![test](https://github.com/homesol/6502-lcd-4bit/blob/main/images/PXL_20210319_171833644.jpg)

## ![test](https://github.com/homesol/6502-lcd-4bit/blob/main/images/PXL_20210319_171838866.jpg)

# Software:
The assembly code is profusly commented, largely to remind me what I did.
The delay functions are detailed in the spreadsheet with the reference to the original creators, the formula's used, and the spreadsheet is set up to calculate the delay that I needed.




