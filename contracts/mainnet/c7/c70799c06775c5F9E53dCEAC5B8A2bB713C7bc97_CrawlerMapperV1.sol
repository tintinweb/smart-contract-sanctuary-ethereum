// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Chamber Mapper v.1
/// @author Studio Avante
/// @notice Creates Chambers tilemap and parameters for ICrawlerRenderer
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import { CrawlerContract } from './CrawlerContract.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { MapV1 } from './MapV1.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerMapperV1 is CrawlerContract, ICrawlerMapper {

	mapping(bytes1 => string) internal _tileNames;
	mapping(Crawl.Terrain => string) internal _terrainNames;
	mapping(Crawl.Gem => string) internal _gemNames;

	string[5][4] internal palettes = [ // in Crawl.Terrain order
		// Background, Path, Tiles,    Shadows,  Player
		['1F1A21', '9F6752', 'F3E9C3', '7D4E1F', 'FFBEA6'],	// Earth
		['1D1A2B', '4A7DD2', 'BDEEFF', '0C6482', 'FFBEA6'],	// Water
		['211E30', '8496A1', 'D2FFF1', '0F5F91', 'FFBEA6'],	// Air
		['301E26', 'BD412C', 'FFAF47', 'D11C00', 'FFBEA6']	// Fire
	];
	string[9] internal gemColors = [ // in Crawl.Gem order
		'BBBBBB',	// Silver
		'FFFF4D',	// Gold
		'2945FF', // Sapphire
		'4DFF64',	// Emerald
		'FF3333',	// Ruby
		'FFFFFF',	// Diamond
		'FF66C4',	// Ethernite
		'000000',	// Kao
		'FFFFFF'	// Coin
	];

	constructor() {
		setupCrawlerContract('Mapper', 1, 1);
		_tileNames[MapV1.Tile_Void] = 'Wall';
		_tileNames[MapV1.Tile_Entry] = 'Entry';
		_tileNames[MapV1.Tile_Exit] = 'Exit';
		_tileNames[MapV1.Tile_LockedExit] = 'Locked';
		_tileNames[MapV1.Tile_Gem] = 'Gem';
		_tileNames[MapV1.Tile_Path] = 'Path';
		_terrainNames[Crawl.Terrain.Earth] = 'Earth';
		_terrainNames[Crawl.Terrain.Water] = 'Water';
		_terrainNames[Crawl.Terrain.Air] = 'Air';
		_terrainNames[Crawl.Terrain.Fire] = 'Fire';
		_gemNames[Crawl.Gem.Silver] = 'Silver';
		_gemNames[Crawl.Gem.Gold] = 'Gold';
		_gemNames[Crawl.Gem.Sapphire] = 'Sapphire';
		_gemNames[Crawl.Gem.Emerald] = 'Emerald';
		_gemNames[Crawl.Gem.Ruby] = 'Ruby';
		_gemNames[Crawl.Gem.Diamond] = 'Diamond';
		_gemNames[Crawl.Gem.Ethernite] = 'Ethernite';
		_gemNames[Crawl.Gem.Kao] = 'Kao';
		_gemNames[Crawl.Gem.Coin] = 'Coin';
	}

	/// @dev implements IERC165
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CrawlerContract) returns (bool) {
		return interfaceId == type(ICrawlerMapper).interfaceId || CrawlerContract.supportsInterface(interfaceId);
	}

	/// @notice Converts a Chamber's bitmap into a Tiles map
	/// @param chamber The Chamber Data, with bitmap
	/// @return result 256 bytes array of Tiles defined in MapV1
	/// @dev Can be overriden by new or derivative contracts, adding new tiles to the Chamber
	function generateTileMap(Crawl.ChamberData memory chamber) public pure virtual override returns (bytes memory result) {
		// alloc 256 bytes, filled with MapV1.Tile_Void (0x0)
		result = new bytes(256);

		// set doors
		Crawl.Dir entry = Crawl.Dir(chamber.entryDir);
		for(uint8 d = 0 ; d < 4 ; ++d) {
			if(chamber.doors[d] > 0) {
				result[chamber.doors[d]] =
					(entry == Crawl.Dir(d)) ? MapV1.Tile_Entry :
					chamber.locks[d] == 0 ? MapV1.Tile_Exit : MapV1.Tile_LockedExit;
			}
		}

		// set Gems
		result[chamber.gemPos] = MapV1.Tile_Gem;
		
		// convert bitmap to path tiles
		for(uint256 i = 0 ; i < 256 ; ++i) {
			if(result[i] == MapV1.Tile_Void && (chamber.bitmap & Crawl.tilePosToBitmap(uint8(i))) > 0) {
				result[i] = MapV1.Tile_Path;
			}
		}
	}

	/// @notice Returns a Tile name
	/// @param tile The Tile id, defined in MapV1
	/// @param bitPos Tile position on the bitmap
	/// @return result The tile name, used as svg xlink:href id by the renderer
	/// @dev Can be overriden by new or derivative contracts, adding new tiles to the Chamber
	function getTileName(bytes1 tile, uint8 bitPos) public view virtual override returns (string memory) {
		if (tile == MapV1.Tile_Entry) {
			if ((bitPos / 16) == 0) return 'Down';
			if ((bitPos / 16) == 15) return 'Up';
			if ((bitPos % 16) == 0) return 'Right';
			return 'Left';
		}
		if (tile == MapV1.Tile_Exit) {
			if ((bitPos / 16) == 0) return 'Up';
			if ((bitPos / 16) == 15) return 'Down';
			if ((bitPos % 16) == 0) return 'Left';
			return 'Right';
		}
		return _tileNames[tile];
	}

	/// @notice Returns a Chamber's Terrain name
	/// @param terrain Terrain type
	/// @return result The Terrain name
	/// @dev Can be overriden by new or derivative contracts, adding new meaning to Terrains
	function getTerrainName(Crawl.Terrain terrain) public view virtual override returns (string memory) {
		return _terrainNames[terrain];
	}

	/// @notice Returns a Chamber's Gem name
	/// @param gem Gem type
	/// @return result The Gem name
	/// @dev Can be overriden by new or derivative contracts, adding new meaning to Gems
	function getGemName(Crawl.Gem gem) public view virtual override returns (string memory) {
		return _gemNames[gem];
	}

	/// @notice Returns a Chamber's complete color values
	/// @param terrain Terrain type of the Chamber
	/// @return result hex color values array (without # prefix)
	/// @dev Can be overriden by new or derivative contracts
	function getColors(Crawl.Terrain terrain) public view virtual override returns (string[] memory result) {
		result = new string[](5);
		for(uint8 i = 0 ; i < result.length ; ++i) {
			result[i] = palettes[uint256(terrain)-1][i];
		}
	}

	/// @notice Returns a Chamber's specific color value
	/// @param terrain Terrain type of the Chamber
	/// @param colorId The color id/index, as defined in MapV1
	/// @return result The hex color value (without # prefix)
	/// @dev Can be overriden by new or derivative contracts
	function getColor(Crawl.Terrain terrain, uint8 colorId) public view virtual override returns (string memory) {
		return palettes[uint256(terrain)-1][colorId];
	}

	/// @notice Returns the complete Gem color values
	/// @return result hex color values array (without # prefix)
	/// @dev Can be overriden by new or derivative contracts
	function getGemColors() public view virtual override returns (string[] memory result) {
		result = new string[](9);
		for(uint8 i = 0 ; i < result.length ; ++i) {
			result[i] = gemColors[i];
		}
	}

	/// @notice Returns a specific Gem color value
	/// @param gemType Gem type
	/// @return result The hex color value (without # prefix)
	/// @dev Can be overriden by new or derivative contracts
	function getGemColor(Crawl.Gem gemType) public view virtual override returns (string memory) {
		return gemColors[uint256(gemType)];
	}

	/// @notice Returns a Chamber's attributes, for tokenURI() metadata
	/// @param chamber The Chamber Data
	/// @return labels Array containing the attributes labels
	/// @return values Array containing the attributes values
	/// @dev Can be overriden by new or derivative contracts, adding new attributes
	function getAttributes(Crawl.ChamberData memory chamber) public view virtual override returns (string[] memory labels, string[] memory values) {
		labels = new string[](9);
		values = new string[](9);
		labels[0] = 'Chapter';
		values[0] =  Crawl.toString(chamber.chapter);
		labels[1] = 'Terrain';
		values[1] = _terrainNames[chamber.terrain];
		if((chamber.coord & Crawl.mask_North) > 0) {
			labels[2] = 'North';
			values[2] = Crawl.toString((chamber.coord & Crawl.mask_North)>>192);
		} else {
			labels[2] = 'South';
			values[2] = Crawl.toString(chamber.coord & Crawl.mask_South);
		}
		if((chamber.coord & Crawl.mask_East) > 0) {
			labels[3] = 'East';
			values[3] = Crawl.toString((chamber.coord & Crawl.mask_East)>>128);
		} else {
			labels[3] = 'West';
			values[3] = Crawl.toString((chamber.coord & Crawl.mask_West)>>64);
		}
		labels[4] = 'Coordinate';
		values[4] = string(bytes.concat(bytes(labels[2])[0], bytes(values[2]), bytes(labels[3])[0], bytes(values[3]) ));
		labels[5] = 'Yonder';
		values[5] = Crawl.toString(chamber.yonder);
		labels[6] = 'Gem';
		values[6] = _gemNames[chamber.hoard.gemType];
		labels[7] = 'Coins';
		values[7] = Crawl.toString(chamber.hoard.coins);
		labels[8] = 'Worth';
		values[8] = Crawl.toString(chamber.hoard.worth);
	}

	/// @notice Returns custom Tile CSS styles
	// @param chamber The Chamber Data
	/// @return result CSS styles string
	/// @dev Can be overriden by new or derivative contracts, updating or adding new Tiles
	function renderSvgStyles(Crawl.ChamberData memory /*chamber*/) public view virtual override returns (string memory) {
		return ''; // Standard styles are defined on the renderer
	}

	/// @notice Returns custom Tile SVG objects
	// @param chamber The Chamber Data
	/// @return result SVG objects string, with ids to be used in <use>
	/// @dev Can be overriden by new or derivative contracts, updating or adding new Tiles
	function renderSvgDefs(Crawl.ChamberData memory /*chamber*/) public pure virtual override returns (string memory) {
		return
			'<path id="Down" d="m 0 0 h 1 l -0.5 0.55 Z"/>'
			'<path id="Up" d="m 0 1 h 1 l -0.5 -0.55 Z"/>'
			'<path id="Left" d="m 1 0 v 1 l -0.55 -0.5 Z"/>'
			'<path id="Right" d="m 0 0 v 1 l 0.55 -0.5 Z"/>'
			'<path id="Gem" d="m 0 0.5 l 0.5 0.5 l 0.5 -0.5 l -0.5 -0.5 Z"/>'
			'<circle id="Locked" cx="0.5" cy="0.5" r="0.4"/>';
	}

}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Mapper Constants v.1
/// @author Studio Avante
/// @dev Definitions and functions for Mappers and Renderers
//
pragma solidity ^0.8.16;

library MapV1 {
	uint8 internal constant Color_Background = 0;
	uint8 internal constant Color_Path = 1;
	uint8 internal constant Color_Tiles = 2;
	uint8 internal constant Color_Shadows = 3;
	uint8 internal constant Color_Player = 4;
	bytes1 internal constant Tile_Void = 0x00;
	bytes1 internal constant Tile_Entry = 0x01;
	bytes1 internal constant Tile_Exit = 0x02;
	bytes1 internal constant Tile_LockedExit = 0x03;
	bytes1 internal constant Tile_Gem = 0x04;
	bytes1 internal constant Tile_Empty = 0xfe;
	bytes1 internal constant Tile_Path = 0xff;
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Chamber Mapper Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerMapper is IERC165 {
	// for generators
	function generateTileMap(Crawl.ChamberData memory chamber) external view returns (bytes memory);
	// getters / for renderers
	function getTerrainName(Crawl.Terrain terrain) external view returns (string memory);
	function getGemName(Crawl.Gem gem) external view returns (string memory);
	function getTileName(bytes1 tile, uint8 bitPos) external view returns (string memory);
	function getColors(Crawl.Terrain terrain) external view returns (string[] memory);
	function getColor(Crawl.Terrain terrain, uint8 colorId) external view returns (string memory);
	function getGemColors() external view returns (string[] memory);
	function getGemColor(Crawl.Gem gemType) external view returns (string memory);
	// for renderers
	function getAttributes(Crawl.ChamberData memory chamber) external view returns (string[] memory, string[] memory);
	function renderSvgStyles(Crawl.ChamberData memory chamber) external view returns (string memory);
	function renderSvgDefs(Crawl.ChamberData memory chamber) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Contract Manifest Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface ICrawlerContract is IERC165 {
	function contractName() external view returns (string memory);
	function contractChapterNumber() external view returns (uint8);
	function contractVersion() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Contract Manifest
/// @author Studio Avante
/// @notice Stores upgradeable contracts name, chapter and version
//
pragma solidity ^0.8.16;
import { IERC165, ERC165 } from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import { ICrawlerContract } from './ICrawlerContract.sol';

abstract contract CrawlerContract is ERC165, ICrawlerContract {
	uint8 private _chapterNumber;
	uint8 private _version;
	string private _name;

	/// @dev Internal function, meant to be called only once by derived contract constructors
	function setupCrawlerContract(string memory name_, uint8 chapterNumber_, uint8 version_) internal {
		_name = name_;
		_chapterNumber = chapterNumber_;
		_version = version_;
	}

	/// @dev implements IERC165
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
		return interfaceId == type(ICrawlerContract).interfaceId || ERC165.supportsInterface(interfaceId);
	}

	/// @notice Returns the contract name
	/// @return name Contract name
	function contractName() public view override returns (string memory) {
		require(bytes(_name).length > 0, 'CrawlerContract: Contract not setup');
		return _name;
	}

	/// @notice Returns the first chapter number this contract was used
	/// @return chapterNumber Contract chapter number
	function contractChapterNumber() public view override returns (uint8) {
		require(_chapterNumber != 0, 'CrawlerContract: Contract not setup');
		return _chapterNumber;
	}

	/// @notice Returns the contract version
	/// @return version Contract version
	function contractVersion() public view override returns (uint8) {
		require(_version != 0, 'CrawlerContract: Contract not setup');
		return _version;
	}
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Game Definitions and Library
/// @author Studio Avante
/// @notice Contains common definitions and functions
//
pragma solidity ^0.8.16;

library Crawl {

  //-----------------------------------
  // ChamberSeed, per token static data
  // generated on mint, stored on-chain
  //
	struct ChamberSeed {
		uint256 tokenId;
		uint256 seed;
		uint232 yonder;
		uint8 chapter;
		Crawl.Terrain terrain;
		Crawl.Dir entryDir;
	}


  //------------------------------------
  // ChamberData, per token dynamic data
  // generated on demand
  //
	struct ChamberData {
		// from ChamberSeed (static)
		uint256 coord;
		uint256 tokenId;
		uint256 seed;
		uint232 yonder;
		uint8 chapter;			// Chapter minted
		Crawl.Terrain terrain;
		Crawl.Dir entryDir;

		// generated on demand (deterministic)
		Crawl.Hoard hoard;
		uint8 gemPos;				// gem bitmap position

		// dynamic until all doors are unlocked
		uint8[4] doors; 		// bitmap position in NEWS order
		uint8[4] locks; 		// lock status in NEWS order

		// optional
		uint256 bitmap;			// bit map, 0 is void/walls, 1 is path
		bytes tilemap;			// tile map

		// custom data
		CustomData[] customData;
	}

	struct Hoard {
		Crawl.Gem gemType;
		uint16 coins;		// coins value
		uint16 worth;		// gem + coins value
	}

	enum CustomDataType {
		Custom0, Custom1, Custom2, Custom3, Custom4,
		Custom5, Custom6, Custom7, Custom8, Custom9,
		Tile,
		Palette,
		Background,
		Foreground,
		CharSet,
		Music
	}

	struct CustomData {
		CustomDataType dataType;
		bytes data;
	}


	//-----------------------
	// Terrain types
	//
	// 2 Water | 3 Air
	// --------|--------
	// 1 Earth | 4 Fire
	//
	enum Terrain {
		Empty,	// 0
		Earth,	// 1
		Water,	// 2
		Air,		// 3
		Fire		// 4
	}

	/// @dev Returns the opposite of a Terrain
	// Opposite terrains cannot access to each other
	// Earth <> Air
	// Water <> Fire
	function getOppositeTerrain(Crawl.Terrain terrain) internal pure returns (Crawl.Terrain) {
		uint256 t = uint256(terrain);
		return t >= 3 ? Crawl.Terrain(t-2) : t >= 1 ? Crawl.Terrain(t+2) : Crawl.Terrain.Empty;
	}

	//-----------------------
	// Gem types
	//
	enum Gem {
		Silver,			// 0
		Gold,				// 1
		Sapphire,		// 2
		Emerald,		// 3
		Ruby,				// 4
		Diamond,		// 5
		Ethernite,	// 6
		Kao,				// 7
		Coin				// 8 (not a gem!)
	}

	/// @dev Returns the Worth value of a Gem
	function getGemValue(Crawl.Gem gem) internal pure returns (uint16) {
		if (gem == Crawl.Gem.Silver) return 50;
		if (gem == Crawl.Gem.Gold) return 100;
		if (gem == Crawl.Gem.Sapphire) return 150;
		if (gem == Crawl.Gem.Emerald) return 200;
		if (gem == Crawl.Gem.Ruby) return 300;
		if (gem == Crawl.Gem.Diamond) return 500;
		if (gem == Crawl.Gem.Ethernite) return 800;
		return 1001; // Crawl.Gem.Kao
	}

	/// @dev Calculates a Chamber Worth value
	function calcWorth(Crawl.Gem gem, uint16 coins) internal pure returns (uint16) {
		return getGemValue(gem) + coins;
	}

	//--------------------------
	// Directions, in NEWS order
	//
	enum Dir {
		North,	// 0
		East,		// 1
		West,		// 2
		South		// 3
	}
	uint256 internal constant mask_South = uint256(type(uint64).max);
	uint256 internal constant mask_West = (mask_South << 64);
	uint256 internal constant mask_East = (mask_South << 128);
	uint256 internal constant mask_North = (mask_South << 192);

	/// @dev Flips a direction
	/// North <> South
	/// East <> West
	function flipDir(Crawl.Dir dir) internal pure returns (Crawl.Dir) {
		return Crawl.Dir(3 - uint256(dir));
	}

	/// @dev Flips a door possition at a direction to connect to neighboring chamber
	function flipDoorPosition(uint8 doorPos, Crawl.Dir dir) internal pure returns (uint8 result) {
		if (dir == Crawl.Dir.North) return doorPos > 0 ? doorPos + (15 * 16) : 0;
		if (dir == Crawl.Dir.South) return doorPos > 0 ? doorPos - (15 * 16) : 0;
		if (dir == Crawl.Dir.West) return doorPos > 0 ? doorPos + 15 : 0;
		return doorPos > 0 ? doorPos - 15 : 0; // Crawl.Dir.East
	}

	//-----------------------
	// Coords
	//	
	// coords have 4 components packed in uint256
	// in NEWS direction:
	// (N)orth, (E)ast, (W)est, (S)outh
	// o-------o-------o-------o-------o
	// 0       32     128     192    256

	/// @dev Extracts the North component from a Chamber coordinate
	function getNorth(uint256 coord) internal pure returns (uint256 result) {
		return (coord >> 192);
	}
	/// @dev Extracts the East component from a Chamber coordinate
	function getEast(uint256 coord) internal pure returns (uint256) {
		return ((coord & mask_East) >> 128);
	}
	/// @dev Extracts the West component from a Chamber coordinate
	function getWest(uint256 coord) internal pure returns (uint256) {
		return ((coord & mask_West) >> 64);
	}
	/// @dev Extracts the South component from a Chamber coordinate
	function getSouth(uint256 coord) internal pure returns (uint256) {
		return coord & mask_South;
	}

	/// @dev Builds a Chamber coordinate from its direction components
	/// a coord is composed of 4 uint64 components packed in a uint256
	/// Components are combined in NEWS order: Nort, East, West, South
	/// @param north North component, zero if South
	/// @param east East component, zero id West
	/// @param west West component, zero if East
	/// @param south South component, zero if North
	/// @return result Chamber coordinate
	function makeCoord(uint256 north, uint256 east, uint256 west, uint256 south) internal pure returns (uint256 result) {
		// North or South need to be positive, but not both
		if(north > 0) {
			require(south == 0, 'Crawl.makeCoord(): bad North/South');
			result += (north << 192);
		} else if(south > 0) {
			result += south;
		} else {
			revert('Crawl.makeCoord(): need North or South');
		}
		// West or East need to be positive, but not both
		if(east > 0) {
			require(west == 0, 'Crawl.makeCoord(): bad West/East');
			result += (east << 128);
		} else if(west > 0) {
			result += (west << 64);
		} else {
			revert('Crawl.makeCoord(): need West or East');
		}
	}

	/// @dev Offsets a Chamber coordinate in one direction
	/// @param coord Chamber coordinate
	/// @param dir Direction to offset
	/// @return coord The new coordinate. If reached limits, return same coord
	// TODO: Use assembly?
	function offsetCoord(uint256 coord, Crawl.Dir dir) internal pure returns (uint256) {
		if(dir == Crawl.Dir.North) {
			if(coord & mask_South > 1) return coord - 1; // --South
			if(coord & mask_North != mask_North) return (coord & ~mask_South) + (1 << 192); // ++North
		} else if(dir == Crawl.Dir.East) {
			if(coord & mask_West > (1 << 64)) return coord - (1 << 64); // --West
			if(coord & mask_East != mask_East) return (coord & ~mask_West) + (1 << 128); // ++East
		} else if(dir == Crawl.Dir.West) {
			if(coord & mask_East > (1 << 128)) return coord - (1 << 128); // --East
			if(coord & mask_West != mask_West) return (coord & ~mask_East) + (1 << 64); // ++West
		} else { //if(dir == Crawl.Dir.South) {
			if(coord & mask_North > (1 << 192)) return coord - (1 << 192); // --North
			if(coord & mask_South != mask_South) return (coord & ~mask_North) + 1; // ++South
		}
		return coord;
	}


	//-----------------------
	// String Builders
	//

	/// @dev Returns a token description for tokenURI()
	function tokenName(string memory tokenId) public pure returns (string memory) {
		return string.concat('Chamber #', tokenId);
	}

	/// @dev Short string representation of a Chamebr coordinate and Yonder
	function coordsToString(uint256 coord, uint256 yonder, string memory separator) public pure returns (string memory) {
		return string.concat(
			((coord & Crawl.mask_North) > 0
				? string.concat('N', toString((coord & Crawl.mask_North)>>192))
				: string.concat('S', toString(coord & Crawl.mask_South))),
			((coord & Crawl.mask_East) > 0
				? string.concat(separator, 'E', toString((coord & Crawl.mask_East)>>128))
				: string.concat(separator, 'W', toString((coord & Crawl.mask_West)>>64))),
			(yonder > 0 ? string.concat(separator, 'Y', toString(yonder)) : '')
		);
	}

	/// @dev Renders IERC721Metadata attributes for tokenURI()
	/// Reference: https://docs.opensea.io/docs/metadata-standards
	function renderAttributesMetadata(string[] memory labels, string[] memory values) public pure returns (string memory result) {
		for(uint256 i = 0 ; i < labels.length ; ++i) {
			result = string.concat(result,
				'{'
					'"trait_type":"', labels[i], '",'
					'"value":"', values[i], '"'
				'}',
				(i < (labels.length - 1) ? ',' : '')
			);
		}
	}

	/// @dev Returns a Chamber metadata, without maps
	/// @param chamber The Chamber, no maps required
	/// @return metadata Metadata, as plain json string
	function renderChamberMetadata(Crawl.ChamberData memory chamber, string memory additionalMetadata) internal pure returns (string memory) {
		return string.concat(
			'{'
				'"tokenId":"', toString(chamber.tokenId), '",'
				'"name":"', tokenName(toString(chamber.tokenId)), '",'
				'"chapter":"', toString(chamber.chapter), '",'
				'"terrain":"', toString(uint256(chamber.terrain)), '",'
				'"gem":"', toString(uint256(chamber.hoard.gemType)), '",'
				'"coins":"', toString(chamber.hoard.coins), '",'
				'"worth":"', toString(chamber.hoard.worth), '",'
				'"coord":"', toString(chamber.coord), '",'
				'"yonder":"', toString(chamber.yonder), '",',
				_renderCompassMetadata(chamber.coord),
				_renderLocksMetadata(chamber.locks),
				additionalMetadata,
			'}'
		);
	}
	function _renderCompassMetadata(uint256 coord) private pure returns (string memory) {
		return string.concat(
			'"compass":{',
				((coord & Crawl.mask_North) > 0
					? string.concat('"north":"', toString((coord & Crawl.mask_North)>>192))
					: string.concat('"south":"', toString(coord & Crawl.mask_South))),
				((coord & Crawl.mask_East) > 0
					? string.concat('","east":"', toString((coord & Crawl.mask_East)>>128))
					: string.concat('","west":"', toString((coord & Crawl.mask_West)>>64))),
			'"},'
		);
	}
	function _renderLocksMetadata(uint8[4] memory locks) private pure returns (string memory) {
		return string.concat(
			'"locks":[',
				(locks[0] == 0 ? 'false,' : 'true,'),
				(locks[1] == 0 ? 'false,' : 'true,'),
				(locks[2] == 0 ? 'false,' : 'true,'),
				(locks[3] == 0 ? 'false' : 'true'),
			'],'
		);
	}


	//-----------------------
	// Utils
	//

	/// @dev converts uint8 tile position to a bitmap position mask
	function tilePosToBitmap(uint8 tilePos) internal pure returns (uint256) {
		return (1 << (255 - tilePos));
	}

	/// @dev overSeed has ~50% more bits
	function overSeed(uint256 seed_) internal pure returns (uint256) {
		return seed_ | uint256(keccak256(abi.encodePacked(seed_)));
	}

	/// @dev underSeed has ~50% less bits
	function underSeed(uint256 seed_) internal pure returns (uint256) {
		return seed_ & uint256(keccak256(abi.encodePacked(seed_)));
	}

	/// @dev maps seed value modulus to range
	function mapSeed(uint256 seed_, uint256 min_, uint256 maxExcl_) internal pure returns (uint256) {
		return min_ + (seed_ % (maxExcl_ - min_));
	}

	/// @dev maps seed value modulus to bitmap position (takes 8 bits)
	/// the position lands in a 12x12 space at the center of the 16x16 map
	function mapSeedToBitmapPosition(uint256 seed_) internal pure returns (uint8) {
		uint8 i = uint8(seed_ % 144);
		return ((i / 12) + 2) * 16 + (i % 12) + 2;
	}

	/// @dev min function
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	/// @dev max function
	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a > b ? a : b;
	}

	//-----------------------------
	// OpenZeppelin Strings library
	// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/utils/Strings.sol
	// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/utils/math/Math.sol
	//
	bytes16 private constant _SYMBOLS = "0123456789abcdef";
	uint8 private constant _ADDRESS_LENGTH = 20;

	/// @dev Return the log in base 10, rounded down, of a positive value.
	function log10(uint256 value) private pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >= 10**64) { value /= 10**64; result += 64; }
			if (value >= 10**32) { value /= 10**32; result += 32; }
			if (value >= 10**16) { value /= 10**16; result += 16; }
			if (value >= 10**8) { value /= 10**8; result += 8; }
			if (value >= 10**4) { value /= 10**4; result += 4; }
			if (value >= 10**2) { value /= 10**2; result += 2; }
			if (value >= 10**1) { result += 1; }
		}
		return result;
	}

	/// @dev Return the log in base 256, rounded down, of a positive value.
	function log256(uint256 value) private pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >> 128 > 0) { value >>= 128; result += 16; }
			if (value >> 64 > 0) { value >>= 64; result += 8; }
			if (value >> 32 > 0) { value >>= 32; result += 4; }
			if (value >> 16 > 0) { value >>= 16; result += 2; }
			if (value >> 8 > 0) { result += 1; }
		}
		return result;
	}

	/// @dev Converts a `uint256` to its ASCII `string` decimal representation.
	function toString(uint256 value) internal pure returns (string memory) {
		unchecked {
			uint256 length = log10(value) + 1;
			string memory buffer = new string(length);
			uint256 ptr;
			/// @solidity memory-safe-assembly
			assembly {
				ptr := add(buffer, add(32, length))
			}
			while (true) {
				ptr--;
				/// @solidity memory-safe-assembly
				assembly {
					mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
				}
				value /= 10;
				if (value == 0) break;
			}
			return buffer;
		}
	}

	/// @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
	/// defined as public to be excluded from the contract ABI and avoid Stack Too Deep error
	function toHexString(uint256 value) public pure returns (string memory) {
		unchecked {
			return toHexString(value, log256(value) + 1);
		}
	}

	/// @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
	/// defined as public to be excluded from the contract ABI and avoid Stack Too Deep error
	function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, "Strings: hex length insufficient");
		return string(buffer);
	}

	/// @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
	function toHexString(address addr) public pure returns (string memory) {
		return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
	}

	/// @dev Converts a single `bytes1` to its ASCII `string` hexadecimal
	function toHexString(bytes1 value) public pure returns (string memory) {
		bytes memory buffer = new bytes(2);
		buffer[0] = _SYMBOLS[uint8(value>>4) & 0xf];
		buffer[1] = _SYMBOLS[uint8(value) & 0xf];
		return string(buffer);
	}

	/// @dev Converts a `bytes` to its ASCII `string` hexadecimal, without '0x' prefix
	function toHexString(bytes memory value, uint256 start, uint256 length) public pure returns (string memory) {
		require(start < value.length, "Strings: hex start overflow");
		require(start + length <= value.length, "Strings: hex length overflow");
		bytes memory buffer = new bytes(2 * length);
		for (uint256 i = 0; i < length; i++) {
			buffer[i*2+0] = _SYMBOLS[uint8(value[start+i]>>4) & 0xf];
			buffer[i*2+1] = _SYMBOLS[uint8(value[start+i]) & 0xf];
		}
		return string(buffer);
	}
	/// @dev Converts a `bytes` to its ASCII `string` hexadecimal, without '0x' prefix
	function toHexString(bytes memory value) public pure returns (string memory) {
		return toHexString(value, 0, value.length);
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}