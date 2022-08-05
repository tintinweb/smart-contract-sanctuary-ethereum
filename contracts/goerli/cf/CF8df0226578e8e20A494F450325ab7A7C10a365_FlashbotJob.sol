// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract FlashbotJob {
  event Debug(address msgSender, address txOrigin, address blockCoinbase, uint256 txGasPrice, uint256 blockBaseFee, uint256 newCounter);

  uint256 public counter;

  function poke(bool shouldFail) external {
    if (shouldFail) {
      revert("should fail");
    }
    counter += 1;
    emit Debug(msg.sender, tx.origin, block.coinbase, tx.gasprice, block.basefee, counter);
  }
}