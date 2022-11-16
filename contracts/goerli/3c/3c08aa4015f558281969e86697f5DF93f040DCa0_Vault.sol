/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
  string private flag;
  address payable public owner;

  constructor(string memory input) public {
    owner = payable(msg.sender);
    flag = input;
  }

  function check_flag(string memory input) payable public returns (string memory){
    require(msg.value > 0 && strcmp(flag, input), "Insufficient funds or wrong flag!");
    return flag;
  }

  function withdraw() public {
    require(msg.sender == owner, "Caller is not the owner!");
    owner.transfer(address(this).balance);
  }

  function get_flag() payable public returns (string memory) {
    require(msg.value > 133333333333333333337, "Insufficient funds!");
    return flag;
  }

  function strcmp(string memory a, string memory b) public view returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }
}