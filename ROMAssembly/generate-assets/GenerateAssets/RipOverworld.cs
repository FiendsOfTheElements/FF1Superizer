namespace GenerateAssets;

using static NesRipper;

public static class RipOverworld
{
	public static void RipOverworldCharacters()
	{
		var tilemaps = RipOverworldTilemaps();
		var paletteMaps = RipOverworldTilePaletteMaps();
		// AFAIK, no tiles are reused with different palettes.  So we'll just store "the" palette
		// for each tile.  We'll shift it up by 2 bits so we can OR it with the tile data to get
		// a 4bpp color.
		var tilePalettes = new byte[0x100];
		for (int i = 0; i < 0x80; i++)
		{
			tilePalettes[tilemaps[i]]         = (byte)((paletteMaps[i] << 2) & 0x0C);
			tilePalettes[tilemaps[i + 0x80]]  = (byte)(paletteMaps[i] & 0x0C);
			tilePalettes[tilemaps[i + 0x100]] = (byte)((paletteMaps[i] >> 2) & 0x0C);
			tilePalettes[tilemaps[i + 0x180]] = (byte)((paletteMaps[i] >> 4) & 0x0C);
		}

		using var readStream = File.Open("ff1.nes", FileMode.Open, FileAccess.Read);
		using var writeStream = File.Open("assets/graphics/overworld-chr.m7", FileMode.Create, FileAccess.Write);

		var tileData2bpp = new byte[0x10]; // one 2bpp tile is 16 bytes
		var tileData8bpp = new byte[0x40]; // one 8bpp tile is 64 bytes
		readStream.Position = 0x8010; // Overworld character data starts at the beginning of bank 02
		for (int i = 0; i < 0x100; i++) // 256 tiles
		{
			var palette = tilePalettes[i];
			readStream.Read(tileData2bpp, 0, 0x10); // Read one 2bpp character (16 bytes)
			for (int y = 0; y < 8; y++) // 8 rows of pixels
			{
				for (int x = 0; x < 8; x++) // 8 pixels per row
				{
					var lowBit = tileData2bpp[y] >> (7 - x) & 1;
					var highBit = tileData2bpp[y + 8] >> (7 - x) & 1;
					tileData8bpp[y * 8 + x] = (byte)((highBit << 1) | lowBit | palette);
				}
			}
			writeStream.Write(tileData8bpp, 0, 0x40); // Write one 8bpp character (64 bytes)
		}

		readStream.Close();
		writeStream.Close();
	}

	public static byte[] RipOverworldTilemaps()
	{
		using var readStream = File.Open("ff1.nes", FileMode.Open, FileAccess.Read);
		using var writeStream = File.Open("assets/data/overworld-tilemaps.bin", FileMode.Create, FileAccess.Write);

		// There are 128 tiles.  The tilemap stores the upper-left character of each tile, then the upper-right, lower-left, and lower-right.
		// A character index is one byte, so the whole tilemap is 512 bytes.
		var tilemapData = new byte[0x200];
		readStream.Position = 0x0110; // Overworld tilemap data starts at 0x0100 in bank 00
		readStream.Read(tilemapData, 0, tilemapData.Length); // Read the entire tilemap
		writeStream.Write(tilemapData, 0, tilemapData.Length); // Write the tilemap to file

		readStream.Close();
		writeStream.Close();

		return tilemapData;
	}

	public static byte[] RipOverworldTilePaletteMaps()
	{
		using var readStream = File.Open("ff1.nes", FileMode.Open, FileAccess.Read);

		// There are 128 tiles, each made of 4 characters, and each character has a palette.
		// A palette index is only 2 bits, so this data fits into 128 bytes.
		var paletteMapData = new byte[0x80];
		readStream.Position = 0x0310; // Overworld palette map data starts at 0x0300 in bank 00
		readStream.Read(paletteMapData, 0, paletteMapData.Length); // Read the entire palette map
		readStream.Close();

		// We don't need to write these, because we'll just apply each palette to the tile data
		// to make them 4bpp.

		return paletteMapData;
	}

	public static void RipOverworldMap()
	{
		using var readStream = File.Open("ff1.nes", FileMode.Open, FileAccess.Read);
		using var writeStream = File.Open("assets/data/overworld-map.bin", FileMode.Create, FileAccess.Write);

		// The overworld map is 256 RLE compressed rows, each having a 2-byte pointer.
		// The pointers are stored in the first 512 bytes, and they index into the map
		// data.  The compressed data doesn't QUITE fill up the entire bank, but it's
		// close, so we can just dump the whole thing here.
		// There is some unrelated data at the end of this bank, about 160 bytes.
		// Dunno what it is.
		var mapData = new byte[0x4000];
		readStream.Position = 0x4010; // Overworld map data starts at the beginning of bank 01
		readStream.Read(mapData, 0, mapData.Length); // Read the entire map, including the pointers
		for (int i = 1; i < 0x0200; i+=2) // we need to fix the pointers
		{
			mapData[i] &= 0x7F; // these pointers are relative to 0x8000, but we want them to be zero-based
		}
		writeStream.Write(mapData, 0, mapData.Length); // Write the map to file

		readStream.Close();
		writeStream.Close();
	}

	public static void RipOverworldTileProperties()
	{
		using var readStream = File.Open("ff1.nes", FileMode.Open, FileAccess.Read);
		using var writeStream = File.Open("assets/data/overworld-tileproperties.bin", FileMode.Create, FileAccess.Write);

		// There are 128 tiles, each has 2 bytes of properties.
		var tilePropertyData = new byte[0x100];
		readStream.Position = 0x0010; // Overworld tile property data starts at the very beginning of the ROM
		readStream.Read(tilePropertyData, 0, tilePropertyData.Length); // Read the entire tilemap
		writeStream.Write(tilePropertyData, 0, tilePropertyData.Length); // Write the tilemap to file

		readStream.Close();
		writeStream.Close();
	}

	public static void RipOverworldSprites()
	{
		using var readStream = File.Open("ff1.nes", FileMode.Open, FileAccess.Read);
		using var writeStream = File.Open("assets/graphics/overworld-sprites.4bpp", FileMode.Create, FileAccess.Write);

		var spriteData2bpp = new byte[0x1180];
		readStream.Position = 0x9010; // start of sprite data
		readStream.Read(spriteData2bpp, 0, spriteData2bpp.Length); // Read all the sprite data

		// All of these sprites are 16x16, stored as 8x8 tiles, UL-UR-LL-LR.
		// We need to convert them to 4bpp SNES format, and put the lower two tiles 16 tiles after
		// the upper two tiles.
		byte[][] snesSprites = new byte[15 * 6][];
		for (int i = 0; i < snesSprites.Length; i++)
		{
			snesSprites[i] = new byte[0x80]; // each SNES sprite is 32 bytes * 4 tiles
		}

		// Start with the player sprites.  There are 12 of these, one for each class.  Each one has
		// facing down, up, and left (facing right is just mirrored).  Facing left has two frames
		// of animation, facing up or down animates by simply mirroring the bottom two tiles.  We
		// will store two frames of animation though, because it's simpler and SNES has the VRAM.
		byte[] classTopPalettes = [0, 1, 2, 0, 3, 2, 0, 0, 2, 0, 0, 2];
		byte[] classBottomPalettes = [0, 2, 1, 0, 3, 1, 0, 0, 1, 0, 3, 1];
		for (int i = 0; i < 12; i++)
		{
			int nesOffset = i * 0x10 * 4 * 4; // 16 bytes, 4 sprites, 4 tiles each

			// Down
			NesSpriteToSnesSprite(spriteData2bpp[nesOffset..(nesOffset + 0x40)], snesSprites[i * 6], classTopPalettes[i], classBottomPalettes[i]);
			// Down second frame, the lower two tiles are horizontally flipped
			NesSpriteToSnesSpriteBottomRowFlipped(spriteData2bpp[nesOffset..(nesOffset + 0x40)], snesSprites[i * 6 + 1], classTopPalettes[i], classBottomPalettes[i]);
			// Up
			NesSpriteToSnesSprite(spriteData2bpp[(nesOffset + 0x40)..(nesOffset + 0x80)], snesSprites[i * 6 + 2], classTopPalettes[i], classBottomPalettes[i]);
			// Up second frame
			NesSpriteToSnesSpriteBottomRowFlipped(spriteData2bpp[(nesOffset + 0x40)..(nesOffset + 0x80)], snesSprites[i * 6 + 3], classTopPalettes[i], classBottomPalettes[i]);
			// Left
			NesSpriteToSnesSprite(spriteData2bpp[(nesOffset + 0x80)..(nesOffset + 0xC0)], snesSprites[i * 6 + 4], classTopPalettes[i], classBottomPalettes[i]);
			// Left second frame
			NesSpriteToSnesSprite(spriteData2bpp[(nesOffset + 0xC0)..(nesOffset + 0x100)], snesSprites[i * 6 + 5], classTopPalettes[i], classBottomPalettes[i]);
		}

		// Ship, Airship, Canoe, these are the same as above, but they don't mirror the bottom half to
		// animate, they actually have full frames.
		int baseVehicleOffset = 13 * 0x10 * 4 * 4; // 16 bytes, 4 sprites, 4 tiles each, +1 for a few random sprites
		for (int i = 0; i < 3; i++)
		{
			for (int j = 0; j < 6; j++)
			{
				int nesOffset = baseVehicleOffset + (i * 6 + j) * 4 * 0x10;
				NesSpriteToSnesSprite(spriteData2bpp[nesOffset..(nesOffset + 0x40)], snesSprites[(i + 12) * 6 + j], 3, 3); // All of these are palette 3?
			}
		}

		// Now we write the output.  The way sprites are stored in VRAM, the lower two tiles are a "row" lower, or 16 tile-lengths farther.
		int numRows = (int)Math.Ceiling((decimal)snesSprites.Length / 8);
		byte[] output = new byte[0x20 * 8 * 4 * numRows]; // 32 bytes, 8 sprites, 4 tiles each
		for (int i = 0; i < snesSprites.Length; i++)
		{
			int offset = (i / 8) * 0x20 * 8 * 4 + (i % 8) * 0x20 * 2;
			Array.Copy(snesSprites[i], 0, output, offset, 0x20 * 2);
			Array.Copy(snesSprites[i], 0x20 * 2, output, offset + 16 * 0x20, 0x20 * 2);
		}

		writeStream.Write(output, 0, output.Length);
	}
}
