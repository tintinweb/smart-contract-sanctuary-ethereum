// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}

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
pragma solidity >=0.8.0 <0.9.0;

import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Common.sol";
import "./Serializer.sol";

/// @notice A helper library to generate and handle token features.
library FeaturesHelper {
    using Serializer for Features;
    using Deserializer for FeaturesSerialized;

    /// @notice Generates random token features.
    /// @dev This method is used to generate features for tokens that were not
    /// set in the quiz.
    /// @dev The generated features will never be `Special` or contain `body=2`.
    /// @param tokenId the token of interest.
    /// @param entropy a shared entropy used for the randomization.
    function generateRandomFeatures(uint256 tokenId, bytes32 entropy)
        internal
        pure
        returns (Features memory)
    {
        unchecked {
            Features memory features;
            uint256 rand = uint256(
                keccak256(abi.encode(entropy ^ bytes32(tokenId)))
            );

            // Special treatment for the body trait to exclude bodyId = 2
            // from random sampling.
            uint8 body = uint8((uint64(rand) % (NUM_BODIES - 1)) + 1);
            if (body >= 2) {
                body += 1;
            }

            features.body = body;
            rand >>= 64;
            features.mouth = uint8((uint64(rand) % NUM_MOUTHS) + 1);
            rand >>= 64;
            features.eyes = uint8((uint64(rand) % NUM_EYES) + 1);

            features.background = 13;
            features.special = Special.None;
            features.golden = (tokenId == 0);
            return features;
        }
    }

    /// @notice Retrieves the token features based on quiz data and entropy.
    /// @param tokenId the token of interest.
    /// @param data the token features set in the quiz.
    /// @param entropy a shared entropy used for the randomization.
    /// @return features Either the features set in the quiz or auto-generated
    /// ones if the entropy is non-zero. Null otherwise.
    /// @return isRevealed Flag denoting that the returned features are valid
    /// (either from data or auto-generated).
    function tokenFeatures(
        uint256 tokenId,
        FeaturesSerialized data,
        bytes32 entropy
    ) internal pure returns (FeaturesSerialized, bool) {
        if (entropy == 0 && !data.isSet()) {
            return (FeaturesSerialized.wrap(bytes32(0)), false);
        }

        if (entropy > 0 && !data.isSet()) {
            return (generateRandomFeatures(tokenId, entropy).serialize(), true);
        }

        return (data, true);
    }

    /// @notice Counts how many revealed tokens have the given set of features.
    /// @dev Token features are auto-generated if not set and non-zero entropy.
    /// @param features the features of interest.
    /// @param entropy collection-wide, shared entropy
    /// @param allData token data for which the counting is performed. Usually
    /// all tokens in the collection.
    function countTokensWithFeatures(
        FeaturesSerialized features,
        bytes32 entropy,
        FeaturesSerialized[] memory allData
    ) internal pure returns (uint256) {
        uint256 numTokens = allData.length;
        bytes32 tokenHash = features.hash();
        uint256 numIdentical = 0;

        for (uint256 idx = 0; idx < numTokens; ++idx) {
            (
                FeaturesSerialized sibling,
                bool isSiblingRevealed
            ) = tokenFeatures(idx, allData[idx], entropy);

            if (!isSiblingRevealed) continue;
            if (tokenHash == sibling.hash()) ++numIdentical;
        }

        return numIdentical;
    }

    /// @notice Computes the entropy of given quiz results.
    /// @param data The tokenData to be hashed - usually the output of
    /// `_loadAllTokens` in the main collection contract.
    function computeEntropy(FeaturesSerialized[] memory data)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(data));
    }
}

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

import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Common.sol";
import "./Serializer.sol";
import "./IMetadataRenderer.sol";
import "./JsonEncoder.sol";
import "./FeaturesHelper.sol";

contract ImaginaryFriendMetadataRenderer is IMetadataRenderer {
    using JSONEncoder for bytes;
    using Serializer for Features;
    using Deserializer for FeaturesSerialized;

    /// @notice Returns the token features from data or random generation.
    /// @dev If data is null, the corresponding features are randomly generated
    /// provided the corresponding flag is set.
    function tokenFeatures(
        uint256 tokenId,
        FeaturesSerialized data,
        FeaturesSerialized[] memory allData,
        bool autogenerate
    ) external pure override returns (Features memory, bool) {
        bytes32 entropy = autogenerate
            ? FeaturesHelper.computeEntropy(allData)
            : bytes32(0);
        return _tokenFeatures(tokenId, data, entropy);
    }

    /// @notice Returns the tokenURI for a given token.
    /// @dev If data is null, the corresponding features are randomly generated
    /// provided the corresponding flag is set.
    function tokenURI(
        uint256 tokenId,
        FeaturesSerialized data,
        string memory baseURI,
        FeaturesSerialized[] memory allData,
        bool autogenerate,
        bool countSiblings
    ) external pure override returns (string memory) {
        bytes32 entropy = autogenerate
            ? FeaturesHelper.computeEntropy(allData)
            : bytes32(0);
        return
            _tokenURI(tokenId, data, baseURI, entropy, allData, countSiblings);
    }

    // -------------------------------------------------------------------------
    //
    //  Internals for testing
    //
    // -------------------------------------------------------------------------

    /// @notice Returns the token features from data or random generation.
    /// @dev If data is null, the corresponding features are randomly generated
    /// provided the entropy is set.
    function _tokenFeatures(
        uint256 tokenId,
        FeaturesSerialized data,
        bytes32 entropy
    ) internal pure returns (Features memory, bool) {
        (FeaturesSerialized features, bool isRevealed) = FeaturesHelper
            .tokenFeatures(tokenId, data, entropy);
        return (features.deserialize(), isRevealed);
    }

    /// @notice Returns the tokenURI for a given token.
    /// @dev If data is null, the corresponding features are randomly generated
    /// provided the entropy is set.
    function _tokenURI(
        uint256 tokenId,
        FeaturesSerialized data,
        string memory baseURI,
        bytes32 entropy,
        FeaturesSerialized[] memory allData,
        bool countSiblings
    ) internal pure returns (string memory) {
        (FeaturesSerialized features, bool isRevealed) = FeaturesHelper
            .tokenFeatures(tokenId, data, entropy);

        bytes memory uri = JSONEncoder.init(tokenId);

        if (isRevealed) {
            uint256 numIdentical = countSiblings
                ? FeaturesHelper.countTokensWithFeatures(
                    features,
                    entropy,
                    allData
                )
                : 0;
            uri.addAttributes(features.deserialize(), numIdentical);
        }

        uri.addImageUrl(baseURI, tokenId);
        uri.finalize();
        return string(uri);
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.0 <0.9.0;

import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Common.sol";
import "./Serializer.sol";
import "./IMetadataRenderer.sol";

/// @notice JSON encoding helper library to assemble data-uris
// solhint-disable quotes
library JSONEncoder {
    using DynamicBuffer for bytes;

    /// @notice The token description that will show up in the OS box.
    bytes private constant DESCRIPTION =
        "My Imaginary Friend is a collection of 3000 Imaginary Friend (IF) NFTs released by Kai, the internationally renowned artist who is known for his themes that include time, money and love. This collection combines Kai's passion for art and new mediums across the NFT community.";

    /// @notice Initializes the JSON uri buffer for a given token.
    /// @dev Adds mime type, token name and description.
    function init(uint256 tokenId) internal pure returns (bytes memory) {
        bytes memory uri = DynamicBuffer.allocate(1 << 12);

        uri.appendSafe('data:application/json;utf-8,{"name":"');
        uri.appendSafe(_tokenName(tokenId));
        uri.appendUnchecked('","description":"');
        uri.appendSafe(DESCRIPTION);
        uri.appendSafe('"');
        return uri;
    }

    /// @notice Parses token features and adds the respective attributes to
    /// the JSON uri.
    /// @param features The token features.
    /// @param numIdentical Number of tokens with the given set of features.
    function addAttributes(
        bytes memory uri,
        Features memory features,
        uint256 numIdentical
    ) internal pure {
        uri.appendSafe(', "attributes":[');
        uri.appendSafe(
            _traitStringNoComma(
                "Background",
                Strings.toString(features.background)
            )
        );
        uri.appendSafe(_traitString("Body", _getBodyTraitStr(features.body)));
        uri.appendSafe(
            _traitString("Mouth", _getMouthTraitStr(features.mouth))
        );
        uri.appendSafe(_traitString("Eyes", _getEyesTraitStr(features.eyes)));
        if (numIdentical > 1) {
            if (numIdentical == 2) {
                uri.appendSafe(_traitString("Twin"));
            }
            if (numIdentical == 3) {
                uri.appendSafe(_traitString("Triplet"));
            }
            if (numIdentical > 3) {
                uri.appendSafe(
                    _traitString("Multiplet", Strings.toString(numIdentical))
                );
            }
        }
        if (
            features.special == Special.Angel ||
            features.special == Special.Both
        ) {
            uri.appendSafe(_traitString("Angel"));
        }
        if (
            features.special == Special.Devil ||
            features.special == Special.Both
        ) {
            uri.appendSafe(_traitString("Devil"));
        }
        if (features.golden) {
            uri.appendSafe(_traitString("Golden"));
        }
        uri.appendSafe("]");
    }

    /// @notice Builds the token image attribute for a given token and adds it
    /// the JSON uri.
    function addImageUrl(
        bytes memory uri,
        string memory baseUrl,
        uint256 tokenId
    ) internal pure {
        uri.appendSafe(', "image": "');
        uri.appendSafe(bytes(baseUrl));
        uri.appendSafe("/");
        uri.appendSafe(bytes(Strings.toString(tokenId)));
        uri.appendSafe('"');
    }

    /// @notice Finalizes the json uri buffer
    function finalize(bytes memory uri) internal pure {
        uri.appendSafe("}");
    }

    /// @notice Builds the token name.
    /// @dev Uses uri compatible character encoding.
    function _tokenName(uint256 tokenId) private pure returns (bytes memory) {
        return
            abi.encodePacked("Imaginary Friend %23", Strings.toString(tokenId));
    }

    /// @notice Builds a named attribute string without leading comma.
    /// @dev The returned attribute string has to be added as the first element
    /// of the attributes array (no leading comma)/
    function _traitStringNoComma(bytes memory name, string memory value)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '{"trait_type": "',
                name,
                '", "value":"',
                value,
                '"}'
            );
    }

    /// @notice Builds a named attribute string with leading comma.
    function _traitString(bytes memory name, string memory value)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(",", _traitStringNoComma(name, value));
    }

    /// @notice Builds an unnamed attribute string with leading comma.
    function _traitString(string memory value)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(',{"value":"', value, '"}');
    }

    /// @notice Computes the trait name for a given body.
    function _getBodyTraitStr(uint8 id) private pure returns (string memory) {
        return
            [
                "", // Skip 0, since we are 1 indexed
                "Special 1",
                "Special 2",
                "Special 3",
                "Big Heart",
                "Big Broken Heart",
                "Balloon",
                "Bunch of Hearts",
                "Winged Heart",
                "Brick of Bills",
                "Gold Brick",
                "Coins and Bills",
                "Diamond",
                "Pirates Treasure",
                "Bag of Money",
                "Cement Spreader",
                "Hammer",
                "Garden Shovel",
                "Welder",
                "Flower",
                "Earth",
                "Plant",
                "Watering Can",
                "Light Bulb",
                "Book",
                "Stacked Books",
                "Clock",
                "Hourglass",
                "Skull",
                "Pocket Watch",
                "Video Camera",
                "Film Camera",
                "Painter",
                "Guitar",
                "Camera",
                "Paper and Pencil",
                "Paint Roller and Can"
            ][id];
    }

    /// @notice Computes the trait name for a given mouth.
    function _getMouthTraitStr(uint8 id) private pure returns (string memory) {
        uint8[4] memory nums = [10, 10, 10, 5];
        string[4] memory names = ["Happy", "Sad", "Mad", "Special"];

        for (uint256 idx = 0; idx < 4; ++idx) {
            if (id <= nums[idx]) {
                return
                    string(
                        abi.encodePacked(names[idx], " ", Strings.toString(id))
                    );
            }
            id -= nums[idx];
        }
        return "";
    }

    /// @notice Computes the trait name for given eyes.
    function _getEyesTraitStr(uint8 id) private pure returns (string memory) {
        uint8[6] memory nums = [9, 8, 8, 8, 8, 4];
        string[6] memory names = [
            "Happy",
            "Sad",
            "Mad",
            "Annoyed",
            "Lost and Confused",
            "Special"
        ];

        for (uint256 idx = 0; idx < 6; ++idx) {
            if (id <= nums[idx]) {
                return
                    string(
                        abi.encodePacked(names[idx], " ", Strings.toString(id))
                    );
            }
            id -= nums[idx];
        }
        return "";
    }
}

// solhint-enable quotes

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.8 <0.9.0;

import "./Common.sol";

/// @notice A helper library for `TokenData` serialization.
/// @dev Data is serialized by following the same order and bit-width of fields
/// as given in the definition of the structs using litte-endian encoding.
/// `TokenDataSerialized` will therefore only ever use the rightmost 80 bits.
library Serializer {
    /// @notice Serializes a given set of features.
    function serialize(Features memory features)
        internal
        pure
        returns (FeaturesSerialized)
    {
        unchecked {
            uint48 packed;
            packed += features.background;
            packed <<= 8;
            packed += features.body;
            packed <<= 8;
            packed += features.mouth;
            packed <<= 8;
            packed += features.eyes;
            packed <<= 8;
            packed += uint8(features.special);
            packed <<= 8;
            packed += features.golden ? 1 : 0;
            return FeaturesSerialized.wrap(bytes32(uint256(packed)));
        }
    }

    /// @notice The hash based on which features can be considered to be the
    /// same.
    /// @dev Just a serializaiton and cast
    function hash(Features memory features) internal pure returns (bytes32) {
        return bytes32(FeaturesSerialized.unwrap(serialize(features)));
    }
}

/// @notice A helper library for `TokenDataSerialized` unpacking.
library Deserializer {
    /// @notice Retrieves the `feature` field from serialized data.
    /// @notice Deserializes data into a struct.
    function deserialize(FeaturesSerialized data_)
        internal
        pure
        returns (Features memory)
    {
        unchecked {
            Features memory feats;
            uint256 data = _toUint256(data_);
            feats.golden = uint8(data) == 1;
            data >>= 8;
            feats.special = Special(uint8(data));
            data >>= 8;
            feats.eyes = uint8(data);
            data >>= 8;
            feats.mouth = uint8(data);
            data >>= 8;
            feats.body = uint8(data);
            data >>= 8;
            feats.background = uint8(data);
            return feats;
        }
    }

    /// @notice Checks it the data is set, i.e. non-zero
    function isSet(FeaturesSerialized data) internal pure returns (bool) {
        return FeaturesSerialized.unwrap(data) != 0;
    }

    /// @notice Converts the serialized data to an `uint`.
    function _toUint256(FeaturesSerialized data)
        private
        pure
        returns (uint256)
    {
        return uint256(FeaturesSerialized.unwrap(data));
    }

    /// @notice The hash based on which features can be considered to be the
    /// same.
    /// @dev Just the serialized version
    function hash(FeaturesSerialized features) internal pure returns (bytes32) {
        return FeaturesSerialized.unwrap(features);
    }
}