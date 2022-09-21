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

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC1155Metadata.sol";
import "./ERC1155MetadataInternal.sol";
import "./ERC1155MetadataStorage.sol";

/**
 * @title ERC1155 - Metadata
 * @notice Provides metadata for ERC1155 tokens according to standard. This extension supports base URI, per-token URI, and a fallback URI. You can also freeze URIs until a certain token ID.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies 0xd9b67a26
 * @custom:provides-interfaces 0x0e89341c
 */
contract ERC1155Metadata is IERC1155Metadata, ERC1155MetadataInternal {
    /**
     * @notice inheritdoc IERC1155Metadata
     */
    function uri(uint256 tokenId) public view virtual returns (string memory) {
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage.layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, l.fallbackURI, Strings.toString(tokenId)));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./IERC1155MetadataEvents.sol";
import "./ERC1155MetadataStorage.sol";

abstract contract ERC1155MetadataInternal is IERC1155MetadataEvents {
    function _setBaseURI(string memory baseURI) internal {
        require(
            !ERC1155MetadataStorage.layout().baseURILocked,
            "ERC1155Metadata: baseURI locked"
        );
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    function _setFallbackURI(string memory baseURI) internal {
        require(
            !ERC1155MetadataStorage.layout().fallbackURILocked,
            "ERC1155Metadata: fallbackURI locked"
        );
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    function _setURI(uint256 tokenId, string memory tokenURI) internal {
        require(
            tokenId > ERC1155MetadataStorage.layout().lastLockedTokenId,
            "ERC1155Metadata: tokenURI locked"
        );
        ERC1155MetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }

    function _lockBaseURI() internal {
        ERC1155MetadataStorage.layout().baseURILocked = true;
    }

    function _lockFallbackURI() internal {
        ERC1155MetadataStorage.layout().fallbackURILocked = true;
    }

    function _lockURIUntil(uint256 tokenId) internal {
        ERC1155MetadataStorage.layout().lastLockedTokenId = tokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC1155Metadata");

    struct Layout {
        string baseURI;
        string fallbackURI;
        bool baseURILocked;
        bool fallbackURILocked;
        uint256 lastLockedTokenId;
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

pragma solidity 0.8.15;

interface IERC1155Metadata {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC1155MetadataEvents {
    event URI(string value, uint256 indexed tokenId);
}