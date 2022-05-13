// SPDX-License-Identifier: UNLICENSED
/// @title StringUtilsV3
/// @notice StringUtilsV3
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.13;

import "./StringUtilsV2.sol";
// import "hardhat/console.sol";

contract StringUtilsV3 is StringUtilsV2 {
    function base64Char(uint8 a) public pure returns(uint8) {
        if (a >= 65 && a <= 90) {
            return a - 65;
        } else if (a >= 97 && a <= 122) {
            return a - 97 + 26;
        } else if (a >= 48 && a <= 57) {
            return a - 48 + 52;
        } else if (a == 43) {
            return 62;
        } else if (a == 47) {
            return 63;
        } else {
            return 0;
        }
    }

    function base64Decode(bytes memory data) public pure returns (bytes memory) {
        uint len = data.length;
        uint resultLength = len * 3 / 4;
        if (data[len - 1] == "=") {
            resultLength--;
        }
        if (data[len - 2] == "=") {
            resultLength--;
        }
        bytes memory result = new bytes(resultLength);

        uint resultIndex = 0;
        for (uint i = 0; i<len; i+=4) {
            uint24 first = uint24(base64Char(uint8(data[i]))) * 2**18;
            uint24 second = uint24(base64Char(uint8(data[i + 1]))) * 2**12;
            uint24 third = uint24(base64Char(uint8(data[i + 2]))) * 2**6;
            uint24 fourth = uint24(base64Char(uint8(data[i + 3])));
            uint24 biggie = first | second | third | fourth;
            bytes1 firstCh = bytes1(uint8(biggie / 2**16));
            bytes1 secondCh = bytes1(uint8(biggie / 2**8 % 2**16));
            bytes1 thirdCh = bytes1(uint8(biggie % 2**8));
            result[resultIndex++] = firstCh;
            if (resultIndex < resultLength) {
                result[resultIndex++] = secondCh;
            }
            if (resultIndex < resultLength) {
                result[resultIndex++] = thirdCh;
            }
        }
        return result;
    }

}

// SPDX-License-Identifier: MIT
/// Deployed by CyberPnk <[email protected]>

pragma solidity ^0.8.13;

import "./NumberToString.sol";
import "./AddressToString.sol";
import "./Base64.sol";

contract StringUtilsV2 {
    function base64Encode(bytes memory data) external pure returns (string memory) {
        return Base64.encode(data);
    }

    function base64EncodeJson(bytes memory data) external pure returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(data)));
    }

    function base64EncodeSvg(bytes memory data) external pure returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(data)));
    }

    function numberToString(uint256 value) external pure returns (string memory) {
        return NumberToString.numberToString(value);
    }

    function addressToString(address account) external pure returns(string memory) {
        return AddressToString.addressToString(account);
    }

    // This is quite inefficient, should be used only in read functions
    function split(string calldata str, string calldata delim) external pure returns(string[] memory) {
        uint numStrings = 1;
        for (uint i=0; i < bytes(str).length; i++) {            
            if (bytes(str)[i] == bytes(delim)[0]) {
                numStrings += 1;
            }
        }

        string[] memory strs = new string[](numStrings);

        string memory current = "";
        uint strIndex = 0;
        for (uint i=0; i < bytes(str).length; i++) {            
            if (bytes(str)[i] == bytes(delim)[0]) {
                strs[strIndex++] = current;
                current = "";
            } else {
                current = string(abi.encodePacked(current, bytes(str)[i]));
            }
        }
        strs[strIndex] = current;
        return strs;
    }

    function substr(bytes calldata str, uint startIndexInclusive, uint endIndexExclusive) external pure returns(string memory) {
        bytes memory result = new bytes(endIndexExclusive - startIndexInclusive);
        for (uint j = startIndexInclusive; j < endIndexExclusive; j++) {
            result[j - startIndexInclusive] = str[j];
        }
        return string(result);
    }

    function substrStart(bytes calldata str, uint endIndexExclusive) external pure returns(string memory) {
        bytes memory result = new bytes(endIndexExclusive);
        for (uint j = 0; j < endIndexExclusive; j++) {
            result[j] = str[j];
        }
        return string(result);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library NumberToString {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     *
     *
     * Inspired by OraclizeAPI's implementation - MIT licence
     * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     * Copied from Mad Dog Jones' replicator
     */
    function numberToString(uint256 value) internal pure returns (string memory) {

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library AddressToString {
    function addressToString(address account) internal pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) private pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes32 value) private pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) private pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

}

// SPDX-License-Identifier: MIT
/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.9;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}