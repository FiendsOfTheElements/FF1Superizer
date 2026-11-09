## Building
To build the ROM, you'll need:
* cc65
* Make
* .NET 10 SDK
* An FF1 ROM, which you should place in the ROMAssembly directory and name `ff1.nes`.  The necessary data will be automatically extracted and compiled into the SNES ROM.

Just run `make` from the command line.

**Note:** We want the Makefile to eventually run the ff1ripper scripts as .cs files straight from the command line, this will require at least .NET 11.
**Another note:** This may be obsoleted by the editor, not sure how we want this to work yet.
