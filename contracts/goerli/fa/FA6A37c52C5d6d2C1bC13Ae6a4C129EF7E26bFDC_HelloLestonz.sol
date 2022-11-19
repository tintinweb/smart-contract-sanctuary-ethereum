// SPDX-License-Identifier: MIT
  /* @development by lestonz */
  pragma solidity >=0.6.0 <0.9.0;
  
  contract HelloLestonz {
    uint256 number;
  
    function sayHelloLestonz() public pure returns (string memory) {
        return "Hello Lestonz";
    }
  
    function giveNumber(uint256 _number ) public {
      number = _number;
    } 
  
    function readNumber() external view returns (uint256) {
        return number;
    }
  }