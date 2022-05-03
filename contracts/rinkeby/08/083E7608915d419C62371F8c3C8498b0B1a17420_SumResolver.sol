/*
SumResolver

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

library SumResolver {
  /**
   * @notice resolve class membership by summing underlying plugin shares
   * @param shares list of shares from plugin classes
   */
  function resolve(uint256[] calldata shares, bytes calldata)
    external
    pure
    returns (uint256)
  {
    uint256 sum;
    for (uint256 i = 0; i < shares.length; i++) {
      sum += shares[i];
    }

    return sum;
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
    return "Sum resolver";
  }
}