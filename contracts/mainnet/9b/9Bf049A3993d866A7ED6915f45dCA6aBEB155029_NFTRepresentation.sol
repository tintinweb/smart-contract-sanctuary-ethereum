// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./INFTRepresentation.sol";
import "./INFT.sol";

contract NFTRepresentation is INFTRepresentation {

    function getContractUri(INFT _nft) external view override returns (string memory) {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"', _nft.name(), '"}'
                    )
                )
            )
        );
    }

    function getTokenUri(INFT _nft, uint _tokenId) external view override returns (string memory) {
        (
            INFT.TokenInfo memory token,
            INFT.RoundInfo memory round,
            /* address owner */
        ) = _nft.getTokenInfoExtended(_tokenId);

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"', _nft.name(), '"',
                        ',"image":"', _getImageUri(_nft.name(), _nft.symbol(), round.name, token.shareBasisPoints), '"',
                        ',"properties":',
                        '{"type":"', round.name, '"',
                        '}}'
                    )
                )
            )
        );
    }

    function _getImageUri(string memory _name, string memory, string memory _roundName, uint) internal pure returns (string memory) {
        return string.concat(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 250 285" style="enable-background:new 0 0 250 285;">',
                        '<style type="text/css">.s0{fill:#C4D740;}.s1{fill:#FFFFFF;}.s2{fill:none;stroke:#DDF247;stroke-width:11;}.s3{font-family:Arial, sans-serif;font-weight:bold;}.s4{font-size:16px;}.s5{fill:#D1D1D1;}.s6{font-size:12px;}.s7{font-family:Arial, sans-serif;}.s8{font-size:14px;}</style>',
                        '<clipPath id="c"><rect x="35" y="35" width="180" height="215"/></clipPath>',
                        '<path class="s0" d="M250,10.9L239,0L0,273.1L11.1,285H250V10.9z"/><path class="s1" d="M5.5,5.5h228v262H5.5V5.5z"/><path class="s2" d="M5.5,5.5h228v262H5.5V5.5z"/>',
                        '<text x="35" y="59" class="s3 s4" clip-path="url(#c)">',
                        _name,
                        '</text>',
                        '<text x="35" y="145" class="s7 s6">Type</text>',
                        '<text x="35" y="168" class="s3 s8" clip-path="url(#c)">',
                        _roundName,
                        '</text>',
                        '</svg>'
                    )
                )
            )
        );
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

// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./INFT.sol";

interface INFTRepresentation {
    /**
     * @dev see https://docs.opensea.io/docs/contract-level-metadata
     **/
    function getContractUri(INFT _nft) external view returns (string memory);

    /**
     * @dev see https://docs.opensea.io/docs/metadata-standards
     **/
    function getTokenUri(INFT _nft, uint _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;


interface INFT {

    struct RoundInfo {
        uint128 valuation;
        uint16 maxRoundSharesBasisPoints;
        uint16 mintedSharesBasisPoints;
        uint32 startTS;
        string name;
    }

    struct TokenInfo {
        uint32 roundId;
        uint16 shareBasisPoints;
        uint128 shareInitialValuation;
    }

    event RoundAdded(uint32 roundId, uint128 valuation, uint16 maxRoundShareBasisPoints, string name);

    function totalMintedSharesBasisPoints() external view returns (uint16);

    /// @notice owner of collection
    function owner() external view returns (address);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function getRoundInfo(uint _roundId) external view returns (RoundInfo memory);
    function getTokenInfo(uint _tokenId) external view returns (TokenInfo memory);
    /// @notice get full info about token (including round info and owner)
    function getTokenInfoExtended(uint256 tokenId) external view returns (
        TokenInfo memory _tokenInfo,
        RoundInfo memory  _roundInfo,
        address _ownersAddress
    );
    /// @notice get full info about tokens (including round info and owner)
    function getTokensInfoExtended(uint256[] memory _tokensIds) external view returns (
        TokenInfo[] memory _tokensInfo,
        RoundInfo[] memory _roundsInfo,
        address[] memory _ownersAddresses
    );

    function getRoundsCount() external view returns (uint);
    function getMaxTokenId() external view returns (uint);

    /**
     * @notice returns token info as json using data url
     * @dev see https://docs.opensea.io/docs/metadata-standards
     **/
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @notice returns contract info as json using data url
     * @dev see https://docs.opensea.io/docs/contract-level-metadata
     **/
    function contractURI() external view returns (string memory);


    function addRound(uint128 _valuation, uint16 _maxRoundShareBasisPoints, string memory _roundName, uint32 _roundStartTS)
        external returns(uint32 _roundId);
    function mint(address _to, uint32 _roundId, uint16[] memory _sharesBasisPoints)
        external returns (uint[] memory mintedIds);
    function addRoundAndMint(
        uint128 _valuation, uint16 _maxRoundShareBasisPoints, string memory _roundName, uint32 _roundStartTS,
        address _to, uint16[] memory _sharesBasisPoints
    ) external returns(uint32 roundId, uint[] memory mintedIds);

    /**
     * @notice burns token by owner. Do not decreases round.mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Common case of usage - burn during swap to project token
     */
    function burn(uint256 _tokenId) external;
    /**
     * @notice burns tokens by owner. Do not decreases round.mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Common case of usage - burn during swap to project token
     */
    function burnMany(uint256[] memory _tokenIds) external;

    /**
     * @notice burns token by owner if owner is a collection ownet.
     * Decreases round.mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Common case of usage - burn minted by mistake or unsold tokens
     */
    function burnByCollectionOwner(uint256 _tokenId) external;
    /**
     * @notice burns tokens by owner if owner is a collection ownet.
     * Decreases round.mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Common case of usage - burn minted by mistake or unsold tokens
     */
    function burnByCollectionOwnerMany(uint256[] memory _tokenIds) external;

    /**
     * @dev marker for checks that nft token deployed by factory
     * @dev must return keccak256("NFTFactoryNFT")
     */
    function isNFTFactoryNFT() external view returns (bytes32);
}