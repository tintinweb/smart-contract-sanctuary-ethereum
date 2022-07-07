// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.12;
pragma abicoder v2;

import './libraries/String.sol';
import './libraries/base64.sol';

library NFTDescriptor {
    using Strings for uint256;
    using Strings for string;

    string private constant prefix = "data:application/json;base64,";

    enum DisplayType {
        STRING,
        NORMAL_NUMBER,
        BOOST_NUMBER,
        BOOST_PERCENT,
        NUMBER,
        DATE
    }
    struct Attribute {
        DisplayType displayType;
        string trait_type;
        bytes value;
    }
    struct ConstructTokenURIParams {
        uint256 tokenId;
        uint256 lastTransfered;
        string image;
        address owner;
        string name;
        Attribute[] attributes;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) external view returns (string memory) {
        string memory desc = generateDescription(params);
        string memory attributes = generateAttributes(params.attributes);

        return prefix.concat(
                Base64.encode(
                    string.concat(
                        '{"name":"',
                        escapeQuotes(params.name),
                        '", "description":"',
                        desc,
                        '", "image": "',
                        params.image,
                        '", "attributes": [',
                        attributes,
                        '] }'
                    )
                )
            );
    }

    function generateAttributes(Attribute[] memory attrs) internal pure returns(string memory str) {
        uint256 length = attrs.length;
        for(uint256 i = 0; i < length; i++) {
            str = str.concat(
                generateAttribute(attrs[i])
            );
            if(i + 1 < length) str = str.concat(",");
        }
    }

    function generateAttribute(Attribute memory attr) internal pure returns(string memory str) {
        str = "{ ";
        if(uint(attr.displayType) > 1) {
            str = str.concat('"displayType": "');
            string memory display;
            if(attr.displayType == DisplayType.BOOST_NUMBER) display = "boost_number";
            else if(attr.displayType == DisplayType.BOOST_PERCENT) display = "boost_percentage";
            else if(attr.displayType == DisplayType.NUMBER) display = "number";
            else display = "date";
            str = str.concat(display, '",');
        }
        str = str.concat('"trait_type": "', attr.trait_type, '", "value": ');
        string memory val;
        if(attr.displayType == DisplayType.STRING) {
            val = string.concat('"', string(attr.value), '"');
        } else {
            val = bytesToUint(attr.value).toString();
        }
        str = str.concat(val, " }");
    }

    function escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = '\\';
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    function generateDescription(ConstructTokenURIParams memory params)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'Strive Genesis NFT ',
                    params.tokenId.toString(),
                    ' currently owned by ',
                    addressToString(params.owner),
                    ' since ',
                    toDaysHoursMinutes(block.timestamp - params.lastTransfered),
                    "."
                )
            );
    }

    function toDaysHoursMinutes(uint256 _seconds) internal pure returns(string memory str) {
        uint256 DAYS = _seconds / 1 days;
        _seconds -= DAYS*1 days;
        uint256 HOURS = _seconds / 1 hours;
        _seconds -= HOURS*1 hours;
        uint256 MINS = _seconds / 1 minutes;

        if(DAYS > 0) {
            str = string.concat(DAYS.toString(), DAYS == 1 ? " Day" : " Days");
            if(HOURS > 0) {
                return string.concat(str, " and ", HOURS.toString(), HOURS == 1 ? " Hour" : " Hours");
            }
            return str;
        }
        if(HOURS > 0) {
            str = string.concat(str, HOURS.toString(), HOURS == 1 ? " Hour" : " Hours");
            if(MINS > 0) {
                return string.concat(str, " and ", MINS.toString(), MINS == 1 ? " Minute" : " Minutes");
            }
            return str;
        }
        if(MINS > 0) {
            return string.concat(str, MINS.toString(), MINS == 1 ? " Minute" : " Minutes");
        }

        return "less than a minute";
    }


    function addressToString(address addr) internal pure returns (string memory) {
        return (uint256(uint160(addr))).toHexString(20);
    }


    function sliceTokenHex(uint256 token, uint256 offset) internal pure returns (uint256) {
        return uint256(uint8(token >> offset));
    }

    function bytesToUint(bytes memory b) internal pure returns (uint256 number){
        for(uint i=0;i<b.length;i++){
            number += uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }

    function encode(string memory str) internal pure returns(string memory) {
        return encode(bytes(str));
    }
}

pragma solidity ^0.8.12;


library Strings  {
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

    function concat(string memory str1, string memory str2) internal pure returns(string memory) {
        return string.concat(str1,str2);
    }
    function concat(string memory str1, string memory str2, string memory str3) internal pure returns(string memory) {
        return string.concat(str1,str2,str3);
    }
    function concat(string memory str1, string memory str2, string memory str3, string memory str4) internal pure returns(string memory) {
        return string.concat(str1,str2,str3,str4);
    }
}