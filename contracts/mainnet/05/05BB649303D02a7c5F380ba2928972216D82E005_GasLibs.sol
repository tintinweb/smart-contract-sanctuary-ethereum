// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


library GasLibs {
  uint256 constant MAX_MINT_GAS_PRICE = 1000000; // 1000 gwei mint would show all checks

  /**
   * @dev depending on seed, provide a max delta for color changes
   * 25% chance of a 50 delta
   * 25% chance of a 35 delta
   * 25% chance of a 25 delta
   * 15% chance of a 15 delta
   * 10% chance of a 5 delta 
   */
  function getMaxDelta(uint256 seed) public pure returns (uint8) {
    uint8 multiplier = 1;
    uint8 random = uint8((seed >> 128) % 100);
    if (random < 25) {
      multiplier = 50;
    } else if (random < 50) {
      multiplier = 35;
    } else if (random < 75) {
      multiplier = 25;
    } else if (random < 90) {
      multiplier = 15;
    } else {
      multiplier = 5;
    }
    return multiplier;
  }

  /**
   * @dev depending on seed, provide a boost to the gas price
   * 25% chance of a 1x multiplier
   * 25% chance of a 2x multiplier
   * 25% chance of a 3x multiplier
   * 15% chance of a 4x multiplier
   * 10% chance of a 5x multiplier 
   */
  function getGasPriceMultiplier(uint256 seed) public pure returns (uint8) {
    uint8 multiplier = 1;
    uint8 random = uint8(seed % 100);
    if (random < 25) {
      multiplier = 1;
    } else if (random < 50) {
      multiplier = 2;
    } else if (random < 75) {
      multiplier = 3;
    } else if (random < 90) {
      multiplier = 4;
    } else {
      multiplier = 5;
    }
    return multiplier;
  }

  function getNumberOfCheckMarks(bool[80] memory isCheckMarkRenderer) public pure returns (uint8) {
    uint8 count = 0;
    for (uint8 i = 0; i < 80; i++) {
      if (isCheckMarkRenderer[i]) {
        count++;
      }
    }
    return count;
  }


  /**
   * @dev For a given gas price (in 1/1000 gwei) and an index, returns whether a checkmark should be generated.
   * The index is the position of the checkmark in the 8 x 10 grid, starting from the top left.
   * For each index, generate a random number between 0 and 1000000. If the gas price is lower than the random number, do not generate a checkmark.
   * For an easy random number, let's use the seed and bit shift it to the right by the index
   */
  function checkmarkGenerates(uint256 seed, uint24 boostedGasPrice, uint8 index) internal pure returns (bool) {
    return boostedGasPrice > (uint24(seed >> index) % MAX_MINT_GAS_PRICE);
  }

  function getIsCheckRendered(uint256 seed, uint24 gasPrice) public pure returns (bool[80] memory) {
    bool[80] memory isCheckRendered;
    uint24 boostedGasPrice = gasPrice * getGasPriceMultiplier(seed);
    for (uint8 i = 0; i < 80; i++) {
      if (checkmarkGenerates(seed, boostedGasPrice, i)) {
        isCheckRendered[i] = true;
      }
    }
    return isCheckRendered;
  }


  function gasPriceToStr(uint24 gasPrice) public pure returns (string memory) {
    uint24 gasPriceLeftSideZero = gasPrice / 1000;
    uint24 gasPriceRightSideZero = gasPrice % 1000;
    return string.concat(
      uint2str(gasPriceLeftSideZero),
      ".",
      leftPad(uint2str(gasPriceRightSideZero), 3)
    );
  }


  // via https://stackoverflow.com/a/65707309
  function uint2str(uint256 _i)
    public
    pure
    returns (string memory _uintAsString)
  {
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

  function uint2hex(uint256 _i)
    public
    pure
    returns (string memory _uintAsHexString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 16;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 16) * 16));
      if (temp > 57) {
        temp += 7;
      }
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 16;
    }
    return string(bstr);
  }

  function leftPad(string memory str, uint256 length) public pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory paddedBytes = new bytes(length);
    for (uint256 i = 0; i < length; i++) {
      if (i < length - strBytes.length) {
        paddedBytes[i] = "0";
      } else {
        paddedBytes[i] = strBytes[i - (length - strBytes.length)];
      }
    }
    return string(paddedBytes);
  }
}