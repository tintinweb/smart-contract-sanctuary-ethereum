// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "./AvatizerSVGRenderer.sol";

interface AvatizersNFT {
    function getTokenGenes(uint256 tokenId) external view returns (bytes memory);
}

contract AvatizersMetadataManager is Ownable {
    using Strings for uint256;

    mapping(uint256 => string) specialImages;

    AvatizersNFT nftContract = AvatizersNFT(address(0));

    function setNFTContract(address _nftContract) external onlyOwner {
        nftContract = AvatizersNFT(_nftContract);
    }

    function setSpecialImage(uint256 tokenId, string memory svg) external onlyOwner {
        specialImages[tokenId] = svg;
    }

    function generateImage(bytes memory seed) public pure returns (string memory svg) {
        {
            svg = string.concat(
                '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 730 850" style="enable-background:new 0 0 730 850;">',
                AvatizersSVGRenderer.genStyleSheet(seed, AvatizersSVGRenderer.genColourPalette(15, seed)),
                '<g transform="translate(-65 0)"><rect id="Background" class="st0" width="100%" height="100%"/></g>',
                AvatizersSVGRenderer.genShards(seed),
                AvatizersSVGRenderer.genNeck(seed),
                '<path id="Head" class="st4" d="M130.7,291.2l66,237.9l84.6,60.6L330,595l56.6-47.3l42.7-167.3l-14-152l-50.6-51.3l-94.6-20l-113.3,48.7L130.7,291.2z"/>',
                AvatizersSVGRenderer.genDimples(seed)
            );
        }
        {
            svg = string.concat(
                svg,
                AvatizersSVGRenderer.genCheekbones(seed),
                AvatizersSVGRenderer.genEyes(seed),
                AvatizersSVGRenderer.genEyebrows(seed),
                AvatizersSVGRenderer.genNose(seed),
                AvatizersSVGRenderer.genLips(seed),
                AvatizersSVGRenderer.genHair(seed),
                AvatizersSVGRenderer.genStreaks(seed),
                '</svg>'
            );
        }
        return string.concat(
            'data:image/svg+xml;base64,',
            Base64.encode(bytes(svg))
        );
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory image;
        if (bytes(specialImages[tokenId]).length == 0) {
            image = generateImage(nftContract.getTokenGenes(tokenId));
        } else {
            image = specialImages[tokenId];
        }
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(abi.encodePacked(
                '{"name":"Avatizers #', tokenId.toString(), '",',
                '"image":"', image, '",'
                '}'
            ))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

library AvatizersSVGRenderer {
    using Strings for uint256;

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    //Modified implementation of Openzeppelin's toHexString functions
    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (int256 i = 2 * int(length) - 1; i >= 0; --i) {
            buffer[uint(i)] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0);
        return string(buffer);
    }

    function intToString(int256 a) public pure returns (string memory) {
        return (a >= 0)? uint256(a).toString() : string.concat('-', SignedMath.abs(a).toString());
    }
    
    //Pads a string array with random numbers in between, and returns the entire padded array as one concatenated string. e.g ["Hello", "World"] => Hello23World
    function strArrRandPad(string[] memory strings, int256[] memory nums) public pure returns (string memory result) {
        require(strings.length - 1 == nums.length);
        for (uint256 i = 0; i < nums.length; i++) {
            result = string.concat(
                result,
                strings[i],
                intToString(nums[i])
            );
        }
        result = string.concat(result, strings[strings.length-1]);
    }

    function genColourPalette(uint256 length, bytes memory seed) public pure returns (string[] memory colourPalette) {
        require(length > 0);
        colourPalette = new string[](length);
        bytes32[] memory hashArr = new bytes32[](length/10 + 1);
        hashArr[0] = keccak256(abi.encodePacked(seed));
        unchecked {
            for (uint256 i = 1; i < length/10 + 1; i++) {
                hashArr[i] = keccak256(abi.encodePacked(hashArr[i-1]));
            }
            for (uint256 i = 0; i < length; i++) {
                colourPalette[i] = toHexString(uint256(hashArr[i/10] ^ ((hashArr[i/10] >> 24) << 24)), 3);
                hashArr[i/10] >>= 24;
            }
        }
    }

    function genPseudoRand(bytes memory seed, uint256[] memory limits) public pure returns (uint256[] memory pseudoRandArr){
        bytes32 hashedSeed = keccak256(abi.encode(seed));
        pseudoRandArr = new uint256[](limits.length);
        for (uint256 i = 0; i < limits.length; i++) {
            pseudoRandArr[i] = uint256(hashedSeed) % limits[i];
            hashedSeed = keccak256(abi.encode(hashedSeed));
        }
    }

    function genSkinTones(bytes memory seed) public pure returns (string[4] memory hexCodes) {        
        unchecked {
            uint256[] memory rgbRange = new uint256[](3);
            for (uint256 i = 0; i < 3; i++) {
                rgbRange[i] = 136;
            }
            uint256[] memory rgbValues = genPseudoRand(seed, rgbRange);
            for (uint256 i = 0; i < 3; i++) {
                rgbValues[i] += 120;
            }
            hexCodes[0] = toHexString((rgbValues[0] - 10) << 16 | (rgbValues[1] - 10) << 8 | (rgbValues[2] - 10), 3);
            hexCodes[1] = toHexString((rgbValues[0] - 100) << 16 | (rgbValues[1] - 100) << 8 | (rgbValues[2] - 100), 3);
            hexCodes[2] = toHexString((rgbValues[0] - 50) << 16 | (rgbValues[1] - 50) << 8 | (rgbValues[2] - 50), 3);
            hexCodes[3] = toHexString((rgbValues[0]) << 16 | (rgbValues[1]) << 8 | (rgbValues[2]), 3);
        }
    }

    function genStyleSheet(bytes memory seed, string[] memory colours) public pure returns (string memory stylesheet) {        
            stylesheet = '<style type="text/css">';
            string[4] memory skinTones = genSkinTones(seed);
            for (uint256 i = 0; i < colours.length; i++) {
                if (i == 5) {
                    stylesheet = string.concat(
                        stylesheet,
                        '.st5{fill:#FFFFFF;}' 
                    );
                } else if (i >= 1 && i <= 4) {
                    stylesheet = string.concat(
                        stylesheet,
                        '.st', i.toString(), 
                        '{fill:#', skinTones[i-1], ';}'
                    );
                } else {
                    stylesheet = string.concat(
                        stylesheet,
                        '.st', i.toString(), 
                        '{fill:#', colours[i], ';}'
                    );
                }
            }
            stylesheet = string.concat(
                stylesheet,
                '</style>'
            );
    }

    function genShards(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](30);
        unchecked {
            uint256[] memory temp = new uint256[](30);        
            uint256[30] memory limits = [uint256(360), 2, 100, 360, 2, 100, 360, 2, 100, 360, 2, 100, 360, 2, 100, 360, 2, 100, 360, 2, 100, 360, 2, 100, 360, 2, 100, 360, 2, 100];
            for (uint256 i = 0; i < 30; i++) {
                temp[i] = limits[i];
            }
            temp =  genPseudoRand(seed, temp);
            for (uint256 i = 0; i < 30; i++) {
                nums[i] = int256(temp[i]);
            }
        }
        string[] memory strings = new string[](31);
        { //Scoping to avoid stack too deep errors
            strings[0] = '<g transform="translate(115.15,582.4) rotate('; 
            strings[1] = ') scale(';
            strings[2] = '.';
            strings[3] = ')"><path class="st1" d="M-53.2-21.7l106.3,23l-84.1,20.4L-53.2-21.7z"/></g><g transform="translate(445.15,650.2) rotate(';
            strings[4] = ') scale(';
            strings[5] = '.';
            strings[6] = ')"><path class="st6" d="M-81.9,44.3l94.8-88.6L81.9-39L-81.9,44.3z"/></g><g transform="translate(200.65,731.2) rotate(';
            strings[7] = ') scale(';
            strings[8] = '.';
            strings[9] = ')"><path class="st9" d="M-42.9-34.1l41.6,9.7l44.3,58.5L-42.9-34.1z"/></g><g transform="translate(500.95,401.25) rotate(';
            strings[10] = ') scale(';
            strings[11] = '.';
            strings[12] = ')"><path class="st11" d="M-35.8-16.9l71.7,27.5l-39,6.2L-35.8-16.9z"/></g><g transform="translate(516.15,637.35) rotate(';
            strings[13] = ') scale(';
            strings[14] = '.';
            strings[15] = ')"><path class="st8" d="M-44.1,14.5l88.1-29.1L30.6,5.4L-44.1,14.5z"/></g><g transform="translate(492.9,146.15) rotate(';
            strings[16] = ') scale(';
            strings[17] = '.';
            strings[18] = ')"><path class="st13" d="M-20.6,26.5h31.8l9.4-53.1L-20.6,26.5z"/></g><g transform="translate(71.85,128.8) rotate(';
            strings[19] = ') scale(';
            strings[20] = '.';
            strings[21] = ')"><path class="st5" d="M-26.6-3.5L2.5-46.7l24.2,93.4L-26.6-3.5z"/></g><g transform="translate(157.8,152.1) rotate(';
            strings[22] = ') scale(';
            strings[23] = '.';
            strings[24] = ')"><path class="st12" d="M-12.4-49.3c4,0,24.8,15.4,24.8,15.4L6.6,49.3L-12.4-49.3z"/></g><g transform="translate(249.65,127.35) rotate(';
            strings[25] = ') scale(';
            strings[26] = '.';
            strings[27] = ')"><path class="st14" d="M-19.5,32.8l38.9-44.1l-3.4-21.6L-19.5,32.8z"/></g><g transform="translate(526.8,251.85) rotate(';
            strings[28] = ') scale(';
            strings[29] = '.';
            strings[30] = ')"><path class="st6" d="M-19.6-1.8L19.6-5L7.1,5L-19.6-1.8z"/></g>';
        }
        svg = strArrRandPad(strings, nums);
    }

    function genNeck(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](4);
        unchecked {
            uint256[] memory temp = new uint256[](4);        
            uint256[4] memory limits = [uint256(30), 20, 40, 60];
            int256[4] memory offsets = [int256(-10), -20, -20, -40];
            for (uint256 i = 0; i < 4; i++) {
                temp[i] = limits[i];
            }
            temp =  genPseudoRand(seed, temp);
            for (uint256 i = 0; i < 4; i++) {
                nums[i] = int256(temp[i]) + offsets[i];
            }
        }
        string[] memory strings = new string[](5);
        { //Scoping to avoid stack too deep errors
            strings[0] = '<path class="st1" d="M214.1,522.7c0.2,15.8,64.7,215.7,64.7,215.7l78.5-109.6L214.1,522.7z" transform="translate(';
            strings[1] = ',0)"/><path class="st2" d="M278.3,548.8c3.1,11.3,44.3,155.3,44.3,155.3l77.2-121.5l-3.4-129L278.3,548.8z" transform="translate(';
            strings[2] = ',0)"/><path class="st3" d="M257.1,547.5c0,9.3,49.9,151.6,49.9,151.6l66-88.9l-5.8-114.8L257.1,547.5z" transform="translate(';
            strings[3] = ',0)"/><path class="st2" d="M293.1,570.2l25.7,76.9l39.6-47.1l-2.7-57.1L293.1,570.2z" transform="translate(';
            strings[4] = ',0)"/>';
        }
        svg = strArrRandPad(strings, nums);
    }

    function genDimples(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](2);
        unchecked {
            uint256[] memory temp = new uint256[](2);        
            uint256[2] memory limits = [uint256(101), 101];
            for (uint256 i = 0; i < 2; i++) {
                temp[i] = limits[i];
            }
            temp =  genPseudoRand(seed, temp);
            for (uint256 i = 0; i < 2; i++) {
                nums[i] = int256(temp[i]);
            }
        }
        string[] memory strings = new string[](3);
        { //Scoping to avoid stack too deep errors
            strings[0] = '<g transform="translate(215.95,501.15)"><path class="st2" d="M-43.9-71.5c3.8,7.9,55.7,66.6,55.7,66.6l32.2,76.3l-58.9-41.3L-43.9-71.5z" transform="scale(0.';
            strings[1] = ')"/></g><g transform="translate(374.25,523.85)"><path class="st2" d="M-8.6-14.4c7.2-3.6,28.9-25.3,28.9-25.3L6.4,14.1l-26.6,25.7L-8.6-14.4z" transform="scale(0.';
            strings[2] = ')"/></g>';
        }
        svg = strArrRandPad(strings, nums);
    }

    function genCheekbones(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](2);
        unchecked {
            uint256[] memory temp = new uint256[](2);        
            uint256[2] memory limits = [uint256(100), 100];
            for (uint256 i = 0; i < 2; i++) {
                temp[i] = limits[i];
            }
            temp =  genPseudoRand(seed, temp);
            for (uint256 i = 0; i < 2; i++) {
                nums[i] = int256(temp[i]);
            }
        }
        string[] memory strings = new string[](3);
        { //Scoping to avoid stack too deep errors
            strings[0] = '<g transform="translate(374.5,458.9)"><path class="st5" d="M-33.1-3.9l66.2-26.5L25.9,1.5l-30,28.9L-33.1-3.9z" transform="scale(0.';
            strings[1] = ')"/></g><g transform="translate(230.25,447.7)"><path class="st5" d="M-39.8-38.5l79.7,51.9L6.9,38.5L-36.2-5.8L-39.8-38.5z" transform="scale(0.';
            strings[2] = ')"/></g>';
        }
        svg = strArrRandPad(strings, nums);
    }

    function genEyes(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](2);
        unchecked {    
            uint256[] memory temp = new uint256[](2);   
            uint256[2] memory limits = [uint256(25), 75];
            int256[2] memory offsets = [int256(75), 25];
            for (uint256 i = 0; i < 2; i++) {
                temp[i] = limits[i];
            } 
            temp =  genPseudoRand(seed, temp);
            for (uint256 i = 0; i < 2; i++) {
                nums[i] = int256(temp[i]) + offsets[i];
            }
        }
        { //Scoping to avoid stack too deep errors
            svg = string.concat(
                '<g transform="translate(365.05,403.9136) scale(0.',
                intToString(nums[0]),
                ',0.',
                intToString(nums[1]),
                ')"><path class="st6" d="M-28.4,7.7c0,0,18-13.6,26.9-17.4c10.8-4.6,30-4.9,30-4.9L20.3,2.6L-28.4,7.7z"/><path class="st7" d="M-28.4,7.7c0,0,18.2-7.6,25.8-8.7c9-1.4,22.9,3.6,22.9,3.6S7.2,13-0.5,14.4C-10.2,16.1-28.4,7.7-28.4,7.7L-28.4,7.7z"/></g><g transform="translate(254,403.9793) scale(0.',
                intToString(nums[0]),
                ',0.',
                intToString(nums[1]),
                ')"><path class="st6" d="M-30.7-17.1l8.2,19.4l53.1,8.9c0,0-10.2-13.2-20-18C-0.9-12.5-30.7-17.1-30.7-17.1L-30.7-17.1z"/><path class="st7" d="M-22.4,2.3c0,0,14.4,12.4,22.9,14.3c10.7,2.4,30.2-5.4,30.2-5.4S13.6,2.1,5.1,0.5C-4.8-1.3-22.4,2.3-22.4,2.3L-22.4,2.3z"/></g>'
            );
        }
    }

    function genEyebrows(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](2);
        unchecked {
            uint256[] memory temp = new uint256[](2);        
            uint256[2] memory limits = [uint256(40), 40];
            int256[2] memory offsets = [int256(-15), -20];
            for (uint256 i = 0; i < 2; i++) {
                temp[i] = limits[i];
            }
            temp =  genPseudoRand(seed, temp);
            for (uint256 i = 0; i < 2; i++) {
                nums[i] = int256(temp[i]) + offsets[i];
            }
        }
        uint256[] memory scaling = new uint256[](1);
        scaling[0] = 105;
        scaling = genPseudoRand(seed, scaling);
        string[] memory strings = new string[](3);
        { //Scoping to avoid stack too deep errors
            strings[0] = '<g transform="translate(361.4,377.15) rotate(';
            strings[1] = string.concat(') scale(1,0.',scaling[0].toString(),')"><path d="M-21.5-2.5c0.3,1.6-9.1,15.7-9.1,15.7L30.6-9.5l-7.2-3.8L-21.5-2.5z"/></g><g transform="translate(254.5,378.05) rotate(');
            strings[2] = string.concat(') scale(1,0.',scaling[0].toString(),')"><path d="M-26.8-12.4l58.6,9.6l11.1,15.3L-42.9-7.8L-26.8-12.4z"/></g>');
        }
        svg = strArrRandPad(strings, nums);
    }

    function genNose(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](2);
        unchecked {
            uint256[] memory temp = new uint256[](2);        
            uint256[2] memory limits = [uint256(99), 50];
            int256[2] memory offsets = [int256(0), 50];
            for (uint256 i = 0; i < 2; i++) {
                temp[i] = limits[i];
            }
            temp =  genPseudoRand(seed, temp);
            for (uint256 i = 0; i < 2; i++) {
                nums[i] = int256(temp[i]) + offsets[i];
            }
        }
        string[] memory strings = new string[](3);
        { //Scoping to avoid stack too deep errors
            strings[0] = '<g transform="translate(309.65,447.25) scale(0.';
            strings[1] = ',0.';
            strings[2] = ')"><path class="st5" d="M0.5-55.8l-26.8,83.5l33.6,2.9L0.5-55.8z"/><path class="st2" d="M14,6l5.1,22.3l7.3-6.4L14,6z"/><path class="st2" d="M3.3,40.3l5.1,15.5L-1.3,54L3.3,40.3z"/></g>';
        }
        svg = strArrRandPad(strings, nums);
    }

    function genLips(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](5);
        unchecked {
            uint256[] memory temp = new uint256[](3);        
            uint256[3] memory limits = [uint256(50), 100, 20];
            int256[3] memory offsets = [int256(75), 25, -10];
            for (uint256 i = 0; i < 3; i++) {
                temp[i] = limits[i];
            }
            temp =  genPseudoRand(seed, temp);
            nums[0] = (int256(temp[0]) + offsets[0])/100;
            nums[1] = (int256(temp[0]) + offsets[0])%100;
            nums[2] = (int256(temp[1]) + offsets[1])/100;
            nums[3] = (int256(temp[1]) + offsets[1])%100;
            nums[4] = int256(temp[2]) + offsets[2];
        }
        string[] memory strings = new string[](6);
        { //Scoping to avoid stack too deep errors
            strings[0] = '<g transform="translate(309.2,521.25) scale(';
            strings[1] = string.concat('.', nums[1] < 10 ? '0': '');
            strings[2] = ',';
            strings[3] = string.concat('.', nums[3] < 10 ? '0': '');
            strings[4] = ') rotate(';
            strings[5] = ')"><path class="st6" d="M-18.3-4.5C-15.8-3.8,11.3,11,11.3,11L22.8-8.9L-18.3-4.5z"/><path class="st6" d="M-43.6,4.4l37-22.9L36.2-1.6L-43.6,4.4z"/><path class="st6" d="M-22.2,2.1l46.7-21L43.6-3.9L-22.2,2.1z"/><path class="st7" d="M-43.6,4.4c1.3,0.5,40.7,14.6,40.7,14.6L27.4,8L1.1,0.7L-43.6,4.4z"/><path class="st7" d="M-8.5,13.8l24.1-15l28-2.6L21,16.6L-8.5,13.8z"/></g>';
        }
        svg = strArrRandPad(strings, nums);
    }

    function genHair(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](17);
        bytes32 hashedSeed = keccak256(abi.encodePacked(seed));
        unchecked {
            uint256[] memory temp = new uint256[](17);        
            uint256[17] memory limits = [uint256(50), 90, 60, 165, 360, 50, 75, 150, 55, 20, 360, 15, 40, 160, 360, 360, 360];
            int256[17] memory offsets = [int256(-45), 0, -60, -90, 0, -20, -45, -90, -45, -20, 0, -15, -10, -130, 0, 0, 0];
            for (uint256 i = 0; i < 17; i++) {
                temp[i] = limits[i];
            }
            temp =  genPseudoRand(seed, temp);
            for (uint256 i = 0; i < 17; i++) {
                nums[i] = int256(temp[i]) + offsets[i];
            }
        }
        if (uint8(hashedSeed[0]) % 5 == 0) {
            return svg;
        } else {
            svg = string.concat(
                svg,
                '<path class="st6" d="M129.6,285.7l14.1,71.2l30.7,55l9-75.1l190.9-67.3l-1.3-13.6l55.7,109.4l-12.2-136.6L364,175l-94.8-18.1l-113.4,49.2L129.6,285.7z"/>'
            );
            if (uint8(hashedSeed[0]) % 3 != 0) {
                string[] memory strings = new string[](18);
                { //Scoping to avoid stack too deep errors
                    strings[0] = string.concat('<g visibility=', uint8(hashedSeed[0]) % 4 != 0 ? '"visible"' : '"hidden"','><g transform="rotate(');
                    strings[1] = ',370.9,302.8)"><path class="st8" d="M425.2,442.3l-54.3-139.5c0,0,41.4,4.2,57.1,45.9C447.9,401.6,425.2,442.3,425.2,442.3L425.2,442.3z"/><path class="st9" d="M453.4,446.6l-49.2-87.4c0,0,29.6-0.7,43.9,25.5C466.3,417.9,453.4,446.6,453.4,446.6L453.4,446.6z"/></g><g transform="rotate(';
                    strings[2] = ',381.043,320.1501)"><path class="st9" d="M251.7,302.5c13.2-0.1,252.1,35.3,252.1,35.3l-117.5-51.2L251.7,302.5z"/></g><g transform="rotate(';
                    strings[3] = string.concat(',238.8356,341.1948)"><path class="st10" d="M485.3,259.1l-238.5,68.3c0,0,26.7-82.3,108.9-101C460.2,202.7,485.3,259.1,485.3,259.1L485.3,259.1z"/></g></g><g visibility=',uint8(hashedSeed[1]) % 4 != 0 ? '"visible"' : '"hidden"','><g transform="rotate(');
                    strings[4] = ',304.9,295.3009)"><path class="st11" d="M304.9,295.3l148.2-136c0,0-0.4,53.9-36.1,90.8C372.7,296.1,304.9,295.3,304.9,295.3L304.9,295.3z"/></g><g transform="rotate(';
                    strings[5] = string.concat(',236.0779,243.1)"><path class="st10" d="M285.5,152.4l-70.3,181.4c0,0-46.5-39.9-20.8-101.8C227,153.3,285.5,152.4,285.5,152.4L285.5,152.4z"/></g></g><g visibility=',uint8(hashedSeed[2]) % 4 != 0 ? '"visible"' : '"hidden"','><g transform="rotate(');
                    strings[6] = ',195.2,347.9)"><path class="st9" d="M195.2,347.9L340.8,84.2c0,0,36.7,66.4,3,124.3C300.3,283,195.2,347.9,195.2,347.9z"/></g><g transform="rotate(';
                    strings[7] = ',227.2,336.2)"><path class="st12" d="M227.2,336.2l119.9-215.6c0,0,35.7,65.7,7.4,126.6C324.6,311.7,227.2,336.2,227.2,336.2L227.2,336.2z"/></g><g transform="rotate(';
                    strings[8] = ',268.9,283.6185)"><path class="st7" d="M268.9,280.3l139.6-170.1c0,0,32.1,74.1-16.6,127.9C334.8,301.2,268.9,280.3,268.9,280.3z"/></g><g transform="rotate(';
                    strings[9] = string.concat(',279.2,330.65)"><path class="st13" d="M344.6,299.9c11,9.3,134.1,61.5,134.1,61.5l-135.6-12.2l-63.9-36.6L344.6,299.9z"/></g></g><g visibility=',uint8(hashedSeed[3]) % 4 != 0 ? '"visible"' : '"hidden"','><g transform="rotate(');
                    strings[10] = ',182.1,332.95)"><path class="st11" d="M182.1,369.6l209.2-73.3l-201.8,2.5L182.1,369.6z"/></g><g transform="rotate(';
                    strings[11] = ',260.8598,221.8042)"><path class="st8" d="M172.6,251.6l176.5-79.2c0,0,2.8,59.7-58.6,85.7C212.6,291,172.6,251.6,172.6,251.6L172.6,251.6z"/></g><g transform="rotate(';
                    strings[12] = ',163.0548,217.8185)"><path class="st8" d="M140.6,427.1l22.5-209.3c0,0-70.5,30.1-80,102.5C70.9,412.9,140.6,427.1,140.6,427.1L140.6,427.1z"/></g></g><g transform="rotate(';
                    strings[13] = string.concat(',244.2,206.4267)" visibility=',uint8(hashedSeed[4]) % 4 != 0 ? '"visible"' : '"hidden"','><path class="st7" d="M244.2,206.6l-74.7,243.9c0,0-55-60.1-27.5-144.9C176.9,197.8,244.2,206.6,244.2,206.6L244.2,206.6z"/><path class="st13" d="M146.4,366.4l54.7,128.1c0,0-40.5-2.9-58.2-48.5C119.8,386.1,146.4,366.4,146.4,366.4L146.4,366.4z"/></g><g visibility=',uint8(hashedSeed[5]) % 4 != 0 ? '"visible"' : '"hidden"','><g transform="rotate(');
                    strings[14] = ',317.1,287.15)"><path class="st14" d="M317.1,266.9l24.2-11.9l178.6,29.7l-83,34.6L317.1,266.9z"/></g><g transform="rotate(';
                    strings[15] = ',187.898,223.5126)"><path class="st11" d="M174.5,185.5c6.5-3.5,34-27.1,34-27.1s-40.9,134.9-41.2,130.1C167.1,283.7,174.5,185.5,174.5,185.5L174.5,185.5z"/></g><g transform="rotate(';
                    strings[16] = ',138.55,378.5)"><path class="st12" d="M148.5,316.8c-9.4,9.2-34.9,123.4-34.9,123.4l49.9-65.4L148.5,316.8z"/></g><g transform="rotate(';
                    strings[17] = ',203.55,315.15)"><path class="st13" d="M154.1,357.9c3.8-3.1,77.2-85.5,77.2-85.5l21.7,13.9L154.1,357.9z"/></g></g>';
                }
                svg = string.concat(
                    svg,
                    strArrRandPad(strings, nums)
                );
            }
        }
    }

    function genStreaks(bytes memory seed) public pure returns (string memory svg) {
        int256[] memory nums = new int256[](5);
        unchecked {
            uint256[] memory temp = new uint256[](5);        
            uint256[5] memory limits = [uint256(361), 361, 361, 361, 361];
            for (uint256 i = 0; i < 5; i++) {
                temp[i] = limits[i];
            }
            temp =  genPseudoRand(seed, temp);
            for (uint256 i = 0; i < 5; i++) {
                nums[i] = int256(temp[i]);
            }
        }
        string[] memory strings = new string[](6);
        { //Scoping to avoid stack too deep errors
            strings[0] = '<g transform="translate(389.35,551.45) rotate(';
            strings[1] = ')"><path d="M-40.9,32.3C-11,5.3,17.4-14.8,47.8-35C13-16-18.1,8.8-47.8,35L-40.9,32.3z"/><path d="M-8.8,14C4.5,1.4,19-8.6,33.4-19.5C15.4-10.1,0,3-15,16.5L-8.8,14z"/></g><g transform="translate(186.7,402.9) rotate(';
            strings[2] = ')"><path d="M36.8,43.6C13.7,30.6-2.5,9-16.8-12.8l-0.2,0.1C-6.1,10.6,10.9,33,33.8,45.5L36.8,43.6L36.8,43.6z"/><path d="M20.4,40.3C-9.1,16.8-26.7-14.1-35.9-45.5l-0.9,0.5c4.2,35.1,27.3,65,53.3,87.7L20.4,40.3L20.4,40.3z"/></g><g transform="translate(330,321.8) rotate(';
            strings[3] = ')"><path d="M37.2,3.4C5.7-1.9-24.9-7.9-56.6-17.1l-0.2,0.1C-28.4-4.8,2.9,0,32.9,6.4L37.2,3.4L37.2,3.4z"/><path d="M56.8,14C22.9,8.7-10-1.7-43.4-9.5l-0.2,0.1C-30.5-3-14.8,0.5-0.8,4.3c18.6,4.6,34.3,11,53.2,12.8L56.8,14L56.8,14z"/></g><g transform="translate(181.15,770.3) rotate(';
            strings[4] = ')"><path d="M16.8-27.5C6.1-17.1-5.1-6-13.6,6.2C0.1-4,9.6-19.1,22.6-30L16.8-27.5L16.8-27.5z"/><path d="M21.3-23.9C3.5-7.9-11.6,10.8-25.6,30C-8.4,12,6.6-9.4,25.6-25.7L21.3-23.9L21.3-23.9z"/></g><g transform="translate(485.8,600.8705) rotate(';
            strings[5] = ')"><path d="M72.8,5.9c-47.7-9-97.1-9.6-145.6-7c47,0.9,94.3,1,140.7,10.1L72.8,5.9L72.8,5.9z"/><path d="M64.4-4.7C26.5-9.6-12.2-9.9-50.3-7.9c36.6,0.4,73.4,1.4,109.7,6.6L64.4-4.7L64.4-4.7z"/></g>';
        }
        svg = strArrRandPad(strings, nums);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}