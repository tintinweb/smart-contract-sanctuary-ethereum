/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InternalTransfer {
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  receive() external payable {}

  function payout(address _to, uint256 _amount) external {
    require(msg.sender == owner);
    (bool sent, ) = _to.call{value: _amount}("");
    require(sent, "Failed to send Ether");
  }
}