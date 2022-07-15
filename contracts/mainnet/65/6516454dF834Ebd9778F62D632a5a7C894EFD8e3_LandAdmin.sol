// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
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

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableInternal, OwnableStorage } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import { ERC1155MetadataInternal } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataInternal.sol";
import { ERC1155MetadataStorage } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";

import { ERC2981Admin } from "../vendor/ERC2981/ERC2981Admin.sol";

import { OpenSeaCompatibleInternal } from "../vendor/OpenSea/OpenSeaCompatible.sol";
import { OpenSeaProxyStorage } from "../vendor/OpenSea/OpenSeaProxyStorage.sol";

import { LandStorage, Segment, Zone } from "./LandStorage.sol";
import { LandPriceStorage, SegmentPrice } from "./LandPriceStorage.sol";
import { Category, MintState, SegmentCount } from "./LandTypes.sol";

/**
 * Administrative functions
 */
contract LandAdmin is
	OwnableInternal,
	ERC1155MetadataInternal,
	OpenSeaCompatibleInternal,
	ERC2981Admin
{
	event SetMintState(MintState mintState);

	// event fired when a proxy is updated
	event SetProxy(address proxy, bool enabled);

	// event fired when a signer is updated
	event SetSigner(address old, address newAddress);

	function addInventory(
		uint8 zoneId,
		uint8 segmentId,
		uint16 count
	) external onlyOwner {
		Zone storage zone = LandStorage._getZone(zoneId);
		Segment memory segment = LandStorage._getSegment(zone, segmentId);

		require(
			count <= segment.endIndex - segment.startIndex - segment.max - segment.count,
			"_addInventory: too much"
		);
		LandStorage._addInventory(zone, segmentId, count);
	}

	function removeInventory(
		uint8 zoneId,
		uint8 segmentId,
		uint16 count
	) external onlyOwner {
		Zone storage zone = LandStorage._getZone(zoneId);
		Segment memory segment = LandStorage._getSegment(zone, segmentId);
		require(count <= segment.max - segment.count, "_removeInventory: too much");
		LandStorage._removeInventory(zone, segmentId, count);
	}

	/**
	 * Add a zone
	 */
	function addZone(Zone memory zone) external onlyOwner {
		uint8 index = LandStorage._getZoneIndex();
		Zone memory last = LandStorage._getZone(index);

		require(LandStorage._isValidSegment(last.four, zone.one), "addZone: wrong one");
		require(LandStorage._isValidSegment(zone.one, zone.two), "addZone: wrong two");
		require(LandStorage._isValidSegment(zone.two, zone.three), "addZone: wrong three");
		require(LandStorage._isValidSegment(zone.three, zone.four), "addZone: wrong four");

		LandStorage._addZone(zone);
	}

	/**
	 * Set the metadata root for tokens
	 */
	function setBaseURI(string memory baseURI) external onlyOwner {
		_setBaseURI(baseURI);
	}

	/**
	 * set the contract metadata root
	 */
	function setContractURI(string memory contractURI) external onlyOwner {
		_setContractURI(contractURI);
	}

	/**
	 * set a discounted price for a zone
	 */
	function setDiscountPrice(uint8 zoneId, SegmentPrice memory price) external onlyOwner {
		LandPriceStorage._setDiscountPrice(zoneId, price);
	}

	function setZoneIndex(uint8 index) external onlyOwner {
		LandStorage._setZoneIndex(index);
	}

	/**
	 * set the $icons contract
	 */
	function setIcons(address icons) external onlyOwner {
		LandStorage.layout().icons = icons;
	}

	/**
	 * set the lions contract
	 */
	function setLions(address lions) external onlyOwner {
		LandStorage.layout().lions = lions;
	}

	/**
	 * add inventory to the zone by setting the maximum
	 */
	function setInventory(uint8 zoneId, SegmentCount memory newMaximums) external onlyOwner {
		Zone storage zone = LandStorage._getZone(zoneId);

		require(
			LandStorage._isValidInventory(zone.one, newMaximums.countOne),
			"setInventory: invalid one"
		);

		require(
			LandStorage._isValidInventory(zone.two, newMaximums.countTwo),
			"setInventory: invalid two"
		);

		require(
			LandStorage._isValidInventory(zone.three, newMaximums.countThree),
			"setInventory: invalid three"
		);

		require(
			LandStorage._isValidInventory(zone.four, newMaximums.countFour),
			"setInventory: invalid four"
		);

		LandStorage._setInventory(
			zone,
			newMaximums.countOne,
			newMaximums.countTwo,
			newMaximums.countThree,
			newMaximums.countFour
		);
	}

	/**
	 * set the mint state
	 */
	function setMintState(MintState mintState) external onlyOwner {
		LandStorage.layout().mintState = uint8(mintState);
		emit SetMintState(mintState);
	}

	/**
	 * set the price
	 */
	function setPrice(SegmentPrice memory price) external onlyOwner {
		LandPriceStorage._setPrice(price);
	}

	/**
	 * set an approved proxy
	 */
	function setProxy(address proxy, bool enabled) external onlyOwner {
		LandStorage._setProxy(proxy, enabled);
		emit SetProxy(proxy, enabled);
	}

	/**
	 * ability to set the opensea proxies
	 */
	function setOSProxies(address os721Proxy, address os1155Proxy) external onlyOwner {
		OpenSeaProxyStorage._setProxies(os721Proxy, os1155Proxy);
	}

	/**
	 * set the authorized signer
	 */
	function setSigner(address signer) external onlyOwner {
		address old = LandStorage._getSigner();
		LandStorage._setSigner(signer);
		emit SetSigner(old, signer);
	}

	function setTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
		_setTokenURI(tokenId, tokenURI);
	}

	/**
	 * Withdraw function
	 */
	function withdraw() external onlyOwner {
		payable(OwnableStorage.layout().owner).transfer(address(this).balance);
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

import { OwnableInternal, OwnableStorage } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import "./ERC2981Storage.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981Admin is OwnableInternal {
	/// @dev Sets token royalties
	/// @param recipient recipient of the royalties
	/// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
	function setRoyalties(address recipient, uint256 value) external onlyOwner {
		require(value <= 10000, "ERC2981Royalties: Too high");
		ERC2981Storage.layout().royalties = RoyaltyInfo(recipient, uint24(value));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct OpenSeaProxyInitArgs {
	address os721Proxy;
	address os1155Proxy;
}

library OpenSeaProxyStorage {
	struct Layout {
		address os721Proxy;
		address os1155Proxy;
	}

	bytes32 internal constant STORAGE_SLOT = keccak256("com.opensea.contracts.storage.proxy");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		// slither-disable-next-line timestamp
		// solhint-disable-next-line no-inline-assembly
		assembly {
			l.slot := slot
		}
	}

	function _setProxies(OpenSeaProxyInitArgs memory init) internal {
		_setProxies(init.os721Proxy, init.os1155Proxy);
	}

	function _setProxies(address os721Proxy, address os1155Proxy) internal {
		layout().os721Proxy = os721Proxy;
		layout().os1155Proxy = os1155Proxy;
	}
}