// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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
pragma solidity ^0.8.0;

interface IOtoCoJurisdiction {
    function getSeriesNameFormatted(uint256 count, string calldata nameToFormat) external pure returns(string memory);
    function getJurisdictionName() external view returns(string memory);
    function getJurisdictionBadge() external view returns(string memory);
    function getJurisdictionGoldBadge() external view returns(string memory);
    function getJurisdictionRenewalPrice() external view returns(uint256);
    function getJurisdictionDeployPrice() external view returns(uint256);
    function isStandalone() external view returns(bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOtoCoJurisdiction.sol";

interface IOtoCoMasterV2 {

    struct Series {
        uint16 jurisdiction;
        uint16 entityType;
        uint64 creation;
        uint64 expiration;
        string name;
    }

    function owner() external  view returns (address);

    function series(uint256 tokenId) external view returns (uint16, uint16, uint64, uint64, string memory);
    function jurisdictionAddress(uint16 jurisdiction) external view returns (IOtoCoJurisdiction j);
    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev See {OtoCoMaster-baseFee}.
     */
    function baseFee() external view returns (uint256 fee);
    function externalUrl() external view returns (string calldata);
    function getSeries(uint256 tokenId) external view returns (Series memory);
    receive() external payable;
    function docs(uint256 tokenId) external view returns(string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./IOtoCoMasterV2.sol";
import "./IOtoCoJurisdiction.sol";

contract OtoCoURI {

    // Libraries
    using Strings for uint256;

    IOtoCoMasterV2 private otocoMaster;

    constructor (address payable masterAddress) {
        otocoMaster = IOtoCoMasterV2(masterAddress);
    }

    // -- TOKEN VISUALS AND DESCRIPTIVE ELEMENTS --

    /**
     * Get the tokenURI that points to a SVG image.
     * Returns the svg formatted accordingly.
     *
     * @param tokenId must exist.
     * @return svg file formatted.
     */
    function tokenExternalURI(uint256 tokenId, uint256 lastMigrated) external view returns (string memory) {
        (uint16 jurisdiction,,uint64 creation,,string memory name) = otocoMaster.series(tokenId);
        IOtoCoJurisdiction jurisdictionContract = IOtoCoJurisdiction(otocoMaster.jurisdictionAddress(jurisdiction));
        string memory badge = jurisdictionContract.getJurisdictionBadge();
        if (tokenId < lastMigrated) badge = jurisdictionContract.getJurisdictionGoldBadge();
        string memory docs = otocoMaster.docs(tokenId); 
            string memory json = Base64.encode(bytes(string(abi.encodePacked(
                '{"name": "',
                name,
                '", "description": "',
                "OtoCo NFTs are minted to represent each entity and their jurisdiction as created by the OtoCo dapp. ",
                "The holder of this NFT as recorded on the blockchain is the owner of ",
                name,
                " and is authorized to access the entity's dashboard on https://otoco.io.",
                '", "image": "',
                badge,
                '", "external_url": "',
                otocoMaster.externalUrl(),
                tokenId.toString(),
                '/',
                bytes(docs).length != 0 ? string(abi.encodePacked('", "docs": "', docs)) : "",
                '","attributes":[',
                '{"display_type": "date","trait_type": "Creation", "value": "',
                uint256(creation).toString(),
                '"},{"trait_type": "Jurisdiction", "value": "',
                jurisdictionContract.getJurisdictionName(),
                '"}]}'
            ))));
            return string(abi.encodePacked('data:application/json;base64,', json));
    }
}