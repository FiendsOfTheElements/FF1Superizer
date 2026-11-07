## Building
To build the ROM, you'll need cc65 and make.  You'll also need an FF1 ROM, which you can place in the ROMAssembly directory and name `ff1.nes`.
You will also need .NET 10 to extract data from the source ROM.  The necessary data will be automatically extracted and compiled into the SNES ROM.

Just run `make` from the command line.

**Note:** We want the Makefile to eventually run the ff1ripper scripts as .cs files straight from the command line, this will require .NET 10.
