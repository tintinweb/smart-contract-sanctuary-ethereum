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
/// @title Endless Crawler Chamber Renderer v.1
/// @author Studio Avante
/// @notice Metadata renderer for Endless Crawler
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import { Base64 } from '@openzeppelin/contracts/utils/Base64.sol';
import { CrawlerContract } from './CrawlerContract.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { ICrawlerRenderer } from './ICrawlerRenderer.sol';
import { MapV1 } from './MapV1.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerRendererV1 is CrawlerContract, ICrawlerRenderer {

	constructor() {
		setupCrawlerContract('Renderer', 1, 1);
	}

	/// @dev implements IERC165
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CrawlerContract) returns (bool) {
		return interfaceId == type(ICrawlerRenderer).interfaceId || CrawlerContract.supportsInterface(interfaceId);
	}

	/// @notice Returns aadditional metadata for CrawlerIndex.getChamberMetadata()
	/// @param chamber The Chamber, without maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return metadata Metadata properties
	function renderAdditionalChamberMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual override returns (string memory) {
		return _renderAtlasImage(chamber, mapper);
	}

	/// @dev Generate Chamber SVG image (not the map, only Terrain color and Yonder for the Atlas)
	/// @param chamber The Chamber, no maps required
	/// @param mapper The ICrawlerMapper contract address
	/// @return metadata The image Metadata containing the SVG source as Base64 string
	function _renderAtlasImage(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) internal view returns (string memory) {
		string memory vp = Crawl.toString(Crawl.max(bytes(Crawl.toString(chamber.yonder)).length, 3));
		return string.concat(
			'"image":"data:image/svg+xml;base64,',
			Base64.encode(
				bytes(string.concat(
					'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="600" height="600" viewBox="0 0 ', vp ,' ', vp ,'">'
					'<defs>'
						'<style>'
							'rect{fill:#', mapper.getColor(chamber.terrain, MapV1.Color_Path), '}'
							'text{font-family:monospace;font-size:1.5px;fill:#', mapper.getColor(chamber.terrain, MapV1.Color_Tiles), '}'
						'</style>'
					'</defs>'
					'<rect width="100%" height="100%" shape-rendering="crispEdges"/>'
					'<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle">', Crawl.toString(chamber.yonder), '</text>'
					'</svg>'
				))
			),
			'"'
		);
	}


	/// @notice Returns the seed and tilemap of a Chamber, used for world building
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return metadata Metadata, as plain json string
	function renderMapMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual override returns (string memory) {
		require(chamber.tilemap.length == 256, 'Bad tilemap');
		string[] memory colors = getColors(chamber, mapper);
		require(colors.length >= 5, 'Incomplete color palette');
		return string.concat(
			'{'
				'"seed":"', Crawl.toHexString(chamber.seed, 32), '",'
				'"tilemap":"data:application/octet-stream;base64,', Base64.encode(chamber.tilemap), '",'
				'"colors":{'
					'"background":"', colors[MapV1.Color_Background], '",'
					'"path":"', colors[MapV1.Color_Path], '",'
					'"tiles":"', colors[MapV1.Color_Tiles], '",'
					'"shadows":"', colors[MapV1.Color_Shadows], '",'
					'"player":"', colors[MapV1.Color_Player], '",'
					'"gem":"', mapper.getGemColor(chamber.hoard.gemType), '",'
					'"coin":"', mapper.getGemColor(Crawl.Gem.Coin), '"'
				'}'
			'}'
		);
	}


	/// @notice Returns IERC721Metadata compliant metadata, used by tokenURI()
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return metadata Metadata, as base64 json string
	/// @dev Reference: https://docs.opensea.io/docs/metadata-standards
	function renderTokenMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual override returns (string memory) {
		require(chamber.tilemap.length == 256, 'Bad tilemap');

		// get current chamber colors
		string[] memory colors = getColors(chamber, mapper);
		require(colors.length >= 5, 'Incomplete color palette');

		string memory variables = string.concat(
			':root{'
				'--Bg:#', colors[MapV1.Color_Background], ';'
				'--Paths:#', colors[MapV1.Color_Path], ';'
				'--Tiles:#', colors[MapV1.Color_Tiles], ';'
				'--Shadows:#', colors[MapV1.Color_Shadows], ';'
				'--Player:#', colors[MapV1.Color_Player], ';'
				'--Gem:#', mapper.getGemColor(chamber.hoard.gemType), ';'
			'}'
		);

		//
		// Generate SVG
		string memory svg = string.concat(
			'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="600" height="600" viewBox="-2 -2 20 20">'
				'<defs>'
					'<style>',
						variables,
						'svg{background-color:var(--Bg);}'
						'text{font-family:monospace;font-size:0.125em;fill:var(--Tiles);}'
						'.Text{}'
						'.Bg{fill:var(--Bg);}'
						'#Gem{fill:var(--Gem);}'
						'#Paths{fill:var(--Paths);}'
						'#Tiles{fill:var(--Tiles);}'
						'#Player{fill:var(--Player);visibility:hidden;}',
						renderSvgStyles(chamber, mapper),
					'</style>',
					renderSvgDefs(chamber, mapper),
				'</defs>'
				'<g>'
					'<rect class="Bg" x="-2" y="-2" width="20" height="20"/>',
					_renderTiles(chamber, mapper),
					'<text class="Text" dominant-baseline="middle" x="0" y="-1">#', Crawl.toString(chamber.tokenId), '</text>'
					// '<text class="Text" dominant-baseline="middle" text-anchor="end" x="16" y="-1">&#167;', Crawl.toString(chamber.chapter), '</text>'
					'<text class="Text" dominant-baseline="middle" x="0" y="17" id="coord">', Crawl.coordsToString(chamber.coord, chamber.yonder, ' '), '</text>'
				'</g>'
			'</svg>'
		);

		string memory animation = string.concat(
			'<!DOCTYPE html>'
			'<html lang="en">'
				'<head>'
					'<meta charset="UTF-8">'
					'<meta name="author" content="Studio Avante">'
					'<title>Endless Crawler Chamber #', Crawl.toString(chamber.tokenId), '</title>'
					'<style>'
						'body{background:#', colors[MapV1.Color_Background], ';margin:0;overflow:hidden;}'
						'#Player{transition:x 0.1s ease-in,y 0.1s ease-in;visibility:visible!important;animation:blinker 1s ease-in infinite;}'
						'@keyframes blinker{75%{opacity:1;}100%{opacity:0;}}'
					'</style>'
				'</head>'
				'<body>',
					renderBackground(chamber, mapper),
					svg,
					'<script>'
						'var coord=document.getElementById("coord").textContent,tm=Array(256);function m(t,e,r,o="moved"){let i=document.getElementById("Player"),l=parseInt(i.getAttribute("x"))+e,d=parseInt(i.getAttribute("y"))+r;if(l>=0&&d>=0&&l<16&&d<16){let n=tm[16*d+l];n&&(i.setAttribute("x",l),i.setAttribute("y",d),window.parent.postMessage(JSON.stringify({crawler:{event:o,x:l,y:d,tile:n,coord}}),"*"))}t?.preventDefault()}window.onload=t=>{let e=document.querySelector("svg");e.setAttribute("height","100vh"),e.setAttribute("width","100vw"),[...document.getElementById("Paths").childNodes,...document.getElementById("Tiles").childNodes].forEach(t=>{if(3!=t.nodeType){let e=t.getBBox(),r=Math.floor(e.x),o=Math.floor(e.y),i=Math.max(e.width,1);e.height;let l=parseInt(t.getAttribute("id")??255);for(let d=0;d<i;++d)tm[16*o+r+d]=l}}),document.addEventListener("keydown",t=>{if(t.repeat)return;let e=t.keyCode;37==e&&m(t,-1,0),38==e&&m(t,0,-1),39==e&&m(t,1,0),40==e&&m(t,0,1),(13==e||32==e)&&m(t,0,0,"action")}),m(null,0,0)};'
					'</script>'
				'</body>'
			'</html>'
		);

		//
		// Generate JSON
		string memory external_url = string.concat('https://endlesscrawler.io/chamber/', Crawl.coordsToString(chamber.coord, 0, ''));
		(string[] memory labels, string[] memory values) = mapper.getAttributes(chamber);
		bytes memory json = bytes(string.concat(
			'{'
				'"name":"', Crawl.tokenName(Crawl.toString(chamber.tokenId)), '",'
				'"description":"Endless Crawler Chamber #', Crawl.toString(chamber.tokenId), '. Play above or below: ', external_url, '",'
				'"external_url":"', external_url, '",'
				'"background_color":"', colors[MapV1.Color_Background], '",'
				'"attributes":[', Crawl.renderAttributesMetadata(labels, values), '],'
				'"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",'
				'"animation_url":"data:text/html;base64,', Base64.encode(bytes(animation)), '"'
			'}'
		));

		return string.concat('data:application/json;base64,', Base64.encode(json));
	}

	/// @dev Render all SVG tiles
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return result The tyiles as SVG elements
	function _renderTiles(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) internal view returns (string memory result) {
		string memory paths;
		string memory tiles;
		string memory player;

		uint256 pathX;
		uint256 pathWidth;
		for(uint256 i = 0 ; i < 256 ; ++i) {
			uint256 x = i % 16;
			uint256 y = i / 16;
			bytes1 tile = chamber.tilemap[i];
			// accumulate path row
			if(tile == MapV1.Tile_Path) {
				if(pathWidth == 0) pathX = x;
				pathWidth++;
			}
			// finish path row
			if((tile != MapV1.Tile_Path || x == 15) && pathWidth > 0) {
				paths = string.concat(paths,
					'<rect x="', Crawl.toString(pathX), '" y="', Crawl.toString(y), '" width="', Crawl.toString(pathWidth), '" height="1"/>'
				);
				pathWidth = 0;
			}
			// draw other tiles
			if(tile != MapV1.Tile_Path && tile != MapV1.Tile_Void) {
				tiles = string.concat(tiles,
					'<use xlink:href="#', mapper.getTileName(tile, uint8(i)), '" x="', Crawl.toString(x), '" y="', Crawl.toString(y), '" id="', Crawl.toString(uint8(tile)), '"/>'
				);
				if(tile == MapV1.Tile_Entry) {
					player = string.concat('<rect id="Player" x="', Crawl.toString(x), '" y="', Crawl.toString(y), '" width="1" height="1"/>');
				}
			}
		}
		
		return string.concat(
			'<g id="Paths" shape-rendering="crispEdges">',
				paths,
			'</g>',
			player,
			'<g id="Tiles">',
				tiles,
			'</g>'
		);
	}


	/// @notice Returns the map colors, from Mapper or curtom data (bound token)
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return result RGB hex color code array, (at least 4 color)
	function getColors(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual returns (string[] memory result) {
		result = mapper.getColors(chamber.terrain);
		for(uint256 i = 0 ; i < chamber.customData.length ; ++i) {
			if(chamber.customData[i].dataType == Crawl.CustomDataType.Palette) {
				for(uint256 c = 0 ; c < chamber.customData[i].data.length / 3 && c < result.length; ++c) {
					result[c] = Crawl.toHexString(chamber.customData[i].data, c*3, 3);
				}
				break;
			}
		}
	}

	/// @notice Returns the map SVG Styles, from Mapper or curtom data (bound token)
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return result SVG code
	function renderSvgStyles(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual returns (string memory) {
		return mapper.renderSvgStyles(chamber);
	}

	/// @notice Returns the map SVG Definitions, from Mapper or curtom data (bound token)
	/// @param chamber The Chamber, with maps
	/// @param mapper The ICrawlerMapper contract address
	/// @return result SVG code
	function renderSvgDefs(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) public view virtual returns (string memory) {
		return mapper.renderSvgDefs(chamber);
	}

	/// @notice Renders animation background
	// @param chamber The Chamber, with maps
	// @param mapper The ICrawlerMapper contract address
	/// @return result HTML code
	function renderBackground(Crawl.ChamberData memory /*chamber*/, ICrawlerMapper /*mapper*/) public view virtual returns (string memory) {
		return '';
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
/// @title Endless Crawler Chamber Renderer Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerRenderer is IERC165 {
	function renderAdditionalChamberMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) external view returns (string memory);
	function renderMapMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) external view returns (string memory);
	function renderTokenMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) external view returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}