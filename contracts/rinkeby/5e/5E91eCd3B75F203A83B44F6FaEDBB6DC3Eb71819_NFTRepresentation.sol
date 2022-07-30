// SPDX-License-Identifier: bsl-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./INFTRepresentation.sol";
import "./INFT.sol";

contract NFTRepresentation is INFTRepresentation {

    function getContractUri(INFT _nft) external view override returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', _nft.name(), '"}'
                        )
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

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', _nft.symbol(), ' ', _bpToPercentsStr(token.shareBasisPoints), '%"',
                            ',"image":"', _getImageUri(_nft.name(), _nft.symbol(), round.name, token.shareBasisPoints), '"',
                            ',"properties":',
                            '{"round":"', round.name, '"',
                            ',"project_valuation_in_round":', Strings.toString(round.valuation),
                            ',"max_shares_percentage_of_round":', _bpToPercentsStr(round.maxRoundSharesBasisPoints),
                            ',"share_percentage":', _bpToPercentsStr(token.shareBasisPoints),
                            ',"share_initial_valuation":', Strings.toString(token.shareInitialValuation),
                            '}}'
                        )
                    )
                )
            )
        );
    }

    function _bpToPercentsStr(uint shareBasisPoints) internal pure returns (string memory) {
        uint digit1 = shareBasisPoints / 10 % 10;
        uint digit2 = shareBasisPoints % 10;
        return string(
            abi.encodePacked(
                Strings.toString(shareBasisPoints / 100),
                digit1 > 0 || digit2 > 0 ? '.' : '',
                digit1 > 0 || digit2 > 0 ? Strings.toString(digit1) : '',
                digit2 > 0 ? Strings.toString(digit2) : ''
            )
        );
    }

    function _getImageUri(string memory _name, string memory _symbol, string memory _roundName, uint _shareBP) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '<?xml version="1.0" encoding="UTF-8"?><svg viewBox="60.469 76.324 321.29 267.95" xmlns="http://www.w3.org/2000/svg"><rect x="60.469" y="76.324" width="321.29" height="267.95" fill="#fff79d" stroke="#000"/><text transform="matrix(.8185 0 0 .8185 76.978 115.06)" fill="rgb(51, 51, 51)" font-family="Arial, sans-serif" font-size="28px" style="white-space:pre">',
                                _name,
                                '</text><text transform="matrix(.8185 0 0 .8185 77.613 161.41)" fill="rgb(51, 51, 51)" font-family="Arial, sans-serif" font-size="28px" style="white-space:pre">',
                                _symbol,
                                '</text><text transform="matrix(.8185 0 0 .8185 76.978 195.7)" fill="rgb(51, 51, 51)" font-family="Arial, sans-serif" font-size="28px" style="white-space:pre">',
                                _roundName,
                                '</text><text transform="matrix(.8185 0 0 .8185 77.479 238.89)" fill="rgb(51, 51, 51)" font-family="Arial, sans-serif" font-size="28px" style="white-space:pre">',
                                _bpToPercentsStr(_shareBP),
                                '%</text><text transform="matrix(.8185 0 0 .8185 274.45 332.21)" fill="rgb(51, 51, 51)" font-family="Arial, sans-serif" font-size="28px" style="white-space:pre">',
                                'raise.is</text><path transform="matrix(.8185 0 0 .8185 -19.535 -44.923)" d="m423.18 379.7q0-0.68 0.619-1.073 0.662-0.419 1.527-0.166 0.961 0.281 1.571 1.239 0.685 1.076 0.575 2.478-0.123 1.568-1.195 2.887-1.187 1.461-3.097 2.069-2.095 0.667-4.337 0.077-2.436-0.64-4.248-2.555-1.953-2.063-2.567-4.956-0.657-3.097 0.421-6.195 1.148-3.298 3.916-5.609 2.932-2.447 6.815-3.065 4.095-0.651 8.054 0.919 4.159 1.651 6.968 5.277 2.943 3.797 3.564 8.673 0.648 5.092-1.417 9.912-2.152 5.022-6.637 8.33-4.662 3.438-10.532 4.061-6.089 0.646-11.771-1.915-5.883-2.651-9.69-7.997-3.935-5.526-4.559-12.391-0.645-7.085 2.413-13.63 3.15-6.745 9.358-11.05 6.388-4.432 14.249-5.057 8.08-0.643 15.488 2.911 7.607 3.649 12.411 10.718 4.929 7.252 5.555 16.108 0.642 9.077-3.409 17.347-4.148 8.469-12.079 13.772-8.115 5.426-17.966 6.053-10.073 0.641-19.206-3.907-9.331-4.648-15.132-13.44-5.923-8.978-6.551-19.825-0.641-11.069 4.405-21.064 5.146-10.194 14.8-16.493 9.841-6.421 21.684-7.049 0.392-0.021 0 0" fill="#d8d8d8" stroke="#000"/></svg>'
                            )
                        )
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
pragma solidity ^0.8.0;
pragma abicoder v2;

// Disabled to make interface light for usage. Needed functions were added to INFT
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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

    function owner() external view returns (address);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function getRoundInfo(uint _roundId) external view returns (RoundInfo memory);
    function getTokenInfo(uint _tokenId) external view returns (TokenInfo memory);
    function getTokenInfoExtended(uint256 tokenId) external view returns (
        TokenInfo memory _tokenInfo,
        RoundInfo memory  _roundInfo,
        address _owner
    );
    function getTokensInfoExtended(uint256[] memory _tokensIds) external view returns (
        TokenInfo[] memory _tokensInfo,
        RoundInfo[] memory _roundsInfo,
        address[] memory _owners
    );

    function getRoundsCount() external view returns (uint);
    function getMaxTokenId() external view returns (uint);

    function burn(uint256 _tokenId) external;

    /**
     * @dev marker for checks that nft token deployed by factory
     * @dev must return keccak256("NFTFactoryNFT")
     */
    function isNFTFactoryNFT() external view returns (bytes32);
}