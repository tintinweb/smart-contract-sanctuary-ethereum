/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
contract Test3 {
  address public main_owner;
  uint256 public start_value;

  modifier restricted() {
    require(msg.sender == main_owner,"Sender is not an owner!");
      _;
  }

constructor(address _owner,uint256 _value) {
    main_owner = payable(_owner);
    start_value = _value;
  }
  
 function setOwner(address payable _owner) public restricted{
      main_owner = _owner;
      start_value = start_value +1;
  }

}