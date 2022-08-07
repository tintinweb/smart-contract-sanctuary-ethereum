// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Strings.sol";

library GLPGenerator {

    function getArt(uint256 tokenId, string memory secret, uint8 layerCount, string memory prefix) public pure returns (string memory, uint256 opacityPercent, string memory pattern) {
         string[55] memory grid;
         string memory suffixTag = '</svg>';
         uint256 opacity = (tokenId % 6) + 3;
         (,string memory pathPattern) = getPath(tokenId, 0, secret);
         
         string memory code = getUniqueCode(tokenId, 101010, secret);
         grid[0] = getR(code, tokenId, secret, 1, 2, 8, opacity, 0, 0);
         grid[1] = getR(code, tokenId, secret, 2, 8, 14, opacity, 40, 0);
         grid[2] = getR(code, tokenId, secret, 3, 14, 20, opacity, 80, 0);
         grid[3] = getR(code, tokenId, secret, 4, 20, 26, opacity, 120, 0);
         grid[4] = getR(code, tokenId, secret, 5, 26, 32, opacity, 160, 0);
         grid[5] = getR(code, tokenId, secret, 6, 32, 38, opacity, 0, 40);
         grid[6] = getR(code, tokenId, secret, 7, 38, 44, opacity, 0, 80);
         grid[7] = getR(code, tokenId, secret, 8, 44, 50, opacity, 0, 120);
         grid[8] = getR(code, tokenId, secret, 9, 50, 56, opacity, 0, 160);
         grid[9] = getR(code, tokenId, secret, 10, 56, 62, opacity, 0, 200);

         code = getUniqueCode(tokenId, 212121, secret);
         grid[10] = getR(code, tokenId, secret, 11, 2, 8, opacity, 200, 0);
         grid[11] = getR(code, tokenId, secret, 12, 8, 14, opacity, 240, 0);
         grid[12] = getR(code, tokenId, secret, 13, 14, 20, opacity, 280, 0);
         grid[13] = getR(code, tokenId, secret, 14, 20, 26, opacity, 320, 0);
         grid[14] = getR(code, tokenId, secret, 15, 26, 32, opacity, 340, 0);
         grid[15] = getR(code, tokenId, secret, 16, 32, 38, opacity, 200, 210);
         grid[16] = getR(code, tokenId, secret, 17, 38, 44, opacity, 200, 250);
         grid[17] = getR(code, tokenId, secret, 18, 44, 50, opacity, 200, 280);
         grid[18] = getR(code, tokenId, secret, 19, 50, 56, opacity, 200, 310);
         grid[19] = getR(code, tokenId, secret, 20, 56, 62, opacity, 200, 340);

         code = getUniqueCode(tokenId, 323232, secret);
         grid[20] = getR(code, tokenId, secret, 21, 2, 8, opacity, 0, 0);
         grid[21] = getR(code, tokenId, secret, 22, 8, 14, opacity, 40, 0);
         grid[22] = getR(code, tokenId, secret, 23, 14, 20, opacity, 80, 0);
         grid[23] = getR(code, tokenId, secret, 24, 20, 26, opacity, 120, 0);
         grid[24] = getR(code, tokenId, secret, 25, 26, 32, opacity, 160, 0);
         grid[25] = getR(code, tokenId, secret, 26, 32, 38, opacity, 0, 40);
         grid[26] = getR(code, tokenId, secret, 27, 38, 44, opacity, 0, 80);
         grid[27] = getR(code, tokenId, secret, 28, 44, 50, opacity, 0, 120);
         grid[28] = getR(code, tokenId, secret, 29, 50, 56, opacity, 0, 160);
         grid[29] = getR(code, tokenId, secret, 30, 56, 62, opacity, 0, 200);

        code = getUniqueCode(tokenId, 434343, secret);
         grid[30] = getR(code, tokenId, secret, 31, 2, 8, opacity, 200, 0);
         grid[31] = getR(code, tokenId, secret, 32, 8, 14, opacity, 240, 0);
         grid[32] = getR(code, tokenId, secret, 33, 14, 20, opacity, 280, 0);
         grid[33] = getR(code, tokenId, secret, 34, 20, 26, opacity, 320, 0);
         grid[34] = getR(code, tokenId, secret, 35, 26, 32, opacity, 340, 0);
         grid[35] = getR(code, tokenId, secret, 36, 32, 38, opacity, 200, 210);
         grid[36] = getR(code, tokenId, secret, 37, 38, 44, opacity, 200, 250);
         grid[37] = getR(code, tokenId, secret, 38, 44, 50, opacity, 200, 280);
         grid[38] = getR(code, tokenId, secret, 39, 50, 56, opacity, 200, 310);
         grid[39] = getR(code, tokenId, secret, 40, 56, 62, opacity, 200, 340);

        code = getUniqueCode(tokenId, 545454, secret);
         grid[40] = getR(code, tokenId, secret, 41, 2, 8, opacity, 0, 0);
         grid[41] = getR(code, tokenId, secret, 42, 8, 14, opacity, 40, 0);
         grid[42] = getR(code, tokenId, secret, 43, 14, 20, opacity, 80, 0);
         grid[43] = getR(code, tokenId, secret, 44, 20, 26, opacity, 120, 0);
         grid[44] = getR(code, tokenId, secret, 45, 26, 32, opacity, 160, 0);
         grid[45] = getR(code, tokenId, secret, 46, 32, 38, opacity, 0, 40);
         grid[46] = getR(code, tokenId, secret, 47, 38, 44, opacity, 0, 80);
         grid[47] = getR(code, tokenId, secret, 48, 44, 50, opacity, 0, 120);
         grid[48] = getR(code, tokenId, secret, 49, 50, 56, opacity, 0, 160);
         grid[49] = getR(code, tokenId, secret, 50, 56, 62, opacity, 0, 200);

        code = getUniqueCode(tokenId, 656565, secret);
         grid[40] = getR(code, tokenId, secret, 51, 2, 8, opacity, 200, 210);
         grid[41] = getR(code, tokenId, secret, 52, 8, 14, opacity, 200, 250);
         grid[42] = getR(code, tokenId, secret, 53, 14, 20, opacity, 200, 280);
         grid[43] = getR(code, tokenId, secret, 54, 20, 26, opacity, 200, 310);
         grid[44] = getR(code, tokenId, secret, 55, 26, 32, opacity, 200, 340);

         string memory output  = string(abi.encodePacked(grid[0], grid[1], grid[2], grid[3], grid[4], grid[5], grid[6], grid[7], grid[8], grid[9], grid[10]));
         output = string(abi.encodePacked(output, grid[11], grid[12], grid[13], grid[14], grid[15], grid[16], grid[17], grid[18], grid[19]));
         output = string(abi.encodePacked(output, grid[20], grid[21], grid[22], grid[23], grid[24]));
        
        if(layerCount == 30) {
         output = string(abi.encodePacked(output, grid[25], grid[26], grid[27], grid[28], grid[29]));
        }
        else if(layerCount == 35) {
         output = string(abi.encodePacked(output, grid[25], grid[26], grid[27], grid[28], grid[29], grid[30], grid[31], grid[32], grid[33], grid[34]));
        }
        else if(layerCount == 40) {
         output = string(abi.encodePacked(output, grid[25], grid[26], grid[27], grid[28], grid[29], grid[30], grid[31], grid[32], grid[33], grid[34]));
         output = string(abi.encodePacked(output, grid[35], grid[36], grid[37], grid[38], grid[39]));
        }
        else if(layerCount == 45) {
         output = string(abi.encodePacked(output, grid[25], grid[26], grid[27], grid[28], grid[29], grid[30], grid[31], grid[32], grid[33], grid[34]));
         output = string(abi.encodePacked(output, grid[35], grid[36], grid[37], grid[38], grid[39], grid[40], grid[41], grid[42], grid[43], grid[44]));
        }
        else if(layerCount == 50){
        output = string(abi.encodePacked(output, grid[25], grid[26], grid[27], grid[28], grid[29], grid[30], grid[31], grid[32], grid[33], grid[34]));
        output = string(abi.encodePacked(output, grid[35], grid[36], grid[37], grid[38], grid[39], grid[40], grid[41], grid[42], grid[43], grid[44]));
        output = string(abi.encodePacked(output, grid[45], grid[46], grid[47], grid[48], grid[49]));
        }
        else if(layerCount == 55){
        output = string(abi.encodePacked(output, grid[25], grid[26], grid[27], grid[28], grid[29], grid[30], grid[31], grid[32], grid[33], grid[34]));
        output = string(abi.encodePacked(output, grid[35], grid[36], grid[37], grid[38], grid[39], grid[40], grid[41], grid[42], grid[43], grid[44]));
        output = string(abi.encodePacked(output, grid[45], grid[46], grid[47], grid[48], grid[49], grid[50], grid[51], grid[52], grid[53], grid[54]));
        }
        return (string(abi.encodePacked(prefix, output, suffixTag)), opacity*10, pathPattern);
    }

    function getR(string memory code, uint256 tokenId, string memory secret, uint8 occurence, uint8 startPos, uint8 endPos, uint256 opacity, uint256 x, uint256 y) public pure returns (string memory) {
        string[17] memory shape;
        
        uint256 h = getHW(tokenId, 3, occurence, secret);
        uint256 w = getHW(tokenId, 4, occurence, secret);
        (string memory path,) = getPath(tokenId, occurence, secret);

        if(h > occurence * 2) {
            h = h - occurence;
        }
        if(w > occurence * 2) {
            w = w - occurence;
        }
        if((x + w) > 400) {
            w = 400 - x;
        }
        if((y + h) > 400) {
            h = 400 - y;
        }
        shape[0] = '<rect x="';
        shape[1] = Strings.toString(x);
        shape[2] = '" y="';
        shape[3] = Strings.toString(y);
        shape[4] = '" width="';
        shape[5] = Strings.toString(w);
        shape[6] = '" height="';
        shape[7] = Strings.toString(h);
        shape[8] = '" style="fill:#';
        shape[9] = getHexColorCode(code, startPos, endPos);
        shape[10] = ';opacity:0.';
        shape[11] = Strings.toString(opacity);
        shape[12] = '"><animateMotion dur="';
        shape[13] = Strings.toString(getDur(tokenId, occurence, secret));
        shape[14] = 's" repeatCount="indefinite" ';
        shape[15] = path;
        shape[16] = '/></rect>';

        string memory rect = string(abi.encodePacked(shape[0], shape[1], shape[2], shape[3], shape[4], shape[5], shape[6], shape[7], shape[8], shape[9]));
        return string(abi.encodePacked(rect, shape[10], shape[11], shape[12], shape[13], shape[14], shape[15], shape[16]));
    }

    function getUniqueCode(uint256 tokenId, uint256 factor, string memory secret) internal pure returns (string memory) {
        return Strings.toHexString(uint256(keccak256(abi.encodePacked(tokenId, factor, secret))));
    }

    function getHW(uint256 tokenId, uint8 factor, uint8 occurence, string memory secretSeed) internal pure returns(uint256){
        return uint256(keccak256(abi.encodePacked(tokenId, factor, occurence, secretSeed))) % 360 + 20;
    }

    function getPath(uint256 tokenId, uint8 occurence, string memory secretSeed) internal pure returns(string memory pathString, string memory motionPattern){
         string memory ord = Strings.toString(uint256(keccak256(abi.encodePacked(tokenId, occurence, secretSeed))) % 330 + 30);
         uint256 pathInd= (tokenId + occurence) % 4;
          if (pathInd == 0) {
            return (string(abi.encodePacked('path="M 0,0 H ', ord, ',0 V ', ord, ',', ord, ' H 0,', ord, ' V 0,0 Z"')) , 'O-H-V-H-O');
          }else if(pathInd == 1) {
            return (string(abi.encodePacked('path="M 0,0 V 0,', ord, ' H ', ord, ',', ord, ' V ', ord, ',0 H 0,0 Z"')) , 'O-V-H-V-O');
          }else if(pathInd == 2) {
            return (string(abi.encodePacked('path="M 0,0 L ', ord, ',', ord, ' L ', ord, ',0 L 0,', ord, ' L 0,0 Z"')) , 'O-D-H-D-O');
          }else {
            return (string(abi.encodePacked('path="M ', ord, ',0 L 0,', ord, ' L 0,0 L ', ord, ',', ord, ' L ', ord, ' 0 Z"')) , 'O-D-V-D-O');
          }
    }

    function getDur(uint256 tokenId, uint8 occurence, string memory secretSeed) internal pure returns(uint256){
        if(tokenId % 3 == 0) {
        return uint256(keccak256(abi.encodePacked(tokenId, occurence, secretSeed))) % 90 + 30;
        }else if(tokenId % 3 == 1) {
            return uint256(keccak256(abi.encodePacked(tokenId, occurence, secretSeed))) % 40 + 10;
        }else {
            return uint256(keccak256(abi.encodePacked(tokenId, occurence, secretSeed))) % 120 + 60;
        }
    }

    function getHexColorCode(string memory code, uint8 startIndex, uint8 endIndex) internal pure returns(string memory) {
     bytes memory codebytes = bytes(code);
     bytes memory result = new bytes(endIndex-startIndex);
       for(uint256 i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = codebytes[i];
        }return string(result);
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