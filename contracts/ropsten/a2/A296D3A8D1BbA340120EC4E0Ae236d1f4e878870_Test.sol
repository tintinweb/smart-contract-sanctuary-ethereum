/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Test {
  address public owner;
  uint256 public createdAt;
  string public data;

  constructor() {
    owner = msg.sender;
    createdAt = block.timestamp;
  }

  function updateData(string memory _data) public {
    require(msg.sender == owner);
    data = _data;
  }

  function finalize() public {
    selfdestruct(payable(msg.sender));
}

  function sender() public view returns (address) {
    return msg.sender;
  }

}