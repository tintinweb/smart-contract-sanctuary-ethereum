/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
// CryptoPunks's missing tokenURI function
// Author: 0xTycoon. Includes Base64 functionality from OpenZeppelin and builds
//  on top of the on-chain CryptoPunks data contact deployed by Larva Labs
//  as described here: https://www.larvalabs.com/blog/2021-8-18-18-0/on-chain-cryptopunks
// Version: 0.0.2
pragma solidity ^0.8.17;

/*
  #####                                   ######
 #     # #####  #   # #####  #####  ####  #     # #    # #    # #    #  ####
 #       #    #  # #  #    #   #   #    # #     # #    # ##   # #   #  #
 #       #    #   #   #    #   #   #    # ######  #    # # #  # ####    ####
 #       #####    #   #####    #   #    # #       #    # #  # # #  #        #
 #     # #   #    #   #        #   #    # #       #    # #   ## #   #  #    #
  #####  #    #   #   #        #    ####  #        ####  #    # #    #  ####

 #######                             #     #
    #     ####  #    # ###### #    # #     # #####  #
    #    #    # #   #  #      ##   # #     # #    # #
    #    #    # ####   #####  # #  # #     # #    # #
    #    #    # #  #   #      #  # # #     # #####  #
    #    #    # #   #  #      #   ## #     # #   #  #
    #     ####  #    # ###### #    #  #####  #    # #
    */

contract CryptoPunksTokenUri {

    ICryptoPunksData private immutable punksData;

    constructor(address _punksData) {
        if (address(_punksData) == address(0)) {
            _punksData = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;
        }
        punksData = ICryptoPunksData(_punksData);
    }

    /**
    * @dev tokenURI gets the metadata about a punk and returns as a JSON
    *   formatted string, according to the ERC721 schema and market
    *   recommendations. It also embeds the SVG data.
    *   The attributes and SVG data are fetched form the CryptoPunksData
    *   contract, which stores all the CryptoPunks metadata on-chain.
    * @param _tokenId the punk id
    */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(_tokenId < 10000, "invalid _tokenId");
        return string(abi.encodePacked("data:application/json;base64,",
        Base64.encode(
                abi.encodePacked(
                    '{\n"description": "CryptoPunks launched as a fixed set of 10,000 items in mid-2017 and became one of the inspirations for the ERC-721 standard. They have been featured in places like The New York Times, Christie',"'",'s of London, Art|Basel Miami, and The PBS NewsHour.",', "\n",
                    '"external_url": "https://cryptopunks.app/cryptopunks/details/',intToString(_tokenId),'",', "\n",
                    '"image": "data:image/svg+xml;base64,', Base64.encode(punksData.punkImageSvg(uint16(_tokenId))), '",', "\n",
                    '"name": "CryptoPunk #',intToString(_tokenId),'",', "\n",
                    '"attributes": ',getAttributes(_tokenId),'', "\n}"
                )
            )
        ));
    }

    /**
    * @dev parseAttributes returns an array of punk attributes. 8 rows in total
    *   The first row is the Type, and next seven rows are the attributes.
    *   The values are fetched form the CryptoPunksData contract and then the
    *   string is parsed.
    * @param _tokenId the punk id
    */
    function parseAttributes(uint256 _tokenId) public view returns (string[8] memory) {
        bytes memory buf = bytes(punksData.punkAttributes(uint16(_tokenId)));
        string[8] memory atts;
        uint16 pos;
        uint8 state;
        uint8 c;
        uint16 start;
        uint8 row;
        while (pos < buf.length) {
            c = uint8(buf[pos]);
            if (state == 0) {
                // match starting char to be alpha-num, or "3"
                if ((c > 64 && c < 91) ||
                    (c > 96 && c < 123) ||
                    (c == 51))
                {
                    start = pos;
                    state = 1;
                }
            } else if (state == 1) {
                // match comma or end-of-string
                if ((c == 44) || (buf.length == pos+1)) {
                    if (c != 44) {
                        pos++; // capture the last character (edge case for 0-attribute punks)
                    }
                    bytes memory b = new bytes(pos - start);
                    for (uint i =0; i < pos - start; i++) { // copy
                        b[i] = buf[start+i];
                    }
                    atts[row] = string(b);
                    row++;
                    state = 2;
                }
            } else if (state == 2) {
                // capture whitespace
                if (c != 32) {
                    state = 0;
                    pos--; // unread
                }
            }
            pos++;
        }
        return atts;
    }

    /**
    * @dev getAttributes calls parseAttributes and returns the result as JSON
    * @param _tokenId the punk id
    */
    function getAttributes(uint256 _tokenId) public view returns (string memory) {
        string memory ret;
        string[8] memory att = parseAttributes( _tokenId);
        for (uint i =0; i < 8; i++) {
            if (bytes(att[i]).length == 0) {break;}
            if (i == 0) {
                ret = string(abi.encodePacked(
                    '[{', "\n",
                    '"trait_type": "Type",', "\n",
                    '"value": "',att[i],'"', "\n",
                    '}'"\n"
                ));
            } else {
                ret = string(abi.encodePacked(
                ret,
                    ',{', "\n",
                    '"trait_type": "Accessory",', "\n",
                    '"value": "',att[i],'"', "\n",
                    '}'"\n"
                ));
            }
        }
        ret = string(abi.encodePacked(ret, "]"));
        return ret;
    }

    function intToString(uint256 value) public pure returns (string memory) {
        // Inspired by openzeppelin's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15
        // this version removes the decimals counting
        uint8 count;
        if (value == 0) {
            return "0";
        }
        uint256 digits = 31;
        // bytes and strings are big endian, so working on the buffer from right to left
        // this means we won't need to reverse the string later
        bytes memory buffer = new bytes(32);
        while (value != 0) {
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
            digits -= 1;
            count++;
        }
        uint256 temp;
        assembly {
            temp := mload(add(buffer, 32))
            temp := shl(mul(sub(32,count),8), temp)
            mstore(add(buffer, 32), temp)
            mstore(buffer, count)
        }
        return string(buffer);
    }
}

interface ICryptoPunksData {
    function punkImageSvg(uint16 index) external view returns (bytes memory);
    function punkAttributes(uint16 index) external view returns (string memory text);
}


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)
// Source: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Base64.sol
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