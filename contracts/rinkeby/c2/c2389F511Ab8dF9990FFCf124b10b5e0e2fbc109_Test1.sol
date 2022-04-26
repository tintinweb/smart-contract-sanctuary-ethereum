/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
contract Test1 {
  address public base_owner;
  uint256 public start_value;

  modifier restricted() {
    require(msg.sender == base_owner,"Sender is not an owner!");
      _;
  }

constructor(address _owner,uint256 _value) {
    base_owner = payable(_owner);
    start_value = _value;
  }
  
 function setOwner(address payable _owner) public restricted{
      base_owner = _owner;
      start_value = start_value +1;
  }

}