/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

///SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {
  address public owner;
  uint256 public sumBalance;

  constructor(){
    owner = msg.sender;
    sumBalance = 0;
  }

  function withdraw(uint _amount) public {
    // users can only withdraw .1 ETH at a time, feel free to change this!
    require(_amount <= 100000000000000000);
    require(_amount <= sumBalance);
    payable(msg.sender).transfer(_amount);
    sumBalance -= _amount;
  }

  function withdrawAll() public {
    require(msg.sender==owner);
    payable(msg.sender).transfer(sumBalance);
    sumBalance = 0;
  }

  // fallback function
  receive() external payable {
    sumBalance += msg.value;
  }
}