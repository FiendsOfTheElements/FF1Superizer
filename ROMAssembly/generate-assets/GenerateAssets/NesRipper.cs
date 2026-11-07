namespace GenerateAssets;

public static class NesRipper
{
	public static void NesSpriteToSnesSprite(Span<byte> nes, Span<byte> snes, byte topPalette, byte bottomPalette)
	{
		Nes2bppToSnes4bpp(nes[0x00..0x10], snes[0x00..0x20], topPalette);
		Nes2bppToSnes4bpp(nes[0x10..0x20], snes[0x20..0x40], topPalette);
		Nes2bppToSnes4bpp(nes[0x20..0x30], snes[0x40..0x60], bottomPalette);
		Nes2bppToSnes4bpp(nes[0x30..0x40], snes[0x60..0x80], bottomPalette);
	}

	public static void NesSpriteToSnesSpriteBottomRowFlipped(Span<byte> nes, Span<byte> snes, byte topPalette, byte bottomPalette)
	{
		FlipNes2bppHorizontally(nes[0x20..0x30]);
		FlipNes2bppHorizontally(nes[0x30..0x40]);
		Nes2bppToSnes4bpp(nes[0x00..0x10], snes[0x00..0x20], topPalette);
		Nes2bppToSnes4bpp(nes[0x10..0x20], snes[0x20..0x40], topPalette);
		Nes2bppToSnes4bpp(nes[0x30..0x40], snes[0x40..0x60], bottomPalette);
		Nes2bppToSnes4bpp(nes[0x20..0x30], snes[0x60..0x80], bottomPalette);
	}

	/// <summary>
	/// Converts a 2bpp 8x8 NES CHR to a 4bpp SNES CHR.
	/// </summary>
	/// <param name="paletteIndex">A value from 0-3 which will fill in the upper 2 bits of
	/// the SNES color.</param>
	public static void Nes2bppToSnes4bpp(Span<byte> nes, Span<byte> snes, byte paletteIndex)
	{
		byte lowPalette = (byte)((paletteIndex & 0x01) == 0 ? 0x00 : 0xFF);
		byte highPalette = (byte)((paletteIndex & 0x02) == 0 ? 0x00 : 0xFF);
		for (int y = 0; y < 8; y++) // 8 rows of pixels
		{
			byte mask = (byte)(nes[y] | nes[y + 8]);
			snes[2 * y] = nes[y];
			snes[2 * y + 1] = nes[y + 8];
			snes[2 * y + 16] = (byte)(lowPalette & mask);
			snes[2 * y + 17] = (byte)(highPalette & mask);
		}
	}

	public static void FlipNes2bppHorizontally(Span<byte> nes)
	{
		for (int y = 0; y < 0x10; y++)
		{
			nes[y] = (byte)(
				(nes[y] & 0x01) << 7 |
				(nes[y] & 0x02) << 5 |
				(nes[y] & 0x04) << 3 |
				(nes[y] & 0x08) << 1 |
				(nes[y] & 0x10) >> 1 |
				(nes[y] & 0x20) >> 3 |
				(nes[y] & 0x40) >> 5 |
				(nes[y] & 0x80) >> 7);
		}
	}
}
