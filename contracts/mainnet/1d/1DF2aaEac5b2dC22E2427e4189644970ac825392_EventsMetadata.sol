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

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata {
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
 * @title ERC721Metadata interface
 */
interface IERC721Metadata {
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

import { OwnableInternal, OwnableStorage } from "@solidstate/contracts/access/OwnableInternal.sol";
import { ERC2981Base } from "../vendor/ERC2981/ERC2981Base.sol";

import { ERC1155MetadataStorage } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";

import { OpenSeaCompatible } from "../vendor/OpenSea/OpenSeaCompatible.sol";

import { EventsStorage, MintState, Edition } from "./EventsStorage.sol";

contract EventsMetadata is
	OwnableInternal,
	ERC2981Base,
	OpenSeaCompatible,
	IERC1155Metadata,
	IERC721Metadata
{
	using UintUtils for uint256;

	function getIndex() internal view returns (uint256 index) {
		return EventsStorage._getIndex();
	}

	function getMintState(uint256 tokenId) public view returns (MintState state) {
		return EventsStorage._getState(tokenId);
	}

	function getPrice(uint256 tokenId) public view returns (uint256 price) {
		return EventsStorage._getPrice(tokenId);
	}

	function getEdition(uint256 tokenId) internal view returns (Edition storage edition) {
		return EventsStorage._getEdition(tokenId);
	}

	// IERC721Metadata

	function name() external pure returns (string memory) {
		return "PASS Events";
	}

	function symbol() external pure returns (string memory) {
		return "PASSPARTY";
	}

	function tokenURI(uint256 tokenId) external view override returns (string memory) {
		return uri(tokenId);
	}

	// IERC1155Metadata

	function uri(uint256 tokenId) public view virtual returns (string memory) {
		ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage.layout();

		string memory tokenIdURI = l.tokenURIs[tokenId];
		string memory baseURI = l.baseURI;

		if (bytes(tokenIdURI).length > 0) {
			return tokenIdURI;
		} else {
			return baseURI;
		}
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