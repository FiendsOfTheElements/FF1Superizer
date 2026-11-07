SRC = $(wildcard src/*.asm)
OBJ = $(patsubst src/%.asm, obj/%.o, $(SRC))
INC = $(wildcard includes/*.inc)

ff1snes.smc: $(OBJ)
	ld65 -C memory-map.cfg --dbgfile ff1snes.dbg $(OBJ) -o ff1snes.smc

rip:
	dotnet run --project generate-assets/GenerateAssets/GenerateAssets.csproj

obj/%.o: src/%.asm $(INC) rip
	@mkdir -p obj
	ca65 --cpu 65816 --include-dir includes --bin-include-dir assets --smart --debug-info -o $@ $<

clean:
	rm obj/*
	rm assets/data/*
	rm assets/graphics/*
	rm ff1snes.smc
