/*
ThresholdResolver

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

library ThresholdResolver {
  /**
   * @notice resolve class membership by checking thresholds for underlying plugin shares
   * @param shares list of shares from plugin classes
   * @param params encoded thresholds for each plugin class
   */
  function resolve(uint256[] calldata shares, bytes calldata params)
    external
    pure
    returns (uint256)
  {
    require(
      params.length == 32 * shares.length,
      "ThresholdResolver: invalid threshold data"
    );

    for (uint256 i = 0; i < shares.length; i++) {
      // parse each threshold value from encoded params
      uint256 thresh;
      uint256 pos = 132 + 32 * shares.length + 32 * i;
      assembly {
        thresh := calldataload(pos)
      }
      // validate each threshold criteria
      if (shares[i] < thresh) {
        return 0;
      }
    }

    return 1;
  }

  /**
   * @notice get a metadata string about the resolver
   * @param params encoded data
   */
  function metadata(bytes calldata params)
    external
    pure
    returns (string memory)
  {
    return "Threshold resolver";
  }
}