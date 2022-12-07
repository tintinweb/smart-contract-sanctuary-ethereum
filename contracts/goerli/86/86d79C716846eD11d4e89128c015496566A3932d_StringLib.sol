// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library StringLib {
    function toUpper(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bUpper = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Lowercase character...
            if ((uint8(bStr[i]) >= 97) && (uint8(bStr[i]) <= 122)) {
                // So we subtract 32 to make it uppercase
                bUpper[i] = bytes1(uint8(bStr[i]) - 32);
            } else {
                bUpper[i] = bStr[i];
            }
        }
        return string(bUpper);
    }

    function numberFromAscII(bytes1 b) private pure returns (uint8 res) {
        if (b>="0" && b<="9") {
            return uint8(b) - uint8(bytes1("0"));
        } else if (b>="A" && b<="F") {
            return 10 + uint8(b) - uint8(bytes1("A"));
        } else if (b>="a" && b<="f") {
            return 10 + uint8(b) - uint8(bytes1("a"));
        }
        return uint8(b); // or return error ... 
    }

    function stringToUint(string memory s, uint8 base ) 
        public 
        pure
        returns (uint256 result) 
    {
        bytes memory b = bytes(s);
        uint i;
        uint c;
        result = 0;
        if ( base == 10 ) {
            for (i = 0; i < b.length; i++) {
                c = uint(uint8(b[i]));
                if (c >= 48 && c <= 57) {
                    result = result * 10 + (c - 48);
                }
            }
        } else if ( base == 16 ) {
            result = 0;
            for (i = 0; i < b.length; i++) {
                result = result << 4;
                result |= numberFromAscII(b[i]);
            }
        }

        return(result);
    }

    function uintToString(uint v) 
        public 
        pure
        returns (string memory str) 
    {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            bytes1 rm = bytes1(uint8(48 + remainder));
            reversed[i++] = rm;
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }
}