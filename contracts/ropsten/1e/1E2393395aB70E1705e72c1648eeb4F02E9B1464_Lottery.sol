/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract Lottery {
  constructor() public payable {}

  function play() external payable {
    require(msg.value == 0.01 ether);
    bytes32 abc = keccak256(abi.encode(rndSource(), address(this).balance));
    if ((uint256(abc) % 10000) == 0) {
      payable(msg.sender).transfer(address(this).balance);
    }
  }

  function rndSource() public view returns (bytes32) {
    return blockhash(block.number - (block.number % 200));
  }

  fallback() external {
    revert();
  }
}