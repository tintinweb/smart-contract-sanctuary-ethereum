// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";


library CalcLib {
    struct ColorScheme {
        string[2] gradient1;
        string[2] gradient2;
        string[2] gradient3;
        string[2] gradient4;
        string buttonBackground;
        string borderStrip;
        string buttonText;
        string screenText;
        string screen;
        string ownerText;

    }

    string internal constant svgStart = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 550 760">';
    
    string internal constant svgButtons = ' <g stroke="#303133" stroke-width="5" fill="url(#Gradient2)" > <rect onclick="handleNumber(1)" rx="7" x="50" y="530" width="80" height="80"/> <rect onclick="handleNumber(2)" rx="7" x="150" y="530" width="80" height="80"/> <rect onclick="handleNumber(3)" rx="7" x="250" y="530" width="80" height="80"/> <rect onclick="handleNumber(4)" rx="7" x="50" y="430" width="80" height="80"/> <rect onclick="handleNumber(5)" rx="7" x="150" y="430" width="80" height="80"/> <rect onclick="handleNumber(6)" rx="7" x="250" y="430" width="80" height="80"/> <rect onclick="handleNumber(7)" rx="7" x="50" y="330" width="80" height="80"/> <rect onclick="handleNumber(8)" rx="7" x="150" y="330" width="80" height="80"/> <rect onclick="handleNumber(9)" rx="7" x="250" y="330" width="80" height="80"/> <rect onclick="handleNumber(0)" rx="7" x="50" y="630" width="80" height="80"/> <rect onclick="handleNumber(symbols.dec)" rx="7" x="150" y="630" width="80" height="80"/> //. <rect onclick="handleOp(add, symbols.add)" rx="7" x="350" y="530" width="150" height="80"/> //+ <rect onclick="handleOp(sub, symbols.sub)" rx="7" x="350" y="430" width="150" height="80"/> //- <rect onclick="handleOp(mul, symbols.mul)" rx="7" x="350" y="330" width="150" height="80"/> //x <rect onclick="handleOp(div, symbols.div)" rx="7" x="350" y="230" width="150" height="80"/> // / <rect onclick="handleOp(mod, symbols.mod)" rx="7" x="150" y="230" width="80" height="80"/> <rect onclick="handleOp(pow, symbols.pow)" rx="7" x="250" y="230" width="80" height="80"/> <rect onclick="clearScreen()" fill="url(#Gradient3)" rx="7" x="50" y="230" width="80" height="80"/> <rect onclick="equals()" fill="url(#Gradient1)" rx="7" x="250" y="630" width="250" height="80"/> </g >';
    
    string internal constant svgButtonText = '<g class="button"> <text onclick="equals()" stroke="none" x="360" y="685">=</text> <text onclick="clearScreen()" x="71" y="285">C</text> <text onclick="handleNumber(1)" x="75" y="585">1</text> <text onclick="handleNumber(2)" x="175" y="585">2</text> <text onclick="handleNumber(3)" x="275" y="585">3</text> <text onclick="handleNumber(4)" x="75" y="485">4</text> <text onclick="handleNumber(5)" x="175" y="485">5</text> <text onclick="handleNumber(6)" x="275" y="485">6</text> <text onclick="handleNumber(7)" x="75" y="385">7</text> <text onclick="handleNumber(8)" x="175" y="385">8</text> <text onclick="handleNumber(9)" x="275" y="385">9</text> <text onclick="handleNumber(0)" x="75" y="685">0</text> <text onclick="handleNumber(symbols.dec)" x="183" y="674">.</text> <text onclick="handleOp(add, symbols.add)" x="408" y="585">+</text> <text onclick="handleOp(sub, symbols.sub)" x="415" y="481">-</text> <text onclick="handleOp(mul, symbols.mul)" x="410" y="380">x</text> <text onclick="handleOp(div, symbols.div)" x="410" y="286">/</text> <text onclick="handleOp(mod, symbols.mod)" x="165" y="285">%</text> <text onclick="handleOp(pow, symbols.pow)" x="275" y="293">^</text> </g>';
    string internal constant svgEnd = '<script type="text/javascript"><![CDATA[ var symbols={mul:"x",div:"/",mod:"%",sub:"-",add:"+",dec:".",pow:"^"},screenLarge=document.getElementById("screenLarge"),screenTop=document.getElementById("screenTop"),screenTiny=document.getElementById("screenTiny");function add(e,t){var n=e+t;return sizeResult(n),n}function sub(e,t){var n=e-t;return sizeResult(n),n}function mul(e,t){var n=e*t;return sizeResult(n),n}function div(e,t){var n=e/t;return sizeResult(n),n}function mod(e,t){var n=e%t;return sizeResult(n),n}function pow(e,t){var n=e**t;return sizeResult(n),n}function equals(){if(0==Number(secondNum)&&operationSym==symbols.div)return screenLarge.textContent="error",void(readyToClear=!0);firstNum.length+secondNum.length<19?screenTop.textContent=firstNum+" "+operationSym+" "+secondNum+" =":firstNum.length<19?(secondNum=secondNum.slice(0,19-firstNum.length),screenTop.textContent=firstNum+" "+operationSym+" "+secondNum+"... ="):screenTop.textContent=firstNum.slice(0,20)+"... =",firstNum=operation(Number(firstNum),Number(secondNum)).toString(),readyToClear=!0}function sizeResult(e){if(e.toString().length<13)screenLarge.setAttribute("class","large"),screenLarge.textContent=e.toString();else{if(!(e.toString().length<24))return screenLarge.textContent=e.toString().slice(0,24)+"...",void(screenTiny.textContent="too large");screenLarge.setAttribute("class","small"),screenLarge.textContent=e.toString()}}function clearScreen(){screenLarge.textContent="",screenTop.textContent="",numCounter=1,firstNum="",secondNum="",operation=null,operationSym="",screenTiny.textContent="",readyToClear=!1}function handleNumber(e){if(readyToClear&&clearScreen(),1==numCounter)if(firstNum.length<13)screenLarge.setAttribute("class","large"),screenLarge.textContent=firstNum+e.toString(),firstNum+=e.toString();else{if(!(firstNum.length<24))return void(screenTiny.textContent="too large");screenLarge.setAttribute("class","small"),screenLarge.textContent=firstNum+e.toString(),firstNum+=e.toString()}else if(secondNum.length<13)screenLarge.setAttribute("class","large"),screenLarge.textContent=secondNum+e.toString(),secondNum+=e.toString();else{if(!(secondNum.length<24))return void(screenTiny.textContent="too large");screenLarge.setAttribute("class","small"),screenLarge.textContent=secondNum+e.toString(),secondNum+=e.toString()}}function handleOp(e,t){secondNum="",screenLarge.textContent="",operationSym=t.toString(),firstNum.length<19?screenTop.textContent=firstNum+" "+operationSym:screenTop.textContent=firstNum.slice(0,20)+"... =",operation=e,numCounter=2}numCounter=1,firstNum="",secondNum="",operation=null,operationSym="",readyToClear=!1; ]]></script> </svg>';


    function generateTokenURI(address owner, uint id, uint schemeIndex, ColorScheme memory scheme, string memory frontEnd) public pure returns(string memory) {

        string memory imageUrl = base64ImageUrl(owner, id, scheme);
        return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              "Calculator #",
                              Strings.toString(id),
                              '", "description":',
                              '"A Fully working, completely on chain calculator. To use, simply copy the image url and paste it in a web browser. Or, visit our [Official Website](',
                              frontEnd,
                              ")",
                              '", "external_url":"',
                              frontEnd,
                              '", "attributes": [{"trait_type": "Color Scheme", "value":"',
                              Strings.toString(schemeIndex),
                              '"}], "owner":"',
                              Strings.toHexString(uint160(owner), 20),
                              '", "image": "',
                              imageUrl,
                              '"}'
                          )
                        )
                    )
              )
          );

    }


    function base64ImageUrl(address owner, uint id, ColorScheme memory scheme) public pure returns (string memory) {
        string memory ownerId = OwnerandIdText(owner, id, scheme.ownerText);
        string memory gradients = getGradients(scheme);
        string memory background = getBackground(scheme);
        string memory screenText = getScreenText(scheme);
        string memory styles = getStyle(scheme);

        string memory svgBase64 = Base64.encode(abi.encodePacked(svgStart, styles, gradients, background, svgButtons, screenText, svgButtonText, ownerId, svgEnd));
        return string(abi.encodePacked("data:image/svg+xml;base64,",svgBase64));

    }



    function OwnerandIdText(address owner, uint id, string memory color) public pure returns (string memory){
        string memory _owner = Strings.toHexString(uint160(owner), 20);
        string memory _id = Strings.toString(id);

        return string(abi.encodePacked('<text fill="#',
        color,
        '" x="190" y="743" class="metadata">', 
        "Owner: ", 
        _owner, 
        '</text> <text fill="#d8e1e0" x="30" y="743" class="metadata">', 
        _id, 
        "/10000", 
        "</text>"));



    }

    function getGradients(ColorScheme memory scheme) public pure returns (string memory) {
        string memory first = '<linearGradient id="';
        string memory second = '" x1="1" x2="0" y1="0" y2="0"> <stop offset="0%" stop-color="#';
        string memory third = '"/> <stop offset="100%" stop-color="#';
        string memory fourth = '" /> </linearGradient>';

        string memory grad1 = string(abi.encodePacked(
            first, 
            "Gradient1",  
            second, 
            scheme.gradient1[0],
            third,
            scheme.gradient1[1],
            fourth
            ));
        string memory grad2 = string(abi.encodePacked(
            first, 
            "Gradient2",  
            second, 
            scheme.gradient2[0],
            third,
            scheme.gradient2[1],
            fourth
            ));
        string memory grad3 = string(abi.encodePacked(
            first, 
            "Gradient3",  
            second, 
            scheme.gradient3[0],
            third,
            scheme.gradient3[1],
            fourth
            ));
        string memory grad4 = string(abi.encodePacked(
            first, 
            "Gradient4",  
            second, 
            scheme.gradient4[0],
            third,
            scheme.gradient4[1],
            fourth
            ));

        return string(abi.encodePacked(grad1, grad2, grad3, grad4));

    }

    function getBackground(ColorScheme memory scheme) public pure returns (string memory) {
        string memory first = '<g  stroke="#';
        string memory second = '" stroke-width="3" > <rect id="border" fill="url(#Gradient4)" rx="7" x="0" y="0" width="550" height="760"/> <rect class="buttonBackground"   rx="7" x="30" y="30" width="490" height="700"/> <rect id="screenBorder" rx="7" fill="url(#Gradient2)" x="45" y="50" width="460" height="150"/> <rect class="screen"  rx="7" x="65" y="70" width="420" height="110"/> <rect rx="7" stroke-width="5" fill="none" x="10" y="10" width="530" height="740"/> </g>';
    

        return string(abi.encodePacked(
            first, 
            scheme.borderStrip,
            second

            ));

    }

    function getScreenText(ColorScheme memory scheme) public pure returns(string memory) {
        string memory first = '<g fill= "#'; 
        string memory second = '"> <text id="screenLarge" x="70" y="160"></text> <text id="screenTop" x="70" y="105" class="light"></text> <text id="screenTiny" x="430" y="170" class="tiny"></text> </g >';
        return string(abi.encodePacked(first, scheme.screenText, second));

    }

    function getStyle(ColorScheme memory scheme) public pure returns(string memory ) {
        return string(abi.encodePacked(
            '<style> .light { font: italic 30px sans-serif; } .tiny { font: 8px sans-serif;  } .large { font: bold 50px sans-serif; } .small { font: bold 30px sans-serif; } .button { font: bold 50px sans-serif; fill: #',
            scheme.buttonText, 
            '} .metadata{ font: bold 12px sans-serif; fill: #', 
            scheme.ownerText, 
            ' } .buttonBackground{fill: #', 
            scheme.buttonBackground,
            '} .screen{fill: #',
            scheme.screen,
            '} .borderStrip{stroke: #',
            scheme.borderStrip,
            '} </style>'
            ));
            
        
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