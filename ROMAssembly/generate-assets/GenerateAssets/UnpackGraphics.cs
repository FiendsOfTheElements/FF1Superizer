using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;

namespace GenerateAssets;

using static ImageRipper;

public static class UnpackGraphics
{
	public static void UnpackOverworldCharacterSprites()
	{
		using var image = Image.Load<Bgra5551>("packs/ff4like/CharacterSprites.png");
		byte[] sprites = new byte[0x4000]; // half a bank full of sprites
		byte[] palettes = new byte[0x200]; // 16 palettes of 16 colors each, 2 bytes per color
		for (int c = 0; c < 6; c++) // character classes
		{
			var inversePalette = GetInversePalette(image, new Rectangle(0, 192 + 16*c, 64, 16));
			var palette = GetPalette(inversePalette, 16);
			Buffer.BlockCopy(palette, 0, palettes, 32*c, 32);

			byte[] character;
			// Top row
			// Facing down
			character = ConvertBgra5551To4bpp(image, new Point(0, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0);
			character = ConvertBgra5551To4bpp(image, new Point(8, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x20);
			character = ConvertBgra5551To4bpp(image, new Point(0, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x40);
			character = ConvertBgra5551To4bpp(image, new Point(8, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x60);
			// Facing up
			character = ConvertBgra5551To4bpp(image, new Point(16, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x80);
			character = ConvertBgra5551To4bpp(image, new Point(24, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0xA0);
			character = ConvertBgra5551To4bpp(image, new Point(16, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0xC0);
			character = ConvertBgra5551To4bpp(image, new Point(24, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0xE0);
			// Facing left
			character = ConvertBgra5551To4bpp(image, new Point(32, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x100);
			character = ConvertBgra5551To4bpp(image, new Point(40, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x120);
			character = ConvertBgra5551To4bpp(image, new Point(48, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x140);
			character = ConvertBgra5551To4bpp(image, new Point(56, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x160);
			// Facing right
			character = ConvertBgra5551To4bpp(image, new Point(40, 192 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x180);
			character = ConvertBgra5551To4bpp(image, new Point(32, 192 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x1A0);
			character = ConvertBgra5551To4bpp(image, new Point(56, 192 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x1C0);
			character = ConvertBgra5551To4bpp(image, new Point(48, 192 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x1E0);

			// Bottom row
			// Facing down
			character = ConvertBgra5551To4bpp(image, new Point(0, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x200);
			character = ConvertBgra5551To4bpp(image, new Point(8, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x220);
			character = ConvertBgra5551To4bpp(image, new Point(8, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x240);
			character = ConvertBgra5551To4bpp(image, new Point(0, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x260);
			// Facing up
			character = ConvertBgra5551To4bpp(image, new Point(16, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x280);
			character = ConvertBgra5551To4bpp(image, new Point(24, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x2A0);
			character = ConvertBgra5551To4bpp(image, new Point(24, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x2C0);
			character = ConvertBgra5551To4bpp(image, new Point(16, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x2E0);
			// Facing left
			character = ConvertBgra5551To4bpp(image, new Point(32, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x300);
			character = ConvertBgra5551To4bpp(image, new Point(40, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x320);
			character = ConvertBgra5551To4bpp(image, new Point(48, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x340);
			character = ConvertBgra5551To4bpp(image, new Point(56, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x400*c + 0x360);
			// Facing right
			character = ConvertBgra5551To4bpp(image, new Point(40, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x380);
			character = ConvertBgra5551To4bpp(image, new Point(32, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x3A0);
			character = ConvertBgra5551To4bpp(image, new Point(56, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x3C0);
			character = ConvertBgra5551To4bpp(image, new Point(48, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x400*c + 0x3E0);
		}
		for (int c = 0; c < 6; c++) // promoted classes
		{
			var inversePalette = GetInversePalette(image, new Rectangle(104, 192 + 16*c, 64, 16));
			var palette = GetPalette(inversePalette, 16);
			Buffer.BlockCopy(palette, 0, palettes, 32*(c + 6), 32);

			byte[] character;
			// Top row
			// Facing down
			character = ConvertBgra5551To4bpp(image, new Point(104, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0);
			character = ConvertBgra5551To4bpp(image, new Point(112, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x20);
			character = ConvertBgra5551To4bpp(image, new Point(104, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x40);
			character = ConvertBgra5551To4bpp(image, new Point(112, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x60);
			// Facing up
			character = ConvertBgra5551To4bpp(image, new Point(120, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x80);
			character = ConvertBgra5551To4bpp(image, new Point(128, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0xA0);
			character = ConvertBgra5551To4bpp(image, new Point(120, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0xC0);
			character = ConvertBgra5551To4bpp(image, new Point(128, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0xE0);
			// Facing left
			character = ConvertBgra5551To4bpp(image, new Point(136, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x100);
			character = ConvertBgra5551To4bpp(image, new Point(144, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x120);
			character = ConvertBgra5551To4bpp(image, new Point(152, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x140);
			character = ConvertBgra5551To4bpp(image, new Point(160, 192 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x160);
			// Facing right
			character = ConvertBgra5551To4bpp(image, new Point(144, 192 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x180);
			character = ConvertBgra5551To4bpp(image, new Point(136, 192 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x1A0);
			character = ConvertBgra5551To4bpp(image, new Point(160, 192 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x1C0);
			character = ConvertBgra5551To4bpp(image, new Point(152, 192 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x1E0);

			// Bottom row
			// Facing down
			character = ConvertBgra5551To4bpp(image, new Point(104, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x200);
			character = ConvertBgra5551To4bpp(image, new Point(112, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x220);
			character = ConvertBgra5551To4bpp(image, new Point(112, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x240);
			character = ConvertBgra5551To4bpp(image, new Point(104, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x260);
			// Facing up
			character = ConvertBgra5551To4bpp(image, new Point(120, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x280);
			character = ConvertBgra5551To4bpp(image, new Point(128, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x2A0);
			character = ConvertBgra5551To4bpp(image, new Point(128, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x2C0);
			character = ConvertBgra5551To4bpp(image, new Point(120, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x2E0);
			// Facing left
			character = ConvertBgra5551To4bpp(image, new Point(136, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x300);
			character = ConvertBgra5551To4bpp(image, new Point(144, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x320);
			character = ConvertBgra5551To4bpp(image, new Point(152, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x340);
			character = ConvertBgra5551To4bpp(image, new Point(160, 200 + 16*c), inversePalette);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x360);
			// Facing right
			character = ConvertBgra5551To4bpp(image, new Point(144, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x380);
			character = ConvertBgra5551To4bpp(image, new Point(136, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x3A0);
			character = ConvertBgra5551To4bpp(image, new Point(160, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x3C0);
			character = ConvertBgra5551To4bpp(image, new Point(152, 200 + 16*c), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x1800 + 0x400*c + 0x3E0);
		}
		for (int v = 0; v < 3; v++) // vehicles
		{
			var inversePalette = GetInversePalette(image, new Rectangle(0, 320 + 16*v, 96, 16));
			var palette = GetPalette(inversePalette, 16);
			Buffer.BlockCopy(palette, 0, palettes, 32*(v + 12), 32);

			byte[] character;
			for (int i = 0; i < 12; i++) // Facing up, down, left
			{
				// Top row
				character = ConvertBgra5551To4bpp(image, new Point(i*8, 320 + 16*v), inversePalette);
				character.CopyTo(sprites, 0x3000 + 0x400*v + 0x20*i);
				// Bottom row
				character = ConvertBgra5551To4bpp(image, new Point(i*8, 328 + 16*v), inversePalette);
				character.CopyTo(sprites, 0x3000 + 0x400*v + 0x200 + 0x20*i);
			}
			// Facing right
			// Top row
			character = ConvertBgra5551To4bpp(image, new Point(72, 320 + 16*v), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x3000 + 0x400*v + 0x180);
			character = ConvertBgra5551To4bpp(image, new Point(64, 320 + 16*v), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x3000 + 0x400*v + 0x1A0);
			character = ConvertBgra5551To4bpp(image, new Point(88, 320 + 16*v), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x3000 + 0x400*v + 0x1C0);
			character = ConvertBgra5551To4bpp(image, new Point(80, 320 + 16*v), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x3000 + 0x400*v + 0x1E0);
			// Bottom row
			character = ConvertBgra5551To4bpp(image, new Point(72, 328 + 16*v), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x3000 + 0x400*v + 0x380);
			character = ConvertBgra5551To4bpp(image, new Point(64, 328 + 16*v), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x3000 + 0x400*v + 0x3A0);
			character = ConvertBgra5551To4bpp(image, new Point(88, 328 + 16*v), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x3000 + 0x400*v + 0x3C0);
			character = ConvertBgra5551To4bpp(image, new Point(80, 328 + 16*v), inversePalette, flipped: true);
			character.CopyTo(sprites, 0x3000 + 0x400*v + 0x3E0);
		}
		// Airship shadow and mini ship
		byte[] etcCharacter = new byte[32];
		var etcInversePalette = GetInversePalette(image, new Rectangle(0, 320, 96, 16)); // same as vehicle palette

		etcCharacter = ConvertBgra5551To4bpp(image, new Point(64, 272), etcInversePalette);
		etcCharacter.CopyTo(sprites, 0x3c00);
		etcCharacter = ConvertBgra5551To4bpp(image, new Point(72, 272), etcInversePalette);
		etcCharacter.CopyTo(sprites, 0x3c20);
		etcCharacter = ConvertBgra5551To4bpp(image, new Point(80, 272), etcInversePalette);
		etcCharacter.CopyTo(sprites, 0x3c40);
		etcCharacter = ConvertBgra5551To4bpp(image, new Point(88, 272), etcInversePalette);
		etcCharacter.CopyTo(sprites, 0x3c60);
		etcCharacter = ConvertBgra5551To4bpp(image, new Point(64, 280), etcInversePalette);
		etcCharacter.CopyTo(sprites, 0x3d00);
		etcCharacter = ConvertBgra5551To4bpp(image, new Point(72, 280), etcInversePalette);
		etcCharacter.CopyTo(sprites, 0x3d20);
		etcCharacter = ConvertBgra5551To4bpp(image, new Point(80, 280), etcInversePalette);
		etcCharacter.CopyTo(sprites, 0x3d40);
		etcCharacter = ConvertBgra5551To4bpp(image, new Point(88, 280), etcInversePalette);
		etcCharacter.CopyTo(sprites, 0x3d60);

		using var spriteFile = File.OpenWrite("assets/graphics/overworld-sprites.4bpp");
		spriteFile.Write(sprites);
		spriteFile.Close();

		using var paletteFile = File.OpenWrite("assets/graphics/overworld-sprite-palettes.pal");
		paletteFile.Write(palettes);
		paletteFile.Close();
	}

	public static void UnpackOverworldGraphics()
	{
		using var image = Image.Load<Bgra5551>("packs/ff4like/OverworldTiles.png");
		var inversePalette = GetInversePalette(image, new Rectangle(0, 0, 144, 240));
		var palette = GetPalette(inversePalette, 128);

		// We need to generate tilemaps and the character graphics themselves.
		// For each map tile in the original game, there is a 16x16 section of the graphics pack
		// that has the graphics for that tile.  So the graphicsMap maps which graphics belong to
		// which original map tile.
		(int x, int y)[] graphicsMap = [
			(  0,   0), ( 32, 144), ( 48, 144), (  0,  16), ( 16,  16), ( 32,  16), ( 96,  16), (112,  16), (128,  16), ( 32, 112), ( 48, 112), (  0, 144), ( 16, 144), ( 32, 160), ( 32,   0), ( 96, 144),
			(  0,  64), ( 16,  64), ( 32,  64), (  0,  32), ( 16,  32), ( 32,  32), ( 96,  32), (112,  32), (128,  32), ( 32, 128), ( 48, 128), (  0, 160), ( 16, 160), ( 32, 192), ( 48, 160), (128, 128),
			(  0,  80), ( 16,  80), ( 32,  80), (  0,  48), ( 16,  48), ( 32,  48), ( 96,  48), (112,  48), (128,  48), (  0, 160), ( 16, 160), ( 32,   0), ( 64, 160), ( 80, 160), ( 96, 160), ( 32,   0),
			(  0,  96), ( 16,  96), ( 32,   0), ( 32,  96), ( 32,   0), ( 32,   0), (112,  80), (112,  80), (  0, 160), ( 16, 160), ( 32,   0), (112, 160), (  0,   0), (  0,   0), (  0,   0), (112, 176),
			( 48,  16), ( 80,  16), ( 96,  64), (128,  64), ( 64,  32), (112,  80), ( 48,   0), ( 64, 112), ( 80, 112), (128, 160), (128, 160), (112, 160), (128, 160), (128, 176), (128, 160), (112, 176),
			( 48,  48), ( 80,  48), ( 96,  96), (128,  96), ( 64,  80), (128, 112), ( 64, 144), ( 64, 128), ( 80, 128), ( 80, 144), (128, 176), (112, 160), ( 48, 176), (128, 176), ( 96, 176), (112, 176),
			( 48,  64), ( 80,  64), ( 96, 112), (112, 112), (  0, 112), ( 16, 112), ( 16,   0), ( 16,   0), ( 16,   0), ( 16,   0), ( 16,   0), (112, 160), ( 16,   0), (128, 160), ( 16,   0), (112, 176),
			( 48,  96), ( 80,  96), ( 96, 128), (112, 128), (  0, 128), ( 16, 128), (  0,   0), (  0,   0), (128, 144), (  0,   0), (  0,   0), ( 48, 176), ( 80, 160), ( 64, 176), ( 80, 176), ( 96, 176),
		];
		Console.WriteLine($"{graphicsMap.Distinct().Count()} unique map tiles");

		// The tileMap stores which 8x8 characters make up each tile.  Tiles can be flipped horizontally
		// or vertically, so we need to compare to flipped versions of tiles we've seen before.
		var ulTilemap = new byte[128];
		var urTilemap = new byte[128];
		var llTilemap = new byte[128];
		var lrTilemap = new byte[128];
		Dictionary<int, int> seenChrLookup = [];
		var chrGraphics = new byte[0x8000]; // This only needs to be 0x4000, but we make it big enough to hold
		// all the possible graphics that could be in the file.  That way this doesn't crash, and you can examine
		// its output to see what needs to be trimmed.
		for (int tileIndex = 0; tileIndex < 128; tileIndex++)
		{
			byte[] chr;
			int hash;
			var (x, y) = graphicsMap[tileIndex];
			chr = ConvertBgra5551To8bpp(image, new Point(x, y), inversePalette);
			hash = HashChr(chr);
			if (!seenChrLookup.ContainsKey(hash))
			{
				int thisChrIndex = seenChrLookup.Count;
				chr.CopyTo(chrGraphics, 64*thisChrIndex);
				seenChrLookup.Add(hash, thisChrIndex);
			}
			ulTilemap[tileIndex] = (byte)seenChrLookup[hash];

			chr = ConvertBgra5551To8bpp(image, new Point(x + 8, y), inversePalette);
			hash = HashChr(chr);
			if (!seenChrLookup.ContainsKey(hash))
			{
				chr.CopyTo(chrGraphics, 64*seenChrLookup.Count);
				seenChrLookup.Add(hash, seenChrLookup.Count);
			}
			urTilemap[tileIndex] = (byte)seenChrLookup[hash];

			chr = ConvertBgra5551To8bpp(image, new Point(x, y + 8), inversePalette);
			hash = HashChr(chr);
			if (!seenChrLookup.ContainsKey(hash))
			{
				chr.CopyTo(chrGraphics, 64*seenChrLookup.Count);
				seenChrLookup.Add(hash, seenChrLookup.Count);
			}
			llTilemap[tileIndex] = (byte)seenChrLookup[hash];

			chr = ConvertBgra5551To8bpp(image, new Point(x + 8, y + 8), inversePalette);
			hash = HashChr(chr);
			if (!seenChrLookup.ContainsKey(hash))
			{
				chr.CopyTo(chrGraphics, 64*seenChrLookup.Count);
				seenChrLookup.Add(hash, seenChrLookup.Count);
			}
			lrTilemap[tileIndex] = (byte)seenChrLookup[hash];
		}

		Console.WriteLine($"{seenChrLookup.Count} unique chr");

		using var paletteFile = File.OpenWrite("assets/graphics/overworld-map-palette.pal");
		var paletteBytes = new byte[128];
		Buffer.BlockCopy(palette, 0, paletteBytes, 0, 128);
		paletteFile.Write(paletteBytes);
		paletteFile.Close();

		using var overworldChrFile = File.OpenWrite("assets/graphics/overworld-chr.m7");
		overworldChrFile.Write(chrGraphics, 0, 0x4000); // only write 16 KB, if there's more, we need to strip down
		overworldChrFile.Close();

		using var overworldTilemapFile = File.OpenWrite("assets/data/overworld-tilemaps.bin");
		overworldTilemapFile.Write(ulTilemap);
		overworldTilemapFile.Write(urTilemap);
		overworldTilemapFile.Write(llTilemap);
		overworldTilemapFile.Write(lrTilemap);
		overworldTilemapFile.Close();
	}

	public static void UnpackTitleScreen()
	{
		using var image = Image.Load<Bgra5551>("packs/ff4like/TitleScreen.png");
		var inversePalette = GetInversePalette(image, new Rectangle(0, 0, 256, 240));
		var palette = GetPalette(inversePalette, 16);

		byte[] spriteGraphics = new byte[0x2800]; // 10 KB
		byte[] spriteData = new byte[544];
		// Initialize all sprites to be off-screen.
		for (int i = 1; i < 512; i += 4)
		{
			spriteData[i] = (byte)0xe0;
		}
		for (int i = 512; i < 544; i++)
		{
			spriteData[i] = (byte)0x55;
		}

		// FINAL FANTASY
		for (int i = 0; i < 8; i++)
		{
			Rip32x32Sprite(image, new Point(32 * i, 40), 32, inversePalette, spriteGraphics, i);
			WriteSpriteData(spriteData, i, new Point(32 * i, 40), 4 * (i % 4) + 4 * 16 * (i / 4), isLarge: true);
			Rip32x32Sprite(image, new Point(32 * i, 72), 32, inversePalette, spriteGraphics, i + 8);
			WriteSpriteData(spriteData, i + 8, new Point(32 * i, 72), 4 * (i % 4) + 4 * 16 * (i / 4) + 2 * 4 * 16, isLarge: true);
		}

		// Superizer
		Rip32x32Sprite(image, new Point(130, 107), 32, inversePalette, spriteGraphics, 16);
		Rip32x32Sprite(image, new Point(162, 107), 32, inversePalette, spriteGraphics, 17);
		Rip32x32Sprite(image, new Point(194, 107), 32, inversePalette, spriteGraphics, 18);
		Rip32x32Sprite(image, new Point(226, 107), 27, inversePalette, spriteGraphics, 19);

		WriteSpriteData(spriteData, 16, new Point(131, 107), 256, isLarge: true);
		WriteSpriteData(spriteData, 17, new Point(163, 107), 260, isLarge: true);
		WriteSpriteData(spriteData, 18, new Point(195, 107), 264, isLarge: true);
		WriteSpriteData(spriteData, 19, new Point(227, 107), 268, isLarge: true);

		using var paletteFile = File.OpenWrite("assets/graphics/title-screen-palette.pal");
		var paletteBytes = new byte[32];
		Buffer.BlockCopy(palette, 0, paletteBytes, 0, 32);
		paletteFile.Write(paletteBytes);
		paletteFile.Close();

		using var spriteGraphicsFile = File.OpenWrite("assets/graphics/title-screen-sprites.4bpp");
		spriteGraphicsFile.Write(spriteGraphics);
		spriteGraphicsFile.Close();

		using var spriteDataFile = File.OpenWrite("assets/data/title-screen-sprites.bin");
		spriteDataFile.Write(spriteData);
		spriteDataFile.Close();
	}

	public static void UnpackFont()
	{
		using var image = Image.Load<Bgra5551>("packs/ff4like/Font.png");
		var inversePalette = GetInversePalette(image, new Rectangle(0, 0, 128, 48));
		byte[] fontChr = new byte[0x1000]; // 4 KB
		byte[] chr;

		int[] asciiMapping = [
			0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d,
			0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a,
			0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d,
			0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a,
			0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x2e, 0x21, 0x3f,
			0x3a, 0x3b, 0x2c, 0x27, 0x22, 0x5f, 0x25, 0x2f, 0x5b, 0x5d, 0x2d, 0x2b, 0x20
		];

		for (int i = 0; i < asciiMapping.Length; i++)
		{
			int x = i % 13;
			int y = i / 13;
			chr = ConvertBgra5551To2bpp(image, new Point(8 * x, 8 * y), inversePalette);
			chr.CopyTo(fontChr, 16 * asciiMapping[i]);
		}

		// Icons
		for (int i = 78; i < 130; i++)
		{
			int y = i / 13 + 42;
			int x = i % 13;
			chr = ConvertBgra5551To2bpp(image, new Point(8 * x, 8 * y), inversePalette);
			chr.CopyTo(fontChr, 16 * (i - 78 + 0x80));
		}

		// Last three icons
		chr = ConvertBgra5551To2bpp(image, new Point(80, 416), inversePalette);
		chr.CopyTo(fontChr, 16 * 180);
		chr = ConvertBgra5551To2bpp(image, new Point(88, 416), inversePalette);
		chr.CopyTo(fontChr, 16 * 181);
		chr = ConvertBgra5551To2bpp(image, new Point(96, 416), inversePalette);
		chr.CopyTo(fontChr, 16 * 182);

		// Window (these are mapped to DOS box-drawing characters)
		chr = ConvertBgra5551To2bpp(image, new Point(104, 0), inversePalette);
		chr.CopyTo(fontChr, 16 * 0xc9);
		chr = ConvertBgra5551To2bpp(image, new Point(112, 0), inversePalette);
		chr.CopyTo(fontChr, 16 * 0xcb);
		chr = ConvertBgra5551To2bpp(image, new Point(120, 0), inversePalette);
		chr.CopyTo(fontChr, 16 * 0xbb);
		chr = ConvertBgra5551To2bpp(image, new Point(104, 16), inversePalette);
		chr.CopyTo(fontChr, 16 * 0xcc);
		chr = ConvertBgra5551To2bpp(image, new Point(112, 16), inversePalette);
		chr.CopyTo(fontChr, 16 * 0xb9);
		chr = ConvertBgra5551To2bpp(image, new Point(120, 16), inversePalette);
		chr.CopyTo(fontChr, 16 * 0xc8);
		chr = ConvertBgra5551To2bpp(image, new Point(104, 8), inversePalette);
		chr.CopyTo(fontChr, 16 * 0xca);
		chr = ConvertBgra5551To2bpp(image, new Point(120, 8), inversePalette);
		chr.CopyTo(fontChr, 16 * 0xbc);

		using var fontChrFile = File.OpenWrite("assets/graphics/font.2bpp");
		fontChrFile.Write(fontChr);
		fontChrFile.Close();

		// Hand
		var spriteGraphics = new byte[128];
		inversePalette = GetInversePalette(image, new Rectangle(new Point(104, 24), new Size(16, 16)));
		var palette = GetPalette(inversePalette, 16);

		chr = ConvertBgra5551To4bpp(image, new Point(104, 24), inversePalette);
		chr.CopyTo(spriteGraphics, 0);
		chr = ConvertBgra5551To4bpp(image, new Point(112, 24), inversePalette);
		chr.CopyTo(spriteGraphics, 32);
		chr = ConvertBgra5551To4bpp(image, new Point(104, 32), inversePalette);
		chr.CopyTo(spriteGraphics, 64);
		chr = ConvertBgra5551To4bpp(image, new Point(112, 32), inversePalette);
		chr.CopyTo(spriteGraphics, 96);

		using var handSpriteFile = File.OpenWrite("assets/graphics/hand.4bpp");
		handSpriteFile.Write(spriteGraphics);
		handSpriteFile.Close();

		using var handPaletteFile = File.OpenWrite("assets/graphics/hand-palette.pal");
		byte[] paletteBytes = new byte[32];
		Buffer.BlockCopy(palette, 0, paletteBytes, 0, 32);
		handPaletteFile.Write(paletteBytes);
		handPaletteFile.Close();
	}

	public static void UnpackBattleCharacterSprites()
	{
		using var image = Image.Load<Bgra5551>("packs/ff4like/CharacterSprites.png");
		byte[] sprites = new byte[0x6000]; // 3/4 of a bank full of sprites (too many to load all at once!)
		byte[] palettes = new byte[0x180]; // 12 palettes of 16 colors each, 2 bytes per color

		for (int c = 0; c < 6; c++) // character classes
		{
			var baseClassInversePalette = GetInversePalette(image, new Rectangle(0, 24 * c, 104, 24));
			var promotedClassInversePalette = GetInversePalette(image, new Rectangle(104, 24 * c, 104, 24));
			var baseClassPalette = GetPalette(baseClassInversePalette, 16);
			var promotedClassPalette = GetPalette(promotedClassInversePalette, 16);
			Buffer.BlockCopy(baseClassPalette, 0, palettes, 32 * c, 32);
			Buffer.BlockCopy(promotedClassPalette, 0, palettes, 32 * (c + 6), 32);

			for (int i = 0; i < 5; i++)
			{
				Rip16x16Sprite(image, new Point(16 * i, 24 * c), 16, 16, baseClassInversePalette, sprites, 16 * c + i);
				Rip16x16Sprite(image, new Point(16 * i, 24 * c + 16), 16, 8, baseClassInversePalette, sprites, 16 * c + i + 8);
				Rip16x16Sprite(image, new Point(16 * i + 104, 24 * c), 16, 16, promotedClassInversePalette, sprites, 16 * (c + 6) + i);
				Rip16x16Sprite(image, new Point(16 * i + 104, 24 * c + 16), 16, 8, promotedClassInversePalette, sprites, 16 * (c + 6) + i + 8);
			}
			Rip16x16Sprite(image, new Point(80, 24 * c + 8), 16, 16, baseClassInversePalette, sprites, 16 * c + 5);
			Rip16x16Sprite(image, new Point(96, 24 * c + 8), 8, 16, baseClassInversePalette, sprites, 16 * c + 6);
			Rip16x16Sprite(image, new Point(184, 24 * c + 8), 16, 16, promotedClassInversePalette, sprites, 16 * (c + 6) + 5);
			Rip16x16Sprite(image, new Point(200, 24 * c + 8), 8, 16, promotedClassInversePalette, sprites, 16 * (c + 6) + 6);
		}

		using var spriteFile = File.OpenWrite("assets/graphics/battle-sprites.4bpp");
		spriteFile.Write(sprites);
		spriteFile.Close();

		using var paletteFile = File.OpenWrite("assets/graphics/battle-sprite-palettes.pal");
		paletteFile.Write(palettes);
		paletteFile.Close();
	}

	private static void Rip16x16Sprite(Image<Bgra5551> image, Point origin, int width, int height, Dictionary<ushort, int> inversePalette, byte[] buffer, int spriteIndex)
	{
		byte[] chr;
		int row = spriteIndex / 8;
		int col = spriteIndex % 8;
		int offset = (row * 16 * 2 + col * 2) * 32;
		chr = ConvertBgra5551To4bpp(image, origin, inversePalette, widthLimit: width, heightLimit: height);
		chr.CopyTo(buffer, offset);
		chr = ConvertBgra5551To4bpp(image, origin + new Size(8, 0), inversePalette, widthLimit: width - 8, heightLimit: height);
		chr.CopyTo(buffer, offset + 32);
		chr = ConvertBgra5551To4bpp(image, origin + new Size(0, 8), inversePalette, widthLimit: width, heightLimit: height - 8);
		chr.CopyTo(buffer, offset + 16 * 32);
		chr = ConvertBgra5551To4bpp(image, origin + new Size(8, 8), inversePalette, widthLimit: width - 8, heightLimit: height - 8);
		chr.CopyTo(buffer, offset + 16 * 32 + 32);
	}

	private static void Rip32x32Sprite(Image<Bgra5551> image, Point origin, int width, Dictionary<ushort, int> inversePalette, byte[] buffer, int spriteIndex)
	{
		byte[] chr;
		int row = spriteIndex / 4;
		int col = spriteIndex % 4;
		int offset = (row * 16 * 4 + col * 4) * 32;
		for (int j = 0; j < 4; j++)
		{
			for (int i = 0; i < 4; i++)
			{
				chr = ConvertBgra5551To4bpp(image, origin + new Size(8 * i, 8 * j), inversePalette, widthLimit: width - i * 8);
				chr.CopyTo(buffer, offset + j * 16 * 32 + i * 32);
			}
		}
	}

	private static void WriteSpriteData(byte[] spriteData, int spriteIndex, Point position, int spriteTile, bool isLarge)
	{
		spriteData[spriteIndex * 4] = (byte)(position.X % 256);
		spriteData[spriteIndex * 4 + 1] = (byte)(position.Y);
		spriteData[spriteIndex * 4 + 2] = (byte)(spriteTile % 256);
		spriteData[spriteIndex * 4 + 3] = (byte)((spriteTile / 256) | 0b00010000);

		int highIndex = 512 + spriteIndex / 4;
		int shift = (spriteIndex % 4) * 2;
		byte mask = (byte)(0b00000011 << shift);
		byte data = (byte)(position.X / 512 | (isLarge ? 0b00000010 : 0));

		spriteData[highIndex] = (byte)((spriteData[highIndex] & ~mask) | (data << shift));
	}
}
