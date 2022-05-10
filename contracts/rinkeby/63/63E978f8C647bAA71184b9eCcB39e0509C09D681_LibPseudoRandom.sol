//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibPseudoRandom {
  uint256 private constant decimals = 6;

  /**
   * @dev Returns amount of requested picks of a pseudo-random number between 0 and 1.
   * @dev Decimals is defined by constant.
   * @param amountOfPicks number of random picks to return.
   * @param entropy random value that must be provided from a reliable oracle source.
   * @return results array of picks.
   */
  function pickRandomNumbers(uint256 amountOfPicks, uint256 entropy)
    external
    view
    returns (uint256[] memory results)
  {
    require(amountOfPicks > 0, "Invalid amountOfPicks!");
    results = new uint256[](amountOfPicks);
    for (uint256 i = 0; i < results.length; i++) {
      results[i] = _pickProbability(i, entropy);
    }
  }

  function _pickProbability(uint256 nonce, uint256 entropy) private view returns (uint256 index) {
    index = (_random(nonce, entropy) % 10**decimals) + 1;
  }

  function _random(uint256 nonce, uint256 entropy) private view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(block.difficulty, block.timestamp, block.coinbase, entropy, nonce)
        )
      );
  }
}