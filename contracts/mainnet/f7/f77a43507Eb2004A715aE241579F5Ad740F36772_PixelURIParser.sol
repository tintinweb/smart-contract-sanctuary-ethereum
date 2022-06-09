// SPDX-License-Identifier: Unlicense
// Creator: 0xBasedPixel; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./HexChars.sol";

library PixelURIParser {
    string private constant startStr = "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='100%25' height='100%25' viewBox='0 0 16 16'>";
    string private constant endStr = "</svg>";
    uint256 private constant rectStart = 27340891238026048097263813569089141950244693325490254729102276207101788291072;
    uint256 private constant heightNum = 14658463167467038245011812029062285656083636211927847345906851957315119087616;
    uint256 private constant inner1 = 57183955277861053027410940421065042940111934717952;
    uint256 private constant inner2 = 793586231870635386738538214064128;

    function getPixelURI(uint256[12] memory slices, uint256 tokenId) public pure returns (string memory) {
        bytes32[] memory rectComponents = new bytes32[](512);

        uint256 uniqueColors = 0;
        uint256[16] memory colorTracker = [uint256(0), uint256(0),uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)];
        uint256 rTotal = 0;
        uint256 gTotal = 0;
        uint256 bTotal = 0;
        uint256 brightnessSum = 0;

        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 64; j++) {
                uint256 hcR = slices[i*3];
                hcR = (hcR>>(j*4))%16;
                uint256 hcG = slices[i*3+1];
                hcG = (hcG>>(j*4))%16;
                uint256 hcB = slices[i*3+2];
                hcB = (hcB>>(j*4))%16;

                uint256 strNum1 = rectStart+((48 + ((((i*64 + j)%16) - (((i*64 + j)%16)%10))/10))<<176)+((48 + (((i*64 + j)%16)%10))<<168)+inner1;
                strNum1 = strNum1+((48 + ((((i*64 + j)>>4) - (((i*64 + j)>>4)%10))/10))<<120)+((48 + (((i*64 + j)>>4)%10))<<112)+inner2;
                uint256 strNum2 = heightNum+((HexChars.getHex(hcR))<<80);
                strNum2 = strNum2+((HexChars.getHex(hcG))<<72);
                strNum2 = strNum2+((HexChars.getHex(hcB))<<64)+2823543661105512448; //+(39<<56)+(47<<48)+(62<<40)
                rectComponents[(i*64 + j)*2] = bytes32(strNum1);
                rectComponents[(i*64 + j)*2 + 1] = bytes32(strNum2);

                if (((colorTracker[hcR])>>(hcG*16+hcB))%2 == 0) {
                    uniqueColors += 1;
                    colorTracker[hcR] += (uint256(1)<<(hcG*16+hcB));
                }
                rTotal += hcR;
                gTotal += hcG;
                bTotal += hcB;
                brightnessSum += (2126*hcR + 7152*hcG + 722*hcB);
            }
        }

        if ((rTotal+gTotal+bTotal) == 0) {
            rTotal = 1;
            gTotal = 1;
            bTotal = 1;
        }
        uint256 rDom = (rTotal*10000)/(rTotal+gTotal+bTotal);
        uint256 gDom = (gTotal*10000)/(rTotal+gTotal+bTotal);
        uint256 bDom = (bTotal*10000)/(rTotal+gTotal+bTotal);

        string memory brightnessStr;
        if ((brightnessSum/4096) == 10000) {
            brightnessStr = "1";
        }
        else if ((brightnessSum/4096) >= 1000) {
            brightnessStr = string(abi.encodePacked("0.",Strings.toString(brightnessSum/4096)));
        }
        else if ((brightnessSum/4096) >= 100) {
            brightnessStr = string(abi.encodePacked("0.0",Strings.toString(brightnessSum/4096)));
        }
        else if ((brightnessSum/4096) >= 10) {
            brightnessStr = string(abi.encodePacked("0.00",Strings.toString(brightnessSum/4096)));
        }
        else if ((brightnessSum/4096) >= 1) {
            brightnessStr = string(abi.encodePacked("0.000",Strings.toString(brightnessSum/4096)));
        }
        else {
            brightnessStr = "0";
        }

        return string(
            abi.encodePacked(
                "data:application/json;utf8,","{\"name\":\"Token: ",
                Strings.toString(tokenId),"\",\"description\":\"Based Pixels #",
                Strings.toString(tokenId),"\",\"image\":\"data:image/svg+xml;utf8,",
                startStr,rectComponents,endStr,"\",\"attributes\":",
                "[{\"trait_type\":\"Unique Colors\",\"value\":",
                Strings.toString(uniqueColors),"},{\"trait_type\":\"Red Dominance\",",
                "\"value\":0.",Strings.toString(rDom),"},",
                "{\"trait_type\":\"Green Dominance\",\"value\":0.",
                Strings.toString(gDom),"},{\"trait_type\":",
                "\"Blue Dominance\",\"value\":0.",Strings.toString(bDom),"},",
                "{\"trait_type\":\"Average Brightness\",\"value\":",brightnessStr,"}]}"));
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

// SPDX-License-Identifier: Unlicense
// Creator: 0xBasedPixel; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet
pragma solidity ^0.8.0;

library HexChars {
    function getHex(uint _index) public pure returns (uint256) {
        uint256[16] memory hexChars = [
        uint256(48), uint256(49),
        uint256(50), uint256(51),
        uint256(52), uint256(53),
        uint256(54), uint256(55),
        uint256(56), uint256(57),
        uint256(65), uint256(66),
        uint256(67), uint256(68),
        uint256(69), uint256(70)
        ];

        return hexChars[_index];
    }
}