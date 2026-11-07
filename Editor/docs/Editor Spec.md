
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
4. 

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




---

# Dan's Old Spec

Important architectural features:
- Map layer support (an authoring convenience for grouping/isolating sections — the ROM has one grid, so layers flatten on export)
- Undo/redo with visible history (e.g. list of text entries describing operations), per-map and unlimited
- On-tile-update hooks to run placement logic as needed (e.g. sprite autotiling, configuring tile properties, etc.)
- Tool reuse for multiple purposes, "drawing a line" can also be used for "selecting tiles in a line" or "erasing tiles in a line"
- Rendering tilesets and their palettes from the ROM's own CHR data at runtime (no external spritesheets in v1)
- Editing scope beyond tiles: NPC/object placement, tile properties, teleport destinations, map palettes, battle rates, and treasure
- A map library larger than the ROM: author freely, then assign up to 61 standard maps + 1 overworld to ROM slots. References between maps are symbolic and resolve to slot numbers only on export
- Autosave with rolling backups, plus crash recovery
- A problems panel that validates continuously and blocks export on real errors

Operations that the app invokes on the tilemaps should be fast. Painting performance is extremely important and should be a top priority. This likely means that operations like "on-tile-update" are run on batches of placed tiles at the end of user interactions (e.g. on keyup/mouseup events, or after the user "commits" the edit in more complex cases) so that they are not firing constantly. One exception may include sprite autotiling which should be cheap and fast.

# App Styling

UI elements will eventually use a fully custom Theme.tres file for the application to unify theming.
- UI will include a mode selection for "icons only" "text only" or "icons + text" which will apply to menu items, toolbar items, docked window titles, and more.
- App will support docked windows that can be shown/hidden/auto-hide (e.g. flyout), but moving/undocking those windows is not initially in scope unless it's near-free.

# User Interaction

User interaction will use all 3 primary mouse buttons, vertical and horizontal scroll wheel, as well as full use of the keyboard.

All user tools are displayed in a primary toolbar at the top of the application. Clicking a tool can show a sub-toolbar below the main toolbar that includes customization options for the selected tool. For example, the Pencil tool paints one tile by default, but a customization option could be a number picker that allows you to select the "tile paint size" with a value of 1-20, causing the pencil to grow in radius. Another example: the Rectangle tool will have an option for outline (default) vs. filled.

- Drawing tiles
	- Pencil (one tile at a time, can drag to draw multiple, can change size to increase drawing radius, and can change shape between circle, diamond, and square)
	- Line (traditional "pixel-line" drawing algorithm but with tiles instead)
	- Rectangle (traditional "rectangle outline" and "filled rectangle" options)
	- Ellipse (traditional "ellipse outline" and "filled ellipse" options)
	- Stamp brush (use selection tools to assemble a stamp, then be able to clone-place that stamp with clicks)
	- Flood fill (contiguous 4-way; wraps at map edges by default since FF1 maps are toroidal, with a toggle to disable; samples the flattened view but writes to the active layer)
- Selecting and manipulating tiles
	- Maintain a cumulative selection via distinct operations, similar to how popular painting programs work - you can add to and subtract from existing selections using any selection tool, then once you have finalized your selection, you can operate on it with other tools.
	- Selections are a first-class user operation and get added to the undo/redo buffer
	- Selection tools: All the same drawing tools! Pencil, Line, Rectangle, Ellipse, and all of their modes and customizations
	- Selection operations are replace by default, "shift" modifier makes them additive, and "shift + right-click" operations are subtractive
	- Global swap/replace: Able to select singular tiles to globally replace with another tile
	- Tile property editor: Right side panel that lists out available properties for the given tile, and the primitive-type-appropriate control to change them (checkbox for bools, dropdown for enums, number input for ints, etc.). Note tile properties belong to the tileset, not the map, so an edit affects every map sharing that tileset — the panel says which ones and asks first.
- Other tools
	- Tile picker (eyedropper) allows a user to quickly select a tile by clicking on it
- View tools
	- Enable/disable tile grid overlay
	- Enable/disable "large grid" overlay (8x8 tiles)
	- Layer visibility and highlighting
		- Layers will have a visible/invisible property on the layer itself which will cause all tiles in the layer to be shown/hidden
		- On the Layer panel the user can also toggle a "highlight current layer/lowlight other layers" option that will basically dim (~40% opacity and/or darkness modulate) all layers besides the currently selected one
- Map viewport navigation
	- Decimal zoom levels with light "snap" to integer multiples of the real resolution
	- Smooth panning
	- Fit-to-map (tweened)
	- Center-on-coordinate (tweened)
	- Current mouse coordinates and viewport bounding box coordinates always visible on screen (bottom status bar)

# Screen layout

- Top bar (full width)
	- Primary toolbar
	- Subtoolbar (if applicable tool selected)
	- Media player
		- Previous, next, play/pause, and track title - that's it
- Left side drawer (vertically stacked and docked on the left side of the screen, pin toggle for visibility)
	- Palette panel
		- Shows all available tiles in the current palette
	- Layer panel
		- Full CRUD(+Select) for layers, and the listing of all current layers and their render order
	- Map panel
		- Two sections:
			1. Allows the user to swap between different maps in the current ROM's loadout
			2. Allows the user to swap between arbitrary other maps that have been authored, but are not in the current ROM's 0-60 loadout
		- Only one map is open for editing at a time; tabs are a possible later addition
- Right side drawer
	- Undo/Redo history
		- Undo/redo controls plus a full scrollable list of all operations this session with their text labels. Text labels are selectable to traverse the history, triggering undo/redo operations as necessary.
	- Tile property editor
- Bottom bar (centered away from the docked panels/no overlap)
	- Left side: ROM packing information, such as bytes used/available
	- Right side: Current mouse coordinates and viewport bounding box

# Silly Stuff

- Media player that will randomly shuffle a directory full of mp3s, specified by the user by pasting a path in. Not required to edit maps, but a fun trinket to include.
