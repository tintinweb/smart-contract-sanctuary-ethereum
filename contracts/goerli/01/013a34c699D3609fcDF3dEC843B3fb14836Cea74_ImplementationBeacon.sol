// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract ImplementationBeacon  {
 
    uint256 public number;
    uint256 public number2;
 
    function setNumber() public {
        number = 1;
    }
    function setNumber2() public {
        number = 2;
    }
   
}