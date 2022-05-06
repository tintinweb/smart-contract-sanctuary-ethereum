// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.8 <0.9.0;

uint8 constant NUM_BACKGROUNDS = 13;
uint8 constant NUM_BODIES = 36;
uint8 constant NUM_MOUTHS = 35;
uint8 constant NUM_EYES = 45;

/// @notice The possible values of the Special trait.
enum Special {
    None,
    Devil,
    Angel,
    Both
}

/// @notice The features an ImaginaryFriend can have.
/// @dev The features are base 1 - zero means the corresponding trait is
/// deactivated.
struct Features {
    uint8 background;
    uint8 body;
    uint8 mouth;
    uint8 eyes;
    Special special;
    bool golden;
}

/// @notice A serialized version of `Features`
type FeaturesSerialized is bytes32;

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.8 <0.9.0;

import "./Common.sol";

interface IMetadataRenderer {
    function tokenFeatures(
        uint256 tokenId,
        FeaturesSerialized data,
        FeaturesSerialized[] memory allData,
        bool autogenerate
    ) external view returns (Features memory, bool);

    function tokenURI(
        uint256 tokenId,
        FeaturesSerialized data,
        string memory baseURI,
        FeaturesSerialized[] memory allData,
        bool autogenerate,
        bool countSiblings
    ) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./Common.sol";
import "./IMetadataRenderer.sol";

/// @notice This contract is compatible with the IF metadata renderer interface
/// but does not compute anything. Instead, it returns the URL to an off-chain
/// backend to accomodate retroactively changed requirements.
contract ImaginaryFriendMetadataRedirector is IMetadataRenderer {
    /// @dev Dummy implementation to satisfy the interface.
    function tokenFeatures(
        uint256,
        FeaturesSerialized,
        FeaturesSerialized[] memory,
        bool
    ) external pure override returns (Features memory, bool) {
        Features memory features;
        return (features, false);
    }

    /// @notice Returns the tokenURI for a given token.
    function tokenURI(
        uint256 tokenId,
        FeaturesSerialized,
        string memory baseURI,
        FeaturesSerialized[] memory,
        bool,
        bool
    ) external pure override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    Strings.toString(tokenId)
                )
            );
    }
}