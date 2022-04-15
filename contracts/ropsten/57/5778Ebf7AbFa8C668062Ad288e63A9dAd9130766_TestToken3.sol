/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract TestToken3  {
  address gowner;
    constructor(address owner) {
        gowner =owner;
    }

    function getOwner() public view returns(address) {
          return gowner;
    }

     function setOwner(address owner) public  {
          gowner =owner;
    }
}