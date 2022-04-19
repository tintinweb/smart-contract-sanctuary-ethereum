/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: box.sol

contract box{
      uint256 private value;

      event valuechanged(uint256 newvalue);

      function store(uint256 newvalue) public {
          value = newvalue;
          emit valuechanged(newvalue);

      }

      function retrive() public view returns(uint256){
          return value;

      }




  }