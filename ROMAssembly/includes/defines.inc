BANK_MAIN          = $00
BANK_AIRSHIPM7     = $01
BANK_OVERWORLD     = $02
BANK_OWGRAPHICS    = $03
BANK_TITLEGRAPHICS = $04
BANK_BATTLESPRITES = $05

; WRAM locations CAN overlap, but only if the bits of code using the overlap are okay with it!

; Low WRAM locations
; We don't have to define EVERY temp variable here.  It is expected that procs will define their own
; temp variables, and that module code is kept reasonably close together so they can coordinate.
GameMode                 = $FF ; For now, we use overworld for the title screen (because it's mode 7)
GAME_MODE_OVERWORLD      = $01 ; and dungeon for anything else (because it's mode 1).  Depending on
GAME_MODE_DUNGEON        = $02 ; what the game needs, we can add more modes.

JoyPad1          = $0300     ; data read from joypad 1
JoyTrigger1      = $0302     ; trigger read from joypad 1
JoyHeld1         = $0304     ; held buttons read from joypad 1

OamMirror        = $05E0     ; to $07FF, this gets DMA'd to OAM every frame

TileMapBuffer      = $1D00   ; this is a buffer from which a row or column of tiles will be DMA'd into VRAM, 256 bytes
TileMapBufferDirty = $1CFF   ; this stores a 1 if the tilemap buffer contains a row, a 2 if it stores a column, and a 0 otherwise
TileMapBufferIndex = $1CFE   ; this stores the index of the row or column contained in the buffer, 0 to 63

StackBase        = $1E00     ; expected to be no more than 512 bytes, grows from $1FFF downward

BG3TileMapBuffer      = $1400 ; $800 bytes, the BG3 tilemap gets stored here so we can draw windows and text on it
BG3TileMapBufferDirty = $13FF ; stores a 1 if BG3 needs to be DMA'd from this buffer

; High WRAM locations
OverworldMapBank = $7E
OverworldMap     = $4000     ; store the decompressed overworld map from $7E:4000-7E:7FFF (64 rows x 256 columns, 4096 bytes)
OverworldMapL    = $7E4000

; Overworld tile properties
OWTP_NoWalk       = $0001
OWTP_NoCanoe      = $0002
OWTP_NoShip       = $0004
OWTP_NoAirship    = $0008 ; can't land
OWTP_Forest       = $0010
OWTP_Dock         = $0020
OWTP_EventMask    = $00C0
OWTP_EventChime   = $0040 ; need chime to enter
OWTP_EventCaravan = $0080
OWTP_EventAirship = $00C0 ; can use the FLOATER to raise the airship from here
OWTP_Fight        = $4000
OWTP_FightRiver   = $4100
OWTP_FightOcean   = $4200
OWTP_Teleport     = $8000
