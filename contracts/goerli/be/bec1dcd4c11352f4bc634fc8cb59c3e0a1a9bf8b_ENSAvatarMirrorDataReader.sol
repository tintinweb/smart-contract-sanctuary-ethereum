// SPDX-License-Identifier: CC0-1.0

/// @title ENS Avatar Mirror Data Reader

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

contract ENSAvatarMirrorDataReader {
    function substring(string memory str, uint256 startIndex, uint256 endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function parseAddrString(string memory addr) external pure returns (address) {
        bytes memory addrBytes = bytes(addr);
        uint160 intAddr;

        for (uint256 i = 2; i < 42; i += 2) {
            uint8 b1 = uint8(addrBytes[i]);
            if (b1 >= 97 && b1 <= 102) {
                b1 -= 87;
            } else if (b1 >= 65 && b1 <= 70) {
                b1 -= 55;
            } else if (b1 >= 48 && b1 <= 57) {
                b1 -= 48;
            }

            uint8 b2 = uint8(addrBytes[i + 1]);
            if (b2 >= 97 && b2 <= 102) {
                b2 -= 87;
            } else if (b2 >= 65 && b2 <= 70) {
                b2 -= 55;
            } else if (b2 >= 48 && b2 <= 57) {
                b2 -= 48;
            }

            intAddr = intAddr * 256 + (b1 * 16 + b2);
        }

        return address(intAddr);
    }

    function parseIntString(string memory intStr) external pure returns (uint256 result) {
        bytes memory intStrBytes = bytes(intStr);

        for (uint256 i = 0; i < intStrBytes.length; i++) {
            result = result * 10 + uint8(intStrBytes[i]) - 48;
        }

        return result;
    }

    function uriScheme(string memory uri) external pure returns (bytes32 scheme, uint256 len, bytes32 root) {
        bytes memory uriBytes = bytes(uri);
        uint256 maxIndex = uriBytes.length > 32 ? 32 : uriBytes.length;
        for (uint256 i = 1; i < maxIndex; i++) {
            if (uriBytes[i] == ":") {
                scheme = bytes32(abi.encodePacked(substring(uri, 0, i)));
                len = i;
                if (root == 0) {
                    root = scheme;
                }
                if (scheme != "eip155") {
                    break;
                }
            }
        }
    }
}