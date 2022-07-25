// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

/// @title deFOCUSed SVG Contract
/// @author Matto
/// @notice This contract builds the SVG.
/// @custom:security-contact [email protected]
contract deFOCUSedSVG {
  using Strings for string;

  function lin(uint16 _x1, uint16 _y1, uint16 _x2, uint16 _y2) 
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(' M', Strings.toString(_x1), ' ', Strings.toString(_y1),' L', Strings.toString(_x2), ' ', Strings.toString(_y2)));
  }

  function qd(uint16 _p1x, uint16 _p1y, uint16 _p2x, uint16 _p2y, uint16 _p3x, uint16 _p3y, uint16 _p4x, uint16 _p4y) 
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked('<path d="M', Strings.toString(_p1x), ' ', Strings.toString(_p1y), ' L', Strings.toString(_p2x), ' ', Strings.toString(_p2y), ' L', Strings.toString(_p3x), ' ', Strings.toString(_p3y), ' L', Strings.toString(_p4x), ' ', Strings.toString(_p4y), ' Z"/>'));
  }

  function decString(uint16 _zeros, uint16 _digits) 
    internal
    pure
    returns (string memory)
  {
    string memory s = '.';
    for (uint16 i = 0; i < _zeros; i++) {
      s = string(abi.encodePacked(s, '0'));
    }
    return string(abi.encodePacked(s, Strings.toString(_digits)));
  }

  function filt(uint16 _num, string memory _freq, uint16 _oct, uint16 _scale, uint16 _time) 
    internal
    pure
    returns (string memory)
  {
    string memory f = string(abi.encodePacked('<filter id="deFOCUS', Strings.toString(_num), '"'));
    if (_num == 2) {
      f = string(abi.encodePacked(f,' filterUnits="userSpaceOnUse"'));
    }
    return string(abi.encodePacked(f,'><feTurbulence type="fractalNoise" baseFrequency="',_freq,'" numOctaves="', Strings.toString(_oct),'"/><feDisplacementMap in="SourceGraphic" scale="', Strings.toString(_scale),'" xChannelSelector="G" yChannelSelector="B"><animate attributeName="scale" values="', Strings.toString(_scale),';', Strings.toString((_scale * 11)/10),';', Strings.toString(_scale),';" dur="', Strings.toString(_time),'s" repeatCount="indefinite"/></feDisplacementMap><feComposite operator="in" in2="finalMask"/></filter>'));
  }

	function getCol(uint16 _pal, uint16 _col)
		internal
		view
		virtual
		returns (string memory)
	{
    string[7] memory c = ["#ffffff","#000000","#275bb2","#43AA8B","#fcd612","#b10b0b","#f368cb"];
    uint8[4][20] memory pals = [
      [0, 1, 3, 0], 
      [0, 1, 2, 0], 
      [0, 1, 5, 0], 
      [0, 1, 6, 0], 
      [0, 1, 4, 0], 
      [0, 1, 5, 4],
      [0, 1, 2, 4],
      [0, 1, 3, 4],
      [1, 0, 3, 4],
      [1, 0, 2, 4],
      [1, 4, 0, 4], 
      [1, 0, 1, 0],
      [2, 5, 0, 4],
      [2, 4, 0, 4], 
      [2, 0, 3, 0],
      [2, 0, 1, 0],
      [5, 0, 1, 4],
      [5, 0, 2, 0],
      [3, 0, 2, 0],
      [4, 1, 0, 1]
    ];
    return c[pals[_pal][_col]];
	}

  function assembleSVG(uint16[25] memory tA, string memory metaP, string memory traitsJSON)
		external
		view
		returns (string memory)
  {
    uint16[20] memory loc;
    loc[0] = tA[1];
    loc[1] = tA[2];
    loc[2] = 30;
    loc[3] = 30;
    loc[4] = tA[1] - 60;
    loc[5] = tA[2] - 60;
    loc[6] = tA[1] / 2;
    loc[7] = tA[2] / 2;
    loc[8] = (tA[1] - (tA[1] * 19)/50) / 2;
    loc[9] = (tA[2] - (tA[2] * 19)/50) / 2;
    loc[10] = loc[0] - loc[8];
    loc[11] = loc[1] - loc[9];
    loc[12] = loc[0] / tA[6] ** 2;
    loc[13] = tA[2] / tA[6] ** 2;

    // Begin Background
    string memory b = string(abi.encodePacked('<?xml version="1.0" encoding="utf-8"?><svg viewBox="0 0 ', Strings.toString(tA[1]),' ', Strings.toString(tA[2]), ' " xmlns="http://www.w3.org/2000/svg">'));
    b = string(abi.encodePacked(b, filt(1, decString(tA[13], tA[14]), tA[15], tA[16], tA[18])));
    b = string(abi.encodePacked(b, filt(2, decString(tA[19], tA[20]), tA[21], tA[22], tA[24])));
    b = string(abi.encodePacked(b, '<g id="pattern" style="stroke: ', getCol(tA[7], 1),'; stroke-width: ', Strings.toString(tA[10]),'px; filter: url(#deFOCUS1); fill:', getCol(tA[7], 0), '">'));

    for (uint16 i = 0; i < tA[6]; i++) {
      loc[2] = loc[2] + i * loc[12];
      loc[3] = loc[3] + i * loc[13];
      loc[4] = loc[4] - i * 2 * loc[12];
      loc[5] = loc[5] - i * 2 * loc[13];
      b = string(abi.encodePacked(b,'<rect x="',Strings.toString(loc[2]),'" y="',Strings.toString(loc[3]),'" width="',Strings.toString(loc[4]),'" height="',Strings.toString(loc[5]),'"/>'));

      loc[14] = loc[4] / (tA[5] + 1);
      loc[15] = loc[5] / (tA[5] + 1);

      if (i + 1 < tA[6]) {
        b = string(abi.encodePacked(b, '<path d="'));
      }
          
      if (i < tA[6] - 1) {
        for (uint16 j = 0; j < tA[5] + 2; j++) {
          loc[16] = loc[2] + j * loc[14];
          loc[17] = loc[3] + j * loc[15];
          loc[18] = loc[3] + loc[5] - j * loc[15];
          if (tA[4] == 1 || tA[4] == 3) { // Verticals
            b = string(abi.encodePacked(b,lin(loc[16], loc[3], loc[16], loc[5] + loc[3])));
          }
          if (tA[4] == 2 || tA[4] == 3) { // Horizontals
            b = string(abi.encodePacked(b,lin(loc[2], loc[17], loc[2] + loc[4], loc[17])));
          }
          if (tA[4] == 4) { // diagonal forward
            b = string(abi.encodePacked(b,lin(loc[16], loc[3], loc[2], loc[17])));
            b = string(abi.encodePacked(b,lin(loc[16], loc[3] + loc[5], loc[2] + loc[4], loc[17])));
          }
          if (tA[4] == 5) { // diagonal backward
            b = string(abi.encodePacked(b,lin(loc[16], loc[3], loc[2] + loc[4], loc[18])));
            b = string(abi.encodePacked(b,lin(loc[16], loc[3] + loc[5], loc[2], loc[18])));
          }
          if (tA[4] == 6) { // web top right bottom left
            b = string(abi.encodePacked(b,lin(loc[16], loc[3], loc[2] + loc[4], loc[17])));
            b = string(abi.encodePacked(b,lin(loc[16], loc[3] + loc[5], loc[2], loc[17])));          
          }
          if (tA[4] == 7) { // web top left bottom right
            b = string(abi.encodePacked(b,lin(loc[16], loc[3], loc[2], loc[18])));
            b = string(abi.encodePacked(b,lin(loc[16], loc[3] + loc[5], loc[2] + loc[4], loc[18])));          
          }
          if (tA[4] == 8) { // points back
            b = string(abi.encodePacked(b,lin(loc[16], loc[3], loc[2] + loc[4], loc[5] + loc[3])));
            b = string(abi.encodePacked(b,lin(loc[16], loc[3] + loc[5], loc[2], loc[3])));      
          }    
          if (tA[4] == 9) { // points forward
            b = string(abi.encodePacked(b,lin(loc[16], loc[3] + loc[5], loc[2] + loc[4], loc[3])));
            b = string(abi.encodePacked(b,lin(loc[16], loc[3], loc[2], loc[3] + loc[5])));      
          }    
          if (tA[4] == 10) { // top/bottom to recurrent points
            loc[19] = loc[2] + loc[4] - j * loc[14];
            b = string(abi.encodePacked(b,lin(loc[16], loc[3], loc[19], loc[5] + loc[3])));
            b = string(abi.encodePacked(b,lin(loc[2], loc[17], loc[2] + loc[4], loc[18])));
          }
          if (tA[8] == 1) {
            if (tA[4] < 10) {
              tA[4] = tA[4] + tA[9];
            } else {
              tA[4] = 1;
            }
          }
        }
      }
      if (i + 1 < tA[6]) {
        b = string(abi.encodePacked(b, '"/>'));
      }
    }
    b = string(abi.encodePacked(b, '</g>'));
    // End Background

    // Begin Shape
    b = string(abi.encodePacked(b, '<g id="shape" style="stroke:', getCol(tA[7], 2), '; stroke-width: ',Strings.toString(tA[11]),'px; filter: url(#deFOCUS2); fill:', getCol(tA[7], 3),'" fill-opacity="',Strings.toString(tA[12]),'">'));
    if (tA[0]== 1 || tA[0]== 4 || tA[0]== 7) {
      b = string(abi.encodePacked(b,qd(loc[8], loc[9], loc[10], loc[9], loc[10], loc[11], loc[8], loc[11])));
    } 
    if (tA[0]== 2 || tA[0]== 5 || tA[0]== 8) {
      b = string(abi.encodePacked(b,qd(loc[6], loc[9], loc[10], loc[7], loc[6], loc[11], loc[8], loc[7])));
    }
    if (tA[0]== 3) { // Circle
      b = string(abi.encodePacked(b,'<circle cx="500" cy="500" r="191"/>'));
    }
    if (tA[0]== 6) { // Tall Eye
      b = string(abi.encodePacked(b,'<path d="M309 309 Q191 500 309 691 Q427 500 309 309 Q191 500 309 691 "/>'));
    }
    if (tA[0]== 9) { // Wide Eye
      b = string(abi.encodePacked(b,'<path d="M309 309 Q500 191 691 309 Q500 427 309 309 Q500 191 691 309 "/>'));
    }
    b = string(abi.encodePacked(b, '</g>'));
    // End Shape
    b = string(abi.encodePacked(b, '<desc>Metadata:',metaP,',', traitsJSON, '}</desc>'));  
    b = string(abi.encodePacked(b,'</svg>'));
    return b;
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