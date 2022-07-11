// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Strings.sol";

contract SVGColor {
  using Strings for uint256;
  using Strings for uint8;

  mapping(string => bytes) public colors;

  constructor() {
    colors["Black"] = hex"000000";
    colors["White"] = hex"FFFFFF";
    colors["Dark1"] = hex"232323";
    colors["Dark2"] = hex"464646";
  }

  function getColor(string memory _colorName) public view returns (bytes memory) {
    require(colors[_colorName].length == 3, "Unknown color");
    return abi.encodePacked(colors[_colorName], hex"64");
  }

  function getColor(string memory _colorName, uint8 _alpha) public view returns (bytes memory) {
    require(colors[_colorName].length == 3, "Unknown color");
    return abi.encodePacked(colors[_colorName], _alpha);
  }

  function getRgba(string memory _colorName) public view returns (string memory) {
    return string(toRgba(getColor(_colorName), 0));
  }

  // Input: array of colors (without alpha)
  // Ouputs a linearGradient
  function autoLinearGradient(
    bytes memory _colors,
    bytes memory _id,
    bytes memory _customAttributes
  ) public view returns (bytes memory) {
    return this.autoLinearGradient("", _colors, _id, _customAttributes);
  }

  function autoLinearGradient(
    bytes memory _coordinates,
    bytes memory _colors,
    bytes memory _id,
    bytes memory _customAttributes
  ) external view returns (bytes memory) {
    bytes memory _b;
    if (_coordinates.length > 3) {
      _b = abi.encodePacked(uint8(128), _coordinates);
    } else {
      _b = hex"00";
    }
    // Count the number of colors passed, each on 4 byte
    uint256 colorCount = _colors.length / 4;
    uint8 i = 0;
    while (i < colorCount) {
      _b = abi.encodePacked(
        _b,
        uint8(i * (100 / (colorCount - 1))), // grad. stop %
        uint8(_colors[i * 4]),
        uint8(_colors[i * 4 + 1]),
        uint8(_colors[i * 4 + 2]),
        uint8(_colors[i * 4 + 3])
      );
      i++;
    }
    return linearGradient(_b, _id, _customAttributes);
  }

  function linearGradient(
    bytes memory _lg,
    bytes memory _id,
    bytes memory _customAttributes
  ) public pure returns (bytes memory) {
    bytes memory grdata;
    uint8 offset = 1;

    if (uint8(_lg[0]) & 128 == 128) {
      grdata = abi.encodePacked(
        'x1="',
        byte2uint8(_lg, 1).toString(),
        '%" x2="',
        byte2uint8(_lg, 2).toString(),
        '%" y1="',
        byte2uint8(_lg, 3).toString(),
        '%" y2="',
        byte2uint8(_lg, 4).toString(),
        '%"'
      );
      offset = 5;
    }
    grdata = abi.encodePacked('<linearGradient id="', _id, '" ', _customAttributes, grdata, ">");
    for (uint256 i = offset; i < _lg.length; i += 5) {
      grdata = abi.encodePacked(
        grdata,
        '<stop offset="',
        byte2uint8(_lg, i).toString(),
        '%" stop-color="',
        toRgba(_lg, i + 1),
        '" id="',
        _id,
        byte2uint8(_lg, i).toString(),
        '"/>'
      );
    }
    return abi.encodePacked(grdata, "</linearGradient>");
  }

  function toRgba(bytes memory _rgba, uint256 offset) public pure returns (bytes memory) {
    return
      abi.encodePacked(
        "rgba(",
        byte2uint8(_rgba, offset).toString(),
        ",",
        byte2uint8(_rgba, offset + 1).toString(),
        ",",
        byte2uint8(_rgba, offset + 2).toString(),
        ",",
        byte2uint8(_rgba, offset + 3).toString(),
        "%)"
      );
  }

  function byte2uint8(bytes memory _data, uint256 _offset) public pure returns (uint8) {
    require(_data.length > _offset, "Out of range");
    return uint8(_data[_offset]);
  }

  // formats rgba white with a specified opacity / alpha
  function white_a(uint256 _a) internal pure returns (string memory) {
    return rgba(255, 255, 255, _a);
  }

  // formats rgba black with a specified opacity / alpha
  function black_a(uint256 _a) internal pure returns (string memory) {
    return rgba(0, 0, 0, _a);
  }

  // formats generic rgba color in css
  function rgba(
    uint256 _r,
    uint256 _g,
    uint256 _b,
    uint256 _a
  ) internal pure returns (string memory) {
    string memory formattedA = _a < 100 ? string.concat("0.", uint2str(_a)) : "1";
    return
      string.concat(
        "rgba(",
        uint2str(_r),
        ",",
        uint2str(_g),
        ",",
        uint2str(_b),
        ",",
        formattedA,
        ")"
      );
  }

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
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