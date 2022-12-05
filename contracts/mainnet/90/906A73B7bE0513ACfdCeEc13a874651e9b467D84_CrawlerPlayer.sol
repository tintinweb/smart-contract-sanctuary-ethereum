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
/// @title Endless Crawler Player Profile and Stash Manager
/// @author Studio Avante
/// @notice Creates and maintain Player profile and stash
/// @dev Serves CrawlerToken.sol, depends on ICrawlerToken (chambers tokens)
//
pragma solidity ^0.8.16;
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC165Checker } from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { ICrawlerQuery } from './ICrawlerQuery.sol';
import { Crawl } from './Crawl.sol';

contract CrawlerPlayer is Ownable {

	ICrawlerQuery public _query;

	struct Profile {
		address pfpContract;
		uint256 pfpId;
		uint8 classId;
		uint8 style;
		uint16 value1;
		uint16 value2;
		uint16 value3;
		uint16 value4;
		uint16 value5;
		bool hidden;
		string name;
	}

	struct Stash {
		uint128 coins;
		uint128 worth;
		uint32[8] gems;
	}

	mapping(address => Profile) private _profiles;
	mapping(address => Stash) private _stash;

	event CreatedProfile(address indexed player);
	event UpdatedProfile(address indexed player);

	event Give(address indexed to, Crawl.Gem indexed gem, uint16 indexed coins, uint16 worth);
	event Take(address indexed from, Crawl.Gem indexed gem, uint16 indexed coins, uint16 worth);

	/// @dev modifier to test profile existence, reverts if it does not
	modifier ifExists(address player) {
		require(_profiles[player].style != 0, 'Profile not found');
		require(!_profiles[player].hidden || msg.sender == player, 'Profile unavailable');
		_;
	}

	//---------------
	// Admin
	//

	/// @notice Admin function
	function setQueryContract(address queryContract_) public onlyOwner {
		_query = ICrawlerQuery(queryContract_);
	}

	//---------------
	// Public
	//

	/// @notice Check if a player has a public profile
	/// @param player The Player wallet address
	/// @return result True if the Player has a public profile, False if not, or profile is not public
	function playerHasProfile(address player) public view returns (bool) {
		return (_profiles[player].style != 0 && (!_profiles[player].hidden || msg.sender == player));
	}

	/// @notice Returns a Player public profile
	/// @param player The Player wallet address
	/// @return result Profile struct
	/// PFP and Class id will return empty if player does not own
	/// reverts if Player has no profile or profile is not public
	function getPlayerProfile(address player) public view ifExists(player) returns (Profile memory result) {
		result = _profiles[player];
		// Check PFP ownership
		if(!_query.isOwner(result.pfpContract, result.pfpId, player)) {
			result.pfpContract = address(0);
			result.pfpId = 0;
		}
		// Check class ownership
		if(result.classId != 0 && !_query.isOwner(address(_query.getCardsContract()), result.classId, player)) {
			result.classId = 0;
		}
		// Get class from owned cards
		if(result.classId == 0) {
			uint256[] memory cards = _query.getOwnedCards(player, 1);
			for(uint8 i = 0 ; i < cards.length ; ++i) {
				if(cards[i] > 0) {
					result.classId = i + 1;
					break;
				}
			}
		}
	}

	/// @notice Returns a Player Stash
	/// @param player The Player wallet address
	/// @return result Stash struct, reverts if Player has no profile or profile is not public
	function getPlayerStash(address player) public view ifExists(player) returns (Stash memory) {
		return _stash[player];
	}

	/// @notice Creates a public profile and stash for the sender wallet, reverts if Player already have a profile
	/// @param name Display name
	/// @param pfpContract The PFP contract address, or address(0) if no PFP
	/// @param pfpId The PFP token id, ownership will be validated by getPlayerProfile()
	/// @param classId Class token id to be used, from CardsMinter, ownership will be validated by getPlayerProfile()
	/// @param style The PFP style, reverts if 0
	/// @param value1 Reserved for styling and customization
	/// @param value2 Reserved for styling and customization
	/// @param value3 Reserved for styling and customization
	/// @param value4 Reserved for styling and customization
	/// @param value5 Reserved for styling and customization
	function createProfile(
		string calldata name,
		address pfpContract,
		uint256 pfpId,
		uint8 classId,
		uint8 style,
		uint16 value1,
		uint16 value2,
		uint16 value3,
		uint16 value4,
		uint16 value5)
	public {
		// create new profile
		require(_profiles[msg.sender].style == 0, 'Your profile already exists');
		_updateProfile(name, pfpContract, pfpId, classId, style, value1, value2, value3, value4, value5, false);

		// Create stash from player's Crawler tokens
		ICrawlerToken chambers = _query.getChambersContract();
		Stash memory stash;
		for(uint256 i = 0 ; i < chambers.balanceOf(msg.sender) ; ++i) {
			uint256 tokenId = chambers.tokenOfOwnerByIndex(msg.sender, i);
			Crawl.Hoard memory hoard = chambers.tokenIdToHoard(tokenId);
			stash.gems[uint8(hoard.gemType)]++;
			stash.coins += hoard.coins;
			stash.worth += hoard.worth;
		}

		_stash[msg.sender] = stash;

		emit CreatedProfile(msg.sender);
	}

	/// @notice Updates a public profile for the sender wallet, reverts if Player does not have a profile
	/// @param name Display name
	/// @param pfpContract The PFP contract address, or address(0) if no PFP
	/// @param pfpId The PFP token id, ownership will be validated by getPlayerProfile()
	/// @param classId Class token id to be used, from CardsMinter, ownership will be validated by getPlayerProfile()
	/// @param style The PFP style, reverts if 0
	/// @param value1 Reserved for styling and customization
	/// @param value2 Reserved for styling and customization
	/// @param value3 Reserved for styling and customization
	/// @param value4 Reserved for styling and customization
	/// @param value5 Reserved for styling and customization
	function updateProfile(
		string calldata name,
		address pfpContract,
		uint256 pfpId,
		uint8 classId,
		uint8 style,
		uint16 value1,
		uint16 value2,
		uint16 value3,
		uint16 value4,
		uint16 value5)
	public ifExists(msg.sender) {
		_updateProfile(name, pfpContract, pfpId, classId, style, value1, value2, value3, value4, value5, _profiles[msg.sender].hidden);
		emit UpdatedProfile(msg.sender);
	}

	/// @dev internal profile updater
	function _updateProfile(
		string calldata name,
		address pfpContract,
		uint256 pfpId,
		uint8 classId,
		uint8 style,
		uint16 value1,
		uint16 value2,
		uint16 value3,
		uint16 value4,
		uint16 value5,
		bool hidden
	)
	internal {
		require(style != 0, 'Invalid style');
		_profiles[msg.sender] = Profile(
			pfpContract,
			pfpId,
			classId,
			style,
			value1,
			value2,
			value3,
			value4,
			value5,
			hidden,
			name
		);
	}

	/// @notice Updates the profile visibility for the sender wallet, reverts if Player does not have a profile
	/// @param hidden True to hide, profile will be kept private, False if profile is public
	function hideProfile(bool hidden) public ifExists(msg.sender) {
		_profiles[msg.sender].hidden = hidden;
	}

	//---------------
	// Crawler only
	//

	/// @notice Transfer a Chamber's Hoard to another wallet, works only if called by CrawlerToken contract
	function transferChamberHoard(address from, address to, Crawl.Hoard memory hoard) public {
		if(address(_query) != address(0) && msg.sender == address(_query.getChambersContract())) {
			// Take from
			emit Take(from, hoard.gemType, hoard.coins, hoard.worth);
			if(_profiles[from].style != 0) {
				Stash storage stash = _stash[from];
				stash.gems[uint8(hoard.gemType)] = safe_sub32(stash.gems[uint8(hoard.gemType)], 1);
				stash.coins = safe_sub128(stash.coins, hoard.coins);
				stash.worth = safe_sub128(stash.worth, hoard.worth);
			}
			// Give to
			emit Give(to, hoard.gemType, hoard.coins, hoard.worth);
			if(_profiles[to].style != 0) {
				Stash storage stash = _stash[to];
				stash.gems[uint8(hoard.gemType)] = safe_add32(stash.gems[uint8(hoard.gemType)], 1);
				stash.coins = safe_add128(stash.coins, hoard.coins);
				stash.worth = safe_add128(stash.worth, hoard.worth);
			}
		}
	}

	/// @dev overflows should not happen, but just to be safe and avoid reverting transfers...
	function safe_add128(uint128 a, uint128 b) internal pure returns (uint128) {
		unchecked {
			uint128 c = a + b;
			if (c < a) return type(uint128).max;
			return c;
		}
	}
	function safe_add32(uint32 a, uint32 b) internal pure returns (uint32) {
		unchecked {
			uint32 c = a + b;
			if (c < a) return type(uint32).max;
			return c;
		}
	}
	function safe_sub128(uint128 a, uint128 b) internal pure returns (uint128) {
		if (b > a) return 0;
		return a - b;
	}
	function safe_sub32(uint32 a, uint32 b) internal pure returns (uint32) {
		if (b > a) return 0;
		return a - b;
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
/// @title Cards Store interface
/// @author Studio Avante
/// @notice Cards Store interface
/// @dev Serves CardsMinter.sol
pragma solidity ^0.8.16;

interface ICardsStore {
	function getVersion() external view returns (uint8);
	function exists(uint256 id) external view returns (bool);
	function getCardCount() external view returns (uint256);
	function getCardSupply(uint256 id) external view returns (uint256);
	function getCardPrice(uint256 id) external view returns (uint256);
	function beforeMint(uint256 id, uint256 currentSupply, uint256 balance, uint256 value) external view;
	function uri(uint256 id) external view returns (string memory);
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
/// @title Endless Crawler Cards Minter Interface
/// @author Studio Avante
/// @dev use this interface for contract interaction
pragma solidity ^0.8.16;
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface ICardsMinter is IERC1155 {

	/// @notice Check if the purchases are paused
	/// @return bool True if paused, False if unpaused
	function isPaused() external view returns (bool);

	/// @notice Returns a Token unit price, not considering availability
	/// @param id Token id
	/// @return price Price of the token, in WEI
	function getPrice(uint256 id) external view returns (uint256);

	/// @notice Run all require tests for a successful purchase()
	/// @param id Token id
	/// @param value Value that will be sent to purchase(), in WEI
	/// @return bool True if purchase is allowed, False if not
	/// @return reason The reason when purchase now allowed
	function canPurchase(uint256 id, uint256 value) external view returns (bool, string memory);
	/// @notice Purchases 1 Token for the Sender. The message value must be equal or higher than getPrice(id)
	/// @param id Token id
	/// @param data Nevermind, use []
  function purchase(uint256 id, bytes memory data) external view;

	/// @notice Burn tokens. Sender must be owner or approved
	/// @param id Token id
	/// @param amount The amount of tokens to burn
	function burn(uint256 id, uint256 amount) external view;

	/// @notice Returns a token metadata, compliant with ERC1155Metadata_URI
	/// @param id Token id
	/// @return metadata Token metadata, as json string base64 encoded
	function uri(uint256 id) external view returns (string memory);

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
/// @title Endless Crawler Query Utility Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { ICrawlerToken } from './ICrawlerToken.sol';
import { ICardsMinter } from './external/ICardsMinter.sol';
import { ICardsStore } from './external/ICardsStore.sol';

interface ICrawlerQuery {
	function getChambersContract() external view returns (ICrawlerToken);
	function getCardsContract() external view returns (ICardsMinter);
	function getStoreContract() external view returns (ICardsStore);
	function getOwnedChambers(address account) external view returns (uint256[] memory result);
	function getOwnedCards(address account, uint8 cardType) external view returns (uint256[] memory result);
	function isOwner(address tokenContract, uint256 id, address account) external view returns (bool);
	function getURI(address tokenContract, uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}