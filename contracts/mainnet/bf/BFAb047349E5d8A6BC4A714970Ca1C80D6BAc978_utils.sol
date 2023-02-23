//SPDX-License-Identifier: MIT

/*                          
                                .................                               
                          ......22222222222222222......                         
                       ......22244444444444444444222.....                       
                       ...222444444           444444222..                       
                    ...222444444                 44444422*..                    
                    ...222444                       44422*..                    
                    ...222444                       44422*..                    
                    ...222444                       44422*..                    
                    ...222444                       44422*..                    
                    ...222444                       44422*..                    
                    ...222444444                 44444422*..                    
                       ...222444444           444444222..                       
                       ......22244444444444444444222.....                       
                          ......22222222222222222......                         
                                .................
*/
pragma solidity ^0.8.12;

library utils {
  function assemblyKeccak(bytes memory _input) public pure returns (bytes32 x) {
    assembly {
      x := keccak256(add(_input, 0x20), mload(_input))
    }
  }

  function random(string memory input) internal pure returns (uint256) {
    return uint256(assemblyKeccak(abi.encodePacked(input)));
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

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
    require(bs.length >= start + 32, "slicing out of range");
    uint256 x;
    assembly {
      x := mload(add(bs, add(0x20, start)))
    }
    return x;
  }

  // function getHslString(HSL memory _hsl) public pure returns (string memory) {
  //   return string(abi.encodePacked("hsl(", uint2str(_hsl.h), ",", uint2str(_hsl.s), "%,", uint2str(_hsl.l), "%)"));
  // }

  // function getHslString(
  //   uint256 _h,
  //   uint256 _s,
  //   uint256 _l
  // ) public pure returns (string memory) {
  //   return string(abi.encodePacked("hsl(", uint2str(_h), ",", uint2str(_s), "%,", uint2str(_l), "%)"));
  // }

  function getHslString(uint256[3] memory _hsl) public pure returns (string memory) {
    return string(abi.encodePacked("hsl(", uint2str(_hsl[0]), ",", uint2str(_hsl[1]), "%,", uint2str(_hsl[2]), "%)"));
  }

  function getHslString(uint256 _packedHsl) public pure returns (string memory) {
    // 3 colors per level, 3 color items per color, H/S/L are color items, 3 bytes each
    return
      string(
        abi.encodePacked(
          "hsl(",
          uint2str((_packedHsl >> (12 * 2)) & 0xFFF),
          ",",
          uint2str((_packedHsl >> (12 * 1)) & 0xFFF),
          "%,",
          uint2str((_packedHsl >> (12 * 0)) & 0xFFF),
          "%)"
        )
      );
  }

  function unpackHsl(uint256 _packedHsl) public pure returns (uint256[3] memory) {
    return [(_packedHsl >> (12 * 2)) & 0xFFF, (_packedHsl >> (12 * 1)) & 0xFFF, (_packedHsl >> (12 * 0)) & 0xFFF];
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

  function sqrt(uint256 x) internal pure returns (uint256 z) {
    assembly {
      // This segment is to get a reasonable initial estimate for the Babylonian method.
      // If the initial estimate is bad, the number of correct bits increases ~linearly
      // each iteration instead of ~quadratically.
      // The idea is to get z*z*y within a small factor of x.
      // More iterations here gets y in a tighter range. Currently, we will have
      // y in [256, 256*2^16). We ensure y>= 256 so that the relative difference
      // between y and y+1 is small. If x < 256 this is not possible, but those cases
      // are easy enough to verify exhaustively.
      z := 181 // The 'correct' value is 1, but this saves a multiply later
      let y := x
      // Note that we check y>= 2^(k + 8) but shift right by k bits each branch,
      // this is to ensure that if x >= 256, then y >= 256.
      if iszero(lt(y, 0x10000000000000000000000000000000000)) {
        y := shr(128, y)
        z := shl(64, z)
      }
      if iszero(lt(y, 0x1000000000000000000)) {
        y := shr(64, y)
        z := shl(32, z)
      }
      if iszero(lt(y, 0x10000000000)) {
        y := shr(32, y)
        z := shl(16, z)
      }
      if iszero(lt(y, 0x1000000)) {
        y := shr(16, y)
        z := shl(8, z)
      }
      // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8),
      // and either y >= 256, or x < 256.
      // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
      // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of x, or about 20bps.

      // The estimate sqrt(x) = (181/1024) * (x+1) is off by a factor of ~2.83 both when x=1
      // and when x = 256 or 1/256. In the worst case, this needs seven Babylonian iterations.
      z := shr(18, mul(z, add(y, 65536))) // A multiply is saved from the initial z := 181

      // Run the Babylonian method seven times. This should be enough given initial estimate.
      // Possibly with a quadratic/cubic polynomial above we could get 4-6.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

      // See https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division.
      // If x+1 is a perfect square, the Babylonian method cycles between
      // floor(sqrt(x)) and ceil(sqrt(x)). This check ensures we return floor.
      // The solmate implementation assigns zRoundDown := div(x, z) first, but
      // since this case is rare, we choose to save gas on the assignment and
      // repeat division in the rare case.
      // If you don't care whether floor or ceil is returned, you can skip this.
      if lt(div(x, z), z) {
        z := div(x, z)
      }
    }
  }
}