/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// @author fbsloXBT

contract FullBlockMinter {
  address public owner;
  uint256 public gasToFinalize = 100;

  constructor(address newOwner){
    owner = newOwner;
  }

  modifier onlyOwner(){
    require(msg.sender == owner, "only owner");
    _;
  }

  function set(address newOwner, uint256 newGasToFinalize) external onlyOwner {
    owner = newOwner;
    gasToFinalize = newGasToFinalize;
  }

  function callWithBurn(address target, uint256 value, bytes memory data, uint256 targetBlockNumber, bool useFullBlock) external onlyOwner {
    if (targetBlockNumber != 0) require(targetBlockNumber == block.number, "!targetBlockNumber");

    (bool success, ) = target.call{value: value}(data);
    require(success, "external call failed");

    if (useFullBlock) burn(gasToFinalize);
  }

  function call(address target, uint256 value, bytes memory data) external onlyOwner {
    (bool success, ) = target.call{value: value}(data);
    require(success, "external call failed");
  }

  function burn(uint256 end) internal {
    while (gasleft() > end) {}
  }
}