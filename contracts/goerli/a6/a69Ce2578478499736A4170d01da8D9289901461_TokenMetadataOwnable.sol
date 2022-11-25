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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./OwnableStorage.sol";
import "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events, Context {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(_msgSender() == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.Ownable");

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

pragma solidity ^0.8.15;

interface ITokenMetadataAdmin {
    function setBaseURI(string calldata newBaseURI) external;

    function setFallbackURI(string calldata newFallbackURI) external;

    function setURISuffix(string calldata newURIPrefix) external;

    function setURI(uint256 tokenId, string calldata newTokenURI) external;

    function setURIBatch(uint256[] calldata tokenIds, string[] calldata newTokenURIs) external;

    function lockBaseURI() external;

    function lockFallbackURI() external;

    function lockURISuffix() external;

    function lockURIUntil(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITokenMetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITokenMetadataInternal.sol";
import "./TokenMetadataStorage.sol";

abstract contract TokenMetadataAdminInternal is ITokenMetadataInternal {
    function _setBaseURI(string memory baseURI) internal virtual {
        require(!TokenMetadataStorage.layout().baseURILocked, "Metadata: baseURI locked");
        TokenMetadataStorage.layout().baseURI = baseURI;
    }

    function _setFallbackURI(string memory baseURI) internal virtual {
        require(!TokenMetadataStorage.layout().fallbackURILocked, "Metadata: fallbackURI locked");
        TokenMetadataStorage.layout().fallbackURI = baseURI;
    }

    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        require(tokenId >= TokenMetadataStorage.layout().lastUnlockedTokenId, "Metadata: tokenURI locked");
        TokenMetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }

    function _setURISuffix(string memory uriSuffix) internal virtual {
        require(!TokenMetadataStorage.layout().uriSuffixLocked, "Metadata: uriSuffix locked");
        TokenMetadataStorage.layout().uriSuffix = uriSuffix;
    }

    function _lockBaseURI() internal virtual {
        TokenMetadataStorage.layout().baseURILocked = true;
    }

    function _lockFallbackURI() internal virtual {
        TokenMetadataStorage.layout().fallbackURILocked = true;
    }

    function _lockURIUntil(uint256 tokenId) internal virtual {
        TokenMetadataStorage.layout().lastUnlockedTokenId = tokenId;
    }

    function _lockURISuffix() internal virtual {
        TokenMetadataStorage.layout().uriSuffixLocked = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../../../access/ownable/OwnableInternal.sol";

import "./TokenMetadataAdminInternal.sol";
import "./TokenMetadataStorage.sol";
import "./ITokenMetadataAdmin.sol";

/**
 * @title NFT Token Metadata - Admin - Ownable
 * @notice Allows diamond owner to change base, per-token, and fallback URIs, as wel as freezing URIs.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies ITokenMetadata
 * @custom:provides-interfaces ITokenMetadataAdmin
 */
contract TokenMetadataOwnable is ITokenMetadataAdmin, TokenMetadataAdminInternal, OwnableInternal {
    function setBaseURI(string calldata newBaseURI) public virtual onlyOwner {
        _setBaseURI(newBaseURI);
    }

    function setFallbackURI(string calldata newFallbackURI) public virtual onlyOwner {
        _setFallbackURI(newFallbackURI);
    }

    function setURISuffix(string calldata newURISuffix) public virtual onlyOwner {
        _setURISuffix(newURISuffix);
    }

    function setURI(uint256 tokenId, string calldata newTokenURI) public virtual onlyOwner {
        _setURI(tokenId, newTokenURI);
    }

    function setURIBatch(uint256[] calldata tokenIds, string[] calldata newTokenURIs) public virtual onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setURI(tokenIds[i], newTokenURIs[i]);
        }
    }

    function lockBaseURI() public virtual onlyOwner {
        _lockBaseURI();
    }

    function lockFallbackURI() public virtual onlyOwner {
        _lockFallbackURI();
    }

    function lockURISuffix() public virtual onlyOwner {
        _lockURISuffix();
    }

    function lockURIUntil(uint256 tokenId) public virtual onlyOwner {
        _lockURIUntil(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library TokenMetadataStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.TokenMetadata");

    struct Layout {
        string baseURI;
        bool baseURILocked;
        string fallbackURI;
        bool fallbackURILocked;
        string uriSuffix;
        bool uriSuffixLocked;
        uint256 lastUnlockedTokenId;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}