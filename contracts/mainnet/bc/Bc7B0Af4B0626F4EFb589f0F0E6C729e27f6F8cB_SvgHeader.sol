//	SPDX-License-Identifier: MIT
/// @notice Helper to build svg elements
pragma solidity ^0.8.0;

import './LogoHelper.sol';

library SvgHeader {
  function getHeader(uint16 width, uint16 height) public pure returns (string memory) {
    string memory svg = '<svg version="2.0" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 ';
    if (width != 0 && height != 0) {
      svg = string(abi.encodePacked(svg, LogoHelper.toString(width), ' ', LogoHelper.toString(height), '">'));
    } else {
      svg = string(abi.encodePacked(svg, '300 300">'));
    }
    return svg;
  }

  function getTransform(uint8 translateXDirection, uint16 translateX, uint8 translateYDirection, uint16 translateY, uint8 scaleDirection, uint8 scaleMagnitude) public pure returns (string memory) {
    string memory translateXStr = translateXDirection == 0 ? string(abi.encodePacked('-', LogoHelper.toString(translateX))) : LogoHelper.toString(translateX);
    string memory translateYStr = translateYDirection == 0 ? string(abi.encodePacked('-', LogoHelper.toString(translateY))) : LogoHelper.toString(translateY);

    string memory scale = '1';
    if (scaleMagnitude != 0) {
      if (scaleDirection == 0) { 
        scale = string(abi.encodePacked('0.', scaleMagnitude < 10 ? LogoHelper.toString(scaleMagnitude): LogoHelper.toString(scaleMagnitude % 10)));
      } else {
        scale = string(abi.encodePacked(LogoHelper.toString((scaleMagnitude / 10) + 1), '.', LogoHelper.toString(scaleMagnitude % 10)));
      }
    }

    return string(abi.encodePacked('translate(', translateXStr, ', ', translateYStr, ') ', 'scale(', scale, ')'));
  }

}

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library LogoHelper {
  function getRotate(string memory text) public pure returns (string memory) {
    bytes memory byteString = bytes(text);
    string memory rotate = string(abi.encodePacked('-', toString(random(text) % 10 + 1)));
    for (uint i=1; i < byteString.length; i++) {
      uint nextRotate = random(rotate) % 10 + 1;
      if (i % 2 == 0) {
        rotate = string(abi.encodePacked(rotate, ',-', toString(nextRotate)));
      } else {
        rotate = string(abi.encodePacked(rotate, ',', toString(nextRotate)));
      }
    }
    return rotate;
  }

  function getTurbulance(string memory seed, uint max, uint magnitudeOffset) public pure returns (string memory) {
    string memory turbulance = decimalInRange(seed, max, magnitudeOffset);
    uint rand = randomInRange(turbulance, max, 0);
    return string(abi.encodePacked(turbulance, ', ', getDecimal(rand, magnitudeOffset)));
  }

  function decimalInRange(string memory seed, uint max, uint magnitudeOffset) public pure returns (string memory) {
    uint rand = randomInRange(seed, max, 0);
    return getDecimal(rand, magnitudeOffset);
  }

  // CORE HELPERS //
  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function randomFromInt(uint256 seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed)));
  }

  function randomInRange(string memory input, uint max, uint offset) public pure returns (uint256) {
    max = max - offset;
    return (random(input) % max) + offset;
  }

  function equal(string memory a, string memory b) public pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

  function toString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);            
    }
    return string(s);
  }

function char(bytes1 b) internal pure returns (bytes1 c) {
  if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
  else return bytes1(uint8(b) + 0x57);
}
  
  function getDecimal(uint val, uint magnitudeOffset) public pure returns (string memory) {
    string memory decimal;
    if (val != 0) {
      for (uint i = 10; i < magnitudeOffset / val; i=10*i) {
        decimal = string(abi.encodePacked(decimal, '0'));
      }
    }
    decimal = string(abi.encodePacked('0.', decimal, toString(val)));
    return decimal;
  }

  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }
    return string(result);
  }
}