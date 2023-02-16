/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

contract PixelPrismaticaData {
    /*
    uint256 private constant numColors = 10;
    uint256 private constant num_rect_x = 32;
    uint256 private constant num_rect_y = 32;
    uint256 private constant rect_width = 8;
    uint256 private constant rect_height = 8;
    uint256 private constant step_duration = 2;
    */

    uint256 private constant numColors = 10;
    uint256 private constant num_rect_x = 32;
    uint256 private constant num_rect_y = 32;
    uint256 private constant rect_width = 8;
    uint256 private constant rect_height = 8;
    uint256 private constant step_duration = 2;

    //mapping(uint256 => string) private map_config2Name;
    //mapping(uint256 => string) private map_config2URI;

    function getConfigName(uint256 config) external pure returns (string memory) {
        if(config == 0) {
            return "Rainbow Light";
        }
        else {
            return "?";
        }
    }

    function getConfigURI(uint256 config) external view returns (string memory) {
        if(config == 0) {
            return getURI_RainbowLight();
        }
        else {
            return "?";
        }
    }

    constructor() payable {
        //map_config2Name[0] = "Rainbow Light";
        initMap();
        //map_config2URI[0] = getURI_RainbowLight();
    }

    //colorStringArray "#0000FF;#00FFFF;#FF00FF;#00FF00;#FF00FF;#FF0000;#FF00FF;#FFFF00;#FF0000;#FF0000;#0000FF"

    //mapping(uint256 => string[]) private map_num2ColorArray;
    mapping(uint256 => string) private map_num2Color1;
    mapping(uint256 => string) private map_num2ColorAll;

    function initMap() private {
        map_num2Color1[0] = "#0000FF";
        map_num2ColorAll[0] = "#0000FF;#00FFFF;#FF00FF;#00FF00;#FF00FF;#FF0000;#FF00FF;#FFFF00;#FF0000;#FF0000;#0000FF";

        /*
        map_num2ColorArray[0].push("#0000FF");
        map_num2ColorArray[0].push("#00FFFF");
        map_num2ColorArray[0].push("#FF00FF");
        map_num2ColorArray[0].push("#00FF00");
        map_num2ColorArray[0].push("#FF00FF");
        map_num2ColorArray[0].push("#FF0000");
        map_num2ColorArray[0].push("#FF00FF");
        map_num2ColorArray[0].push("#FFFF00");
        map_num2ColorArray[0].push("#FF0000");
        map_num2ColorArray[0].push("#FF0000");
        map_num2ColorArray[0].push("#0000FF");
        */
    }

    function getURI_RainbowLight_external() external view returns (string memory) {
        return getURI_RainbowLight();
    }

    function getSVG_RainbowLight_external() external view returns (string memory) {
        return getSVG_RainbowLight();
    }

    function getURI_RainbowLight() private view returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", encode64(abi.encodePacked(getSVG_RainbowLight()))));
    }

    function getSVG_RainbowLight() private view returns (string memory) {
        uint256 width = rect_width * num_rect_x;
        uint256 height = rect_height * num_rect_y;
        string memory dur = string.concat(uint256ToString(numColors * step_duration), "s");

        string memory start = string.concat("<?xml version=\"1.1\"?>", "\n");
        start = string.concat(start, "<svg width=\"", uint256ToString(width), "\" height=\"", uint256ToString(height), "\" xmlns=\"http://www.w3.org/2000/svg\">", "\n");
        start = string.concat(start, "<defs>", "\n");
        start = string.concat(start, "<rect id=\"box\" width=\"", uint256ToString(rect_width), "\" height=\"", uint256ToString(rect_height), "\"/>", "\n");
        start = string.concat(start, "</defs>", "\n");

        string memory content = "";
        //string[] memory colorStringArray = map_num2ColorArray[0];

        //for(uint256 i_y = 0; i_y < num_rect_y; i_y++) {
            //for(uint256 i_x = 0; i_x < num_rect_x; i_x++) {
        for(uint256 rect_y = 0; rect_y < num_rect_y * rect_height; rect_y += rect_height) {
            for(uint256 rect_x = 0; rect_x < num_rect_x * rect_width; rect_x += rect_width) {
        
                /*
                string memory sValues = "";
                for(uint256 i = 0; i < numColors; i++) {
                    sValues = string.concat(sValues, colorStringArray[i], ";");
                }
                sValues = string.concat(sValues, colorStringArray[0]);
                */
                
                content = string.concat(content, "<use href=\"#box\" x=\"", uint256ToString(rect_x), "\" y=\"", uint256ToString(rect_y), "\">", "\n");
                content = string.concat(content, "<animate attributeName=\"fill\" values=\"", map_num2ColorAll[0], "\" dur=\"", dur, "\" repeatCount=\"indefinite\"/>", "\n");
                content = string.concat(content, "</use>", "\n");
            }
        }

        string memory end = "</svg>";
        return string.concat(start, content, end);
    }

    function uint256ToString(uint256 _i) internal pure returns (string memory) {
        if(_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while(j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while(_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode64(bytes memory data) internal pure returns (string memory) {
        if(data.length == 0) return "";
        string memory table = _TABLE;
        string memory result = new string(4 * ((data.length + 2) / 3));
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {
            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }
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