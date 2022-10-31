// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/Strings.sol';
import '../libraries/ColorUtils.sol';

library ColorShifters {
  uint8 public constant NUM_MATERIALS = 8;

  //amt : 20
  function colorFlip(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    bytes memory colorsTemp = abi.encodePacked(colors);
    for (uint256 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory rgbNew = ColorUtils.getColor(
        colorsTemp,
        NUM_MATERIALS - i - 1
      );
      bytes memory rgbOld = ColorUtils.getColor(colorsTemp, i);
      if (rgbNew[0] > rgbOld[0]) {
        rgbOld = ColorUtils.add(
          rgbOld,
          0,
          (uint16(uint8(rgbNew[0]) - uint8(rgbOld[0])) * uint16(amt)) / 40
        );
      } else {
        rgbOld = ColorUtils.sub(
          rgbOld,
          0,
          (uint16(uint8(rgbOld[0]) - uint8(rgbNew[0])) * uint16(amt)) / 40
        );
      }
      if (rgbNew[1] > rgbOld[1]) {
        rgbOld = ColorUtils.add(
          rgbOld,
          1,
          (uint16(uint8(rgbNew[1]) - uint8(rgbOld[1])) * uint16(amt)) / 40
        );
      } else {
        rgbOld = ColorUtils.sub(
          rgbOld,
          1,
          (uint16(uint8(rgbOld[1]) - uint8(rgbNew[1])) * uint16(amt)) / 40
        );
      }
      if (rgbNew[2] > rgbOld[2]) {
        rgbOld = ColorUtils.add(
          rgbOld,
          2,
          (uint16(uint8(rgbNew[2]) - uint8(rgbOld[2])) * uint16(amt)) / 40
        );
      } else {
        rgbOld = ColorUtils.sub(
          rgbOld,
          2,
          (uint16(uint8(rgbOld[2]) - uint8(rgbNew[2])) * uint16(amt)) / 40
        );
      }
      colors = ColorUtils.setColor(colors, i, rgbOld);
    }
    return colors;
  }

  function testHSV(bytes memory colors) public pure returns (bytes memory) {
    for (uint256 i = 0; i < NUM_MATERIALS; i++) {
      colors = ColorUtils.setColor(
        colors,
        i,
        ColorUtils.HSVtoRGB(ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i)))
      );
    }
    return colors;
  }

  //amt : 60
  function hueHighlight(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i == NUM_MATERIALS - 1) {
        hsv = ColorUtils.subWrap(hsv, 0, amt / 3);
        hsv = ColorUtils.add(hsv, 2, amt / 2);
      } else if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.sub(hsv, 1, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  //amt : 50
  function twoToneHue(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i <= (NUM_MATERIALS / 3) * 2) {
        hsv = ColorUtils.subWrap(hsv, 0, amt);
        //hsv = ColorUtils.sub(hsv, 2, amt/2);
      } else {
        hsv = ColorUtils.addWrap(hsv, 0, amt);
        //hsv = ColorUtils.add(hsv, 2, amt);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function corrupted(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.sub(hsv, 2, uint16(amt));
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function glow(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.add(hsv, 2, uint16(amt) * i);
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.sub(hsv, 1, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function blackGlow(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.sub(hsv, 2, uint16((amt / 3) * 2) * i);
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift / 2);
        hsv = ColorUtils.add(hsv, 2, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift / 2);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function hueShift(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.addWrap(hsv, 0, amt);
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function saturationShift(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.add(hsv, 1, amt);
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function valueShift(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.add(hsv, 2, amt);
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function contrast(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.sub(hsv, 2, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.add(hsv, 2, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  //amt : 40
  function colorContrast(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.sub(hsv, 1, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  //amt : 60
  function hueContrast(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.addWrap(hsv, 0, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.subWrap(hsv, 0, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
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

pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/Strings.sol';

library ColorUtils {
  function getColor(bytes memory colors, uint256 colorIdx)
    public
    pure
    returns (bytes memory)
  {
    colorIdx *= 3;
    bytes memory color = abi.encodePacked(
      colors[colorIdx],
      colors[colorIdx + 1],
      colors[colorIdx + 2]
    );
    return color;
  }

  function setColor(
    bytes memory colors,
    uint256 colorIdx,
    bytes memory color
  ) public pure returns (bytes memory) {
    colorIdx *= 3;
    colors[colorIdx + 0] = color[0];
    colors[colorIdx + 1] = color[1];
    colors[colorIdx + 2] = color[2];
    return colors;
  }

  function addWrap(
    bytes memory color,
    uint8 idx,
    uint16 amt
  ) public pure returns (bytes memory) {
    unchecked {
      color[idx] = bytes1(uint8(uint16(uint8(color[idx])) + amt));
    }
    return color;
  }

  function add(
    bytes memory color,
    uint8 idx,
    uint16 amt
  ) public pure returns (bytes memory) {
    if (amt + uint16(uint8(color[idx])) >= 255) {
      color[idx] = bytes1(uint8(255));
      return color;
    }
    color[idx] = bytes1(uint8(color[idx]) + uint8(amt));
    return color;
  }

  function subWrap(
    bytes memory color,
    uint8 idx,
    uint16 amt
  ) public pure returns (bytes memory) {
    unchecked {
      color[idx] = bytes1(uint8(uint16(uint8(color[idx])) - amt));
    }
    return color;
  }

  function sub(
    bytes memory color,
    uint8 idx,
    uint16 amt
  ) public pure returns (bytes memory) {
    if (uint16(uint8(color[idx])) < amt) {
      color[idx] = bytes1(uint8(0));
      return color;
    }
    color[idx] = bytes1(uint8(uint16(uint8(color[idx])) - amt));
    return color;
  }

  function RGBtoHSV(bytes memory color) public pure returns (bytes memory) {
    return RGBtoHSV(uint8(color[0]), uint8(color[1]), uint8(color[2]));
  }

  function RGBtoHSV(
    uint8 r,
    uint8 g,
    uint8 b
  ) public pure returns (bytes memory) {
    bytes memory hsv = new bytes(3);
    uint8 min = r < g ? (r < b ? r : b) : (g < b ? g : b);
    uint8 max = r > g ? (r > b ? r : b) : (g > b ? g : b);
    hsv[2] = bytes1(max); // v

    if (max == 0) {
      hsv[0] = 0;
      hsv[1] = 0;
      return hsv;
    }

    hsv[1] = bytes1(uint8((255 * uint32(max - min)) / uint8(hsv[2])));

    if (uint8(hsv[1]) == 0) {
      hsv[0] = 0;
      return hsv;
    }

    unchecked {
      if (max == r) {
        if (g > b) {
          hsv[0] = bytes1(uint8(0 + (43 * uint32(g - b)) / uint32(max - min)));
        } else {
          hsv[0] = bytes1(uint8(0 - (43 * uint32(b - g)) / uint32(max - min)));
        }
      } else if (max == g) {
        if (b > r) {
          hsv[0] = bytes1(uint8(85 + (43 * uint32(b - r)) / uint32(max - min)));
        } else {
          hsv[0] = bytes1(uint8(85 - (43 * uint32(r - b)) / uint32(max - min)));
        }
      } else {
        if (r > g) {
          hsv[0] = bytes1(
            uint8(171 + (43 * uint32(r - g)) / uint32(max - min))
          );
        } else {
          hsv[0] = bytes1(
            uint8(171 - (43 * uint32(g - r)) / uint32(max - min))
          );
        }
      }
    }
    return hsv;
  }

  function HSVtoRGB(bytes memory color) public pure returns (bytes memory) {
    return HSVtoRGB(uint8(color[0]), uint8(color[1]), uint8(color[2]));
  }

  function HSVtoRGB(
    uint8 h,
    uint8 s,
    uint8 v
  ) public pure returns (bytes memory) {
    bytes memory rgb = new bytes(3);
    uint8 region = 0;
    uint8 remainder = 0;
    uint8 p = 0;
    uint8 q = 0;
    uint8 t = 0;

    if (s == 0) {
      rgb[0] = bytes1(v);
      rgb[1] = bytes1(v);
      rgb[2] = bytes1(v);
      return rgb;
    }

    region = h / 43;
    remainder = (h - (region * 43)) * 6;

    p = uint8((v * uint32(255 - s)) >> 8);
    q = uint8((v * (255 - ((uint32(s) * uint32(remainder)) >> 8))) >> 8);
    t = uint8((v * (255 - ((uint32(s) * uint32(255 - remainder)) >> 8))) >> 8);

    if (region == 0) {
      rgb[0] = bytes1(v);
      rgb[1] = bytes1(t);
      rgb[2] = bytes1(p);
    } else if (region == 1) {
      rgb[0] = bytes1(q);
      rgb[1] = bytes1(v);
      rgb[2] = bytes1(p);
    } else if (region == 2) {
      rgb[0] = bytes1(q);
      rgb[1] = bytes1(v);
      rgb[2] = bytes1(t);
    } else if (region == 3) {
      rgb[0] = bytes1(p);
      rgb[1] = bytes1(q);
      rgb[2] = bytes1(v);
    } else if (region == 4) {
      rgb[0] = bytes1(t);
      rgb[1] = bytes1(p);
      rgb[2] = bytes1(v);
    } else {
      rgb[0] = bytes1(v);
      rgb[1] = bytes1(p);
      rgb[2] = bytes1(q);
    }
    return rgb;
  }
}