// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { IERC1155Metadata } from './IERC1155Metadata.sol';
import { ERC1155MetadataInternal } from './ERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155 metadata extensions
 */
abstract contract ERC1155Metadata is IERC1155Metadata, ERC1155MetadataInternal {
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC1155Metadata
     */
    function uri(uint256 tokenId) public view virtual returns (string memory) {
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage
            .layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155Metadata internal functions
 */
abstract contract ERC1155MetadataInternal is IERC1155MetadataInternal {
    /**
     * @notice set base metadata URI
     * @dev base URI is a non-standard feature adapted from the ERC721 specification
     * @param baseURI base URI
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    /**
     * @notice set per-token metadata URI
     * @param tokenId token whose metadata URI to set
     * @param tokenURI per-token URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        ERC1155MetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC1155 metadata extensions
 */
library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Metadata');

    struct Layout {
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Internal } from '../IERC721Internal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721Internal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Metadata } from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155Metadata.sol";

import { UintUtils } from "@solidstate/contracts/utils/UintUtils.sol";

import { ERC2981Base } from "../vendor/ERC2981/ERC2981Base.sol";

import { ERC1155MetadataStorage } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";

import { OpenSeaCompatible } from "../vendor/OpenSea/OpenSeaCompatible.sol";
import { LandStorage, Segment, Zone } from "./LandStorage.sol";
import { LandPriceStorage, SegmentPrice } from "./LandPriceStorage.sol";
import { MintState } from "./LandTypes.sol";

contract LandMetadata is ERC2981Base, OpenSeaCompatible, IERC1155Metadata, IERC721Metadata {
	using UintUtils for uint256;

	// Domain Property Getters

	function getDiscountPrice(uint8 zoneId) external view returns (SegmentPrice memory price) {
		return LandPriceStorage._getDiscountPrice(zoneId);
	}

	function getDiscountPriceBySegment(uint8 zoneId, uint8 segmentId)
		external
		view
		returns (uint64 price)
	{
		return LandPriceStorage._getDiscountPrice(zoneId, segmentId);
	}

	function getMintState() external view returns (MintState state) {
		return MintState(LandStorage.layout().mintState);
	}

	function getPrice() external view returns (SegmentPrice memory price) {
		return LandPriceStorage._getPrice();
	}

	function getPriceBySegment(uint8 segmentId) external view returns (uint64 price) {
		return LandPriceStorage._getPrice(segmentId);
	}

	function getSegment(uint8 zoneId, uint8 segmentId) external view returns (Segment memory zone) {
		return LandStorage._getSegment(zoneId, segmentId);
	}

	function getZone(uint8 zoneId) public view returns (Zone memory zone) {
		return LandStorage._getZone(zoneId);
	}

	function getZoneIndex() external view returns (uint8 count) {
		return LandStorage._getZoneIndex();
	}

	// IERC721

	function totalSupply() external view returns (uint256 supply) {
		uint8 zoneCount = LandStorage._getZoneIndex();
		// Currently 3 zones
		for (uint8 i = 1; i <= zoneCount; i++) {
			Zone memory zone = getZone(i);
			supply += zone.one.count;
			supply += zone.two.count;
			supply += zone.three.count;
			supply += zone.four.count;
		}

		return supply;
	}

	// IERC721Metadata

	function name() external pure returns (string memory) {
		return "Sports Metaverse Land";
	}

	function symbol() external pure returns (string memory) {
		return "SPORTSLAND";
	}

	function tokenURI(uint256 tokenId) external view override returns (string memory) {
		return uri(tokenId);
	}

	// IERC1155Metadata

	function uri(uint256 tokenId) public view override returns (string memory) {
		ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage.layout();

		string memory tokenIdURI = l.tokenURIs[tokenId];
		string memory baseURI = l.baseURI;

		if (bytes(baseURI).length == 0) {
			return tokenIdURI; //3
		} else if (bytes(tokenIdURI).length > 0) {
			return string(abi.encodePacked(tokenIdURI));
		} else {
			return string(abi.encodePacked(baseURI, tokenId.toString()));
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Category, SegmentPrice } from "./LandTypes.sol";

library LandPriceStorage {
	struct Layout {
		SegmentPrice price;
		mapping(uint8 => SegmentPrice) discountPrices;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("co.sportsmetaverse.contracts.storage.LandPriceStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}

	// Getters

	function _getDiscountPrice(uint8 zoneId) internal view returns (SegmentPrice storage) {
		return layout().discountPrices[zoneId];
	}

	function _getDiscountPrice(uint8 zoneId, uint8 category) internal view returns (uint64) {
		SegmentPrice memory price = layout().discountPrices[zoneId];
		return _getPrice(price, category);
	}

	function _getPrice() internal view returns (SegmentPrice storage) {
		return layout().price;
	}

	function _getPrice(uint8 category) internal view returns (uint64) {
		SegmentPrice storage price = layout().price;
		return _getPrice(price, category);
	}

	function _getPrice(SegmentPrice memory price, uint8 category) internal pure returns (uint64) {
		if (Category(category) == Category.ONExONE) {
			return price.one;
		}
		if (Category(category) == Category.TWOxTWO) {
			return price.two;
		}
		if (Category(category) == Category.THREExTHREE) {
			return price.three;
		}
		if (Category(category) == Category.SIXxSIX) {
			return price.four;
		}
		revert("_getPrice: wrong category");
	}

	// determine if a specific zone is discountable
	function _isDiscountable(uint8 zoneId) internal view returns (bool) {
		return
			layout().discountPrices[zoneId].one != 0 &&
			layout().discountPrices[zoneId].two != 0 &&
			layout().discountPrices[zoneId].three != 0 &&
			layout().discountPrices[zoneId].four != 0;
	}

	// Setters

	function _setDiscountPrice(uint8 zoneId, SegmentPrice memory price) internal {
		layout().discountPrices[zoneId] = price;
	}

	function _setPrice(SegmentPrice memory price) internal {
		layout().price = price;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Category, Segment, Zone } from "./LandTypes.sol";

library LandStorage {
	struct Layout {
		uint8 mintState;
		address signer;
		address icons;
		address lions;
		uint8 zoneIndex;
		mapping(uint8 => Zone) zones;
		mapping(address => bool) proxies;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("co.sportsmetaverse.contracts.storage.LandStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		// slither-disable-next-line timestamp
		// solhint-disable-next-line no-inline-assembly
		assembly {
			l.slot := slot
		}
	}

	// Adders

	// add the count of minted inventory to the zone segment
	function _addCount(
		uint8 zoneId,
		uint8 segmentId,
		uint16 count
	) internal {
		Zone storage zone = LandStorage.layout().zones[zoneId];
		Category category = Category(segmentId);

		if (category == Category.ONExONE) {
			zone.one.count += count;
		} else if (category == Category.TWOxTWO) {
			zone.two.count += count;
		} else if (category == Category.THREExTHREE) {
			zone.three.count += count;
		} else if (category == Category.SIXxSIX) {
			zone.four.count += count;
		}
	}

	function _addInventory(
		Zone storage zone,
		uint8 segmentId,
		uint16 count
	) internal {
		Category category = Category(segmentId);

		if (category == Category.ONExONE) {
			zone.one.max += count;
		} else if (category == Category.TWOxTWO) {
			zone.two.max += count;
		} else if (category == Category.THREExTHREE) {
			zone.three.max += count;
		} else if (category == Category.SIXxSIX) {
			zone.four.max += count;
		}
	}

	function _removeInventory(
		Zone storage zone,
		uint8 segmentId,
		uint16 count
	) internal {
		Category category = Category(segmentId);

		if (category == Category.ONExONE) {
			zone.one.max -= count;
		} else if (category == Category.TWOxTWO) {
			zone.two.max -= count;
		} else if (category == Category.THREExTHREE) {
			zone.three.max -= count;
		} else if (category == Category.SIXxSIX) {
			zone.four.max -= count;
		}
	}

	// add a new zone
	function _addZone(Zone memory zone) internal {
		uint8 index = _getZoneIndex();
		index += 1;
		_setZone(index, zone);
		_setZoneIndex(index);
	}

	// Getters

	// TODO: resolve the indicies in a way that does not
	// require a contract upgrade to add a named zone
	function _getIndexSportsCity() internal pure returns (uint8) {
		return 1;
	}

	function _getIndexLionLands() internal pure returns (uint8) {
		return 2;
	}

	// get a segment for a zoneId and segmentId
	function _getSegment(uint8 zoneId, uint8 segmentId)
		internal
		view
		returns (Segment memory segment)
	{
		Zone memory zone = _getZone(zoneId);
		return _getSegment(zone, segmentId);
	}

	// get a segment for a zone and segmentId
	function _getSegment(Zone memory zone, uint8 segmentId)
		internal
		pure
		returns (Segment memory segment)
	{
		Category category = Category(segmentId);
		if (category == Category.ONExONE) {
			return zone.one;
		}
		if (category == Category.TWOxTWO) {
			return zone.two;
		}
		if (category == Category.THREExTHREE) {
			return zone.three;
		}
		if (category == Category.SIXxSIX) {
			return zone.four;
		}
		revert("_getCategory: wrong category");
	}

	function _getSigner() internal view returns (address) {
		return layout().signer;
	}

	// get the current index of zones
	function _getZoneIndex() internal view returns (uint8) {
		return layout().zoneIndex;
	}

	// get a zone from storage
	function _getZone(uint8 zoneId) internal view returns (Zone storage) {
		return LandStorage.layout().zones[zoneId];
	}

	// Setters

	// set maximum available inventory
	// note setting to the current count effectively makes none available.
	function _setInventory(
		Zone storage zone,
		uint16 maxOne,
		uint16 maxTwo,
		uint16 maxThree,
		uint16 maxFour
	) internal {
		zone.one.max = maxOne;
		zone.two.max = maxTwo;
		zone.three.max = maxThree;
		zone.four.max = maxFour;
	}

	// set an approved proxy
	function _setProxy(address proxy, bool enabled) internal {
		layout().proxies[proxy] = enabled;
	}

	// set the account that can sign tgransactions
	function _setSigner(address signer) internal {
		layout().signer = signer;
	}

	function _setZone(uint8 zoneId, Zone memory zone) internal {
		layout().zones[zoneId] = zone;
	}

	function _setZoneIndex(uint8 index) internal {
		layout().zoneIndex = index;
	}

	function _isValidInventory(Segment memory segment, uint16 maxCount) internal pure returns (bool) {
		require(maxCount >= segment.count, "_isValidInventory: invalid");
		require(
			maxCount <= segment.endIndex - segment.startIndex - segment.count,
			"_isValidInventory: too much"
		);

		return true;
	}

	function _isValidSegment(Segment memory last, Segment memory incoming)
		internal
		pure
		returns (bool)
	{
		require(incoming.count == 0, "_isValidSegment: wrong count");
		require(incoming.startIndex == last.endIndex, "_isValidSegment: wrong start");
		require(incoming.startIndex <= incoming.endIndex, "_isValidSegment: wrong end");
		require(incoming.max <= incoming.endIndex - incoming.startIndex, "_isValidSegment: wrong max");
		return true;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Enums

enum MintState {
	CLOSED,
	PRESALE,
	OPEN
}

// item category
enum Category {
	UNKNOWN,
	ONExONE,
	TWOxTWO,
	THREExTHREE,
	SIXxSIX
}

// Data Types

// defines the valid range of token id's of a segment
struct Segment {
	uint16 count; // count of tokens minted in the segment
	uint16 max; // max available for the segment (make sure it doesnt overflow)
	uint24 startIndex; // starting index of the segment
	uint24 endIndex; // end index of the segment
}

// price per type
struct SegmentPrice {
	uint64 one; // 1x1
	uint64 two; // 2x2
	uint64 three; // 3x3
	uint64 four; // 6x6
}

// a zone is a specific area of land
struct Zone {
	Segment one; // 1x1
	Segment two; // 2x2
	Segment three; // 3x3
	Segment four; // 6x6
}

// Init Args

// initialization args for the proxy
struct LandInitArgs {
	address signer;
	address lions;
	address icons;
	SegmentPrice price;
	SegmentPrice lionsDiscountPrice;
	Zone zoneOne; // City
	Zone zoneTwo; // Lion
}

// requests

// request to mint a single item
struct MintRequest {
	address to;
	uint64 deadline; // block.timestamp
	uint8 zoneId;
	uint8 segmentId;
	uint16 count;
}

// request to mint many different types
// expects the SegmentCount array to be in index order
struct MintManyRequest {
	address to;
	uint64 deadline;
	SegmentCount[] zones;
}

// requested amount for a specific segment
struct SegmentCount {
	uint16 countOne; // 1x1
	uint16 countTwo; // 2x2
	uint16 countThree; // 3x3
	uint16 countFour; // 6x6
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC2981Storage.sol";
import "./IERC2981Royalties.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is IERC2981Royalties {
	/// @inheritdoc	IERC2981Royalties
	function royaltyInfo(uint256, uint256 value)
		external
		view
		override
		returns (address receiver, uint256 royaltyAmount)
	{
		RoyaltyInfo memory royalties = ERC2981Storage.layout().royalties;
		receiver = royalties.recipient;
		royaltyAmount = (value * royalties.amount) / 10000;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct RoyaltyInfo {
	address recipient;
	uint24 amount;
}

library ERC2981Storage {
	struct Layout {
		RoyaltyInfo royalties;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("IERC2981Royalties.contracts.storage.ERC2981Storage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		// slither-disable-next-line timestamp
		// solhint-disable-next-line no-inline-assembly
		assembly {
			l.slot := slot
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
	/// @notice Called with the sale price to determine how much royalty
	//          is owed and to whom.
	/// @param _tokenId - the NFT asset queried for royalty information
	/// @param _value - the sale price of the NFT asset specified by _tokenId
	/// @return _receiver - address of who should be sent the royalty payment
	/// @return _royaltyAmount - the royalty payment amount for value sale price
	function royaltyInfo(uint256 _tokenId, uint256 _value)
		external
		view
		returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenSeaCompatible {
	/**
	 * Get the contract metadata
	 */
	function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOpenSeaCompatible } from "./IOpenSeaCompatible.sol";

library OpenSeaCompatibleStorage {
	struct Layout {
		string contractURI;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("com.opensea.contracts.storage.OpenSeaCompatibleStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}
}

abstract contract OpenSeaCompatibleInternal {
	function _setContractURI(string memory contractURI) internal virtual {
		OpenSeaCompatibleStorage.layout().contractURI = contractURI;
	}
}

abstract contract OpenSeaCompatible is OpenSeaCompatibleInternal, IOpenSeaCompatible {
	function contractURI() external view returns (string memory) {
		return OpenSeaCompatibleStorage.layout().contractURI;
	}
}