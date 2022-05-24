// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

/// @title BLONKS SVG Contract
/// @author Matto
/// @notice This contract builds the SVG text.
/// @custom:security-contact [email protected]
contract BLONKSsvg {
  using Strings for string;

  function eM(uint256 _ent, uint256 _mod)
    internal
    pure
    returns (uint16) 
  {
    return uint16(_ent % _mod);
  }

  function bC(uint16 _r, uint16 _g, uint16 _b) 
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked('rgb(',Strings.toString(_r),', ',Strings.toString(_g),', ',Strings.toString(_b),')"/>')); 
  }

  function rA(uint16 _x, uint16 _y, uint16 _w, uint16 _h, uint16 _r, uint16 _g, uint16 _b, uint16 _alpha, uint16 _sw, uint16 _sc)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked('<rect x="',Strings.toString(_x),'" y="',Strings.toString(_y),'" width="',Strings.toString(_w),'" height="',Strings.toString(_h),'" style="fill: rgba(',Strings.toString(_r),', ',Strings.toString(_g),', ',Strings.toString(_b),', ',Strings.toString(_alpha),'); stroke-width: ',Strings.toString(_sw),'px; stroke: rgb(',Strings.toString(_sc),', ',Strings.toString(_sc),', ',Strings.toString(_sc),');"/>'));
  }

  function rS(uint16 _x, uint16 _y, uint16 _w, uint16 _h, string memory _style)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked('<rect x="',Strings.toString(_x),'" y="',Strings.toString(_y),'" width="',Strings.toString(_w),'" height="',Strings.toString(_h),'" style="fill: rgb',_style));
  }

  function cS(uint16 _v, uint16 _mod)
    internal
    pure
    returns (uint16)
  {
    if (_v > _mod) {
      return _v - _mod;
    } else {
      return 255 - _mod + _v;
    }
  }

  function assembleSVG(uint256 eO, uint256 eT, uint8[11] memory tA, uint16[110] memory loc)
    external
    pure
    returns (string memory)
  {
    // Variables
    string memory b = '<?xml version="1.0" encoding="utf-8"?><svg viewBox="0 0 1000 1000" width="1000" height="1000" xmlns="http://www.w3.org/2000/svg">';
    string[3] memory s;

    // Background Colors
    uint16 tR = 25 + (eM(eO,10) * 20);
    eO /= 10;
    uint16 tG = 25 + (eM(eO,10) * 20);
    eO /= 10;
    uint16 tB = 25 + (eM(eO,10) * 20);
    eO /= 10;

    // Background
    if (tA[0] == 0) {
      b = string(abi.encodePacked(b,'<defs><linearGradient id="bkStyle"><stop offset="0" style="stop-color: rgb(255, 0, 0);"/><stop offset="0.17" style="stop-color: rgb(255, 170, 0);"/><stop offset="0.36" style="stop-color: rgb(255, 251, 0);"/><stop offset="0.52" style="stop-color: rgb(115, 255, 0);"/><stop offset="0.69" style="stop-color: rgb(0, 81, 255);"/><stop offset="0.85" style="stop-color: rgb(29, 1, 255);"/><stop offset="1" style="stop-color: rgb(102, 0, 255);"/></linearGradient></defs>'));
    } else if (tA[0] == 1) {
      b = string(abi.encodePacked(b,'<defs><linearGradient gradientUnits="userSpaceOnUse" x1="500" y1="0" x2="500" y2="1000" id="bkStyle"><stop offset="0" style="stop-color: #eeeeee"/><stop offset="1" style="stop-color: ',bC(tR, tG, tB),'</linearGradient></defs>'));
    } else if (tA[0] == 2) {
      b = string(abi.encodePacked(b,'<defs><radialGradient gradientUnits="userSpaceOnUse" cx="500" cy="500" r="700" id="bkStyle"><stop offset="0" style="stop-color: #eeeeee"/><stop offset="1" style="stop-color: ',bC(tR, tG, tB),'</radialGradient></defs>'));
    } else {
      b = string(abi.encodePacked(b,'<defs><radialGradient gradientUnits="userSpaceOnUse" cx="500" cy="500" r="490" id="bkStyle"><stop offset=".5" style="stop-color: #ffffff"/><stop offset="1" style="stop-color: ',bC(tR, tG, tB),'</radialGradient></defs>'));
    }
    b = string(abi.encodePacked(b,'<rect id="background" width="1000" height="1000"  style="fill: url(#bkStyle);" onclick="background.style.fill='));
    b = string(abi.encodePacked(b,"'rgba(0,0,0,0)'"));
    b = string(abi.encodePacked(b,'"/>'));

    // Blonk Colors
    tR = 255 - tR;
    tG = 255 - tG;
    tB = 255 - tB;

    // Neck
    b = string(abi.encodePacked(b,rA(loc[0], 500, loc[1], 520, tR, tG, tB, 1, 10, 32)));

    // Head
    tR += 20;
    tG += 20;
    tB += 20;
    b = string(abi.encodePacked(b,rA(loc[2], loc[3], loc[4], loc[5], tR, tG, tB, 1, 19, 42)));

    // Eye Colors
    tR += 20 + eM(eO,10) * 9;
    eO /= 10;
    tG += 20 + eM(eO,10) * 9;
    eO /= 10;
    tB += 20 + eM(eO,10) * 9;
    eO /= 10;

    // Eyes
    b = string(abi.encodePacked(b,rA(loc[6], loc[7], loc[8], loc[9], tR, tG, tB, 1, 6, 55)));
    b = string(abi.encodePacked(b,rA(loc[10], loc[11], loc[12], loc[13], tR, tG, tB, 1, 6, 55)));

    // Pupils
    if (tA[1] == 1) {
      s[0] = '(32,32,32); stroke-width: 6px; stroke: rgb(210,42,42);"/>';
    } else if (tA[1] == 2) {
      s[0] = '(47,201,20); stroke-width: 6px; stroke: rgb(70,219,44);"/>';
    } else {
      s[0] = '(32,32,32); stroke-width: 6px; stroke: rgb(55,55,55);"/>';
    }
    b = string(abi.encodePacked(b,rS(loc[16], loc[17], loc[18], loc[19], s[0])));
    b = string(abi.encodePacked(b,rS(loc[20], loc[21], loc[22], loc[23], s[0])));

    // Nose
    tR = cS(tR, 40) + eM(eO,10) * 9;
    eO /= 10;
    tG = cS(tG, 40) + eM(eO,10) * 9;
    eO /= 10;
    tB = cS(tB, 40) + eM(eO,10) * 9;
    eO /= 10;
    b = string(abi.encodePacked(b,rA(loc[24], loc[25], loc[26], loc[27], tR, tG, tB, 1, 6, 55)));

    // Ears
    tR = cS(tR, 40) + eM(eO,10) * 9;
    eO /= 10;
    tG = cS(tG, 40) + eM(eO,10) * 9;
    eO /= 10;
    tB = cS(tB, 40) + eM(eO,10) * 9;
    eO /= 10;
    b = string(abi.encodePacked(b,rA(loc[28], loc[30], loc[31], loc[32], tR, tG, tB, 1, 6, 42)));
    b = string(abi.encodePacked(b,rA(loc[29], loc[30], loc[31], loc[32], tR, tG, tB, 1, 6, 42)));

    // Eyebrows
    b = string(abi.encodePacked(b,rA(loc[37], loc[38], loc[39], loc[40], 55, 55, 55, 1, 0, 0)));
    b = string(abi.encodePacked(b,rA(loc[41], loc[42], loc[43], loc[44], 55, 55, 55, 1, 0, 0)));

    // Mouth
    tR = cS(tR, 40) + eM(eT,10) * 9;
    eT /= 10;
    tG = cS(tG, 40) + eM(eT,10) * 9;
    eT /= 10;
    tB = cS(tB, 40) + eM(eT,10) * 9;
    eT /= 10;
    b = string(abi.encodePacked(b,rA(loc[33], loc[34], loc[35], loc[36], tR, tG, tB, 1, 6, 55)));

    // Teeth
    if (tA[2] > 0) {
      b = string(abi.encodePacked(b,rA(loc[50], loc[51], loc[52], loc[53], 230, 230, 230, 1, 0, 0)));
    }
    if (tA[2] == 3) {
      b = string(abi.encodePacked(b,rA(loc[93], loc[94], loc[95], loc[96], tR, tG, tB, 1, 0, 0))); // paints mouth over tusks
    }

    // Mole
    if (loc[45] > 0) {
      b = string(abi.encodePacked(b,rA(loc[45],loc[106],loc[107],loc[108], 55, 55, 55, 1, 0, 0)));     
    } 

    // Extra Detail
    if (tA[3] == 1) {
      s[0] = '(50,50,255)"/>';
    } else if (tA[3] == 2) {
      s[0] = '(222,22,22)"/>';
    } else if (tA[3] == 3) {
      s[0] = '(150,220,255)"/>';
    } else if (tA[3] == 4) {
      s[0] = 'a(42,42,42,.5)"/>';
    }
    if (tA[3] > 0) {
      b = string(abi.encodePacked(b,rS(loc[54], loc[55], loc[56], loc[57], s[0])));
      b = string(abi.encodePacked(b,rS(loc[58], loc[59], loc[60], loc[61], s[0])));
    }

    // Glasses
    if (tA[4] == 1) {
      s[0] = '(32,32,32)"/>';
      s[1] = 'a(255,255,255,.3); stroke-width: 16px; stroke: rgb(32,32,32);"/>';
      s[2] = s[1]; 
    } else if (tA[4] == 2) {
      s[0] = '(243,104,203)"/>';
      s[1] = 'a(22,22,22,.9); stroke-width: 16px; stroke: rgb(243,104,203);"/>';
      s[2] = s[1]; 
    } else if (tA[4] == 3) {
      s[0] = '(245,245,245)"/>';
      s[2] = '(255,22,22); stroke-width: 16px; stroke: rgb(245,245,245);"/>';
      s[1] = '(22,122,255); stroke-width: 16px; stroke: rgb(245,245,245);"/>';
    } else if (tA[4] == 4) {
      s[0] = '(252,214,18)"/>';
      s[1] = '(11,11,11); stroke-width: 16px; stroke: rgb(252,214,18);"/>';
      s[2] = s[1]; 
    }
    if (tA[4] != 0) {
      b = string(abi.encodePacked(b,rS(loc[62],loc[63],loc[64],loc[65],s[0])));
      b = string(abi.encodePacked(b,rS(loc[66],loc[67],loc[47],loc[46],s[1])));
      b = string(abi.encodePacked(b,rS(loc[68],loc[67],loc[47],loc[46],s[2])));
      b = string(abi.encodePacked(b,rS(loc[69],loc[70],loc[71],loc[65],s[0])));
      b = string(abi.encodePacked(b,rS(loc[72],loc[73],loc[74],loc[65],s[0])));
    }

    // Hair
    tR = cS(tR, 20 + eM(eT,10) * 9);
    eT /= 10;
    tG = cS(tG, 20 + eM(eT,10) * 9);
    eT /= 10;
    tB = cS(tB, 20 + eM(eT,10) * 9);
    eT /= 10;
    if (tA[5] > 0) {
      b = string(abi.encodePacked(b,rA(loc[75],loc[76],loc[77],loc[78], tR, tG, tB, 1, 0, 0)));
    }
    if (tA[5] == 3) {
      b = string(abi.encodePacked(b,rA(loc[79],loc[80],loc[81],loc[82], tR, tG, tB, 1, 0, 0)));  
    }
    if (tA[6] > 0) {
      b = string(abi.encodePacked(b,rA(loc[87],loc[88],loc[89],loc[90], 252, 214, 18, 1, 0, 0)));
    } 
    if (tA[6] == 2) {
      b = string(abi.encodePacked(b,rA(loc[87],loc[91],loc[89],loc[92], 0, 120, 90, 1, 0, 0)));
    }
    if (tA[5] == 3) {
      b = string(abi.encodePacked(b,rA(loc[83],loc[84],loc[85],loc[86], tR, tG, tB, 1, 0, 0))); 
    }

    // Ear rings
    s[0] = '(242,242,255); stroke-width: 2px; stroke: rgb(233,233,242);"/>';
    if (tA[7] == 4) { 
      s[0] = 'a(22,22,22, .5); stroke-width: 8px; stroke: rgb(12,12,12);"/>';
      loc[48] = 20;
    }
    if (tA[7] == 1 || tA[7] == 3 || tA[7] == 4) {
      b = string(abi.encodePacked(b,rS(loc[28] + (loc[31] - loc[48]) / 2, loc[49], loc[48], loc[48], s[0])));
    }
    if (tA[7] == 2 || tA[7] == 3 || tA[7] == 4) {
      b = string(abi.encodePacked(b,rS(loc[29] + (loc[31] - loc[48]) / 2, loc[49], loc[48], loc[48], s[0])));
    }
    loc[49] = loc[30] + 20;
    s[0] = '(252,214,18)"/>';
    if (tA[8] == 1 || tA[8] == 3) { 
      b = string(abi.encodePacked(b,rS(loc[28] - 15, loc[49], 30, 15, s[0])));
    } 
    if (tA[8] == 2 || tA[8] == 3) { 
      b = string(abi.encodePacked(b,rS(loc[29] + loc[31] - 15, loc[49], 30, 15, s[0])));
    }

    // Other
    tR = cS(tR, 40);
    tG = cS(tG, 40);
    tB = cS(tB, 40);
    if (tA[9] == 0) {
      b = string(abi.encodePacked(b,rA(loc[98],loc[99],loc[100],loc[101], tR, tG, tB, 1, 6, 32)));
    } else if (tA[9] == 1) {
      b = string(abi.encodePacked(b,rA(loc[98],loc[99],loc[100],loc[101], tR, tG, tB, 1, 0, 0))); 
      b = string(abi.encodePacked(b,rA(loc[102],loc[103],loc[104],loc[105], tR, tG, tB, 1, 0, 0)));
      b = string(abi.encodePacked(b,rA(loc[97],loc[103],loc[104],loc[105], tR, tG, tB, 1, 0, 0)));  
    } else if (tA[9] == 2) {
      b = string(abi.encodePacked(b,rS(loc[98],loc[99],loc[100],loc[101],'(32,32,32)"/>')));
    } else if (tA[9] == 3) {
      b = string(abi.encodePacked(b,rS(loc[98],loc[99],loc[100],loc[101],'(252,214,18)"/>')));
    } else if (tA[9] == 4) {
      b = string(abi.encodePacked(b,rS(loc[98],loc[99],loc[100],loc[101],'(8,8,8)"/>')));
    } else if (tA[9] == 5) {
      b = string(abi.encodePacked(b,rS(loc[98],loc[99],loc[100],loc[101],'(252,214,18)"/>')));
      b = string(abi.encodePacked(b,rS(loc[102],loc[99],loc[104],loc[101],'(0,120,90)"/>')));
    }
    b = string(abi.encodePacked(b,'</svg>'));
    return b;
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