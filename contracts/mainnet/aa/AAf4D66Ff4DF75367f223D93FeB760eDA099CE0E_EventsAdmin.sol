// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
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

import { OwnableInternal, OwnableStorage } from "@solidstate/contracts/access/OwnableInternal.sol";
import { ERC1155MetadataInternal } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataInternal.sol";
import { ERC1155MetadataStorage } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";

import { ERC2981Admin } from "../vendor/ERC2981/ERC2981Admin.sol";

import { OpenSeaCompatibleInternal } from "../vendor/OpenSea/OpenSeaCompatible.sol";
import { OpenSeaProxyStorage } from "../vendor/OpenSea/OpenSeaProxyStorage.sol";

import { Edition, EventsStorage, MintState } from "./EventsStorage.sol";

contract EventsAdmin is
	OwnableInternal,
	ERC1155MetadataInternal,
	OpenSeaCompatibleInternal,
	ERC2981Admin
{
	function setAuthorized(address target, bool allowed) external onlyOwner {
		EventsStorage._setAuthorized(target, allowed);
	}

	function setBaseURI(string memory baseURI) external onlyOwner {
		_setBaseURI(baseURI);
	}

	function setContractURI(string memory contractURI) external onlyOwner {
		_setContractURI(contractURI);
	}

	function setIndex(uint256 index) external onlyOwner {
		EventsStorage._setIndex(index);
	}

	function setLimit(uint256 tokenId, uint8 limit) external onlyOwner {
		EventsStorage._setLimit(tokenId, limit);
	}

	function setMaxCount(uint256 tokenId, uint16 maxCount) external onlyOwner {
		EventsStorage._setMaxCount(tokenId, maxCount);
	}

	function setPrice(uint256 tokenId, uint64 price) external onlyOwner {
		EventsStorage._setPrice(tokenId, price);
	}

	function setState(uint256 tokenId, MintState state) external onlyOwner {
		EventsStorage._setState(tokenId, state);
	}

	function setTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
		_setTokenURI(tokenId, tokenURI);
	}

	function setProxy(address proxy, bool allowed) external onlyOwner {
		EventsStorage._setProxy(proxy, allowed);
	}

	function setProxies(address os721Proxy, address os1155Proxy) external onlyOwner {
		OpenSeaProxyStorage._setProxies(os721Proxy, os1155Proxy);
	}

	function withdraw() external onlyOwner {
		payable(OwnableStorage.layout().owner).transfer(address(this).balance);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum MintState {
	CLOSED,
	OPEN
}

struct Edition {
	uint8 state;
	uint16 count;
	uint16 max;
	uint64 price;
	uint8 limit; // purchase limit
}

library EventsStorage {
	struct Layout {
		uint256 index;
		mapping(uint256 => Edition) editions;
		mapping(address => bool) authorized;
		mapping(address => bool) proxies;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("io.partyanimalz.contracts.storage.EventsStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}

	// Adders

	function _addCount(uint256 tokenId, uint16 count) internal {
		Edition storage edition = _getEdition(tokenId);
		_addCount(edition, count);
	}

	function _addCount(Edition storage edition, uint16 count) internal {
		edition.count += count;
	}

	function _addEdition(Edition memory edition) internal {
		uint256 index = _getIndex();
		_addEdition(index, edition);
	}

	function _addEdition(uint256 index, Edition memory edition) internal {
		EventsStorage.layout().editions[index] = edition;
		index += 1;
		_setIndex(index);
	}

	// Getters

	function _getCount(uint256 tokenId) internal view returns (uint16) {
		return layout().editions[tokenId].count;
	}

	function _getEdition(uint256 tokenId) internal view returns (Edition storage) {
		return layout().editions[tokenId];
	}

	function _getIndex() internal view returns (uint256 index) {
		return layout().index;
	}

	function _getPrice(uint256 tokenId) internal view returns (uint64) {
		return layout().editions[tokenId].price;
	}

	function _getState(uint256 tokenId) internal view returns (MintState) {
		return MintState(layout().editions[tokenId].state);
	}

	// Setters

	function _setAuthorized(address target, bool allowed) internal {
		layout().authorized[target] = allowed;
	}

	function _setIndex(uint256 index) internal {
		layout().index = index;
	}

	function _setLimit(uint256 tokenId, uint8 limit) internal {
		layout().editions[tokenId].limit = limit;
	}

	function _setMaxCount(uint256 tokenId, uint16 maxCount) internal {
		layout().editions[tokenId].max = maxCount;
	}

	function _setPrice(uint256 tokenId, uint64 price) internal {
		layout().editions[tokenId].price = price;
	}

	function _setProxy(address proxy, bool enabled) internal {
		layout().proxies[proxy] = enabled;
	}

	function _setState(uint256 tokenId, MintState state) internal {
		layout().editions[tokenId].state = uint8(state);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OwnableInternal, OwnableStorage } from "@solidstate/contracts/access/OwnableInternal.sol";

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