//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
  struct HSL {
    uint256 h;
    uint256 s;
    uint256 l;
  }

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function randomRange(
    uint256 tokenId,
    string memory keyPrefix,
    uint256 lower,
    uint256 upper
  ) internal pure returns (uint256) {
    uint256 rand = random(string(abi.encodePacked(keyPrefix, uint2str(tokenId))));
    return (rand % (upper - lower + 1)) + lower;
  }

  function min(int256 a, int256 b) internal pure returns (int256) {
    return a < b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function max(int256 a, int256 b) internal pure returns (int256) {
    return a > b ? a : b;
  }

  function generateColors(uint256 _hue, uint256 _numColors) public pure returns (HSL[] memory) {
    HSL[] memory colors = new HSL[](_numColors);

    for (uint256 i = 0; i < _numColors; i++) {
      colors[i] = HSL(_hue, 100 - ((i * 50) / _numColors), 70 - ((i * 30) / _numColors));
    }

    return colors;
  }

  function getHueName(uint256 _hue) public pure returns (string memory) {
    _hue = _hue % 360;

    string[12] memory colors = [
      "Red",
      "Orange",
      "Yellow",
      "Chartreuse",
      "Green",
      "Spring green",
      "Turquoise",
      "Teal",
      "Blue",
      "Violet",
      "Magenta",
      "Rose"
    ];

    uint256 colorIndex = (_hue / 30) % colors.length;
    return colors[colorIndex];
  }

  function getHslString(HSL memory _hsl) public pure returns (string memory) {
    return string(abi.encodePacked("hsl(", uint2str(_hsl.h), ",", uint2str(_hsl.s), "%,", uint2str(_hsl.l), "%)"));
  }

  function uint2floatstr(uint256 _i_scaled, uint256 _decimals) internal pure returns (string memory) {
    return string.concat(uint2str(_i_scaled / (10**_decimals)), ".", uint2str(_i_scaled % (10**_decimals)));
  }

  function int2str(int256 _i) internal pure returns (string memory _uintAsString) {
    if (_i < 0) {
      return string.concat("-", uint2str(uint256(-_i)));
    } else {
      return uint2str(uint256(_i));
    }
  }

  // converts an unsigned integer to a string
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