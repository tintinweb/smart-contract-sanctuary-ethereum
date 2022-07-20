pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract storageContract {

  event SetVar(address sender, bool bool_variable);

  bool public bool_variable = true;

  constructor() payable {
    // what should we do on deploy?
  }

  function setVar() public {
        if (bool_variable == true) {
            bool_variable = false;
        } else if (bool_variable == false) {
            bool_variable = true;
        } 
      
      emit SetVar(msg.sender, bool_variable);
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}