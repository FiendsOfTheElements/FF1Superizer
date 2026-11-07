# Assets layout
- assets/
	- data/
		- overworld-map.bin
			- This is the overworld map itself!
			- First 512 bytes are pointers to Run-Length Encoded (RLE) row data for every row on the map
			- Each row is 256 tile entries, a tile is an index number between 0-127 that references the __
		- overworld-tilemaps.bin
			- Tiles are 16x16 real pixels, but they are comprised of 8x8 characters
			- Tilemaps are 4 indexes that say which 8x8 characters comprise a single tile
			- upper left, upper right, lower left, lower right - but not sure if this is per-tile, or all tiles in a given map
		- overworld-tileproperties.bin
			- For each of the 128 available tiles, these are bitflags for each option for tiles (no walk, no canoe, no ship, fight, teleport, etc.)
		- title-screen-sprites.bin
			- Skip
	- graphics/
		- *.pal
			- A list of N colors, 2 bytes per color
			- This will often pair with an image and defines the palette based on what that image format needs (4bpp = 16 colors, 2bpp = 4 colors)
			- Sometimes its just multiple palettes in sequence
		- *.4bpp
			- Ordered by the first two bitplanes for the whole image, followed by the second two bitplanes for the whole image
		- *.2bpp
			- Colors per tile: 0-3, 2 bits per pixel, 16 bytes per 8x8 tile (2 bytes per row, first byte is the low bit, second byte is the high bit)
		- *.m7
			- Colors per tile: 0-255
			- 8 bits per pixel, 64 bytes for an 8x8 tile
			- Linear palettized format, NOT bitplanes, not bitmap (even though that is technically possible with direct color mode)

# Startup
1. If the user doesn't have a full set of assets in the project:
	1. Prompt the user to select a ROM
	2. Validate their ROM (checksum etc.)
	3. Load the ROM in memory
	4. Write the assets to the project structure/directory on disk
	5. Save a project file?
2. Load the project assets in memory
	1. Tilesets/Palette
	2. Maps
	3. etc.
3. Load some default map, last edited map or map at index 0 or overworld, whatever looks cool

# Settings
- Auto-save on/off
- Auto-save interval?
- Auto-backup (default: on open, off, on save, on open)
- Maximum saved backups (default: 10)

# Map Editor

## Saving/loading
- Saving
	- If auto-backup is on and set to "on save" then we save a backup
	- Save all dirty data to disk:
		- Maps
		- Tile properties
- Loading
	- Just load the thing, what's so hard about that?

## Saving Backups
- Compress the current full /assets directory to a zip file, then name it with a datetimestamp and put it in the backups directory
- If maximum saved backups are >0, delete any old backups over the limit

## Layout
- File menu (maybe)
- Top toolbar (full width on top)
	- File operations (New, Open, Save)
	- Actions
		- Undo/Redo
		- Brushes
	- Subactions (context-specific based on the chosen action/brush)
		- 
- Left bar (full height on left)
	- Palette
	- Tile Properties (tied to the definition of the Palette's tiles)
	- Maps - a dropdown of all the maps
- Right bar (full height on right)
	- Minimap?
	- Inspector-ish panels
		- Teleports?
		- Objects?
	- History?
- Center (inset inside of every other panel)
	- Map canvas
	- Modals
- Status bar (bottom of screen, full width)

## Tools

### Selection tools
Selections are a first-class user operation, and every one gets added to the undo/redo buffer. We maintain a single cumulative selection based on each select/deselect operation that has fed into that selection, similar to how popular painting programs work. You can add to and subtract from your existing selection using any selection tool, then once you have finalized your selection, you can operate on it with other tools.

### Drawing tools
All drawing tools either operate on the map as a whole, or if there is a 

#### Pencil
Draw one tile at a time, can drag to free-hand draw.
**Subactions:**
- Drawing radius (int)
- Drawing shape (enum of circle, diamond, square)

#### Line
Pixel line drawing algorithm, draws from starting point to ending point.

#### Rectangle
Rectangle drawing algorithm.
**Subactions:**
- Filled (bool)

#### Ellipse
Traditional pixel ellipse drawing algorithm.
**Subactions:**
- Filled (bool)

#### Flood fill
Contiguous 4-way flood fill (adjacent edges, not diagonal edges), wraps at map edges by default.
**Subactions:**
- Wrap at map edges (bool)
	- If on, flood operations wrap around all 4 map edges
- Contiguous (bool)
	- If off, flood fills every same tile across the entire map
