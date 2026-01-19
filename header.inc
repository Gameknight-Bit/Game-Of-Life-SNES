;==LoRom==    ;NOT HiRom

.MEMORYMAP    ;Describe System Architecture
    SLOTSIZE $8000
    DEFAULTSLOT 0
    SLOT 0 $8000
.ENDME

.ROMBANKSIZE $8000 ;Every ROM Bank is 32KB in size
.ROMBANKS 8        ;2 MBits - Tell WLA we want 8 ROM Banks

.SNESHEADER
    ID "SNES"

    NAME "The Game of Life     "  ;Program Title - can't be over 21 bytes,
    ;    "123456789012345678901"  ;use spaces for unused bytes of the name.

    SLOWROM
    LOROM

    CARTRIDGETYPE $00             ;$00 = ROM only
    ROMSIZE $08                   ;$08 = 2 MBits
    SRAMSIZE $00                  ;No SRAM
    COUNTRY $01                   ;$01 = U.S.
    LICENSEECODE $00
    VERSION $00
.ENDSNES

.SNESNATIVEVECTOR         ;Def Native Mode Interrupt Vec Table
    COP EmptyHandler
    BRK EmptyHandler
    ABORT EmptyHandler
    NMI VBlank
    IRQ EmptyHandler
.ENDNATIVEVECTOR

.SNESEMUVECTOR            ;Def Emulation Mode Interrupt Vec Table
    COP EmptyHandler
    ABORT EmptyHandler
    NMI VBlank
    RESET Start           ;Where Execution Starts!!!
    IRQBRK EmptyHandler
.ENDEMUVECTOR

.BANK 0 SLOT 0
.ORG 0
.SECTION "EmptyVectors" SEMIFREE

EmptyHandler:
    rti
.ENDS

.EMPTYFILL $00           ;Fill unused areas with $00, BRK opcode
                         ;BRK will crash snes if executed.