using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;

namespace GenerateAssets;

public static class ImageRipper
{
	public static unsafe int HashChr(byte[] chr)
	{
		const int p = 16777619;
		int hash = -2128831035;
		fixed (byte* chrptr = chr)
		{
			int* intptr = (int*)chrptr;
			for (int i = 0; i < 16; i++)
			{
				hash = (hash ^ intptr[i]) * p;
			}
		}

		return hash;
	}

	public static Dictionary<ushort, int> GetInversePalette(Image<Bgra5551> image, Rectangle region)
	{
		var palette = new Dictionary<ushort, int>();
		palette.Add(0x7c1f, 0); // color 0 is #FF00FF
		int colorIndex = 0;
		image.ProcessPixelRows(accessor =>
		{
			for (int y = 0; y < region.Height; y++)
			{
				var row = accessor.GetRowSpan(region.Top + y);
				for (int x = 0; x < region.Width; x++)
				{
					var color = (ushort)(row[region.Left + x].PackedValue & 0x7fff);
					if (!palette.ContainsKey(color))
					{
						colorIndex++;
						palette.Add(color, colorIndex);
					}
				}
			}
		});

		return palette;
	}

	/// <summary>
	/// Converts a reverse-lookup palette to an array of 16-bit colors.
	/// Throws if the inverse palette contains more colors than the count provided.
	/// </summary>
	public static ushort[] GetPalette(Dictionary<ushort, int> inversePalette, int count)
	{
		var palette = new ushort[count];
		foreach (var color in inversePalette.Keys)
		{
			int index = inversePalette[color];
			palette[index] = (ushort)(((color & 0x001f) << 10) | (color & 0x03e0) | ((color & 0x7c00) >> 10));
		}

		return palette;
	}

	/// <summary>
	/// Converts a single 8x8 character from 16-bit to SNES 4bpp.
	/// </summary>
	/// <param name="characterPos=">The upper-left corner of an 8x8 character to convert.</param>
	public static byte[] ConvertBgra5551To2bpp(Image<Bgra5551> image, Point characterPos, Dictionary<ushort, int> inversePalette, bool flipped = false, int limit = 8)
	{
		byte[] buffer = new byte[16];
		image.ProcessPixelRows(accessor =>
		{
			for (int y = 0; y < 8; y++)
			{
				var row = accessor.GetRowSpan(characterPos.Y + y);
				for (int x = 0; x < 8; x++)
				{
					var actualX = flipped ? characterPos.X + x : characterPos.X + 7 - x;
					var color = actualX >= characterPos.X + limit ? (ushort)0x7c1f : (ushort)(row[actualX].PackedValue & 0x7fff);
					var paletteIndex = inversePalette[color];
					buffer[2 * y] |= (byte)(((paletteIndex & 0x01)) << x);
					buffer[2 * y + 1] |= (byte)(((paletteIndex & 0x02) >> 1) << x);
				}
			}
		});

		return buffer;
	}

	/// <summary>
	/// Converts a single 8x8 character from 16-bit to SNES 4bpp.
	/// </summary>
	/// <param name="characterPos=">The upper-left corner of an 8x8 character to convert.</param>
	public static byte[] ConvertBgra5551To4bpp(Image<Bgra5551> image, Point characterPos, Dictionary<ushort, int> inversePalette, bool flipped = false, int widthLimit = 8, int heightLimit = 8)
	{
		byte[] buffer = new byte[32];
		image.ProcessPixelRows(accessor =>
		{
			for (int y = 0; y < 8; y++)
			{
				if (y >= heightLimit)
				{
					buffer[2 * y] = 0;
					buffer[2 * y + 1] = 0;
					buffer[2 * y + 16] = 0;
					buffer[2 * y + 17] = 0;
				}
				else
				{
					var row = accessor.GetRowSpan(characterPos.Y + y);
					for (int x = 0; x < 8; x++)
					{
						var actualX = flipped ? characterPos.X + x : characterPos.X + 7 - x;
						var color = actualX >= characterPos.X + widthLimit ? (ushort)0x7c1f : (ushort)(row[actualX].PackedValue & 0x7fff);
						var paletteIndex = inversePalette[color];
						buffer[2 * y] |= (byte)(((paletteIndex & 0x01)) << x);
						buffer[2 * y + 1] |= (byte)(((paletteIndex & 0x02) >> 1) << x);
						buffer[2 * y + 16] |= (byte)(((paletteIndex & 0x04) >> 2) << x);
						buffer[2 * y + 17] |= (byte)(((paletteIndex & 0x08) >> 3) << x);
					}
				}
			}
		});

		return buffer;
	}

	/// <summary>
	/// Converts a single 8x8 character from 16-bit to SNES 8bpp (Mode 7).
	/// </summary>
	/// <param name="characterPos=">The upper-left corner of an 8x8 character to convert.</param>
	public static byte[] ConvertBgra5551To8bpp(Image<Bgra5551> image, Point characterPos, Dictionary<ushort, int> inversePalette, bool flipped = false)
	{
		byte[] buffer = new byte[64];
		image.ProcessPixelRows(accessor =>
		{
			for (int y = 0; y < 8; y++)
			{
				var row = accessor.GetRowSpan(characterPos.Y + y);
				for (int x = 0; x < 8; x++)
				{
					var color = (ushort)(row[characterPos.X + x].PackedValue & 0x7fff);
					var paletteIndex = inversePalette[color];
					buffer[8 * y + x] = (byte)paletteIndex;
				}
			}
		});

		return buffer;
	}
}
