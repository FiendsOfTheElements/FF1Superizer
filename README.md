# Final Fantasy Superizer

A port of Final Fantasy Randomizer to the SNES.  All SNES code is written from the ground up: No asm code was copied from the original NES game, though the disassembly was certainly used as a reference.

## Project Structure
* **ROMAssembly** contains all the assembly code needed to build the SNES ROM.
* **Editor** contains an editor that can produce maps, data files for items and enemies, graphics packs, etc. that can be assembled into the ROM.
* **Randomizer** contains the actual randomizer application.  This will shuffle up the data files, set environment variables for the assembler, and create an initial state for the ROM so that it runs the correct code path for the randomizer options.
