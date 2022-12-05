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
/// @title Endless Crawler Chamber Generator v.1
/// @author Studio Avante
/// @notice Creates Chambers bitmap and provide data for ICrawlerMapper
/// @dev Upgradeable for eventual optimizations, can also be extended to generate new game data
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { CrawlerContract } from './CrawlerContract.sol';
import { ICrawlerChamberGenerator } from './ICrawlerChamberGenerator.sol';
import { ICrawlerGenerator } from './ICrawlerGenerator.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerGeneratorV1 is CrawlerContract, ICrawlerChamberGenerator, ICrawlerGenerator {

	struct Rules {
		bool overseed;
		bool wfc;
		bool openSpaces;
		uint8 bitSizeX;
		uint8 bitSizeY;
		uint8 carveValue1;
		uint8 carveValue2;
	}

	mapping(Crawl.Terrain => Rules) private _rules;

	constructor() {
		setupCrawlerContract('Generator', 1, 1);
		_rules[Crawl.Terrain.Earth] = Rules(false, false, false, 1, 1, 5, 5);
		_rules[Crawl.Terrain.Water] = Rules(false, false, false, 4, 2, 4, 0);
		_rules[Crawl.Terrain.Air] = Rules(false, true, false, 1, 1, 0, 0);
		_rules[Crawl.Terrain.Fire] = Rules(true, true, true, 1, 1, 0, 0);
	}

	/// @dev implements IERC165
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CrawlerContract) returns (bool) {
		return interfaceId == type(ICrawlerGenerator).interfaceId || CrawlerContract.supportsInterface(interfaceId);
	}

	/// @notice Returns custom data for a Chamber
	// @param chamber The Chamber, without maps
	/// @return result An array of Crawl.CustomData
	/// @dev implements ICrawlerGenerator
	function generateCustomChamberData(Crawl.ChamberData memory /*chamber*/) public pure override returns (Crawl.CustomData[] memory) {
		return new Crawl.CustomData[](0);
	}

	/// @notice Returns ChamberData for a Chamber
	/// @param coord Chamber coordinate
	/// @param chamberSeed Chamber static data
	/// @param generateMaps True if bitmap need to be generated. Tilemap is generated later by ICrawlerMapper
	/// @param tokenContract the CrawlerToken contract address, for checking the doors
	/// @param customGenerator Current ICrawlerGenerator for additional custom data
	/// @return result The complete ChamberData structure, less tilemap
	/// @dev implements ICrawlerChamberGenerator
	function generateChamberData(
		uint256 coord,
		Crawl.ChamberSeed memory chamberSeed,
		bool generateMaps,
		ICrawlerToken tokenContract,
		ICrawlerGenerator customGenerator)
	public view override returns (Crawl.ChamberData memory result) {
		if(chamberSeed.seed == 0) return result;

		result = Crawl.ChamberData(
			coord,
			chamberSeed.tokenId,
			chamberSeed.seed,
			chamberSeed.yonder,
			chamberSeed.chapter,
			chamberSeed.terrain,
			chamberSeed.entryDir,
			generateHoard(chamberSeed.seed),
			generateGemPos(chamberSeed.seed),
			// dynamic (optional)
			[0, 0, 0, 0], // doors
			[0, 0, 0, 0], // locks
			0,							// bitmap
			new bytes(0),		// tile map
			new Crawl.CustomData[](0)	// custom
		);

		// Generate doors
		for(uint8 d = 0; d < 4 ; ++d) {
			Crawl.Dir dir = Crawl.Dir(d);
			Crawl.ChamberSeed memory otherChamber = tokenContract.coordToSeed(Crawl.offsetCoord(coord, dir));
			if (otherChamber.tokenId == 0) {
				// other is empty, can be minted (locked)
				result.locks[d] = 1;
			}
			if (Crawl.Terrain(otherChamber.terrain) != Crawl.getOppositeTerrain(result.terrain)) {
				if (otherChamber.tokenId == 0 || otherChamber.tokenId > chamberSeed.tokenId) {
					// this chamber is older: generate
					result.doors[d] = generateDoorPos(chamberSeed.seed, dir);
				} else {
					// other chamber is older, invert its door
					Crawl.Dir otherDir = Crawl.flipDir(dir);
					result.doors[d] = Crawl.flipDoorPosition(generateDoorPos(otherChamber.seed, otherDir), otherDir);
				}
			}
		}

		// Generate custom chamber data
		result.customData = customGenerator.generateCustomChamberData(result);

		// generate bitmap
		if(generateMaps) {
			result.bitmap = generateBitmap(result);
		}
	}

	//-------------------
	// Property Generators
	//

	/// @notice Generates random terrain type for a new Chamber
	/// @param seed The Chamber's seed
	/// @param fromTerrain Terrain type of the Chamber unlocking the door
	/// @return terrain A random Terrain type
	/// @dev implements ICrawlerChamberGenerator
	function generateTerrainType(uint256 seed, Crawl.Terrain fromTerrain) public pure override returns (Crawl.Terrain) {
		// we have only 3 options per terrain (cant be opposite)
		uint256 result = uint256(fromTerrain) + (seed % 3);
		if (result > 4) result -= 4; // wrap if necessry
		if (result == uint256(Crawl.getOppositeTerrain(fromTerrain))) {
			result++; // skip opposite
			if (result > 4) result -= 4; // wrap if necessry
		} 
		return Crawl.Terrain(result);
	}

	/// @notice Generates random deterministic door position of a Chamber
	/// @param seed The Chamber's seed
	/// @param dir Direction of the door
	/// @return result A position on the bitmap
	/// @dev Doors are always between position 4-11 of a row/column (4 tiles from edges)
	/// North: always on row 0, random column
	/// South: always on row 15, random column
	/// West: always on column 0, random row
	/// East: always on column 15, random row
	function generateDoorPos(uint256 seed, Crawl.Dir dir) public pure returns (uint8) {
		if (dir == Crawl.Dir.North) return uint8(Crawl.mapSeed(seed >> 0, 4, 12));
		if (dir == Crawl.Dir.South) return uint8(Crawl.mapSeed(seed >> 4, 4, 12) + (15 * 16) );
		if (dir == Crawl.Dir.West) return uint8(Crawl.mapSeed(seed >> 8, 4, 12) * 16);
		return uint8(Crawl.mapSeed(seed >> 12, 4, 12) * 16 + 15); // Crawl.Dir.East
	}

	/// @notice Generates random deterministic Gem position of a Chamber
	/// @param seed The Chamber's seed
	/// @return result A position on the bitmap
	/// @dev Gems are always between row 2-13 and column 2-13 (2 tiles from edges)
	function generateGemPos(uint256 seed) public pure returns (uint8) {
		return Crawl.mapSeedToBitmapPosition(seed >> 20);
	}

	/// @notice Generates random deterministic Gem type of a Chamber
	/// @param seed The Chamber's seed
	/// @return result Gem type
	function generateGemType(uint256 seed) public pure returns (Crawl.Gem) {
		uint8 r = uint8((seed >> 30) % 256);
		if(r < 90) return Crawl.Gem.Silver;
		if(r < 160) return Crawl.Gem.Gold;
		if(r < 200) return Crawl.Gem.Sapphire;
		if(r < 230) return Crawl.Gem.Emerald;
		if(r < 246) return Crawl.Gem.Ruby;
		if(r < 251) return Crawl.Gem.Diamond;
		if(r < 254) return Crawl.Gem.Ethernite;
		return Crawl.Gem.Kao;
	}

	/// @notice Generates random deterministic Coins value of a Chamber
	/// @param seed The Chamber's seed
	/// @return result Coins value
	function generateCoins(uint256 seed) public pure returns (uint16) {
		return uint16(Crawl.mapSeed(seed >> 40, 1, Crawl.mapSeed(seed >> 50, 2, Crawl.mapSeed(seed >> 60, 3, 103))) * 10);
	}

	/// @notice Generates random deterministic Hoard of a Chamber (treasures)
	/// @param seed The Chamber's seed
	/// @return result Crawl.Hoard, including Gem type, Coins value, and calculated Worth value
	function generateHoard(uint256 seed) public pure returns (Crawl.Hoard memory result) {
		result = Crawl.Hoard(
			generateGemType(seed),
			generateCoins(seed),
			0
		);
		result.worth = Crawl.calcWorth(result.gemType, result.coins);
	}

	//----------------------------
	// Bitmap Generators
	//

	/// @notice Returns the bitmap of a Chamber
	/// @param chamber The Chamber, without maps
	/// @return bitmap The Chamber bitmap
	/// @dev The uint256 bitmap contains 256 bits, representing a 16 x 16 Chamber
	/// bit value 0 = void / walls / inaccessible areas
	/// bit value 1 = path / tiles / active game areas
	function generateBitmap(Crawl.ChamberData memory chamber) internal view returns (uint256 bitmap) {
		Rules storage rules = _rules[chamber.terrain];

		uint256 seed = rules.overseed ? Crawl.overSeed(chamber.seed) : chamber.seed;

		// Wave Function Collapse
		if(rules.wfc) {
			bitmap = collapse(seed, rules.openSpaces);
		}
		// Scale seed
		else if (rules.bitSizeX != 1 || rules.bitSizeY != 1) {
			bool vertical = (Crawl.Dir(chamber.entryDir) == Crawl.Dir.North || Crawl.Dir(chamber.entryDir) == Crawl.Dir.South);
			uint256 bitSizeX = vertical ? Math.min(rules.bitSizeX, rules.bitSizeY) : Math.max(rules.bitSizeX, rules.bitSizeY);
			uint256 bitSizeY = vertical ? Math.max(rules.bitSizeX, rules.bitSizeY) : Math.min(rules.bitSizeX, rules.bitSizeY);
			for(uint256 i = 0 ; i < 256 ; ++i) {
				uint256 x = uint256(i % 16) / bitSizeX;
				uint256 y = uint256(i / 16) / bitSizeY;
				uint256 ix = (x + (y * 16));
				if((seed & (1 << (255-ix))) != 0) {
					bitmap |= (1 << (255-i));
				}
			}
		}
		// Purely random
		else {
			bitmap = seed;
		}

		// create protected areas around doors, gems and other tiles
		uint256 protected = Crawl.tilePosToBitmap(chamber.gemPos);
		for(uint8 d = 0 ; d < 4 ; ++d) {
			if (chamber.doors[d] > 0) {
				protected |= Crawl.tilePosToBitmap(chamber.doors[d]);
			}
		}
		for(uint8 i = 0 ; i < chamber.customData.length ; ++i) {
			if(chamber.customData[i].dataType == Crawl.CustomDataType.Tile) {
				protected |= Crawl.tilePosToBitmap(uint8(chamber.customData[i].data[0]));
			}
		}
		
		// carve bitmap with cellular automata
		if(rules.carveValue1 != 0) {
			bitmap = carve(bitmap, protected, rules.carveValue1);
			if(rules.carveValue2 != 0) {
				bitmap = carve(bitmap, protected, rules.carveValue2);
			}
		}
		// ... or else just protect protected areas
		else {
			bitmap = protect(bitmap, protected);
		}
	}

	/// @notice Apply Simplified Wave Function Collapse 
	/// @param seed The Chamber's seed, used as initial random bitmap
	/// @param openSpaces True if the generation rules prefer open spaces
	/// @return result The collapsed bitmap
	/// @dev inspired by:
	/// https://www.youtube.com/watch?v=rI_y2GAlQFM
	/// https://github.com/mxgmn/WaveFunctionCollapse (MIT)
	function collapse(uint256 seed, bool openSpaces) internal pure returns (uint256 result) {
		uint8[64] memory cells;
		for(uint256 i = 0 ; i < 64 ; ++i) {
			uint8 x = uint8(i % 8);
			uint8 y = uint8(i / 8);
			uint8 left = (x == 0 ? 255 : cells[(y * 8) + x - 1]);
			uint8 up = (y == 0 ? 255 : cells[((y - 1) * 8) + x]);

			// each cell is 4 bits (2x2)
			uint8 cell;
			// bit 1: 1000 (0x08)
			// - is left[1] set?
			// - is up[2] set?
			// - else random
			if(left != 255) {
				if(left & 0x04 != 0) cell |= 0x08;
			} else if (up != 255) {
				if(up & 0x02 != 0) cell |= 0x08;
			} else if((seed >> (i*4)) & 1 != 0) {
				cell |= 0x08;
			}
			// bit 2: 0100 (0x04)
			// - is up[3] set?
			// - else random
			if (up != 255) {
				if(up & 0x01 != 0) cell |= 0x04;
			} else if((seed >> (i*4+1)) & 1 != 0) {
				cell |= 0x04;
			}
			// bit 3: 0010 (0x02)
			// - is left[3] set?
			// - else random
			if(left != 255) {
				if(left & 0x01 != 0) cell |= 0x02;
			} else if((seed >> (i*4+2)) & 1 != 0) {
				cell |= 0x02;
			}
			// bit 4: 0001 (0x01)
			// - always random
			if((seed >> (i*4+3)) & 1 != 0) {
				cell |= 0x01;
			}

			//
			// avoid checkers pattern
			// (for more connected rooms)
			//
			// if 0110 (0x06), replace by:
			// 1111 (0x0f) if openSpaces, or 1110 (0x0e) or 0111 (0x07)
			if(cell == 0x06) cell = openSpaces ? 0x0f : ((seed >> (i*4)) & 1) != 0 ? 0x0e : 0x07;
			// if 1001 (0x09), replace by:
			// 1111 (0x0f) if openSpaces, or 1101 (0x0d) or 1011 (0x0b)
			if(cell == 0x09) cell = openSpaces ? 0x0f : ((seed >> (i*4)) & 1) != 0 ? 0x0d : 0x0b;

			cells[i] = cell;
		}

		// print cells into bitmap
		for(uint256 i = 0 ; i < 64 ; ++i) {
			if(cells[i] & 0x08 != 0) result |= (1 << (255 - ((i%8)*2 + (i/8)*2*16)));
			if(cells[i] & 0x04 != 0) result |= (1 << (255 - ((i%8)*2+1 + (i/8)*2*16)));
			if(cells[i] & 0x02 != 0) result |= (1 << (255 - ((i%8)*2 + ((i/8)*2+1)*16)));
			if(cells[i] & 0x01 != 0) result |= (1 << (255 - ((i%8)*2+1 + ((i/8)*2+1)*16)));
		}
	}

	/// @notice Apply Simplified Cellular Automata Cave Generator over a bitmap
	/// @param bitmap The original bitmap
	/// @param protected Bitmap of protected tiles (doors, etc)
	/// @param passValue Minimum neighbour sum value for a bit to remain on
	/// @return result The carved bitmap
	/// @dev inspired by:
	// http://www.roguebasin.com/index.php?title=Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels
	function carve(uint256 bitmap, uint256 protected, uint8 passValue) internal pure returns (uint256 result) {
		// cache cell types. 0 to walls, 1 to paths
		uint8[] memory cellValues = new uint8[](256);
		for(uint256 i = 0 ; i < 256 ; ++i) {
			uint256 bit = (1 << (255-i));
			if((protected & bit) != 0) {
				cellValues[i] = 0x04	; // set a high value for protected tiles
			} else if((bitmap & bit) != 0) {
				cellValues[i] = 0x01;
			}
		}
		// iterate each cell
		for(uint256 i = 0 ; i < 256 ; ++i) {
			// count paths in cell area
			int x = int(i % 16);
			int y = int(i / 16);
			uint8 areaCount = cellValues[i] * 2;
			if(y > 0) areaCount += cellValues[i-16]; // x, y-1
			if(y < 15) areaCount += cellValues[i+16]; // x, y+1
			if(x > 0) {
				areaCount += cellValues[i-1]; // x-1, y
				if(y > 0) areaCount += cellValues[i-16-1]; // x-1, y-1
				if(y < 15) areaCount += cellValues[i+16-1]; // x-1, y+1
			}
			if(x < 15) {
				areaCount += cellValues[i+1]; // x+1, y
				if(y > 0) areaCount += cellValues[i-16+1]; // x+, y-1
				if(y < 15) areaCount += cellValues[i+16+1]; // x+1, y+1
			}
			// apply rule
			if(areaCount >= passValue) {
				result |= (1 << (255 - i)); // set bit
			}
		}
	}

	/// @notice Create space around protected areas
	/// @param bitmap The original bitmap
	/// @param protected Bitmap of protected tiles
	/// @return result The resultimg bitmap
	function protect(uint256 bitmap, uint256 protected) internal pure returns (uint256 result) {
		result = bitmap;
		for(uint256 i = 0 ; i < 256 ; ++i) {
			uint256 bit = (1 << (255-i));
			if(protected & bit != 0) {
				uint256 x = (i % 16);
				uint256 y = (i / 16);
				if(y > 0) result |= (bit << 16);
				if(y < 15) result |= (bit >> 16);
				if(x > 0) {
					result |= (bit << 1);
					if(y > 0) result |= (bit << (16+1));
					if(y < 15) result |= (bit >> (16-1));
				}
				if(x < 15) {
					result |= (bit >> 1);
					if(y > 0) result |= (bit << (16-1));
					if(y < 15) result |= (bit >> (16+1));
				}
			}
		}
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
/// @title Endless Crawler IERC721Enumerable implementation Interface
/// @author Studio Avante
//
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IERC721Enumerable is IERC721 {
	function totalSupply() external view returns (uint256);
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
	function tokenByIndex(uint256 index) external view returns (uint256);
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
/// @title Endless Crawler Chamber Minter Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC721Metadata } from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import { IERC721Enumerable } from './extras/IERC721Enumerable.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerToken is IERC165, IERC721, IERC721Metadata, IERC721Enumerable {
	function isPaused() external view returns (bool);
	function getPrices() external view returns (uint256, uint256);
	function calculateMintPrice(address to) external view returns (uint256);
	function tokenIdToCoord(uint256 tokenId) external view returns (uint256);
	function coordToSeed(uint256 coord) external view returns (Crawl.ChamberSeed memory);
	function coordToChamberData(uint8 chapterNumber, uint256 coord, bool generateMaps) external view returns (Crawl.ChamberData memory);
	function tokenIdToHoard(uint256 tokenId) external view returns (Crawl.Hoard memory);
	// Metadata calls
	function getChamberMetadata(uint8 chapterNumber, uint256 coord) external view returns (string memory);
	function getMapMetadata(uint8 chapterNumber, uint256 coord) external view returns (string memory);
	function getTokenMetadata(uint8 chapterNumber, uint256 coord) external view returns (string memory);
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
/// @title Endless Crawler Chamber Generator Interface (Custom data)
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerGenerator is IERC165 {
	function generateCustomChamberData(Crawl.ChamberData memory chamber) external view returns (Crawl.CustomData[] memory);
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
/// @title Endless Crawler Static Chamber Generator Interface (static data)
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { ICrawlerGenerator } from './ICrawlerGenerator.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerChamberGenerator {
	function generateTerrainType(uint256 seed, Crawl.Terrain fromTerrain) external view returns (Crawl.Terrain);
	function generateHoard(uint256 seed) external view returns (Crawl.Hoard memory);
	function generateChamberData(uint256 coord, Crawl.ChamberSeed memory chamberSeed, bool generateMaps, ICrawlerToken tokenContract, ICrawlerGenerator customGenerator) external view returns (Crawl.ChamberData memory);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}