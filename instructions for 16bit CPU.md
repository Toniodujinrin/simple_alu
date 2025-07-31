instructions for 16bit CPU

**Instruction        Description**                                  Class Opcode 	**Class Specific Opcode**

//R-Type Instructions                                                                                                   **REG(out)    REG(in1)    Options/REG(in2)**

MOV RZ, RX         (MOV reg contents,  integer)                      01		        00000                           XXX         XXX         000

MOVF FZ, FX        (MOV reg contents,  floating point)               01		        00000                           FFF         FFF         001

ADD RZ, RX, RY     (Add, updates CPSR reg bits)                      01		        00001                           XXX         XXX         YYY

SUB RZ, RX, RY     (Subtract, updates CPSR reg bits)     	     01		        00010	                        XXX         XXX         YYY

MULH RZ , RX, RY   (Signed multiply, stores high bits)	             01		        00011                           XXX         XXX         YYY

UMULH RZ , RX, RY  (Unsigned multiply, stores high bits )            01		        00100                           XXX         XXX         YYY

UCMP RX,RY         (Compare, Integer Signed Compare)                 01		        00101                           XXX         YYY         000

CMP RX,RY          (Compare, Integer Unsigned Compare)               01		        00101                           XXX         YYY         001

FCMP FX,FY         (Compare, Floating Point Compare)                 01		        00101                           XXX         YYY         010

AND RZ, RX, RY     (Bitwise AND)                                     01		        00110                           XXX         YYY         YYY

OR  RZ, RX, RY     (Bitwise OR)                                      01		        00111                           XXX         YYY         YYY

NOR RZ, RX, RY     (Bitwise NOR)                                     01		        01000                           XXX         YYY         YYY

NAND RZ, RX, RY    (Bitwise NAND)                                    01		        01001                           XXX         YYY         YYY

XOR RZ, RX, RY     (Bitwise XOR)                                     01		        01010                           XXX         YYY         YYY

XNOR RZ, RY, RX    (Bitwise XNOR)                                    01		        01011                           XXX         YYY         YYY

NOT  RZ, RY        (Negate)                                          01		        01100                           XXX         YYY

MULL RZ , RX, RY   (Signed multiply, stores low bits)	             01		        01111                           XXX         YYY         YYY

UMULL RZ , RX, RY  (Unsigned multiply, stores low bits)              01		        10000                           XXX         YYY         YYY

FADD FZ, FX, FY    (Floating Point Addition)			     01                 10001                           FFF         FFF         FFF

FSUB FZ, FX, FY    (Floating Point Subtraction)                      01                 10010                           FFF         FFF         FFF

FMUL FZ, FX, FY    (Floating Point Multiplication)		     01                 10011                           FFF         FFF         FFF

FTOI RZ, FX        (Convert FP to Int)                               01                 10110                           XXX         FFF         000

ITOF FX, RZ        (Convert Int to Float)                            01                 10110                           FFF         YYY         001

LSR  RZ, RX, RY    (Logical shift Right)                             01                 11000                           XXX         YYY         YYY

LSL  RZ, RX, RY    (Logical shift Right)                             01                 11001                           XXX         YYY         YYY

ASR  RZ, RX, RY    (Arithmetic shift right)                          01                 11010                           XXX         YYY         YYY

ASL  RZ, RX, RY    (Arithmetic shift left)                           01                 11011                           XXX         YYY         YYY

ROR  RZ, RX, RY    (Rotate Bits right)                               01                 11100                           XXX         YYY         YYY



Unused Class Specific Opcodes (01110, 01101, 10100, 11111, 11101, 11110, 10101, 10110, 10111)



//Immediate Value Instructions                                                                                          **REG(out)    REG(in)    IMM**

LDR  RZ, RX, IMM   (Load Half word (16bits) with offset)             00                 00				XXX	    YYY        000000

STR  RZ, RX, IMM   (Store Half word, with offset)                    00                 01                              XXX         YYY        000000

ADDI RZ, RX, IMM   (Add with immediate value)                        00                 10                              XXX         YYY        000000

SUBI RZ, RX, IMM   (Subtract with immediate value)                   00                 11                              XXX         YYY        000000



//Branch instructions \& compar                                                                                          **REG(addr)   IMM(offset)**

B RZ, IMM          (Unconditional Branch)                            10                 000                             XXX	    00000000

BEQ RZ, IMM        (Branch if Equal, CPSR Z = 1)                     10                 001                             XXX         00000000

BNE RZ, IMM        (Branch Not Equal, CPSR Z = 0)                    10                 010                             XXX         00000000

BLE RZ, IMM        (Branch Less than or Equal, CPSR N=1|Z=1)         10                 011                             XXX         00000000

BGT RX, IMM        (Branch Greater than or Equal, CPSR N=0|Z=1)      10                 100                             XXX         00000000

CMP RX, IMM        (Compare with immediate value)                    10                 101                             XXX         00000000

UCMP RX, IMM       (Unsigned compare with immediate value)           10                 110                             XXX         00000000

 

//Immediate Value instructions continued                                                                                REG(out)    REG(in)    IMM    UNUSED

LSL  RZ, RX, IMM   (Logical shift left with immediate val)           11                 000				XXX	    YYY        0000   0

LSR  RZ, RX, IMM   (Logical shift right with immediate val)          11                 001                             XXX         YYY        0000   0

ASR  RZ, RX, IMM   (Arithmetic shift right with immediate val)       11                 010                             XXX         YYY        0000   0

ASL  RZ, RX, IMM   (Arithmetic shift right with immediate val)       11                 011                             XXX         YYY        0000   0

ROR  RZ, RX, IMM   (Rotate right with immediate val)                 11                 100                             XXX         YYY        0000   0

