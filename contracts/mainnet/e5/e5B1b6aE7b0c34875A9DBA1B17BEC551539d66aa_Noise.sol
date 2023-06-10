// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library Noise {
  // Normal distribution
  function getNoiseArrayZero() external pure returns (int256[256] memory) {
    int[256] memory noiseArray = [int(8), 16, 24, 32, 40, 40, 48, 48, 48, 56, 56, 64, 64, 64, 64, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 80, 80, 80, 80, 80, 80, 80, 80, 88, 88, 88, 88, 88, 88, 88, 88, 88, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 104, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 112, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 144, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 168, 168, 168, 168, 168, 168, 168, 168, 168, 168, 168, 176, 176, 176, 176, 176, 176, 176, 176, 176, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 192, 192, 192, 192, 200, 200, 200, 200, 200, 200, 200, 208, 208, 216, 224, 232, 240, 248];
    return noiseArray;
  }

  // Linear -64 -> 63
  function getNoiseArrayOne() external pure returns (int256[] memory) {
    return createLinearNoiseArray(128);
  }

  // Linear -16 -> 15
  function getNoiseArrayTwo() external pure returns (int256[] memory) {
    return createLinearNoiseArray(32);
  }

  // Linear -32 -> 31
  function getNoiseArrayThree() external pure returns (int256[] memory) {
    return createLinearNoiseArray(64);
  }

  // Create a linear noise array
  function createLinearNoiseArray(uint range) internal pure returns (int256[] memory) {
    int[] memory output = new int[](256);

    require(256 % range == 0, "range must be a factor of 256");

    require(range % 2 == 0, "range must be even");

    uint numOfCycles = 256 / range;

    int halfRange = int(range / 2);

    for (uint i = 0; i < numOfCycles; i++) {
      for (uint j = 0; j < range; ++j) {
        output[i * range + j] = int(j) - halfRange;
      }
    }

    return output;
  }
}